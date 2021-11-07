when defined(cpu64):
  type
    ULONG_PTR* = uint64
else:
  type
    ULONG_PTR* = uint32

type
  BOOL* = int32
  LPBOOL* = ptr BOOL
  UINT* = uint32
  WORD* = uint16
  DWORD* = int32
  LPDWORD* = ptr DWORD
  LPSTR* = cstring
  LPCCH* = cstring
  WCHAR* = uint16
  LPWSTR* = ptr WCHAR
  LPCWSTR* = ptr WCHAR
  LPCWCH* = ptr WCHAR
  HINTERNET* = pointer
  INTERNET_PORT* = WORD
  DWORD_PTR* = ULONG_PTR
  LPVOID* = pointer

const
  CP_UTF8* = 65001
  INTERNET_OPEN_TYPE_PRECONFIG* = 0
  INTERNET_OPEN_TYPE_DIRECT* = 1
  INTERNET_OPEN_TYPE_PROXY* = 3
  INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY* = 4
  INTERNET_SERVICE_HTTP* = 3
  INTERNET_FLAG_NO_COOKIES* = 0x00080000
  INTERNET_FLAG_SECURE* = 0x00800000
  INTERNET_FLAG_RELOAD* = 0x80000000'i32
  INTERNET_FLAG_NO_CACHE_WRITE* = 0x04000000
  INTERNET_FLAG_KEEP_CONNECTION* = 0x00400000
  HTTP_ADDREQ_FLAG_ADD_IF_NEW* = 0x10000000
  HTTP_ADDREQ_FLAG_ADD* = 0x20000000
  HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA* = 0x40000000
  HTTP_ADDREQ_FLAG_COALESCE_WITH_SEMICOLON* = 0x01000000
  HTTP_ADDREQ_FLAG_COALESCE* = HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA
  HTTP_ADDREQ_FLAG_REPLACE* = 0x80000000'i32
  HTTP_QUERY_RAW_HEADERS_CRLF* = 22
  ERROR_INSUFFICIENT_BUFFER* = 122

{.push importc, stdcall.}

proc GetLastError*(): DWORD {.dynlib: "kernel32".}

proc MultiByteToWideChar*(
  codePage: UINT,
  dwFlags: DWORD,
  lpMultiByteStr: LPCCH,
  cbMultiByte: int32,
  lpWideCharStr: LPWSTR,
  cchWideChar: int32
): int32 {.dynlib: "kernel32".}

proc WideCharToMultiByte*(
  codePage: UINT,
  dwFlags: DWORD,
  lpWideCharStr: LPCWCH,
  cchWideChar: int32,
  lpMultiByteStr: LPSTR,
  cbMultiByte: int32,
  lpDefaultChar: LPCCH,
  lpUsedDefaultChar: LPBOOL
): int32 {.dynlib: "kernel32".}

proc InternetOpenW*(
  lpszAgent: LPCWSTR,
  dwAccessType: DWORD,
  lpszProxy: LPCWSTR,
  lpszProxyBypass: LPCWSTR,
  dwFlags: DWORD
): HINTERNET {.dynlib: "Wininet".}

proc InternetConnectW*(
  hInternet: HINTERNET,
  lpszServerName: LPCWSTR,
  nServerPort: INTERNET_PORT,
  lpszUserName: LPCWSTR,
  lpszPassword: LPCWSTR,
  dwService: DWORD,
  dwFlags: DWORD,
  dwContext: DWORD_PTR
): HINTERNET {.dynlib: "Wininet".}

proc HttpOpenRequestW*(
  hConnect: HINTERNET,
  lpszVerb: LPCWSTR,
  lpszObjectName: LPCWSTR,
  lpszVersion: LPCWSTR,
  lpszReferrer: LPCWSTR,
  lplpszAcceptTypes: ptr LPCWSTR,
  dwFlags: DWORD,
  dwContext: DWORD_PTR
): HINTERNET {.dynlib: "Wininet".}

proc HttpAddRequestHeadersW*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  dwModifiers: DWORD
): BOOL {.dynlib: "Wininet".}

proc HttpSendRequestW*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  lpOptional: LPVOID,
  dwOptionalLength: DWORD
): BOOL {.dynlib: "Wininet".}

proc HttpQueryInfoW*(
  hRequest: HINTERNET,
  dwInfoLevel: DWORD,
  lpBuffer: LPVOID,
  lpdwBufferLength: LPDWORD,
  lpdwIndex: LPDWORD
): BOOL {.dynlib: "Wininet".}

proc InternetReadFile*(
  hFile: HINTERNET,
  lpBuffer: LPVOID,
  dwNumberOfBytesToRead: DWORD,
  lpdwNumberOfBytesRead: LPDWORD
): BOOL {.dynlib: "Wininet".}

proc InternetCloseHandle*(hInternet: HINTERNET): BOOL {.dynlib: "Wininet".}

{.pop.}
