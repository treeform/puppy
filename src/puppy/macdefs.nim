{.passL: "-framework AppKit".}

type
  Class* = distinct int
  ID* = distinct int
  SEL* = distinct int

{.push importc, cdecl, dynlib:"libobjc.dylib".}

proc objc_msgSend(self: ID, op: SEL): ID {.varargs.}
proc objc_getClass(name: cstring): Class
proc class_getName(cls: Class): cstring
proc object_getClass(id: ID): Class
proc sel_registerName(s: cstring): SEL
proc sel_getName(sel: SEL): cstring

{.pop.}

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

proc new*(_: typedesc[NSAutoreleasePool]): NSAutoreleasePool =
  objc_msgSend(
    objc_getClass("NSAutoreleasePool".cstring).ID,
    sel_registerName("new".cstring)
  ).NSAutoreleasePool

proc release*(pool: NSAutoreleasePool) =
  discard objc_msgSend(
    pool.ID,
    sel_registerName("release".cstring)
  )

template autoreleasepool*(body: untyped) =
  let pool = NSAutoreleasePool.new()
  try:
    body
  finally:
    pool.release()

proc `@`*(s: string): NSString =
  objc_msgSend(
    objc_getClass("NSString".cstring).ID,
    sel_registerName("stringWithUTF8String:".cstring),
    s.cstring
  ).NSString

proc UTF8String(s: NSString): cstring =
  cast[cstring](objc_msgSend(
    s.ID,
    sel_registerName("UTF8String".cstring)
  ))

proc `$`*(s: NSString): string =
  $s.UTF8String

proc localizedDescription(error: NSError): NSString =
  objc_msgSend(
    error.ID,
    sel_registerName("localizedDescription".cstring)
  ).NSString

proc `$`*(error: NSError): string =
  $error.localizedDescription

proc code*(error: NSError): int =
  objc_msgSend(
    error.ID,
    sel_registerName("code".cstring)
  ).int

proc dataWithBytes*(_: typedesc[NSData], bytes: pointer, len: int): NSData =
  objc_msgSend(
    objc_getClass("NSData".cstring).ID,
    sel_registerName("dataWithBytes:length:".cstring),
    bytes,
    len
  ).NSData

proc bytes*(data: NSData): pointer =
  cast[pointer](objc_msgSend(
    data.ID,
    sel_registerName("bytes".cstring)
  ))

proc length*(data: NSData): int =
  objc_msgSend(
    data.ID,
    sel_registerName("length".cstring)
  ).int

proc keyEnumerator*(dictionary: NSDictionary): NSEnumerator =
  objc_msgSend(
    dictionary.ID,
    sel_registerName("keyEnumerator".cstring)
  ).NSEnumerator

proc objectForKey*(dictionary: NSDictionary, key: ID): ID =
  objc_msgSend(
    dictionary.ID,
    sel_registerName("objectForKey:".cstring),
    key
  )

proc nextObject*(enumerator: NSEnumerator): ID =
  objc_msgSend(
    enumerator.ID,
    sel_registerName("nextObject".cstring)
  )

proc URLWithString*(_: typedesc[NSURL], url: NSString): NSURL =
  objc_msgSend(
    objc_getClass("NSURL".cstring).ID,
    sel_registerName("URLWithString:".cstring),
    url
  ).NSURL

proc requestWithURL*(
  _: typedesc[NSMutableURLRequest],
  url: NSURL,
  cachePolicy: NSURLRequestCachePolicy,
  timeoutInterval: NSTimeInterval
): NSMutableURLRequest =
  objc_msgSend(
    objc_getClass("NSMutableURLRequest".cstring).ID,
    sel_registerName("requestWithURL:cachePolicy:timeoutInterval:".cstring),
    url,
    cachePolicy,
    timeoutInterval
  ).NSMutableURLRequest

proc setHTTPMethod*(
  request: NSMutableURLRequest,
  httpMethod: NSString,
) =
  discard objc_msgSend(
    request.ID,
    sel_registerName("setHTTPMethod:".cstring),
    httpMethod
  )

proc setValue*(
  request: NSMutableURLRequest,
  value: NSString,
  field: NSString
) =
  discard objc_msgSend(
    request.ID,
    sel_registerName("setValue:forHTTPHeaderField:".cstring),
    value,
    field
  )

proc setHTTPBody*(
  request: NSMutableURLRequest,
  httpBody: NSData
) =
  discard objc_msgSend(
    request.ID,
    sel_registerName("setHTTPBody:".cstring),
    httpBody
  )

proc sendSynchronousRequest*(
  _: typedesc[NSURLConnection],
  request: NSMutableURLRequest,
  response: ptr NSHTTPURLResponse,
  error: ptr NSError
): NSData =
  objc_msgSend(
    objc_getClass("NSURLConnection".cstring).ID,
    sel_registerName("sendSynchronousRequest:returningResponse:error:".cstring),
    request,
    response,
    error
  ).NSData

proc statusCode*(response: NSHTTPURLResponse): int =
  objc_msgSend(
    response.ID,
    sel_registerName("statusCode".cstring)
  ).int

proc allHeaderFields*(response: NSHTTPURLResponse): NSDictionary =
  objc_msgSend(
    response.ID,
    sel_registerName("allHeaderFields".cstring)
  ).NSDictionary
