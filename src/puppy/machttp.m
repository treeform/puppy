#include <AppKit/AppKit.h>

typedef struct MacRequest {
  NSString *url;
  NSString *method;
  NSURL *theUrl;
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
  MacRequest *req = calloc(1, sizeof(MacRequest));
  req->url = [NSString stringWithUTF8String:utf8Url];
  req->method = [NSString stringWithUTF8String:utf8Method];
  req->theUrl = [NSURL URLWithString:req->url];
  req->request = [NSMutableURLRequest
    requestWithURL: req->theUrl
    cachePolicy: NSURLRequestReloadIgnoringCacheData
    timeoutInterval: timeout
  ];
  [req->request setHTTPMethod:req->method];
  return req;
}

void setHeader(
  MacRequest* req,
  char* uft8Key,
  char* utf8Value
) {
  NSString *key = [NSString stringWithUTF8String:uft8Key];
  NSString *value = [NSString stringWithUTF8String:utf8Value];
  [req->request
    setValue: value
    forHTTPHeaderField: key
  ];
}

void sendSync(
  MacRequest* req,
  char* bodyData,
  long long bodyLength
) {

  if (bodyLength > 0) {
    [req->request setHTTPBody: [NSData
      dataWithBytes: bodyData
      length: bodyLength
    ]];
  }

  NSError *error = NULL;
  req->responseBody = [NSURLConnection
    sendSynchronousRequest: req->request
    returningResponse: &req->response
    error: &error
  ];

  if (error != NULL && error.code != NSURLErrorUserCancelledAuthentication) {
    req->responseError = [error.localizedDescription
      dataUsingEncoding:NSUTF8StringEncoding];
  }
}

long long getCode(MacRequest* req) {
  return req->response.statusCode;
}

void getResponseBody(
  MacRequest* req,
  char** data,
  long long* length
) {
  if (req->responseBody != NULL) {
    *data = [req->responseBody bytes];
    *length = [req->responseBody length];
  }
}

void getResponseHeaders(
  MacRequest* req,
  char** data,
  long long* length
) {
  if (req->response != NULL) {
    NSString *str = @"";
    for(id key in req->response.allHeaderFields) {
      str = [str stringByAppendingString:key];
      str = [str stringByAppendingString:@": "];
      str = [str stringByAppendingString:[
        req->response.allHeaderFields objectForKey:key]];
      str = [str stringByAppendingString:@"\r\n"];
    }
    req->responseHeaders = [str dataUsingEncoding:NSUTF8StringEncoding];
    *data = [req->responseHeaders bytes];
    *length = [req->responseHeaders length];
  }
}

void getResponseError(
  MacRequest* req,
  char** data,
  long long* length
) {
  if (req->responseError != NULL) {
    *data = [req->responseError bytes];
    *length = [req->responseError length];
  }
}

void freeRequest(MacRequest* req) {
  [req->url release];
  [req->method release];
  [req->theUrl release];
  [req->request release];
  [req->response release];
  if (req->responseError != NULL) {
    [req->responseError release];
  }
  if (req->responseBody != NULL) {
    [req->responseBody release];
  }
  if (req->responseHeaders != NULL) {
    [req->responseHeaders release];
  }
  free(req);
}
