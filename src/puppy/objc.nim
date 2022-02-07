import macros, typetraits, strutils

type
  Class* = distinct int
  ID* = distinct int
  SEL* = distinct int
  Protocol* = distinct int
  IMP* = proc(self: ID, cmd: SEL): ID {.cdecl, varargs.}
  objc_super* = object
    receiver*: ID
    super_class*: Class

{.push cdecl, dynlib: "libobjc.dylib".}
proc objc_msgSend*() {.importc.}
proc objc_msgSendSuper*() {.importc.}
when defined(amd64):
  proc objc_msgSend_fpret*() {.importc.}
  proc objc_msgSend_stret*() {.importc.}
else:
  proc objc_msgSend_fpret*() {.importc: "objc_msgSend".}
  proc objc_msgSend_stret*() {.importc: "objc_msgSend".}
proc objc_getClass*(name: cstring): Class {.importc.}
proc objc_getProtocol*(name: cstring): Protocol {.importc.}
proc objc_allocateClassPair*(super: Class, name: cstring, extraBytes = 0): Class {.importc.}
proc objc_registerClassPair*(cls: Class) {.importc.}
proc class_getName*(cls: Class): cstring {.importc.}
proc class_addMethod*(cls: Class, name: SEL, imp: IMP, types: cstring): bool {.importc.}
proc object_getClass*(id: ID): Class {.importc.}
proc sel_registerName*(s: cstring): SEL {.importc.}
proc sel_getName*(sel: SEL): cstring {.importc.}
proc class_addProtocol*(cls: Class, protocol: Protocol): bool {.importc.}
{.pop.}

var
  numClass {.compiletime.} = 1
  numSel {.compiletime.} = 2

macro objc*(body: untyped) =
  ## Takes function declarations and converts them to ObjC calls.

  # Header contains all static class lookups and selector registration.
  var header = newStmtList()

  # For each function, add body and collect its classes and selectors.
  for fn in body:
    var
      name = fn[0].repr
      retType = fn[3][0]
      sel = name
      classMethod = false
      numParams = 0

    sel.removeSuffix("*")

    # Mark each proc inline:
    fn[4] = quote do: {.inline.}

    # Add a template body without the arguments.
    let msgSend = ident("msgSend")
    var procBody = quote do:
      let `msgSend` = cast[proc(): `retType` {.cdecl, raises: [], gcsafe.}](
        objc_msgSend
      )
      `msgSend`()

    fn[6] = procBody

    # Someday we can look at the retType and be smarter but this works well now.
    if repr(retType) in ["NSRect"]:
      procBody[0][0][2][1] = ident("objc_msgSend_stret")
    elif repr(retType) in ["float64", "NSPoint"]:
      procBody[0][0][2][1] = ident("objc_msgSend_fpret")

    # For each argument decide what to do
    for defs in fn[3][1..^1]:
      for arg in defs[0 .. ^3]:
        let
          argName = repr arg
          argType = defs[^2]

        if numParams == 0:
          if argName notin ["class", "self"]:
            error("First argument needs to be class or self.", arg)

          # First argument is very special, it is either a class or self ID.
          if argType.kind == nnkBracketExpr:
            if argType[0].strVal == "typedesc":
              let
                classVar = ident("class" & $numClass)
                classStr = newStrLitNode(argType[1].strVal)
              header.add quote do:
                let `classVar` = objc_getClass(`classStr`.cstring)
              classMethod = true
              inc numClass
              procBody[1].add classVar

              var idenDefs = newIdentDefs(ident("cls"), ident("Class"))
              procBody[0][0][2][0][0].add idenDefs

          else:
            var idenDefs = newIdentDefs(ident("self"), argType)
            procBody[0][0][2][0][0].add idenDefs
            procBody[1].add ident(argName)

          var idenDefs = newIdentDefs(ident("cmd"), ident("SEL"))
          procBody[0][0][2][0][0].add idenDefs
          procBody[1].add ident("sel" & $numSel)

        else:
          # Second "first real arugment never gets a selector entry, only :
          if numParams != 1:
            var fixArg = argName
            fixArg.removeSuffix("_mangle")
            sel.add fixArg
          else:
            if argName != "_":
              error("Second arugment needs to be _.", arg)
          sel.add ":"

          # Add second name and type as is.
          var idenDefs = newIdentDefs(ident(argName), argType)
          procBody[0][0][2][0][0].add idenDefs
          procBody[1].add ident(argName)

        inc numParams

    let
      selVar = ident("sel" & $numSel)
      selStr = newStrLitNode(sel)
    header.add quote do:
      let `selVar` = sel_registerName(`selStr`.cstring)

    inc numSel

  body.insert(0, header)

  return body

type
  NSAutoreleasePool* = distinct int
  NSString* = distinct int
  NSError* = distinct int

objc:
  proc UTF8String(self: NSString): cstring
  proc localizedDescription(self: NSError): NSString
  proc release*(self: NSAutoreleasePool)

template addClass*(className, superName: string, cls: Class, body: untyped) =
  block:
    cls = objc_allocateClassPair(
      objc_getClass(superName.cstring),
      className.cstring
    )

    template addProtocol(protocolName: string) =
      discard class_addProtocol(cls, objc_getProtocol(protocolName.cstring))

    template addMethod(methodName: string, fn: untyped) =
      discard class_addMethod(
        cls,
        s(methodName),
        cast[IMP](fn),
        "".cstring
      )

    body

    objc_registerClassPair(cls)

template s*(s: string): SEL =
  sel_registerName(s.cstring)

proc `$`*(cls: Class): string =
  $class_getName(cls)

proc `$`*(id: ID): string =
  $object_getClass(id)

proc `$`*(sel: SEL): string =
  $sel_getName(sel)

proc getClass*(t: typedesc): Class =
  objc_getClass(t.name.cstring)

template autoreleasepool*(body: untyped) =
  let pool = NSAutoreleasePool.new()
  try:
    body
  finally:
    pool.release()

proc `@`*(s: string): NSString =
  let msgSend = cast[
    proc(self: ID, cmd: SEL, s: cstring): NSString {.cdecl, raises: [], gcsafe.}
  ](objc_msgSend)
  msgSend(
    NSString.getClass().ID,
    s"stringWithUTF8String:",
    s.cstring
  )

proc `$`*(s: NSString): string =
  $s.UTF8String

proc `$`*(error: NSError): string =
  $error.localizedDescription

proc new*(cls: Class): ID =
  let msgSend = cast[proc(self: ID, cmd: SEL): ID {.cdecl, gcsafe, raises: [].}](objc_msgSend)
  msgSend(
    cls.ID,
    s"new"
  )

proc new*[T](class: typedesc[T]): T =
  class.getClass().new().T

proc alloc*(cls: Class): ID =
  let msgSend = cast[proc(self: ID, cmd: SEL): ID {.cdecl, gcsafe, raises: [].}](objc_msgSend)
  msgSend(
    cls.ID,
    s"alloc"
  )

proc alloc*[T](class: typedesc[T]): T =
  class.getClass().alloc().T
