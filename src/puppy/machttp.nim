{.
  passL: "-framework AppKit",
  compile: "machttp.m",
.}

type MacRequest = object

proc newRequest*(
  httpMethod, url: cstring, timeout: cfloat
): ptr MacRequest {.cdecl, importc.}

proc setHeader*(
  req: ptr MacRequest,
  key: cstring,
  value: cstring
) {.cdecl, importc.}

proc sendSync*(
  req: ptr MacRequest,
  body: cstring,
  bodyLen: int
) {.cdecl, importc.}

proc getCode*(
  req: ptr MacRequest
): int {.cdecl, importc.}

proc getResponseBody*(
  req: ptr MacRequest,
  data: ptr ptr char,
  length: ptr int
) {.cdecl, importc.}

proc getResponseError*(
  req: ptr MacRequest,
  data: ptr ptr char,
  length: ptr int
) {.cdecl, importc.}

proc getResponseHeaders*(
  req: ptr MacRequest,
  data: ptr ptr char,
  length: ptr int
) {.cdecl, importc.}

proc freeRequest*(
  req: ptr MacRequest
) {.cdecl, importc.}
