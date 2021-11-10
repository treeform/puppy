when not compileOption("threads"):
  echo "This test requres --threads:on"
else:
  import std/os, std/locks, puppy, puppy/requestpools, osproc, streams

  var p = startProcess("tests/debug_server", options={poParentStreams})
  sleep(100)

  try:
    var pool = newRequestPool(10)

    for i in 0 ..< 10:
      var handles: seq[ResponseHandle]
      for j in 0 ..< 100:
        handles.add pool.fetch(Request(
          url: parseUrl("http://localhost:8080/page?ret=" & $j),
          verb: "get"
        ))

      while true:
        var running = 0
        var change = false
        for id, handle in handles:
          if handle != nil and handle.ready:
            let r = handle.response
            doAssert r.code == 200
            doAssert r.headers.len == 1
            doAssert r.body == $id
            handles[id] = nil
            change = true
          if handle != nil:
            inc running

        if change:
          echo "running: ", running, "/", handles.len
        if running == 0:
          break

        sleep(1)
  finally:
    p.terminate()
