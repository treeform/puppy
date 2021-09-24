import puppy/common, net, strutils, urlly, zippy

export common, urlly

const CRLF = "\r\n"

type
  Header* = object
    key*: string
    value*: string

  Request* = ref object
    url*: Url
    headers*: seq[Header]
    timeout*: float32
    verb*: string
    body*: string

  Response* = ref object
    url*: Url
    headers*: seq[Header]
    code*: int
    body*: string
    error*: string

func `[]`*(headers: seq[Header], key: string): string =
  ## Get a key out of headers. Not case sensitive.
  ## Use a for loop to get multiple keys.
  for header in headers:
    if header.key.toLowerAscii() == key.toLowerAscii():
      return header.value

func `[]=`*(headers: var seq[Header], key, value: string) =
  ## Sets a key in the headers. Not case sensitive.
  ## If key is not there appends a new key-value pair at the end.
  for header in headers.mitems:
    if header.key.toLowerAscii() == key.toLowerAscii():
      header.value = value
      return
  headers.add(Header(key: key, value: value))

proc `$`*(req: Request): string =
  ## Turns a req into the HTTP wire format.
  var path = req.url.path
  if path == "":
    path = "/"
  if req.url.query.len > 0:
    path.add "?"
    path.add req.url.search

  result.add "GET " & path & " HTTP/1.1" & CRLF
  result.add "Host: " & req.url.hostname & CRLF
  for header in req.headers:
    result.add header.key & ": " & header.value & CRLF
  result.add CRLF

proc merge(a: var seq[Header], b: seq[Header]) =
  for headerB in b:
    var found = false
    for headerA in a.mitems:
      if headerA.key.toLowerAscii() == headerB.key.toLowerAscii():
        headerA.value = headerB.value
        found = true
    if not found:
      a.add(headerB)

proc addDefaultHeaders(req: Request) =
  if req.headers["user-agent"].len == 0:
    req.headers["user-agent"] = "nim/puppy"
  if req.headers["accept-encoding"].len == 0:
    # If there isn't a specific accept-encoding specified, enable gzip
    req.headers["accept-encoding"] = "gzip"

when defined(windows) and not defined(puppyLibcurl):
  # WIN32 API
  import puppy/winhttp

  proc fetch*(req: Request): Response =
    # Fetch using win com API
    result = Response()

    let winHttp = newWinHttp()
    try:
      # Trim #hash-fragment from URL like curl does.
      var url = $req.url
      if req.url.fragment.len != 0:
        url.setLen(url.len - req.url.fragment.len - 1)

      winHttp.open(req.verb.toUpperAscii(), url)

      req.addDefaultHeaders()

      for header in req.headers:
        winHttp.setRequestHeader(header.key, header.value)

      if req.timeout == 0:
        req.timeout = 60
      let ms = int(req.timeout * 1000)
      winHttp.setTimeouts(ms, ms, ms, ms)

      winHttp.send(req.body)
    except:
      result.error = getCurrentExceptionMsg()

    result.url = req.url
    if result.error.len == 0:
      result.code = winHttp.status
      result.body = winHttp.responseBody

      let headers = winHttp.getAllResponseHeaders()
      for headerLine in headers.split(CRLF):
        let arr = headerLine.split(":", 1)
        if arr.len == 2:
          result.headers[arr[0].strip()] = arr[1].strip()

      if result.headers["content-encoding"].toLowerAscii() == "gzip":
        result.body = uncompress(result.body, dfGzip)

elif defined(macosx) and not defined(puppyLibcurl):
  # AppKit macOS
  import puppy/machttp

  proc fetch*(req: Request): Response =
    var url = $req.url
    if req.url.fragment.len != 0:
      url.setLen(url.len - req.url.fragment.len - 1)

    if req.timeout == 0:
      req.timeout = 60

    let macHttp = newRequest(req.verb.toUpperAscii(), $req.url, req.timeout)

    req.addDefaultHeaders()
    for header in req.headers:
      macHttp.setHeader(header.key, header.value)

    macHttp.sendSync(req.body, req.body.len)

    result = Response()
    result.url = req.url

    result.code = macHttp.getCode()

    if result.code == 200:
      var
        data: ptr[char]
        len: int
      macHttp.getResponseBody(data.addr, len.addr)
      if len > 0:
        result.body = newString(len)
        copyMem(result.body[0].addr, data, len)

    block:
      var
        data: ptr[char]
        len: int
      macHttp.getResponseHeaders(data.addr, len.addr)
      if len > 0:
        let headers = newString(len)
        copyMem(headers[0].unsafeAddr, data, len)
        for headerLine in headers.split(CRLF):
          let arr = headerLine.split(":", 1)
          if arr.len == 2:
            result.headers[arr[0].strip()] = arr[1].strip()

    if result.code != 200:
      var
        data: ptr[char]
        len: int
      macHttp.getResponseError(data.addr, len.addr)
      if len > 0:
        result.error = newString(len)
        copyMem(result.error[0].addr, data, len)

    macHttp.freeRequest()

else:
  # LIBCURL linux
  import libcurl

  type
    StringWrap = object
      ## As strings are value objects they need
      ## some sort of wrapper to be passed to C.
      str: string

  proc curlWriteFn(
    buffer: cstring,
    size: int,
    count: int,
    outstream: pointer
  ): int {.cdecl.} =
    if size != 1:
      raise newException(PuppyError, "Unexpected curl write callback size")
    let
      outbuf = cast[ptr StringWrap](outstream)
      i = outbuf.str.len
    outbuf.str.setLen(outbuf.str.len + count)
    copyMem(outbuf.str[i].addr, buffer, count)
    result = size * count

  proc fetch*(req: Request): Response =
    result = Response()

    req.addDefaultHeaders()

    var strings: seq[string]
    strings.add $req.url
    strings.add req.verb.toUpperAscii()
    for header in req.headers:
      strings.add header.key & ": " & header.value

    let curl = easy_init()
    try:
      discard curl.easy_setopt(OPT_URL, strings[0].cstring)
      discard curl.easy_setopt(OPT_CUSTOMREQUEST, strings[1].cstring)

      if req.timeout == 0:
        req.timeout = 60
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

      if req.body.len > 0:
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

      let
        ret = curl.easy_perform()
        headerData = headerWrap.str

      result.url = req.url

      if ret == E_OK:
        var httpCode: uint32
        discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
        result.code = httpCode.int
        for headerLine in headerData.split(CRLF):
          let arr = headerLine.split(":", 1)
          if arr.len == 2:
            result.headers[arr[0].strip()] = arr[1].strip()
        result.body = bodyWrap.str
        if result.headers["Content-Encoding"] == "gzip":
          result.body = uncompress(result.body, dfGzip)
      else:
        result.error = $easy_strerror(ret)
    finally:
      curl.easy_cleanup()
      strings.setLen(0) # Make sure strings sticks around until now

proc newRequest*(
  url: string,
  verb = "get",
  headers = newSeq[Header](),
  timeout: float32 = 60
): Request =
  ## Allocates a new request object with defaults.
  result = Request()
  result.url = parseUrl(url)
  result.verb = verb
  result.headers.merge(headers)
  result.timeout = timeout

proc fetch*(url: string, verb = "get", headers = newSeq[Header]()): string =
  let
    req = newRequest(url, verb, headers)
    res = req.fetch()
  if res.code == 200:
    return res.body
