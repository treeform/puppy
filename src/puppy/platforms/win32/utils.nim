import windefs

proc wstr*(str: string): string =
  let wlen = MultiByteToWideChar(
    CP_UTF8,
    0,
    str.cstring,
    str.len.int32,
    nil,
    0
  )
  result.setLen(wlen * 2 + 1)
  discard MultiByteToWideChar(
    CP_UTF8,
    0,
    str.cstring,
    str.len.int32,
    cast[ptr WCHAR](result[0].addr),
    wlen
  )

proc `$`*(p: ptr WCHAR): string =
  let len = WideCharToMultiByte(
    CP_UTF8,
    0,
    p,
    -1,
    nil,
    0,
    nil,
    nil
  )
  if len > 0:
    result.setLen(len)
    discard WideCharToMultiByte(
      CP_UTF8,
      0,
      p,
      -1,
      result[0].addr,
      len,
      nil,
      nil
    )
    # The null terminator is included when -1 is used for the parameter length.
    # Trim this null terminating character.
    result.setLen(len - 1)
