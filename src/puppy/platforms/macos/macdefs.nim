import objc
export objc

{.passL: "-framework AppKit".}

type
  NSData* = distinct int
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

objc:
  proc code*(self: NSError): int
  proc dataWithBytes*(class: typedesc[NSData], _: pointer, length: int): NSData
  proc bytes*(self: NSData): pointer
  proc length*(self: NSData): int
  proc keyEnumerator*(self: NSDictionary): NSEnumerator
  proc objectForKey*(self: NSDictionary, _: ID): ID
  proc nextObject*(self: NSEnumerator): ID
  proc URLWithString*(class: typedesc[NSURL], _: NSString): NSURL
  proc requestWithURL*(
    class: typedesc[NSMutableURLRequest],
    _: NSURL,
    cachePolicy: NSURLRequestCachePolicy,
    timeoutInterval: NSTimeInterval
  ): NSMutableURLRequest
  proc setHTTPMethod*(self: NSMutableURLRequest, _: NSString)
  proc setValue*(self: NSMutableURLRequest, _: NSString, forHTTPHeaderField: NSString)
  proc setHTTPBody*(self: NSMutableURLRequest, _: NSData)
  proc sendSynchronousRequest*(
    class: typedesc[NSURLConnection],
    _: NSMutableURLRequest,
    returningResponse: ptr NSHTTPURLResponse,
    error: ptr NSError
  ): NSData
  proc statusCode*(self: NSHTTPURLResponse): int
  proc allHeaderFields*(self: NSHTTPURLResponse): NSDictionary
