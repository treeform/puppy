import puppy, zippy


for i in 0 ..< 100:
  block:
    # test basic
    doAssert fetch("http://localhost:8080/ok") == "ok"
    doAssert fetch("http://localhost:8080/401") == ""

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
    let res = fetch(Request(
      url: parseUrl("http://localhost:8080/post"),
      verb: "post",
      body: "some data"
    ))
    doAssert res.code == 200
    doAssert res.body == "some data"

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
