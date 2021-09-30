type
  BOOL* = int32
  WCHAR* = uint16
  OLECHAR* = WCHAR
  LPCOLESTR* = ptr OLECHAR
  GUID* {.pure.} = object
    Data1*: int32
    Data2*: uint16
    Data3*: uint16
    Data4*: array[8, uint8]
  CLSID* = GUID
  LPCLSID* = ptr CLSID
  LONG* = int32
  USHORT* = uint16
  HRESULT* = LONG
  PVOID* = pointer
  WORD* = uint16
  LONGLONG* = int64
  DWORD* = int32
  INT* = int32
  UINT* = int32
  BYTE* = uint8
  LPCCH* = cstring
  CHAR* = char
  LPWSTR* = ptr WCHAR
  LPCWCH* = ptr WCHAR
  VARTYPE* = uint16
  LPSTR* = cstring
  LPBOOL* = ptr BOOL
  SHORT* = int16
  ULONGLONG* = int64
  LCID* = ULONG
  IID* = GUID
  REFIID* = ptr IID
  DOUBLE* = float64
  REFCLSID* = ptr IID
  HTTPREQUEST_PROXY_SETTING* = LONG
  HTTPREQUEST_SETCREDENTIALS_FLAGS* = LONG
  FLOAT* = float32
  ULONG* = uint32
  DISPID* = LONG
  DATE* = float64
  LPOLESTR* = ptr OLECHAR
  SCODE* = LONG
  BSTR* = distinct ptr OLECHAR
  DECIMAL_UNION1_STRUCT1* {.pure.} = object
    scale*: BYTE
    sign*: BYTE
  DECIMAL_UNION1* {.pure, union.} = object
    struct1*: DECIMAL_UNION1_STRUCT1
    signscale*: USHORT
  DECIMAL_UNION2_STRUCT1* {.pure.} = object
    Lo32*: ULONG
    Mid32*: ULONG
  DECIMAL_UNION2* {.pure, union.} = object
    struct1*: DECIMAL_UNION2_STRUCT1
    Lo64*: ULONGLONG
  DECIMAL* {.pure.} = object
    wReserved*: USHORT
    union1*: DECIMAL_UNION1
    Hi32*: ULONG
    union2*: DECIMAL_UNION2
  EXCEPINFO* {.pure.} = object
    wCode*: WORD
    wReserved*: WORD
    bstrSource*: BSTR
    bstrDescription*: BSTR
    bstrHelpFile*: BSTR
    dwHelpContext*: DWORD
    pvReserved*: PVOID
    pfnDeferredFillIn*: proc(P1: ptr EXCEPINFO): HRESULT {.stdcall.}
    scode*: SCODE
  CY_STRUCT1* {.pure.} = object
    Lo*: int32
    Hi*: int32
  CY* {.pure, union.} = object
    struct1*: CY_STRUCT1
    int64*: LONGLONG
  SAFEARRAYBOUND* {.pure.} = object
    cElements*: ULONG
    lLbound*: LONG
  SAFEARRAY* {.pure.} = object
    cDims*: USHORT
    fFeatures*: USHORT
    cbElements*: ULONG
    cLocks*: ULONG
    pvData*: PVOID
    rgsabound*: array[1, SAFEARRAYBOUND]
  VARIANT_UNION1_STRUCT1_UNION1_STRUCT1* {.pure.} = object
    pvRecord*: PVOID
    pRecInfo*: ptr IRecordInfo
  VARIANT_UNION1_STRUCT1_UNION1* {.pure, union.} = object
    llVal*: LONGLONG
    lVal*: LONG
    bVal*: BYTE
    iVal*: SHORT
    fltVal*: FLOAT
    dblVal*: DOUBLE
    boolVal*: VARIANT_BOOL
    scode*: SCODE
    cyVal*: CY
    date*: DATE
    bstrVal*: BSTR
    punkVal*: ptr IUnknown
    pdispVal*: ptr IDispatch
    parray*: ptr SAFEARRAY
    pbVal*: ptr BYTE
    piVal*: ptr SHORT
    plVal*: ptr LONG
    pllVal*: ptr LONGLONG
    pfltVal*: ptr FLOAT
    pdblVal*: ptr DOUBLE
    pboolVal*: ptr VARIANT_BOOL
    pscode*: ptr SCODE
    pcyVal*: ptr CY
    pdate*: ptr DATE
    pbstrVal*: ptr BSTR
    ppunkVal*: ptr ptr IUnknown
    ppdispVal*: ptr ptr IDispatch
    pparray*: ptr ptr SAFEARRAY
    pvarVal*: ptr VARIANT
    byref*: PVOID
    cVal*: CHAR
    uiVal*: USHORT
    ulVal*: ULONG
    ullVal*: ULONGLONG
    intVal*: INT
    uintVal*: UINT
    pdecVal*: ptr DECIMAL
    pcVal*: cstring
    puiVal*: ptr USHORT
    pulVal*: ptr ULONG
    pullVal*: ptr ULONGLONG
    pintVal*: ptr INT
    puintVal*: ptr UINT
    struct1*: VARIANT_UNION1_STRUCT1_UNION1_STRUCT1
  VARIANT_UNION1_STRUCT1* {.pure.} = object
    vt*: VARTYPE
    wReserved1*: WORD
    wReserved2*: WORD
    wReserved3*: WORD
    union1*: VARIANT_UNION1_STRUCT1_UNION1
  VARIANT_UNION1* {.pure, union.} = object
    struct1*: VARIANT_UNION1_STRUCT1
    decVal*: DECIMAL
  VARIANT* {.pure.} = object
    union1*: VARIANT_UNION1
  VARIANT_BOOL* = int16
  DISPPARAMS* {.pure.} = object
    rgvarg*: ptr VARIANT
    rgdispidNamedArgs*: ptr DISPID
    cArgs*: UINT
    cNamedArgs*: UINT
  LPUNKNOWN* = pointer
  LPVOID* = pointer
  WinHttpRequestOption* = enum
    UserAgentString
    URL
    URLCodePage
    EscapePercentInURL
    SslErrorIgnoreFlags
    SelectCertificate
    EnableRedirects
    UrlEscapeDisable
    UrlEscapeDisableQuery
    SecureProtocols
    EnableTracing
    RevertImpersonationOverSsl
    EnableHttpsToHttpRedirects
    EnablePassportAuthentication
    MaxAutomaticRedirects
    MaxResponseHeaderSize
    MaxResponseDrainSize
    EnableHttp1_1
    EnableCertificateRevocationCheck
    RejectUserpwd
  WinHttpRequestAutoLogonPolicy* = enum
    Always
    OnlyIfBypassProxy
    Never
  IUnknown* {.pure.} = object
    lpVtbl*: ptr IUnknownVtbl
  IUnknownVtbl* {.pure, inheritable.} = object
    QueryInterface*: proc(self: ptr IUnknown, riid: REFIID, ppvObject: ptr pointer): HRESULT {.stdcall.}
    AddRef*: proc(self: ptr IUnknown): ULONG {.stdcall.}
    Release*: proc(self: ptr IUnknown): ULONG {.stdcall.}
  ITypeInfo* {.pure.} = object
    lpVtbl*: pointer
  IRecordInfo* = object
    lpVtbl*: pointer
  IDispatch* {.pure.} = object
    lpVtbl*: ptr IDispatchVtbl
  IDispatchVtbl* {.pure, inheritable.} = object of IUnknownVtbl
    GetTypeInfoCount*: proc(self: ptr IDispatch, pctinfo: ptr UINT): HRESULT {.stdcall.}
    GetTypeInfo*: proc(self: ptr IDispatch, iTInfo: UINT, lcid: LCID, ppTInfo: ptr ptr ITypeInfo): HRESULT {.stdcall.}
    GetIDsOfNames*: proc(self: ptr IDispatch, riid: REFIID, rgszNames: ptr LPOLESTR, cNames: UINT, lcid: LCID, rgDispId: ptr DISPID): HRESULT {.stdcall.}
    Invoke*: proc(self: ptr IDispatch, dispIdMember: DISPID, riid: REFIID, lcid: LCID, wFlags: WORD, pDispParams: ptr DISPPARAMS, pVarResult: ptr VARIANT, pExcepInfo: ptr EXCEPINFO, puArgErr: ptr UINT): HRESULT {.stdcall.}
  IWinHttpRequest* {.pure.} = object
    lpVtbl*: ptr IWinHttpRequestVtbl
  IWinHttpRequestVtbl* {.pure.} = object of IDispatchVtbl
    SetProxy*: proc(self: ptr IWinHttpRequest, proxySetting: HTTPREQUEST_PROXY_SETTING, proxyServer, bypassList: VARIANT): HRESULT {.stdcall.}
    SetCredentials*: proc(self: ptr IWinHttpRequest, userName, password: BSTR, flags: HTTPREQUEST_SETCREDENTIALS_FLAGS): HRESULT {.stdcall.}
    Open*: proc(self: ptr IWinHttpRequest, verb, url: BSTR, async: VARIANT): HRESULT {.stdcall.}
    SetRequestHeader*: proc(self: ptr IWinHttpRequest, header, value: BSTR): HRESULT {.stdcall.}
    GetResponseHeader*: proc(self: ptr IWinHttpRequest, header: BSTR, value: ptr BSTR): HRESULT {.stdcall.}
    GetAllResponseHeaders*: proc(self: ptr IWinHttpRequest, headers: ptr BSTR): HRESULT {.stdcall.}
    Send*: proc(self: ptr IWinHttpRequest, body: VARIANT): HRESULT {.stdcall.}
    get_Status*: proc(self: ptr IWinHttpRequest, status: ptr LONG): HRESULT {.stdcall.}
    get_StatusText*: proc(self: ptr IWinHttpRequest, status: ptr BSTR): HRESULT {.stdcall.}
    get_ResponseText*: proc(self: ptr IWinHttpRequest, body: ptr BSTR): HRESULT {.stdcall.}
    get_ResponseBody*: proc(self: ptr IWinHttpRequest, body: ptr VARIANT): HRESULT {.stdcall.}
    get_ResponseStream*: proc(self: ptr IWinHttpRequest, body: ptr VARIANT): HRESULT {.stdcall.}
    get_Option*: proc(self: ptr IWinHttpRequest, option: WinHttpRequestOption, value: ptr VARIANT): HRESULT {.stdcall.}
    put_Option*: proc(self: ptr IWinHttpRequest, option: WinHttpRequestOption, value: VARIANT): HRESULT {.stdcall.}
    WaitForResponse*: proc(self: ptr IWinHttpRequest, timeout: VARIANT, succeeded: ptr VARIANT_BOOL): HRESULT {.stdcall.}
    Abort*: proc(self: ptr IWinHttpRequest): HRESULT {.stdcall.}
    SetTimeouts*: proc(self: ptr IWinHttpRequest, resolveTimeout, connectTimeout, sendTimeout, receiveTimeout: LONG): HRESULT {.stdcall.}
    SetClientCertificate*: proc(self: ptr IWinHttpRequest, clientCertificate: BSTR): HRESULT {.stdcall.}
    SetAutoLogonPolicy*: proc(self: ptr IWinHttpRequest, autoLogonPolicy: WinHttpRequestAutoLogonPolicy): HRESULT {.stdcall.}

const
  CP_UTF8* = 65001
  S_OK* = HRESULT 0x00000000
  CLSCTX_INPROC_SERVER* = 0x1
  CLSCTX_INPROC_HANDLER* = 0x2
  CLSCTX_LOCAL_SERVER* = 0x4
  VT_EMPTY* = 0
  VT_NULL* = 1
  VT_I2* = 2
  VT_I4* = 3
  VT_R4* = 4
  VT_R8* = 5
  VT_CY* = 6
  VT_DATE* = 7
  VT_BSTR* = 8
  VT_DISPATCH* = 9
  VT_ERROR* = 10
  VT_BOOL* = 11
  VT_VARIANT* = 12
  VT_UNKNOWN* = 13
  VT_DECIMAL* = 14
  VT_I1* = 16
  VT_UI1* = 17
  VT_UI2* = 18
  VT_UI4* = 19
  VT_I8* = 20
  VT_UI8* = 21
  VT_INT* = 22
  VT_UINT* = 23
  VT_VOID* = 24
  VT_HRESULT* = 25
  VT_PTR* = 26
  VT_SAFEARRAY* = 27
  VT_CARRAY* = 28
  VT_USERDEFINED* = 29
  VT_LPSTR* = 30
  VT_LPWSTR* = 31
  VT_RECORD* = 36
  VT_INT_PTR* = 37
  VT_UINT_PTR* = 38
  VT_FILETIME* = 64
  VT_BLOB* = 65
  VT_STREAM* = 66
  VT_STORAGE* = 67
  VT_STREAMED_OBJECT* = 68
  VT_STORED_OBJECT* = 69
  VT_BLOB_OBJECT* = 70
  VT_CF* = 71
  VT_CLSID* = 72
  VT_VERSIONED_STREAM* = 73
  VT_BSTR_BLOB* = 0xfff
  VT_VECTOR* = 0x1000
  VT_ARRAY* = 0x2000
  VT_BYREF* = 0x4000
  VT_RESERVED* = 0x8000
  VT_ILLEGAL* = 0xffff
  VT_ILLEGALMASKED* = 0xfff
  VT_TYPEMASK* = 0xfff

proc MultiByteToWideChar*(codePage: UINT, dwFlags: DWORD, lpMultiByteStr: LPCCH, cbMultiByte: int32, lpWideCharStr: LPWSTR, cchWideChar: int32): int32 {.importc, stdcall, dynlib: "kernel32".}
proc WideCharToMultiByte*(codePage: UINT, dwFlags: DWORD, lpWideCharStr: LPCWCH, cchWideChar: int32, lpMultiByteStr: LPSTR, cbMultiByte: int32, lpDefaultChar: LPCCH, lpUsedDefaultChar: LPBOOL): int32 {.importc, stdcall, dynlib: "kernel32".}
proc CLSIDFromProgID*(lpszProgID: LPCOLESTR, lpclsid: LPCLSID): HRESULT {.importc, stdcall, dynlib: "ole32".}
proc CoInitialize*(pvReserved: LPVOID): HRESULT {.importc, stdcall, dynlib: "ole32".}
proc CoCreateInstance*(rclsid: REFCLSID, pUnkOuter: LPUNKNOWN, dwClsContext: DWORD, riid: REFIID, ppv: ptr LPVOID): HRESULT {.importc, stdcall, dynlib: "ole32".}
proc SysAllocStringLen*(psz: ptr OLECHAR, ui: UINT): BSTR {.importc, stdcall, dynlib: "oleaut32".}
proc SysFreeString*(bstrString: BSTR): void {.importc, stdcall, dynlib: "oleaut32".}
proc SysStringLen *(bstrString: BSTR): UINT {.importc, stdcall, dynlib: "oleaut32".}
proc VariantInit*(pvarg: ptr VARIANT): void {.importc, stdcall, dynlib: "oleaut32".}
proc VariantClear*(pvarg: ptr VARIANT): void {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayCreate*(vt: VARTYPE, cDims: UINT, rgsabound: ptr SAFEARRAYBOUND): ptr SAFEARRAY {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayGetDim*(psa: ptr SAFEARRAY): HRESULT {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayDestroy*(psa: ptr SAFEARRAY): UINT {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayGetUBound*(psa: ptr SAFEARRAY, nDim: UINT, plUbound: ptr LONG): HRESULT {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayGetLBound*(psa: ptr SAFEARRAY, nDim: UINT, plLbound: ptr LONG): HRESULT {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayAccessData*(psa: ptr SAFEARRAY, ppvData: ptr pointer): HRESULT {.importc, stdcall, dynlib: "oleaut32".}
proc SafeArrayUnaccessData*(psa: ptr SAFEARRAY): HRESULT {.importc, stdcall, dynlib: "oleaut32".}
