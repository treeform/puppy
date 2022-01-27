import std/typetraits

{.passL: "-framework AppKit".}

type
  Class* = distinct int
  ID* = distinct int
  SEL* = distinct int

{.push importc, cdecl, dynlib: "libobjc.dylib".}

proc objc_msgSend(self: ID, op: SEL): ID
proc objc_getClass(name: cstring): Class
proc class_getName(cls: Class): cstring
proc object_getClass(id: ID): Class
proc sel_registerName(s: cstring): SEL
proc sel_getName(sel: SEL): cstring

{.pop.}

template s*(s: string): SEL =
  sel_registerName(s.cstring)

proc `$`*(cls: Class): string =
  $class_getName(cls)

proc `$`*(id: ID): string =
  $object_getClass(id)

proc `$`*(sel: SEL): string =
  $sel_getName(sel)

type
  NSAutoreleasePool* = distinct int
  NSString* = distinct int
  NSData* = distinct int
  NSError* = distinct int
  NSDictionary* = distinct int
  NSEnumerator* = distinct int
  NSURL* = distinct int
  NSMutableURLRequest* = distinct int
  NSURLRequestCachePolicy* = distinct int
  NSTimeInterval* = float64
  NSURLConnection* = distinct int
  NSHTTPURLResponse* = distinct int

const
  NSURLRequestUseProtocolCachePolicy* = 0.NSURLRequestCachePolicy
  NSURLRequestReloadIgnoringLocalCacheData* = 1.NSURLRequestCachePolicy
  NSURLRequestReturnCacheDataElseLoad* = 2.NSURLRequestCachePolicy
  NSURLRequestReturnCacheDataDontLoad* = 3.NSURLRequestCachePolicy
  NSURLRequestReloadIgnoringLocalAndRemoteCacheData* = 4.NSURLRequestCachePolicy
  NSURLRequestReloadIgnoringCacheData* = NSURLRequestReloadIgnoringLocalCacheData
  NSURLRequestReloadRevalidatingCacheData* = 5.NSURLRequestCachePolicy
  NSURLErrorUserCancelledAuthentication* = -1012

proc getClass*(t: typedesc): Class =
  objc_getClass(t.name.cstring)

proc new*(cls: Class): ID =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): ID {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    cls.ID,
    sel_registerName("new".cstring)
  )

proc release*(id: ID) =
  let msgSend = cast[
    proc(self: ID, cmd: SEL) {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    id,
    s"release"
  )

template autoreleasepool*(body: untyped) =
  let pool = NSAutoreleasePool.getClass().new()
  try:
    body
  finally:
    pool.release()

proc `@`*(s: string): NSString =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, s: cstring): NSString {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSString.getClass().ID,
    s"stringWithUTF8String:",
    s.cstring
  )

proc UTF8String(s: NSString): cstring =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): cstring {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    s.ID,
    s"UTF8String"
  )

proc `$`*(s: NSString): string =
  $s.UTF8String

proc localizedDescription(error: NSError): NSString =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): NSString {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    error.ID,
    s"localizedDescription"
  )

proc `$`*(error: NSError): string =
  $error.localizedDescription

proc code*(error: NSError): int =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): int {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    error.ID,
    s"code"
  )

proc dataWithBytes*(_: typedesc[NSData], bytes: pointer, len: int): NSData =
  let msgSend = cast[
    proc(
      self: ID,
      cmd: SEL,
      bytes: pointer,
      len: int
    ): NSData {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSData.getClass().ID,
    s"dataWithBytes:length:",
    bytes,
    len
  )

proc bytes*(data: NSData): pointer =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): pointer {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    data.ID,
    s"bytes"
  )

proc length*(data: NSData): int =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): int {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    data.ID,
    s"length"
  )

proc keyEnumerator*(dictionary: NSDictionary): NSEnumerator =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): NSEnumerator {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    dictionary.ID,
    s"keyEnumerator"
  )

proc objectForKey*(dictionary: NSDictionary, key: ID): ID =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, key: ID): ID {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    dictionary.ID,
    s"objectForKey:",
    key
  )

proc nextObject*(enumerator: NSEnumerator): ID =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): ID {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    enumerator.ID,
    s"nextObject"
  )

proc URLWithString*(_: typedesc[NSURL], url: NSString): NSURL =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, ur: NSString): NSURL {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSURL.getClass().ID,
    s"URLWithString:",
    url
  )

proc requestWithURL*(
  _: typedesc[NSMutableURLRequest],
  url: NSURL,
  cachePolicy: NSURLRequestCachePolicy,
  timeoutInterval: NSTimeInterval
): NSMutableURLRequest =
  let msgSend = cast[
    proc(
      self: ID,
      cmd: SEL,
      url: NSURL,
      cachePolicy: NSURLRequestCachePolicy,
      timeoutInterval: NSTimeInterval
    ): NSMutableURLRequest {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSMutableURLRequest.getClass().ID,
    s"requestWithURL:cachePolicy:timeoutInterval:",
    url,
    cachePolicy,
    timeoutInterval
  )

proc setHTTPMethod*(request: NSMutableURLRequest, httpMethod: NSString) =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, httpMethod: NSString) {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    request.ID,
    s"setHTTPMethod:",
    httpMethod
  )

proc setValue*(request: NSMutableURLRequest, value: NSString, field: NSString) =
  let msgSend = cast[
    proc(
      self: ID,
      cmd: SEL,
      value: NSString,
      field: NSString
    ) {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    request.ID,
    s"setValue:forHTTPHeaderField:",
    value,
    field
  )

proc setHTTPBody*(request: NSMutableURLRequest, httpBody: NSData) =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, httpBody: NSData) {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    request.ID,
    s"setHTTPBody:",
    httpBody
  )

proc sendSynchronousRequest*(
  _: typedesc[NSURLConnection],
  request: NSMutableURLRequest,
  response: ptr NSHTTPURLResponse,
  error: ptr NSError
): NSData =
  let msgSend = cast[
    proc(
      self: ID,
      cmd: SEL,
      request: NSMutableURLRequest,
      response: ptr NSHTTPURLResponse,
      error: ptr NSError
    ): NSData {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSURLConnection.getClass().ID,
    s"sendSynchronousRequest:returningResponse:error:",
    request,
    response,
    error
  )

proc statusCode*(response: NSHTTPURLResponse): int =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): int {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    response.ID,
    s"statusCode"
  )

proc allHeaderFields*(response: NSHTTPURLResponse): NSDictionary =
  let msgSend = cast[
    proc(self: ID, cmd: SEL): NSDictionary {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    response.ID,
    s"allHeaderFields"
  )
