import puppy

echo repr(fetch("http://localhost:8080/401"))

let res = fetch(Request(
  url: parseUrl("http://localhost:8080/401"),
  verb: "get"
))
echo "code: ", res.code
echo "headers: ", res.headers
echo "body: ", res.body
echo "error: ", res.error
