import puppy

# test simple string API

doAssert fetch("http://www.istrolid.com").len != 0
doAssert fetch(
  "http://www.istrolid.com",
  headers = @[Header(key: "User-Agent", value: "Nim 1.0")]
).len != 0
doAssert fetch("http://neverssl.com/").len != 0
doAssert fetch("https://blog.istrolid.com/").len != 0
doAssert fetch("https://not-a-real-site.xyz/").len == 0

# test request/response API

block:
  echo "# http fail"
  let res = fetch(Request(
    url: parseUrl("https://not-a-real-site.xyz/"),
    verb: "get"
  ))
  echo "res.error: ", res.error
  doAssert res.error != ""

block:
  echo "# http"
  let res = fetch(Request(
    url: parseUrl("http://www.istrolid.com"),
    verb: "get",
    headers: @[Header(key: "Auth", value: "1")]
  ))
  echo "res.error: ", res.error
  echo "res.code: ", res.code
  echo "res.headers: ", res.headers
  echo "res.body.len: ", res.body.len
  doAssert res.error == ""
  doAssert res.code == 200
  doAssert res.headers.len > 0
  doAssert res.body != ""

block:
  echo "# https"
  let res = fetch(Request(
    url: parseUrl("https://blog.istrolid.com/"),
    verb: "get"
  ))
  echo "res.error: ", res.error
  echo "res.code: ", res.code
  echo "res.headers: ", res.headers
  echo "res.body.len: ", res.body.len
  doAssert res.error == ""
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
