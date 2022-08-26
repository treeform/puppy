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
  ERROR_WINHTTP_SECURE_FAILURE* = 12175
  ERROR_INTERNET_INVALID_CA* = 12045
  WINHTTP_OPTION_SECURITY_FLAGS* = 31
  SECURITY_FLAG_IGNORE_UNKNOWN_CA* = 0x00000100
  # SECURITY_FLAG_IGNORE_WRONG_USAGE* = 0x00000200
  SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE* = 0x00000200
  SECURITY_FLAG_IGNORE_CERT_CN_INVALID* = 0x00001000
  SECURITY_FLAG_IGNORE_CERT_DATE_INVALID* = 0x00002000

{.push importc, stdcall.}
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

proc WinHttpSetOption*(
  hInternet: HINTERNET,
  dwOption: DWORD,
  lpBuffer: LPVOID,
  dwBufferLength: DWORD
): BOOL {.dynlib: "winhttp".}

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
