import net, strutils, urlly, zippy

export urlly

const CRLF = "\r\n"

type
  PuppyError* = object of IOError ## Raised if an operation fails.

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
  import winim/com

  proc fetch*(req: Request): Response =
    # Fetch using win com API
    result = Response()

    let obj = CreateObject("WinHttp.WinHttpRequest.5.1")
    try:
      obj.open(req.verb.toUpperAscii(), $req.url)

      req.addDefaultHeaders()

      for header in req.headers:
        obj.setRequestHeader(header.key, header.value)

      if req.timeout == 0:
        req.timeout = 60
      let ms = int(req.timeout * 1000)
      obj.SetTimeouts(ms, ms, ms, ms)

      if req.body.len > 0:
        obj.send(req.body)
      else:
        obj.send()
    except:
      result.error = getCurrentExceptionMsg()

    result.url = req.url
    if result.error.len == 0:
      result.code = parseInt(obj.status)

      let isEmpty =
        try:
          obj.responseBody == VT_EMPTY
        except:
          false

      if not isEmpty:
        result.body = string(fromVariant[COMBinary](obj.responseBody))

      let headers = $obj.getAllResponseHeaders()
      for headerLine in headers.split(CRLF):
        let arr = headerLine.split(":", 1)
        if arr.len == 2:
          result.headers[arr[0].strip()] = arr[1].strip()

      if result.headers["content-encoding"].toLowerAscii() == "gzip":
        result.body = uncompress(result.body, dfGzip)

else:
  # LIBCURL linux/mac
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
    var outbuf = cast[ptr StringWrap](outstream)
    let i = outbuf.str.len
    outbuf.str.setLen(outbuf.str.len + count)
    copyMem(outbuf.str[i].addr, buffer, count)
    result = size * count

  proc fetch*(req: Request): Response =
    result = Response()

    let curl = easy_init()

    discard curl.easy_setopt(OPT_URL, $req.url)
    discard curl.easy_setopt(OPT_CUSTOMREQUEST, req.verb.toUpperAscii())

    if req.timeout == 0:
      req.timeout = 60
    discard curl.easy_setopt(OPT_TIMEOUT, req.timeout.int)

    req.addDefaultHeaders()

    var headerList: Pslist
    for header in req.headers:
      headerList = slist_append(headerList, header.key & ": " & header.value)

    discard curl.easy_setopt(OPT_HTTPHEADER, headerList)

    if req.body.len > 0:
      discard curl.easy_setopt(OPT_POSTFIELDS, req.body)

    # Setup writers.
    var
      headerWrap: StringWrap
      bodyWrap: StringWrap
    discard curl.easy_setopt(OPT_WRITEDATA, bodyWrap.addr)
    discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
    discard curl.easy_setopt(OPT_HEADERDATA, headerWrap.addr)
    discard curl.easy_setopt(OPT_HEADERFUNCTION, curlWriteFn)

    # On windows look for cacert.pem.
    when defined(windows):
      discard curl.easy_setopt(OPT_CAINFO, "cacert.pem")
    # Follow redirects by default.
    discard curl.easy_setopt(OPT_FOLLOWLOCATION, 1)

    let
      ret = curl.easy_perform()
      headerData = headerWrap.str
      bodyData = bodyWrap.str

    result.url = req.url

    if ret == E_OK:
      var httpCode: uint32
      discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
      result.code = httpCode.int
      for headerLine in headerData.split(CRLF):
        let arr = headerLine.split(":", 1)
        if arr.len == 2:
          result.headers[arr[0].strip()] = arr[1].strip()
      result.body = bodyData
      if result.headers["Content-Encoding"] == "gzip":
        result.body = uncompress(result.body, dfGzip)
    else:
      result.error = $easy_strerror(ret)

    curl.easy_cleanup()
    slist_free_all(headerList)

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
  let req = newRequest(url, verb, headers)
  let res = req.fetch()
  if res.code == 200:
    return res.body
