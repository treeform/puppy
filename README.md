## Puppy - Fetch url resources via HTTP.

Getting content from a url should be as easy as readFile.

```nim
import puppy

fetch("http://neverssl.com/")

```

Need to pass special headers?

```nim
import puppy

fetch("http://neverssl.com/", headers = @[("User-Agent", "Nim 1.0"]))

```

Need to pass a bunch of similar requests, create one and modify it!

```nim
var req = newRequest()
req.url = parseUrl("http://test.com/view.html?page=1")
req.headers["User-Agent"] = "Nim 1.0"
for i in 1 .. 10:
  req.url.search["page"] = $i
  let res = req.fetch()
  echo res.code
  echo res.headers
  echo res.body
```

Need to handle zlib compressed bodies? It's handled automatically.
