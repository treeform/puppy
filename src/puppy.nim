import puppy/common, urlly

when defined(windows) and not defined(puppyLibcurl):
  # WinHTTP Windows
  import puppy/platforms/win32/platform
elif defined(macosx) and not defined(puppyLibcurl):
  # AppKit macOS
  import puppy/platforms/macos/platform
else:
  # LIBCURL Linux
  import puppy/platforms/linux/platform

export common, urlly

proc addDefaultHeaders(req: Request) =
  if req.headers["user-agent"].len == 0:
    req.headers["user-agent"] = "Puppy"
  if req.headers["accept-encoding"].len == 0:
    # If there isn't a specific accept-encoding specified, enable gzip
    req.headers["accept-encoding"] = "gzip"

proc fetch*(req: Request): Response {.raises: [PuppyError].} =
  if req.url.scheme notin ["http", "https"]:
    raise newException(
      PuppyError, "Unsupported request scheme: " & req.url.scheme
    )

  req.addDefaultHeaders()

  if req.timeout == 0:
    req.timeout = 60

  platform.fetch(req)

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
  result.headers = headers
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
