import macdefs, objc, puppy/common, std/strutils

proc fetch*(req: Request): Response {.raises: [PuppyError].} =
  result = Response()

  autoreleasepool:
    let request = NSMutableURLRequest.requestWithURL(
      NSURL.URLWithString(@($req.url)),
      NSURLRequestReloadIgnoringLocalCacheData,
      req.timeout
    )

    request.setHTTPMethod(@(req.verb.toUpperAscii()))

    for header in req.headers:
      request.setValue(@(header.value), @(header.key))

    if req.body.len > 0:
      request.setHTTPBody(NSData.dataWithBytes(req.body[0].addr, req.body.len))

    var
      response: NSHTTPURLResponse
      error: NSError
    let data = NSURLConnection.sendSynchronousRequest(
      request,
      response.addr,
      error.addr
    )

    if response.int != 0:
      result.code = response.statusCode

      let
        dictionary = response.allHeaderFields
        keyEnumerator = dictionary.keyEnumerator
      while true:
        let key = keyEnumerator.nextObject
        if key.int == 0:
          break
        let value = dictionary.objectForKey(key)
        result.headers[$(key.NSString)] = $(value.NSString)

      if data.length > 0:
        result.body.setLen(data.length)
        copyMem(result.body[0].addr, data.bytes, result.body.len)

    if error.int != 0 and error.code != NSURLErrorUserCancelledAuthentication:
      raise newException(PuppyError, $error)
