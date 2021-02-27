import net, urlly, print, strformat, parseutils, strutils

const CRLF = "\r\n"

type
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

proc merge*(a: var seq[(string, string)], b: seq[(string, string)]) =
  for headerB in b:
    var found = false
    for headerA in a.mitems:
      if headerA[0] == headerB[0]:
        headerA[1] = headerB[1]
        found = true
    if not found:
      a.add(headerB)

proc readChunk(socket: Socket): string =
  while true:
    let line = socket.recvLine()
    print line
    result.add line & CRLF
    if line == CRLF:
      break

proc fetchStr(hostname, reqBody: string): (string, seq[string]) =
  ## Fetches a URL and returns header and chunks.
  echo reqBody

  var socket = newSocket()
  socket.connect(hostname, Port(80))
  socket.send(reqBody)

  var
    chunked: bool
    contentLength: int

  var res = ""
  while true:
    let line = socket.recvLine()
    print line
    res.add line & CRLF
    let lineLower = line.toLowerAscii()
    if line == CRLF:
      break
    elif lineLower.startsWith("content-length:"):
      contentLength = parseInt(line.split(" ")[1])
    elif lineLower == "transfer-encoding: chunked":
      chunked = true

  var chunks: seq[string]
  if chunked:
    while true:
      let chunkLenStr = socket.readChunk()
      if chunkLenStr == CRLF & CRLF: break
      var chunkLen: int
      discard parseHex(chunkLenStr, chunkLen)
      var chunk = newString(chunkLen)
      let readLen = socket.recv(chunk[0].addr, chunkLen)
      doAssert readLen == chunkLen
      chunks.add(chunk[0..^3])
  else:
      var chunk = newString(contentLength)
      let readLen = socket.recv(chunk[0].addr, contentLength)
      doAssert readLen == contentLength
      chunks.add(chunk[0..^3])

  return (res, chunks)

proc `$`(req: Request): string =
  ## Turns a req into the HTTP wire format.
  var path = req.url.path
  if path == "":
    path = "/"
  result.add "GET " & path & " HTTP/1.1" & CRLF
  result.add "Host: " & req.url.hostname & CRLF
  result.add "User-Agent: nim/puppy" & CRLF
  result.add CRLF

proc fetch(req: Request): Response =
  let (resBody, chunks) = fetchStr(req.url.hostname, $req)

  var res = Response()
  res.url = req.url

  doAssert chunks.len == 1

  let resLines = resBody.split(CRLF)
  let headerArr = resLines[0].split(" ")
  res.code = parseInt(headerArr[1])
  res.body = chunks[0]

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

print fetch("www.istrolid.com", headers = @[("Auth", "1")])
#print fetch("http://neverssl.com/")