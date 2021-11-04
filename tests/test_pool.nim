import std/os, std/locks, puppy, puppy/pool, osproc

var p = startProcess("tests/debug_server")
sleep(100)

openPool()

var handle1 = fetchParallel(Request(
  url: parseUrl("http://localhost:8080/ok"),
  verb: "get"
))

var handle2 = fetchParallel(Request(
  url: parseUrl("http://localhost:8080/slow"),
  verb: "get"
))

var handle3 = fetchParallel(Request(
  url: parseUrl("http://localhost:8080/404"),
  verb: "get"
))

while true:
  if handle1 != -1 and handle1.ready:
    let r = handle1.response
    echo "res.code:", r.code
    echo "res.headers:", r.headers
    echo "res.body:", r.body
    handle1 = -1

  if handle2 != -1 and handle2.ready:
    let r = handle2.response
    echo "res.code:", r.code
    echo "res.headers:", r.headers
    echo "res.body:", r.body
    handle2 = -1

  if handle3 != -1 and handle3.ready:
    let r = handle3.response
    echo "res.code:", r.code
    echo "res.headers:", r.headers
    echo "res.body:", r.body.len
    handle3 = -1

  if handle1 == -1 and handle2 == -1 and handle3 == -1:
    break

  sleep(1)

closePool()
p.terminate()
