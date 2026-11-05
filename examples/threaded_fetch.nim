## Fetch URLs from one long-lived worker thread instead of creating a new
## thread per request.
##
## Nim's per-thread memory is not returned to the OS when a short-lived
## thread exits, so an app that spawns a fresh thread for every request
## keeps growing its resident memory (see nim-lang/Nim#23361 and
## treeform/puppy#123). Reusing a single worker thread keeps memory flat.
## Channels deep-copy the data you send through them, which makes this
## hand-off safe.
##
## Compile and run with:
##   nim c -d:release --threads:on examples/threaded_fetch.nim

import std/strutils
import puppy

type
  FetchJob = object
    id: int
    url: string

  FetchResult = object
    id: int
    ok: bool
    body: string
    errorMsg: string

var
  jobs: Channel[FetchJob]
  results: Channel[FetchResult]

proc fetchWorker() {.thread.} =
  ## Runs forever, fetching URLs until a job with an empty url asks it to stop.
  while true:
    let job = jobs.recv()
    if job.url.len == 0:
      break
    var res: FetchResult
    res.id = job.id
    try:
      res.body = fetch(job.url)
      res.ok = true
    except CatchableError as e:
      res.errorMsg = e.msg
    results.send(res)

proc showRss(label: string) =
  ## Best effort, Linux only.
  when defined(linux):
    for line in lines("/proc/self/status"):
      if line.startsWith("VmRSS:"):
        echo label, " RSS: ", line.splitWhitespace()[1], " kB"
        break

proc main() =
  jobs.open()
  results.open()

  var worker: Thread[void]
  worker.createThread(fetchWorker)

  showRss("before:")
  for id in 1 .. 20:
    jobs.send(FetchJob(id: id, url: "https://www.google.com/"))
    let res = results.recv()
    if res.ok:
      echo "job ", res.id, ": got ", res.body.len, " bytes"
    else:
      echo "job ", res.id, " failed: ", res.errorMsg
  showRss("after: ")

  jobs.send(FetchJob()) # an empty url stops the worker
  worker.joinThreads()
  jobs.close()
  results.close()

main()
