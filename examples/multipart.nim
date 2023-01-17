import puppy

var entries: seq[MultipartEntry]
entries.add MultipartEntry(
  name: "input_text",
  fileName: "input.txt",
  contentType: "text/plain",
  payload: "foobar"
)
entries.add MultipartEntry(
  name: "options",
  payload: "{\"utf8\":true}"
)

let (contentType, body) = encodeMultipart(entries)

var headers: HttpHeaders
headers["Content-Type"] = contentType

let response = post("http://localhost:8080", headers, body)

echo response.code
