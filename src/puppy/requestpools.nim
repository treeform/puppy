import puppy, std/locks, std/deques

when not defined(gcArc):
  {.error: "Please use --gc:arc when using Puppy request pools.".}

type
  RequestPoolObj = object
    lock: Lock
    cond: Cond
    threads: seq[Thread[ptr RequestPoolObj]]
    queue: Deque[ResponseHandle]
    closed: bool

  RequestPool* = ref RequestPoolObj

  ResponseHandle* = ref object
    lock: Lock
    request: Request
    response: Response
    error: ref PuppyError

proc `=destroy`(handle: var typeof(ResponseHandle()[])) =
  deinitLock(handle.lock)
  handle.request = nil
  handle.response = nil
  handle.error = nil

proc `=destroy`(pool: var RequestPoolObj) =
  acquire(pool.lock)
  pool.closed = true
  release(pool.lock)

  broadcast(pool.cond)

  joinThreads(pool.threads)

  deinitLock(pool.lock)
  deinitCond(pool.cond)
  `=destroy`(pool.threads)
  `=destroy`(pool.queue)

proc ready*(handle: ResponseHandle): bool =
  acquire(handle.lock)
  result = handle.response != nil
  release(handle.lock)

proc response*(handle: ResponseHandle): Response =
  var error: ref PuppyError

  acquire(handle.lock)
  result = handle.response
  error = handle.error
  release(handle.lock)

  if error != nil:
    raise error

proc workerProc(pool: ptr RequestPoolObj) {.raises: [].} =
  while true:
    acquire(pool.lock)

    while pool.queue.len == 0 and not pool.closed:
      wait(pool.cond, pool.lock)

    if pool.closed:
      release(pool.lock)
      break

    let handle = pool.queue.popFirst()

    release(pool.lock)

    var
      response: Response
      error: ref PuppyError
    try:
      response = fetch(handle.request)
    except PuppyError as e:
      error = e

    acquire(handle.lock)
    handle.response = response
    handle.error = error
    release(handle.lock)

proc newRequestPool*(maxInFlight: int): RequestPool =
  result = RequestPool()
  initLock(result.lock)
  initCond(result.cond)
  result.threads.setLen(maxInFlight)
  for thread in result.threads.mitems:
    createThread(thread, workerProc, cast[ptr RequestPoolObj](result))

proc fetch*(pool: RequestPool, request: Request): ResponseHandle =
  result = ResponseHandle()
  initLock(result.lock)
  result.request = request

  acquire(pool.lock)
  pool.queue.addLast(result)
  release(pool.lock)

  signal(pool.cond)
