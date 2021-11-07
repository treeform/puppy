import puppy/common, unicode

proc toUtf16*(input: string): seq[uint16] =
  for rune in input.runes:
    let u = rune.uint32
    if (0x0000 <= u and u <= 0xD7FF) or (0xE000 <= u and u <= 0xFFFF):
      result.add(u.uint16)
    elif 0x010000 <= u and u <= 0x10FFFF:
      let
        u0 = u - 0x10000
        w1 = 0xD800 + u0 div 0x400
        w2 = 0xDC00 + u0 mod 0x400
      result.add(w1.uint16)
      result.add(w2.uint16)
  result.add(0) # null terminator

proc toUtf8*(input: seq[uint16]): string =
  if input[input.high] != 0:
    raise newException(PuppyError, "Missing UTF-16 null terminator")

  var i: int
  while i < input.high:
    var u1 = input[i]
    inc i
    if u1 - 0xd800 >= 0x800:
      result.add Rune(u1.int)
    else:
      var u2 = input[i]
      inc i
      if ((u1 and 0xfc00) == 0xd800) and ((u2 and 0xfc00) == 0xdc00):
        result.add Rune((u1.uint32 shl 10) + u2.uint32 - 0x35fdc00)
      else:
        # Error, produce tofu character.
        result.add "□"
