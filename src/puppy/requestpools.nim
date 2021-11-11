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
    requestsCompleted: bool

  RequestPool* = ref RequestPoolObj

  ResponseHandleInternal = object
    lock: Lock
    request: Request
    response: Response
    error: ref PuppyError
    refCount: int

  ResponseHandle* = object
    internal: ptr ResponseHandleInternal

proc free(internal: ptr ResponseHandleInternal) =
  deinitLock(internal.lock)
  internal.request = nil
  internal.response = nil
  internal.error = nil
  dealloc(internal)

proc `=destroy`(handle: var ResponseHandle) =
  if handle.internal != nil:
    acquire(handle.internal.lock)
    if handle.internal.refCount == 0:
      release(handle.internal.lock)
      free handle.internal
    else:
      dec handle.internal.refCount
      release(handle.internal.lock)

proc `=`*(dst: var ResponseHandle, src: ResponseHandle) =
  if src.internal != nil:
    acquire(src.internal.lock)
    inc src.internal.refCount
    release(src.internal.lock)

  if dst.internal != nil:
    `=destroy`(dst)

  dst.internal = src.internal

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
  acquire(handle.internal.lock)
  result = handle.internal.response != nil
  release(handle.internal.lock)

proc response*(handle: ResponseHandle): Response =
  var error: ref PuppyError

  acquire(handle.internal.lock)
  result = handle.internal.response
  error = handle.internal.error
  release(handle.internal.lock)

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
      response = fetch(handle.internal.request)
    except PuppyError as e:
      error = e

    acquire(handle.internal.lock)
    handle.internal.response = response
    handle.internal.error = error
    release(handle.internal.lock)

    acquire(pool.lock)
    pool.requestsCompleted = true
    release(pool.lock)

proc newRequestPool*(maxInFlight: int): RequestPool =
  result = RequestPool()
  initLock(result.lock)
  initCond(result.cond)
  result.threads.setLen(maxInFlight)
  for thread in result.threads.mitems:
    createThread(thread, workerProc, cast[ptr RequestPoolObj](result))

proc fetch*(pool: RequestPool, request: Request): ResponseHandle =
  result.internal = cast[ptr ResponseHandleInternal](
    alloc0(sizeof(ResponseHandleInternal))
  )
  initLock(result.internal.lock)
  result.internal.request = request

  acquire(pool.lock)
  pool.queue.addLast(result)
  release(pool.lock)

  signal(pool.cond)

proc requestsCompleted*(pool: RequestPool): bool =
  ## Returns whether or not at least one request has completed since the last
  ## time this proc was called.
  acquire(pool.lock)
  result = pool.requestsCompleted
  pool.requestsCompleted = false
  release(pool.lock)
