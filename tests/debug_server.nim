import asyncdispatch, asynchttpserver, zippy, uri

let server = newAsyncHttpServer()

proc cb(req: Request) {.async.} =
  echo "got request"

  if req.url.path == "/401":
    echo "responding with 401 - no body"
    await req.respond(Http401, "")

  if req.url.path == "/url":
    echo "responding with 200 - with url sent"
    echo $req.url
    await req.respond(Http200, $req.url)

  if req.url.path == "/gzip":
    if req.headers.hasKey("Accept-Encoding") and
      req.headers["Accept-Encoding"].contains("gzip"):
      echo "sending gzip result"
      let headers = newHttpHeaders([("Content-Encoding", "gzip")])
      await req.respond(
        Http200,
        compress("gzip'ed response body", BestSpeed, dfGzip),
        headers
      )
    else:
      echo "sending pain text result"
      await req.respond(Http200, "uncompressed response body")

waitFor server.serve(Port(8080), cb)
