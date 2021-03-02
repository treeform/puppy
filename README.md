## Puppy - Fetch url resources via HTTP and HTTPS.

Getting content from a url should be as easy as readFile. Puppy does not use Nim's HTTP stack instead it uses `win32 WinHttp` api on windows and `libcurl` on linux and macOS.

`nimble install puppy`

Because it uses the windows/linux/macOS system API there is no need to ship extra `*.dll`s, `cacert.pem`, or forget to pass the `-d:ssl` flag..

Libcurl and cacert.pem is installed by default on most desktop or server linux and macOS.

Everything is handled by normal system APIs native to each OS!

*Will not support async*

```nim
import puppy

echo fetch("http://neverssl.com/")
```

Will return `""` if any error accrued for any reason.

Need to pass headers?

```nim
import puppy

echo fetch(
  "http://neverssl.com/",
  headers = @[("User-Agent", "Nim 1.0"])
)
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
    headers*: seq[(string, string)]
    verb*: string
    body*: string

  Response* = ref object
    url*: Url
    headers*: seq[(string, string)]
    code*: int
    body*: string
    error*: string
```

Usage example:

```nim
let req = Request(
  url: parseUrl("http://www.istrolid.com"),
  verb: "get",
  headers: @[("Auth", "1")]
)
let res = fetch(req)
echo res.error
echo res.code
echo res.headers
echo res.body.len
```
