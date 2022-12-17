import std/strutils, urlly, webby

export urlly, webby

const CRLF* = "\r\n"

type
  Header* = object
    key*: string
    value*: string

  Request* = ref object
    url*: Url
    headers*: HttpHeaders
    timeout*: float32
    verb*: string
    body*: string
    when defined(puppyLibcurl) or (defined(windows) or not defined(macosx)):
      # If you want to use this on Mac, please us -d:puppyLibcurl
      allowAnyHttpsCertificate*: bool

  Response* = ref object
    headers*: HttpHeaders
    code*: int
    body*: string

  PuppyError* = object of IOError ## Raised if an operation fails.

# proc `[]`*(headers: seq[Header], key: string): string =
#   ## Get a key out of headers. Not case sensitive.
#   ## Use a for loop to get multiple keys.
#   for header in headers:
#     if cmpIgnorecase(header.key, key) == 0:
#       return header.value

# proc `[]=`*(headers: var seq[Header], key, value: string) =
#   ## Sets a key in the headers. Not case sensitive.
#   ## If key is not there appends a new key-value pair at the end.
#   for header in headers.mitems:
#     if cmpIgnorecase(header.key, key) == 0:
#       header.value = value
#       return
#   headers.add(Header(key: key, value: value))

proc `$`*(req: Request): string =
  req.verb.toUpperAscii & " " & $req.url

converter toWebby*(headers: seq[Header]): HttpHeaders =
  cast[HttpHeaders](headers)

# converter toWebby*(header: Header): (string, string) =
#   cast[(string, string)](header)
