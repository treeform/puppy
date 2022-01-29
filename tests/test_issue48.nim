when (NimMajor, NimMinor, NimPatch) >= (1, 6, 0):
  when not compileOption("threads"):
    echo "This test requres --threads:on"
  else:
    import puppy

    type
      ChannelRef*[T] = ptr Channel[T]
      Client* = ref object
        requestThread*: Thread[Client]
        action*: ChannelRef[Action]
      ActionKind* = enum
        Stop, Fetch,
      Action* = object
        case kind*: ActionKind
        of Stop:
          discard
        of Fetch:
          request*: Request

    proc sendAction*(client: Client, action: Action) =
      client.action[].send(action)

    proc recvAction(client: Client) {.thread.} =
      while true:
        let action = client.action[].recv()
        case action.kind:
        of Stop:
          break
        of Fetch:
          discard fetch(action.request)
          echo "Fetch success!"

    proc initShared(client: var Client) =
      client.action = cast[ChannelRef[Action]](
        allocShared0(sizeof(Channel[Action]))
      )
      client.action[].open()

    proc deinitShared(client: var Client) =
      client.action[].close()
      deallocShared(client.action)

    proc initThreads(client: var Client) =
      createThread(client.requestThread, recvAction, client)

    proc deinitThreads(client: var Client) =
      client.action[].send(Action(kind: Stop))
      client.requestThread.joinThread() # on puppy 1.4.0, it gets stuck here

    proc start*(client: var Client) =
      initShared(client)
      initThreads(client)

    proc stop*(client: var Client) =
      deinitThreads(client)
      deinitShared(client)
      echo "Stopped client thread"

    when isMainModule:
      var client = Client()
      client.start()
      let req = Request(
        url: parseUrl("https://nim-lang.org/"),
        verb: "get",
      )
      client.sendAction(Action(kind: Fetch, request: req))
      client.stop()
