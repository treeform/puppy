import puppy

# test simple string API

doAssert fetch("http://www.istrolid.com").body.len != 0
doAssert fetch(
  "http://www.istrolid.com",
  headers = @[Header(key: "User-Agent", value: "Nim 1.0")]
).body.len != 0
doAssert fetch("http://neverssl.com/").body.len != 0
doAssert fetch("https://blog.istrolid.com/").body.len != 0
doAssertRaises(PuppyError):
  discard fetch("https://not-a-real-site.xyz/")

# test request/response API

block:
  echo "# http fail"
  doAssertRaises(PuppyError):
    discard fetch(Request(
      url: parseUrl("https://not-a-real-site.xyz/"),
      verb: "get"
    ))

block:
  echo "# http"
  let res = fetch(Request(
    url: parseUrl("http://www.istrolid.com"),
    verb: "get",
    headers: @[Header(key: "Auth", value: "1")]
  ))
  echo "res.code: ", res.code
  echo "res.headers: ", res.headers
  echo "res.body.len: ", res.body.len
  doAssert res.code == 200
  doAssert res.headers.len > 0
  doAssert res.body != ""

block:
  echo "# https"
  let res = fetch(Request(
    url: parseUrl("https://blog.istrolid.com/"),
    verb: "get"
  ))
  echo "res.code: ", res.code
  echo "res.headers: ", res.headers
  echo "res.body.len: ", res.body.len
  doAssert res.code == 200
  doAssert res.headers.len > 0
  doAssert res.body != ""

# test headers

block:
  let req = Request()
  req.headers["Content-Type"] = "application/json"
  doAssert req.headers["content-type"] == "application/json"

block:
  let req = Request()
  req.headers["Content-Type"] = "application/json"
  req.headers["content-type"] = "application/json"
  doAssert req.headers["Content-TYPE"] == "application/json"
