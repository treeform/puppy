import asyncdispatch, asynchttpserver, uri, urlly, zippy

let server = newAsyncHttpServer()

proc cb(req: Request) {.async.} =
  echo "got request ", $req.url

  if req.url.path == "/ok":
    await req.respond(Http200, "ok")
    return

  if req.url.path == "/slow":
    await sleepAsync(5000)
    await req.respond(Http200, "ok... slow")
    return

  if req.url.path == "/page":
    let url = parseUrl($req.url)
    await sleepAsync(100)
    await req.respond(Http200, url.query["ret"])
    return

  if req.url.path == "/401":
    await req.respond(Http401, "")
    return

  if req.url.path == "/500":
    await req.respond(Http500, "500 Unkown Error (simulated).")
    return

  if req.url.path == "/post":
    if req.headers["Content-Length"] == "":
      await req.respond(Http200, "missing content-length header")
    else:
      await req.respond(Http200, req.body)
    return

  if req.url.path == "/url":
    await req.respond(Http200, $req.url)
    return

  if req.url.path == "/gzip":
    if req.headers.hasKey("Accept-Encoding") and
      req.headers["Accept-Encoding"].contains("gzip"):
      let headers = newHttpHeaders([("Content-Encoding", "gzip")])
      await req.respond(
        Http200,
        compress("gzip'ed response body", BestSpeed, dfGzip),
        headers
      )
    else:
      await req.respond(Http200, "uncompressed response body")
    return

  if req.url.path == "/postgzip":
    if req.headers.hasKey("Accept-Encoding") and
        req.headers["Accept-Encoding"].contains("gzip") and
        req.headers.hasKey("Content-Encoding") and
        req.headers["Content-Encoding"].contains("gzip"):
      let headers = newHttpHeaders([("Content-Encoding", "gzip")])
      let body = uncompress(req.body, dfGzip)
      await req.respond(
        Http200,
        compress(body, BestSpeed, dfGzip),
        headers
      )
      return

  if req.url.path == "/headers":
    var headers = newHttpHeaders()
    for key, value in req.headers.pairs:
      if key in ["accept", "user-agent"]:
        continue
      headers.add(value, key)
    await req.respond(Http200, $req.url, headers)
    return

  await req.respond(Http404, "Not found.")

waitFor server.serve(Port(8080), cb)
