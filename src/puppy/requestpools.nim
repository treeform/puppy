import std/atomics
import puppy
import loony, loony/ward

when not defined(gcArc):
  {.error: "Please use --gc:arc when using Puppy request pools.".}

type
  RequestPoolObj = object
    threads: seq[Thread[ptr RequestPoolObj]]
    queue: Ward[ResponseHandle, toWardFlags {PoolWaiter}]
    closed: Atomic[bool]
    requestsCompleted: Atomic[bool]

  RequestPool* = ref RequestPoolObj

  ResponseHandleInternal = object
    ready: Atomic[bool]
    request: Request
    response: Response
    error: ref PuppyError
    refCount: Atomic[int]

  ResponseHandle* = object
    internal: ptr ResponseHandleInternal

proc free(internal: ptr ResponseHandleInternal) =
  internal.request = nil
  internal.response = nil
  internal.error = nil

proc `=destroy`(handle: var ResponseHandle) =
  if handle.internal != nil:
    if handle.internal.refCount.load() == 0:
      free handle.internal
    else:
      discard handle.internal.refCount.fetchSub(1)

proc `=`*(dst: var ResponseHandle, src: ResponseHandle) =
  if src.internal != nil:
    discard src.internal.refCount.fetchAdd(1)

  if dst.internal != nil:
    `=destroy`(dst)

  dst.internal = src.internal

proc `=destroy`(pool: var RequestPoolObj) =
  pool.closed.store(true)
  pool.queue.killWaiters()

  joinThreads(pool.threads)

  `=destroy`(pool.threads)
  `=destroy`(pool.queue)

proc ready*(handle: ResponseHandle): bool =
  result = handle.internal.response != nil

proc response*(handle: ResponseHandle): Response =
  var error: ref PuppyError

  result = handle.internal.response
  error = handle.internal.error

  if error != nil:
    raise error

proc workerProc(pool: ptr RequestPoolObj) {.raises: [].} =
  while true:
    let handle = pool.queue.pop()
    if pool.closed.load():
      break

    var
      response: Response
      error: ref PuppyError
    try:
      response = fetch(handle.internal.request)
    except PuppyError as e:
      error = e

    handle.internal.response = response
    handle.internal.error = error

    pool.requestsCompleted.store(true)

proc newRequestPool*(maxInFlight: int): RequestPool =
  result = RequestPool()
  var looq = newLoonyQueue[ResponseHandle]()
  var queue = newWard(looq, {PoolWaiter})
  result.queue = queue
  result.threads.setLen(maxInFlight)
  for thread in result.threads.mitems:
    createThread(thread, workerProc, cast[ptr RequestPoolObj](result))

proc fetch*(pool: RequestPool, request: Request): ResponseHandle =
  result.internal = cast[ptr ResponseHandleInternal](
    alloc0(sizeof(ResponseHandleInternal))
  )
  result.internal.request = request

  discard pool.queue.push(result)

proc requestsCompleted*(pool: RequestPool): bool =
  ## Returns whether or not at least one request has completed since the last
  ## time this proc was called.
  result = pool.requestsCompleted.exchange(false)
