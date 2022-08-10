import libcurl, puppy/common, std/strutils, zippy
type StringWrap = object
  ## As strings are value objects they need
  ## some sort of wrapper to be passed to C.
  str: string
proc fetch*(req: Request): Response {.raises: [PuppyError].} =
  result = Response()
  {.push stackTrace: off.}
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
@@ -74,6 +72,10 @@ proc fetch*(req: Request): Response {.raises: [PuppyError].} =
  # Follow redirects by default.
  discard curl.easy_setopt(OPT_FOLLOWLOCATION, 1)

  if req.allowAnyHttpsCertificate:
    discard curl.easy_setopt(OPT_SSL_VERIFYPEER, 0)
    discard curl.easy_setopt(OPT_SSL_VERIFYHOST, 0)

  let
    ret = curl.easy_perform()
    headerData = headerWrap.str
  curl.easy_cleanup()
  if ret == E_OK:
    var httpCode: uint32
    discard curl.easy_getinfo(INFO_RESPONSE_CODE, httpCode.addr)
    result.code = httpCode.int
    for headerLine in headerData.split(CRLF):
      let arr = headerLine.split(":", 1)
      if arr.len == 2:
        result.headers.add(Header(key: arr[0].strip(), value: arr[1].strip()))
    result.body = bodyWrap.str
    if result.headers["Content-Encoding"] == "gzip":
      try:
        result.body = uncompress(result.body, dfGzip)
      except ZippyError as e:
        raise newException(PuppyError, "Error uncompressing response", e)
  else:
    raise newException(PuppyError, $easy_strerror(ret))