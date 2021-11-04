
when not compileOption("threads"):
  echo "do nothing maybe pass --threads:on?"
else:
  import std/os, std/locks, puppy, puppy/pool, osproc, streams

  var p = startProcess("tests/debug_server", options={poParentStreams})
  sleep(100)

  openPool()

  var handles: seq[RequestHandle]
  for i in 0 ..< 1000:
    handles.add fetchParallel(Request(
      url: parseUrl("http://localhost:8080/page?ret=" & $i),
      verb: "get"
    ))

  while true:
    var running = 0
    var change = false
    for id, handle in handles:
      if handle != -1 and handle.ready:
        let r = handle.response
        doAssert r.code == 200
        doAssert r.headers.len == 1
        doAssert r.body == $id
        handles[id] = -1
        change = true
      if handle != -1:
        inc running

    if change:
      echo "running: ", running, "/", handles.len
    if running == 0:
      break

    sleep(1)

  closePool()
  p.terminate()
  sleep(100)
