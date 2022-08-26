import strutils, urlly

export urlly

const CRLF* = "\r\n"

type
  Header* = object
    key*: string
    value*: string

  Request* = ref object
    url*: Url
    headers*: seq[Header]
    timeout*: float32
    verb*: string
    body*: string
    when defined(puppyLibcurl) or (defined(windows) or not defined(macosx)):
      allowAnyHttpsCertificate*: bool

  Response* = ref object
    headers*: seq[Header]
    code*: int
    body*: string
  PuppyError* = object of IOError ## Raised if an operation fails.

proc `[]`*(headers: seq[Header], key: string): string =
  ## Get a key out of headers. Not case sensitive.
  ## Use a for loop to get multiple keys.
  for header in headers:
    if header.key.toLowerAscii() == key.toLowerAscii():
      return header.value

proc `[]=`*(headers: var seq[Header], key, value: string) =
  ## Sets a key in the headers. Not case sensitive.
  ## If key is not there appends a new key-value pair at the end.
  for header in headers.mitems:
    if header.key.toLowerAscii() == key.toLowerAscii():
      header.value = value
      return
  headers.add(Header(key: key, value: value))

proc `$`*(req: Request): string =
  req.verb.toUpperAscii & " " & $req.url
