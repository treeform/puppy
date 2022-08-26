import libcurl, puppy/common, std/strutils, zippy

type StringWrap = object
  ## As strings are value objects they need
  ## some sort of wrapper to be passed to C.
  str: string

proc fetch*(req: Request): Response {.raises: [PuppyError].} =
  result = Response()

  {.push stackTrace: off.}

  proc curlWriteFn(
    buffer: cstring,
    size: int,
    count: int,
    outstream: pointer
  ): int {.cdecl.} =
    let
      outbuf = cast[ptr StringWrap](outstream)
      i = outbuf.str.len
    outbuf.str.setLen(outbuf.str.len + count)
    copyMem(outbuf.str[i].addr, buffer, count)
    result = size * count

  {.pop.}

  var strings: seq[string]
  strings.add $req.url
  strings.add req.verb.toUpperAscii()
  for header in req.headers:
    strings.add header.key & ": " & header.value

  let curl = easy_init()

  discard curl.easy_setopt(OPT_URL, strings[0].cstring)
  discard curl.easy_setopt(OPT_CUSTOMREQUEST, strings[1].cstring)
  discard curl.easy_setopt(OPT_TIMEOUT, req.timeout.int)

  # Create the Pslist for passing headers to curl manually. This is to
  # avoid needing to call slist_free_all which creates problems
  var slists: seq[Slist]
  for i, header in req.headers:
    slists.add Slist(data: strings[2 + i].cstring, next: nil)
  # Do this in two passes so the slists index addresses are stable
  var headerList: Pslist
  for i, header in req.headers:
    if i == 0:
      headerList = slists[0].addr
    else:
      var tail = headerList
      while tail.next != nil:
        tail = tail.next
      tail.next = slists[i].addr

  discard curl.easy_setopt(OPT_HTTPHEADER, headerList)

  if req.verb.toUpperAscii() == "POST" or req.body.len > 0:
    discard curl.easy_setopt(OPT_POSTFIELDSIZE, req.body.len)
    discard curl.easy_setopt(OPT_POSTFIELDS, req.body.cstring)

  # Setup writers.
  var headerWrap, bodyWrap: StringWrap
  discard curl.easy_setopt(OPT_WRITEDATA, bodyWrap.addr)
  discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
  discard curl.easy_setopt(OPT_HEADERDATA, headerWrap.addr)
  discard curl.easy_setopt(OPT_HEADERFUNCTION, curlWriteFn)

  # On windows look for cacert.pem.
  when defined(windows):
    discard curl.easy_setopt(OPT_CAINFO, "cacert.pem".cstring)
  # Follow redirects by default.
  discard curl.easy_setopt(OPT_FOLLOWLOCATION, 1)

  if req.allowAnyHttpsCertificate:
    discard curl.easy_setopt(OPT_SSL_VERIFYPEER, 0)
    discard curl.easy_setopt(OPT_SSL_VERIFYHOST, 0)

  let
    ret = curl.easy_perform()
    headerData = headerWrap.str

  curl.easy_cleanup()

  if ret == E_OK:
    var httpCode: uint32
    discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
    result.code = httpCode.int
    for headerLine in headerData.split(CRLF):
      let arr = headerLine.split(":", 1)
      if arr.len == 2:
        result.headers.add(Header(key: arr[0].strip(), value: arr[1].strip()))
    result.body = bodyWrap.str
    if result.headers["Content-Encoding"] == "gzip":
      try:
        result.body = uncompress(result.body, dfGzip)
      except ZippyError as e:
        raise newException(PuppyError, "Error uncompressing response", e)
  else:
    raise newException(PuppyError, $easy_strerror(ret))
