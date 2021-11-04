import std/os, std/locks, ../puppy

## Create a pool of 12 threads

const
  numConcurrentThreads = 12

type
  RequestHandle* = int
  RequestHandleState = enum
    RequestEmpty
    RequestInProgress
    RequestDone

var
  requestThreads: array[numConcurrentThreads, Thread[int]]
  requestLock: Lock
  mapping: seq[(Request, Response, RequestHandleState)]
  chanIn: Channel[RequestHandle]

proc threadFunc(threadNum: int) {.thread.} =
  while true:
    let chanRequest = chanIn.tryRecv()
    if chanRequest.dataAvailable:
      let id = chanRequest.msg
      {.gcSafe.}:
        acquire(requestLock)
        var request = mapping[id][0]
        release(requestLock)

      echo "started: ", threadNum, " ", $request.url

      {.gcSafe.}:
        var response = fetch(request)

      {.gcSafe.}:
        acquire(requestLock)
        mapping[id][2] = RequestDone
        mapping[id][1] = response
        release(requestLock)

    sleep(1)

proc fetchParallel*(request: Request): RequestHandle =
  acquire(requestLock)
  result = -1
  for id in 0 ..< mapping.len:
    if mapping[id][2] == RequestEmpty:
      mapping[id] = (request, Response(), RequestInProgress)
      result = id
  if result == -1:
    result = mapping.len
    mapping.add((request, Response(), RequestInProgress))
  release(requestLock)
  chanIn.send(result)

proc ready*(id: RequestHandle): bool =
  acquire(requestLock)
  result = mapping[id][2] == RequestDone
  release(requestLock)

proc response*(id: RequestHandle): Response =
  acquire(requestLock)
  if mapping[id][2] == RequestDone:
    result = mapping[id][1]
    mapping[id][2] = RequestEmpty
  release(requestLock)

proc openPool*() =
  initLock(requestLock)
  chanIn.open()
  for i in 0 ..< numConcurrentThreads:
    createThread(requestThreads[i], threadFunc, i)

proc closePool*() =
  acquire(requestLock)
  mapping.setLen(0)
  release(requestLock)
  chanIn.close()
