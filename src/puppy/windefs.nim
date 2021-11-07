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
  WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY* = 4
  WINHTTP_FLAG_SECURE* = 0x00800000
  WINHTTP_ADDREQ_FLAG_ADD* = 0x20000000
  WINHTTP_ADDREQ_FLAG_REPLACE* = 0x80000000'i32
  WINHTTP_QUERY_STATUS_CODE* = 19
  WINHTTP_QUERY_FLAG_NUMBER* = 0x20000000
  WINHTTP_QUERY_RAW_HEADERS_CRLF* = 22
  ERROR_INSUFFICIENT_BUFFER* = 122

{.push importc, stdcall.}

proc GetLastError*(): DWORD {.dynlib: "kernel32".}

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

proc WinHttpOpen*(
  lpszAgent: LPCWSTR,
  dwAccessType: DWORD,
  lpszProxy: LPCWSTR,
  lpszProxyBypass: LPCWSTR,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpSetTimeouts*(
  hSession: HINTERNET,
  nResolveTimeout, nConnectTimeout, nSendTimeout, nReceiveTimeout: int32
): BOOL {.dynlib: "winhttp".}

proc WinHttpConnect*(
  hSession: HINTERNET,
  lpszServerName: LPCWSTR,
  nServerPort: INTERNET_PORT,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpOpenRequest*(
  hConnect: HINTERNET,
  lpszVerb: LPCWSTR,
  lpszObjectName: LPCWSTR,
  lpszVersion: LPCWSTR,
  lpszReferrer: LPCWSTR,
  lplpszAcceptTypes: ptr LPCWSTR,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpAddRequestHeaders*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  dwModifiers: DWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpSendRequest*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  lpOptional: LPVOID,
  dwOptionalLength: DWORD,
  dwTotalLength: DWORD,
  dwContext: DWORD_PTR
): BOOL {.dynlib: "winhttp".}

proc WinHttpReceiveResponse*(
  hRequest: HINTERNET,
  lpReserved: LPVOID
): BOOL {.dynlib: "winhttp".}

proc WinHttpQueryHeaders*(
  hRequest: HINTERNET,
  dwInfoLevel: DWORD,
  pwszName: LPCWSTR,
  lpBuffer: LPVOID,
  lpdwBufferLength: LPDWORD,
  lpdwIndex: LPDWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpReadData*(
  hFile: HINTERNET,
  lpBuffer: LPVOID,
  dwNumberOfBytesToRead: DWORD,
  lpdwNumberOfBytesRead: LPDWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpCloseHandle*(hInternet: HINTERNET): BOOL {.dynlib: "winhttp".}

{.pop.}
