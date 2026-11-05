<img src="docs/puppyBanner.png">

# Puppy - Fetch resources via HTTP and HTTPS.

`nimble install puppy`

![Github Actions](https://github.com/treeform/puppy/actions/workflows/build.yml/badge.svg)

[API reference](https://treeform.github.io/puppy)

## About

Puppy makes HTTP requests easy!

With Puppy you can make HTTP requests without needing to pass the `-d:ssl` flag or shipping extra `*.dll`s and `cacerts.pem` on Windows. Puppy avoids these gotchas by using system APIs instead of Nim's HTTP stack.

Some other highlights of Puppy are:

* Supports gzip'ed responses out of the box
* Make an HTTP request using a one-line `proc` call

OS    |  Method
----- | ---------------------------
Win32 | WinHttp WinHttpRequest
macOS | AppKit NSMutableURLRequest
Linux | libcurl easy_perform

*Curently does not support async*

## Easy mode

```nim
echo fetch("http://neverssl.com/")
```

A call to `fetch` will raise PuppyError if the response status code is not 200.

## More request types

Make a basic GET request:

```nim
import puppy

let response = get("https://www.google.com/")
```

Need to pass headers?

```nim
import puppy

let response = get(
  "http://neverssl.com/",
  headers = @[("User-Agent", "Nim 1.0")]
)
```

Easy one-line procs for your favorite verbs:

```nim
discard get(url, headers)
discard post(url, headers, body)
discard put(url, headers, body)
discard patch(url, headers, body)
discard delete(url, headers)
discard head(url, headers)
```

## Working with responses

```nim
Response* = ref object
  headers*: HttpHeaders
  code*: int
  body*: string
```

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

## More examples

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

## Threading

`fetch` blocks, so GUI apps often call it from a thread to keep the UI responsive. If you do that, reuse one long-lived worker thread instead of spawning a new thread per request — see [examples/threaded_fetch.nim](examples/threaded_fetch.nim).

With Nim's default ORC memory management, the memory a thread used is not returned to the OS when that thread exits (see [nim-lang/Nim#23361](https://github.com/nim-lang/Nim/issues/23361)), so a thread-per-request loop keeps growing resident memory. Measured on Linux with Nim 2.2.4: a thread-per-request loop grew by ~300 kB of RSS per request (~29 MB over 100 requests), while one reused worker thread plateaued after a one-time warm-up and stayed flat through 100 requests. Until that Nim issue is fixed, compiling your own program with `-d:useMalloc` also avoids the growth.

## Always use libcurl

You can pass `-d:puppyLibcurl` to force use of `libcurl` even on Windows and macOS. This is useful if for some reason the native OS API is not working.

Libcurl is typically ready-to-use on macOS and Linux. On Windows you'll need to grab the latest libcurl DLL from https://curl.se/windows/, rename it to libcurl.dll, and put it in the same directory as your executable.
