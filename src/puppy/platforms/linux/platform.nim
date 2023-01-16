import libcurl, puppy/common, std/strutils, zippy

block:
  ## If you did not already call curl_global_init then
  ## curl_easy_init does it automatically.
  ## This may be lethal in multi-threaded cases since curl_global_init
  ## is not thread-safe.
  ## https://curl.se/libcurl/c/curl_easy_init.html
  let ret = global_init(GLOBAL_DEFAULT)
  if ret != E_OK:
    raise newException(Defect, $easy_strerror(ret))

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
  for (k, v) in req.headers:
    strings.add k & ": " & v

  let curl = easy_init()
  defer:
    curl.easy_cleanup()

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

  # On Windows look for cacert.pem.
  when defined(windows):
    discard curl.easy_setopt(OPT_CAINFO, "cacert.pem".cstring)

  # Follow up to 10 redirects by default.
  discard curl.easy_setopt(OPT_FOLLOWLOCATION, 1)
  discard curl.easy_setopt(OPT_MAXREDIRS, 10)

  if req.allowAnyHttpsCertificate:
    discard curl.easy_setopt(OPT_SSL_VERIFYPEER, 0)
    discard curl.easy_setopt(OPT_SSL_VERIFYHOST, 0)

  let
    ret = curl.easy_perform()
    headerData = headerWrap.str

  if ret == E_OK:
    var httpCode: uint32
    discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
    result.code = httpCode.int

    var responseUrl: cstring
    discard curl.easy_getinfo(INFO_EFFECTIVE_URL, responseUrl.addr)
    result.url = $responseUrl

    for headerLine in headerData.split(CRLF):
      let arr = headerLine.split(":", 1)
      if arr.len == 2:
        result.headers.add((arr[0].strip(), arr[1].strip()))
    
    result.body = bodyWrap.str
    if result.headers["Content-Encoding"] == "gzip":
      try:
        result.body = uncompress(result.body, dfGzip)
      except ZippyError as e:
        raise newException(PuppyError, "Error uncompressing response", e)
  else:
    raise newException(PuppyError, $easy_strerror(ret))
