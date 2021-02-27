import os, net, urlly, parseutils, strutils

export urlly

const CRLF = "\r\n"

type

  PuppyError* = object of IOError ## Raised if an operation fails.

  Request* = ref object
    url*: Url
    headers*: seq[(string, string)]

  Response* = ref object
    url*: Url
    code*: int
    body*: string

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

proc fetchStr(req: Request): (string, seq[string]) =
  ## Fetches a URL and returns header and chunks.

  var socket = newSocket()
  if req.url.scheme == "https":
    var ctx =
      try:
        let certFile = getCurrentDir() / "cacert.pem"
        echo certFile
        echo existsFile(certFile)
        newContext(verifyMode = CVerifyPeer, certFile = certFile)
      except:
        var message = getCurrentExceptionMsg()
        raise newException(PuppyError, message)

    #wrapSocket(ctx, socket)
    socket.connect(req.url.hostname, Port(443))
    try:
      ctx.wrapConnectedSocket(
        socket, handshakeAsClient, req.url.hostname)
    except:
      var message = getCurrentExceptionMsg()
      if "error:14094410:SSL" in message:
        message = "Not Secure: Domain failed SSL certificate check."
      raise newException(PuppyError, message)

  else:
    socket.connect(req.url.hostname, Port(80))

  socket.send($req)

  var
    chunked: bool
    contentLength: int

  var res = ""
  while true:
    let line = socket.recvLine()
    res.add line & CRLF
    let lineLower = line.toLowerAscii()
    if line == CRLF:
      break
    elif lineLower.startsWith("content-length:"):
      contentLength = parseInt(line.split(" ")[1])
    elif lineLower.startsWith("x-uncompressed-content-length:"):
      contentLength = parseInt(line.split(" ")[1])
    elif lineLower == "transfer-encoding: chunked":
      chunked = true

  var chunks: seq[string]
  if chunked:
    while true:
      var chunkLenStr: string
      while true:
        var readChar: char
        let readLen = socket.recv(readChar.addr, 1)
        doAssert readLen == 1
        chunkLenStr.add(readChar)
        if chunkLenStr.endsWith(CRLF):
          break
      if chunkLenStr == CRLF:
        break
      var chunkLen: int
      discard parseHex(chunkLenStr, chunkLen)
      if chunkLen == 0:
        break
      var chunk = newString(chunkLen)
      let readLen = socket.recv(chunk[0].addr, chunkLen)
      doAssert readLen == chunkLen
      chunks.add(chunk)
      var endStr = newString(2)
      let readLen2 = socket.recv(endStr[0].addr, 2)
      doAssert endStr == CRLF
  else:
      var chunk = newString(contentLength)
      let readLen = socket.recv(chunk[0].addr, contentLength)
      doAssert readLen == contentLength
      chunks.add(chunk[0..^3])

  return (res, chunks)

proc fetch(req: Request): Response =
  let (resBody, chunks) = fetchStr(req)

  var res = Response()
  res.url = req.url

  let resLines = resBody.split(CRLF)
  let headerArr = resLines[0].split(" ")
  res.code = parseInt(headerArr[1])
  res.body = join(chunks)
  return res

proc fetch*(url: string): string =
  var req = newRequest()
  req.url = parseUrl(url)
  let res = req.fetch()
  return res.body

proc fetch*(url: string, headers: seq[(string, string)]): string =
  var req = newRequest()
  req.url = parseUrl(url)
  req.headers.merge(headers)
  let res = req.fetch()
  return res.body

when defined(windows) and defined(ssl):
  let caCertPath = getAppDir() / "cacert.pem"
  if not fileExists(caCertPath):
    echo caCertPath
    let cmd = """powershell -Command "Invoke-WebRequest -outf """ &
      caCertPath &
      """ http://curl.se/ca/cacert.pem""""
    echo cmd
    let code = execShellCmd(
      cmd
    )
    if code != 0:
      raise newException(PuppyError, "Could not download cacert.pem")
