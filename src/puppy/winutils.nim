import unicode

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
