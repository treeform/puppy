import common

template currentExceptionAsPuppyError*(): untyped =
  ## Gets the current exception and returns it as a PuppyError with stack trace.
  let e = getCurrentException()
  newException(PuppyError, e.getStackTrace & e.msg, e)
