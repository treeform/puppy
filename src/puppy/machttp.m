#include <AppKit/AppKit.h>

typedef struct MacRequest {
  NSMutableURLRequest *request;
  NSHTTPURLResponse *response;
  NSData *responseError;
  NSData *responseBody;
  NSData *responseHeaders;
} MacRequest;

MacRequest* newRequest(
  char* utf8Method,
  char* utf8Url,
  float timeout
) {
  @autoreleasepool {
    MacRequest *req = calloc(1, sizeof(MacRequest));
    req->request = [NSMutableURLRequest
      requestWithURL: [NSURL URLWithString:@(utf8Url)]
      cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
      timeoutInterval: timeout
    ];
    [req->request setHTTPMethod:@(utf8Method)];
    [req->request retain];
    return req;
  }
}

void setHeader(
  MacRequest* req,
  char* uft8Key,
  char* utf8Value
) {
  @autoreleasepool {
    [req->request
      setValue: @(utf8Value)
      forHTTPHeaderField: @(uft8Key)
    ];
  }
}

void sendSync(
  MacRequest* req,
  void* bodyData,
  long long bodyLength
) {
  @autoreleasepool {
    if (bodyLength > 0) {
      [req->request setHTTPBody: [NSData
        dataWithBytes: bodyData
        length: bodyLength
      ]];
    }

    NSError *error = nil;
    req->responseBody = [NSURLConnection
      sendSynchronousRequest: req->request
      returningResponse: &req->response
      error: &error
    ];
    if (req->response != nil) {
      [req->response retain];
    }
    if (req->responseBody != nil) {
      [req->responseBody retain];
    }

    NSString *str = @"";
    for(id key in req->response.allHeaderFields) {
      str = [str stringByAppendingString:key];
      str = [str stringByAppendingString:@": "];
      str = [str stringByAppendingString:[
        req->response.allHeaderFields objectForKey:key]];
      str = [str stringByAppendingString:@"\r\n"];
    }
    req->responseHeaders = [str dataUsingEncoding:NSUTF8StringEncoding];
    [req->responseHeaders retain];

    if (error != nil && error.code != NSURLErrorUserCancelledAuthentication) {
      req->responseError = [error.localizedDescription
        dataUsingEncoding:NSUTF8StringEncoding];
      [req->responseError retain];
    }
  }
}

long long getCode(MacRequest* req) {
  @autoreleasepool {
    return req->response.statusCode;
  }
}

void getResponseBody(
  MacRequest* req,
  void** data,
  long long* length
) {
  @autoreleasepool {
    if (req->responseBody != nil) {
      *data = [req->responseBody bytes];
      *length = [req->responseBody length];
    }
  }
}

void getResponseHeaders(
  MacRequest* req,
  void** data,
  long long* length
) {
  @autoreleasepool {
    if (req->responseHeaders != nil) {
      *data = [req->responseHeaders bytes];
      *length = [req->responseHeaders length];
    }
  }
}

void getResponseError(
  MacRequest* req,
  void** data,
  long long* length
) {
  @autoreleasepool {
    if (req->responseError != nil) {
      *data = [req->responseError bytes];
      *length = [req->responseError length];
    }
  }
}

void freeRequest(MacRequest* req) {
  [req->request release];
  [req->response release];
  if (req->responseError != nil) {
    [req->responseError release];
  }
  if (req->responseBody != nil) {
    [req->responseBody release];
  }
  if (req->responseHeaders != nil) {
    [req->responseHeaders release];
  }
  free(req);
}
