import os, osproc, puppy, strutils, zippy

# test simple string API
doAssert fetch("http://www.istrolid.com").len != 0
doAssert fetch(
  "http://www.istrolid.com",
  headers = @[Header(key: "User-Agent", value: "Nim 1.0")]
).len != 0

doAssert fetch("http://neverssl.com/").len != 0
doAssert fetch("https://blog.istrolid.com/").len != 0
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

when defined(windows):
  block:
    let httpsServer = startProcess(
      "python tests/https_server.py",
      options = {poEvalCommand, poParentStreams}
    )

    # Wait for server to start, Python is mega slow
    sleep(5000)

    try:
      echo "# allowAnyHttpsCertificate"
      let res = fetch(
        Request(
          url: parseUrl("https://127.0.0.1/connect"),
          verb: "get",
          allowAnyHttpsCertificate: true,
        )
      )
      echo "res.code: ", res.code
      echo "res.headers: ", res.headers
      echo "res.body.len: ", res.body.len
      doAssert res.code == 200
      doAssert res.headers.len > 0
      doAssert res.body != ""
    finally:
      httpsServer.terminate()

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

let debugServer = startProcess(
  "tests/debug_server",
  options = {poParentStreams}
)

# Wait for server to start
sleep(100)

try:
  for i in 0 ..< 10:
    block:
      # test basic
      doAssert fetch("http://localhost:8080/ok") == "ok"
      doAssertRaises(PuppyError):
        discard fetch("http://localhost:8080/401")

    block:
      # test 404
      let res = fetch(Request(
        url: parseUrl("http://localhost:8080/404"),
        verb: "get"
      ))
      doAssert res.code == 404
      doAssert res.body == "Not found."

    block:
      # test 500
      let res = fetch(Request(
        url: parseUrl("http://localhost:8080/500"),
        verb: "get"
      ))
      doAssert res.code == 500
      doAssert res.body == "500 Unkown Error (simulated)."

    block:
      # test hash
      doAssert fetch("http://localhost:8080/url#hash") == "/url"
      doAssert fetch("http://localhost:8080/url?a=b#hash") == "/url?a=b"

    block:
      # test gzip
      let res = fetch(Request(
        url: parseUrl("http://localhost:8080/gzip"),
        headers: @[Header(key: "Accept-Encoding", value: "gzip")],
        verb: "get"
      ))
      doAssert res.code == 200
      doAssert res.body == "gzip'ed response body"

    block:
      # test post
      let req = Request(
        url: parseUrl("http://localhost:8080/post"),
        verb: "post",
        body: "some data"
      )
      let res = fetch(req)
      doAssert ($req).startsWith("POST http://localhost:8080/post")
      doAssert res.code == 200
      doAssert res.body == "some data"

    block:
      # test empty post
      let req = Request(
        url: parseUrl("http://localhost:8080/post"),
        verb: "post",
        body: ""
      )
      let res = fetch(req)
      doAssert ($req).startsWith("POST http://localhost:8080/post")
      doAssert res.code == 200
      doAssert res.body == ""

    block:
      # test post + gzip
      let res = fetch(Request(
        url: parseUrl("http://localhost:8080/postgzip"),
        headers: @[
          Header(key: "Accept-Encoding", value: "gzip"),
          # Header(key: "Content-Type", value: "text/html; charset=UTF-8"),
          Header(key: "Content-Encoding", value: "gzip")
        ],
        verb: "post",
        body: compress("gzip'ed request body", BestSpeed, dfGzip),
      ))
      doAssert res.code == 200
      doAssert res.body == "gzip'ed request body"

    block:
      # test headers
      let res = fetch(Request(
        url: parseUrl("http://localhost:8080/headers"),
        headers: @[
          Header(key: "a", value: "1"),
          Header(key: "b", value: "2")
        ],
        verb: "get",
      ))
      doAssert res.code == 200
      doAssert res.headers["1"] == "a"
      doAssert res.headers["2"] == "b"

finally:
  debugServer.terminate()
