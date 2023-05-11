<img src="docs/puppyBanner.png">

# Puppy - Fetch resources via HTTP and HTTPS.

`nimble install puppy`

![Github Actions](https://github.com/treeform/puppy/workflows/Github%20Actions/badge.svg)

[API reference](https://treeform.github.io/puppy)

## About

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

echo fetch("http://neverssl.com/")
```

Will raise `PuppyError` if the response status code is not `200`.

Need to pass headers?

```nim
import puppy

echo fetch(
  "http://neverssl.com/",
  headers = @[("User-Agent", "Nim 1.0")]
)
```

Need a more complex API?
* verbs: GET, POST, PUT, UPDATE, DELETE..
* headers: User-Agent, Content-Type..
* response code: 200, 404, 500..
* response headers: Content-Type..

Use these instead.

```nim
Response* = ref object
  headers*: HttpHeaders
  code*: int
  body*: string
```

Usage examples:

```nim
import puppy

let response = get("http://www.istrolid.com", @[("Auth", "1")])
echo response.code
echo response.headers
echo response.body.len
```

```nim
import puppy

let body = "{\"json\":true}"

let response = post(
    "http://api.website.com",
    @[("Content-Type", "application/json")],
    body
)
echo response.code
echo response.headers
echo response.body.len
```

## Examples

Using multipart/form-data:

```nim
var entries: seq[MultipartEntry]
entries.add MultipartEntry(
  name: "input_text",
  fileName: "input.txt",
  contentType: "text/plain",
  payload: "foobar"
)
entries.add MultipartEntry(
  name: "options",
  payload: "{\"utf8\":true}"
)

let (contentType, body) = encodeMultipart(entries)

var headers: HttpHeaders
headers["Content-Type"] = contentType

let response = post("Your API endpoint here", headers, body)
```

See the [examples/](https://github.com/treeform/puppy) folder for more examples.

## Always use Libcurl

You can pass `-d:puppyLibcurl` to force use of `libcurl` even on windows and macOS. This is useful to debug, if the some reason native OS API does not work. Libcurl is usually installed on macOS but requires a `curl.dll` on windows.
