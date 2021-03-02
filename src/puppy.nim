import net, urlly, strutils
export urlly

const CRLF = "\r\n"

type
  PuppyError* = object of IOError ## Raised if an operation fails.

  Request* = ref object
    url*: Url
    headers*: seq[(string, string)]
    verb*: string
    body*: string

  Response* = ref object
    url*: Url
    headers*: seq[(string, string)]
    code*: int
    body*: string
    error*: string

proc newRequest*(): Request =
  result = Request()
  result.headers["User-Agent"] = "nim/puppy"

proc `$`(req: Request): string =
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
    result.add header[0] & ": " & header[1] & CRLF
  result.add CRLF

proc merge*(a: var seq[(string, string)], b: seq[(string, string)]) =
  for headerB in b:
    var found = false
    for headerA in a.mitems:
      if headerA[0] == headerB[0]:
        headerA[1] = headerB[1]
        found = true
    if not found:
      a.add(headerB)

when not defined(libcurl) and defined(windows):
  # WIN32 API
  import winim/com

  proc fetch*(req: Request): Response =
    # Fetch using win com API
    var res = Response()

    var obj = CreateObject("WinHttp.WinHttpRequest.5.1")
    try:
      obj.open(req.verb.toUpperAscii(), $req.url)
      for (k, v) in req.headers:
        obj.setRequestHeader(k, v)
      if req.body.len > 0:
        obj.send(req.body)
      else:
        obj.send()
    except:
      res.error = getCurrentExceptionMsg()
    res.url = req.url
    if res.error.len == 0:
      res.code = parseInt(obj.status)
      res.body = $obj.responseText

      let headers = $obj.getAllResponseHeaders()
      for headerLine in headers.split(CRLF):
        let arr = headerLine.split(":", 1)
        if arr.len == 2:
          res.headers.add((arr[0].strip(), arr[1].strip()))

    return res

else:
  # LIBCURL linux/mac

  import libcurl

  proc curlWriteFn(
    buffer: cstring,
    size: int,
    count: int,
    outstream: pointer
  ): int {.cdecl.} =
    var outbuf = cast[ref string](outstream)
    outbuf[].add($buffer)
    result = size * count

  proc fetch*(req: Request): Response =

    let curl = easy_init()

    discard curl.easy_setopt(OPT_URL, $req.url)
    discard curl.easy_setopt(OPT_CUSTOMREQUEST, req.verb.toUpperAscii())

    var headerList: Pslist
    for (k, v) in req.headers:
      headerList = slist_append(headerList, k & ": " & v)
    discard curl.easy_setopt(OPT_HTTPHEADER, headerList)

    if req.body.len > 0:
      discard curl.easy_setopt(OPT_POSTFIELDS, req.body)

    # Setup writers.
    var
      headerData: ref string = new string
      bodyData: ref string = new string
    discard curl.easy_setopt(OPT_WRITEDATA, bodyData)
    discard curl.easy_setopt(OPT_WRITEFUNCTION, curlWriteFn)
    discard curl.easy_setopt(OPT_HEADERDATA, headerData)
    discard curl.easy_setopt(OPT_HEADERFUNCTION, curlWriteFn)
    # On windows look for cacert.pem.
    when defined(windows):
      discard curl.easy_setopt(OPT_CAINFO, "cacert.pem")
    # Follow redirects by default.
    discard curl.easy_setopt(OPT_FOLLOWLOCATION, 1)

    let ret = curl.easy_perform()
    var res = Response()
    res.url = req.url

    if ret == E_OK:
      var httpCode: uint32
      discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
      res.code = httpCode.int
      for headerLine in headerData[].split(CRLF):
        let arr = headerLine.split(":", 1)
        if arr.len == 2:
          res.headers.add((arr[0].strip(), arr[1].strip()))
      res.body = bodyData[]
    else:
      res.error = $easy_strerror(ret)

    curl.easy_cleanup()
    slist_free_all(headerList)
    return res

proc fetch*(url: string, verb = "get"): string =
  var req = newRequest()
  req.url = parseUrl(url)
  req.verb = verb
  let res = req.fetch()
  return res.body

proc fetch*(url: string, verb = "get", headers: seq[(string, string)]): string =
  var req = newRequest()
  req.url = parseUrl(url)
  req.verb = verb
  req.headers.merge(headers)
  let res = req.fetch()
  return res.body
