<img src="docs/puppyBanner.png">

## Puppy - Fetch url resources via HTTP and HTTPS.

Getting content from a url should be as easy as `readFile`.

![Github Actions](https://github.com/treeform/puppy/workflows/Github%20Actions/badge.svg)

`nimble install puppy`

API reference: [nimdocs puppy](https://nimdocs.com/treeform/puppy/puppy.html)

Puppy does not use Nim's HTTP stack, instead it uses `WinHttp` API on Windows , `AppKit` on macOS, and `libcurl` on Linux. Because Puppy uses system APIs, there is no need to ship extra `*.dll`s, `cacert.pem`, or forget to pass the `-d:ssl` flag. This also has the effect of producing slightly smaller binaires.

Furthermore, Puppy supports gzip transparently right out of the box.

OS    |  Method
----- | ---------------------------
Win32 | WinHttp WinHttpRequest
macOS | AppKit NSMutableURLRequest
linux | libcurl easy_perform

*Curently does not support async*

```nim
import puppy

echo fetch("http://neverssl.com/").body
```

Need to pass headers?

```nim
import puppy

echo fetch(
  "http://neverssl.com/",
  headers = @[Header(key: "User-Agent", value: "Nim 1.0")]
).body
```

Need a more complex API?
* verbs: GET, POST, PUT, UPDATE, DELETE..
* headers: User-Agent, Content-Type..
* response code: 200, 404, 500..
* response headers: Content-Type..
* error: timeout, DNS fail ...

Use request/response instead.

```nim
Request* = ref object
  url*: Url
  headers*: seq[Header]
  timeout*: float32
  verb*: string
  body*: string

Response* = ref object
  url*: Url
  headers*: seq[Header]
  code*: int
  body*: string
```

Usage example:

```nim
let req = Request(
  url: parseUrl("http://www.istrolid.com"),
  verb: "get",
  headers: @[Header(key: "Auth", value: "1"))]
)
let res = fetch(req)
echo res.code
echo res.headers
echo res.body.len
```

## A note on exceptions

Puppy throws a `PuppyError` if an HTTP(S) request does not complete, either due to DNS failure, timeout, or some other unexpected issue.

If the HTTP(S) request completes, the Response contains the status code and any other data from the server. No status codes result in exceptions.

## Always use Libcurl

You can pass `-d:puppyLibcurl` to force use of `libcurl` even on windows and macOS. This is useful to debug, if the some reason native OS API does not work. Libcurl is usually installed on macOS but requires a `curl.dll` on windows.
