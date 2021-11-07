import net, puppy/common, strutils, urlly, zippy

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
    req.headers["user-agent"] = "Puppy"
  if req.headers["accept-encoding"].len == 0:
    # If there isn't a specific accept-encoding specified, enable gzip
    req.headers["accept-encoding"] = "gzip"

when defined(windows) and not defined(puppyLibcurl):
  # WinHTTP Windows
  import puppy/windefs, puppy/winutils
elif defined(macosx) and not defined(puppyLibcurl):
  # AppKit macOS
  import puppy/machttp
else:
  # LIBCURL Linux
  import libcurl

proc fetch*(req: Request): Response =
  if req.url.scheme notin ["http", "https"]:
    raise newException(
      PuppyError, "Unsupported request scheme: " & req.url.scheme
    )

  result = Response()
  result.url = req.url

  req.addDefaultHeaders()

  if req.timeout == 0:
    req.timeout = 60

  when defined(windows) and not defined(puppyLibcurl):
    proc `$`(p: ptr WCHAR): string =
      let len = WideCharToMultiByte(
        CP_UTF8,
        0,
        p,
        -1,
        nil,
        0,
        nil,
        nil
      )
      if len > 0:
        result.setLen(len)
        discard WideCharToMultiByte(
          CP_UTF8,
          0,
          p,
          -1,
          result[0].addr,
          len,
          nil,
          nil
        )
        # The null terminator is included when -1 is used for the parameter length.
        # Trim this null terminating character.
        result.setLen(len - 1)

    var hSession, hConnect, hRequest: HINTERNET
    try:
      let wideUserAgent = req.headers["user-agent"].toUtf16()

      hSession = WinHttpOpen(
        wideUserAgent[0].unsafeAddr,
        WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,
        nil,
        nil,
        0
      )
      if hSession == nil:
        raise newException(
          PuppyError, "WinHttpOpen error: " & $GetLastError()
        )

      let ms = (req.timeout * 1000).int32
      if WinHttpSetTimeouts(hSession, ms, ms, ms, ms) == 0:
        raise newException(
          PuppyError, "WinHttpSetTimeouts error: " & $GetLastError()
        )

      var port: INTERNET_PORT
      if req.url.port == "":
        case req.url.scheme:
        of "http":
          port = 80
        of "https":
          port = 443
        else:
          discard # Scheme is validated above
      else:
        try:
          let parsedPort = parseInt(req.url.port)
          if parsedPort < 0 or parsedPort > uint16.high.int:
            raise newException(PuppyError, "Invalid port: " & req.url.port)
          port = parsedPort.uint16
        except ValueError as e:
          raise newException(PuppyError, "Parsing port failed", e)

      let wideHostname = req.url.hostname.toUtf16()

      hConnect = WinHttpConnect(
        hSession,
        wideHostname[0].unsafeAddr,
        port,
        0
      )
      if hConnect == nil:
        raise newException(
          PuppyError, "WinHttpConnect error: " & $GetLastError()
        )

      var openRequestFlags: DWORD
      if req.url.scheme == "https":
        openRequestFlags = openRequestFlags or WINHTTP_FLAG_SECURE

      var objectName = req.url.path
      if req.url.search != "":
        objectName &= "?" & req.url.search

      let
        wideVerb = req.verb.toUpperAscii().toUtf16()
        wideObjectName = objectName.toUtf16()

      let
        defaultAcceptType = "*/*".toUtf16()
        defaultacceptTypes = [
          defaultAcceptType[0].unsafeAddr,
          nil
        ]

      hRequest = WinHttpOpenRequest(
        hConnect,
        wideVerb[0].unsafeAddr,
        wideObjectName[0].unsafeAddr,
        nil,
        nil,
        cast[ptr ptr WCHAR](defaultacceptTypes.unsafeAddr),
        openRequestFlags.DWORD
      )
      if hRequest == nil:
        raise newException(
          PuppyError, "WinHttpOpenRequest error: " & $GetLastError()
        )

      var requestHeaderBuf: string
      for header in req.headers:
        requestHeaderBuf &= header.key & ": " & header.value & CRLF

      let wideRequestHeaderBuf = requestHeaderBuf.toUtf16()

      if WinHttpAddRequestHeaders(
        hRequest,
        wideRequestHeaderBuf[0].unsafeAddr,
        -1,
        (WINHTTP_ADDREQ_FLAG_ADD or WINHTTP_ADDREQ_FLAG_REPLACE).DWORD
      ) == 0:
        raise newException(
          PuppyError, "WinHttpAddRequestHeaders error: " & $GetLastError()
        )

      if WinHttpSendRequest(
        hRequest,
        nil,
        0,
        req.body.cstring,
        req.body.len.DWORD,
        req.body.len.DWORD,
        0
      ) == 0:
        raise newException(
          PuppyError, "WinHttpSendRequest error: " & $GetLastError()
        )

      if WinHttpReceiveResponse(hRequest, nil) == 0:
        raise newException(
          PuppyError, "WinHttpReceiveResponse error: " & $GetLastError()
        )

      var
        statusCode: DWORD
        dwSize = sizeof(DWORD).DWORD
      if WinHttpQueryHeaders(
        hRequest,
        WINHTTP_QUERY_STATUS_CODE or WINHTTP_QUERY_FLAG_NUMBER,
        nil,
        statusCode.addr,
        dwSize.addr,
        nil
      ) == 0:
        raise newException(
          PuppyError, "WinHttpQueryHeaders error: " & $GetLastError()
        )

      result.code = statusCode

      var responseHeaderBuf = newString(8192)

      proc readResponseHeaders() =
        # Read the response headers. This may be called again after resizing
        # the buffer.
        var responseHeaderBytes = responseHeaderBuf.len.DWORD
        if WinHttpQueryHeaders(
          hRequest,
          WINHTTP_QUERY_RAW_HEADERS_CRLF,
          nil,
          responseHeaderBuf.cstring,
          responseHeaderBytes.addr,
          nil
        ) == 0:
          let errorCode = GetLastError()
          if errorCode == ERROR_INSUFFICIENT_BUFFER:
            responseHeaderBuf.setLen(responseHeaderBytes)
            readResponseHeaders()
          else:
            raise newException(
              PuppyError, "HttpQueryInfoW error: " & $errorCode
            )
        else:
          responseHeaderBuf.setLen(responseHeaderBytes)

      readResponseHeaders()

      let responseHeaders =
        ($cast[ptr WCHAR](responseHeaderBuf[0].addr)).split(CRLF)

      template errorParsingResponseHeaders() =
        raise newException(PuppyError, "Error parsing response headers")

      if responseHeaders.len == 0:
        errorParsingResponseHeaders()

      for i, line in responseHeaders:
        if i == 0: # HTTP/1.1 200 OK
          continue
        if line != "":
          let parts = line.split(":", 1)
          if parts.len == 2:
            result.headers[parts[0].strip()] = parts[1].strip()

      var i: int
      result.body.setLen(8192)

      while true:
        var bytesRead: DWORD
        if WinHttpReadData(
          hRequest,
          result.body[i].addr,
          (result.body.len - i).DWORD,
          bytesRead.addr
        ) == 0:
          raise newException(
            PuppyError, "WinHttpReadData error: " & $GetLastError()
          )

        i += bytesRead

        if bytesRead == 0:
          break

        if i == result.body.len:
          result.body.setLen(min(i * 2, i + 100 * 1024 * 1024))

      result.body.setLen(i)

      if result.headers["content-encoding"].toLowerAscii() == "gzip":
        result.body = uncompress(result.body, dfGzip)
    finally:
      discard WinHttpCloseHandle(hRequest)
      discard WinHttpCloseHandle(hConnect)
      discard WinHttpCloseHandle(hSession)

  elif defined(macosx) and not defined(puppyLibcurl):
    let macHttp = newRequest(req.verb.toUpperAscii(), $req.url, req.timeout)

    for header in req.headers:
      macHttp.setHeader(header.key, header.value)

    macHttp.sendSync(req.body, req.body.len)

    result.code = macHttp.getCode()

    block:
      var
        data: ptr char
        len: int
      macHttp.getResponseBody(data.addr, len.addr)
      if len > 0:
        result.body = newString(len)
        copyMem(result.body[0].addr, data, len)

    block:
      var
        data: ptr char
        len: int
      macHttp.getResponseHeaders(data.addr, len.addr)
      if len > 0:
        let headers = newString(len)
        copyMem(headers[0].unsafeAddr, data, len)
        for headerLine in headers.split(CRLF):
          let arr = headerLine.split(":", 1)
          if arr.len == 2:
            result.headers[arr[0].strip()] = arr[1].strip()

    var error: string
    block:
      var
        data: ptr char
        len: int
      macHttp.getResponseError(data.addr, len.addr)
      if len > 0:
        error.setLen(len)
        copyMem(error[0].addr, data, len)

    macHttp.freeRequest()

    if error != "":
      raise newException(PuppyError, error)

  else:
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

    if req.body.len > 0:
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

    let
      ret = curl.easy_perform()
      headerData = headerWrap.str

    curl.easy_cleanup()
    strings.setLen(0) # Make sure strings sticks around until now

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
      raise newException(PuppyError, $easy_strerror(ret))

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

proc fetch*(url: string, headers = newSeq[Header]()): string =
  let
    req = newRequest(url, "get", headers)
    res = req.fetch()
  if res.code == 200:
    return res.body
  raise newException(PuppyError,
    "Non 200 response code: " & $res.code & "\n" & res.body
  )
