import common, strutils, windefs

type
  WinHttpObj = object
    i: ptr IWinHttpRequest

  WinHttp* = ref WinHttpObj

proc wstr(str: string): string =
  let wlen = MultiByteToWideChar(
    CP_UTF8,
    0,
    str[0].unsafeAddr,
    str.len.int32,
    nil,
    0
  )
  result = newString(wlen * 2 + 1)
  discard MultiByteToWideChar(
    CP_UTF8,
    0,
    str[0].unsafeAddr,
    str.len.int32,
    cast[ptr WCHAR](result[0].addr),
    wlen
  )

proc bstr(str: string): BSTR =
  var ws = str.wstr()
  result = SysAllocStringLen(cast[ptr WCHAR](ws[0].addr), str.len.UINT)

proc `$`(bstr: BSTR): string =
  let mlen = WideCharToMultiByte(
    CP_UTF8,
    0,
    cast[ptr WCHAR](bstr),
    SysStringLen(bstr),
    nil,
    0,
    nil,
    nil
  )
  result = newString(mlen)
  discard WideCharToMultiByte(
    CP_UTF8,
    0,
    cast[ptr WCHAR](bstr),
    SysStringLen(bstr),
    result[0].addr,
    mlen,
    nil,
    nil
  )

proc checkHRESULT(hresult: HRESULT) =
  if hresult != S_OK:
    raise newException(PuppyError, "HRESULT: " & toHex(hresult))

proc `=destroy`(http: var WinHttpObj) =
  discard http.i.lpVtbl.Release(cast[ptr IUnknown](http.i))

proc newWinHttp*(): WinHttp =
  var
    wname = "WinHttp.WinHttpRequest.5.1".wstr()
    clsid: GUID
    hresult = CLSIDFromProgID(
      cast[ptr WCHAR](wname[0].addr),
      clsid.addr
    )
  checkHRESULT(hresult)

  discard CoInitialize(nil)

  var
    IID_IWinHttpRequest = GUID(
      Data1: 0x06f29373,
      Data2: 0x5c5a,
      Data3: 0x4b54,
      Data4: [0xb0.uint8, 0x25, 0x6e, 0xf1, 0xbf, 0x8a, 0xbf, 0x0e]
    )
    p: pointer
  hresult = CoCreateInstance(
    clsid.addr,
    nil,
    CLSCTX_LOCAL_SERVER or CLSCTX_INPROC_SERVER,
    IID_IWinHttpRequest.addr,
    p.addr
  )
  checkHRESULT(hresult)

  result = WinHttp()
  result.i = cast[ptr IWinHttpRequest](p)

proc open*(http: WinHttp, verb, url: string) =
  var varFalse: VARIANT
  VariantInit(varFalse.addr)
  varFalse.union1.struct1.vt = VT_BOOL
  varFalse.union1.struct1.union1.boolVal = false.VARIANT_BOOL

  let
    verbBstr = verb.bstr()
    urlBstr = url.bstr()
    hresult = http.i.lpVtbl.Open(http.i, verbBstr, urlBstr, varFalse)
  SysFreeString(verbBstr)
  SysFreeString(urlBstr)
  VariantClear(varFalse.addr)
  checkHRESULT(hresult)

proc setRequestHeader*(http: WinHttp, header, value: string) =
  let
    headerBstr = header.bstr()
    valueBstr = value.bstr()
    hresult = http.i.lpVtbl.SetRequestHeader(http.i, headerBstr, valueBstr)
  SysFreeString(headerBstr)
  SysFreeString(valueBstr)
  checkHRESULT(hresult)

proc setTimeouts*(
  http: WinHttp,
  resolveTimeout,
  connectTimeout,
  sendTimeout,
  receiveTimeout: int
) =
  checkHRESULT(http.i.lpVtbl.SetTimeouts(
    http.i,
    resolveTimeout.int32,
    connectTimeout.int32,
    sendTimeout.int32,
    receiveTimeout.int32
  ))

proc send*(http: WinHttp, body: string = "") =
  var variantBody: VARIANT
  VariantInit(variantBody.addr)
  if body == "":
    variantBody.union1.struct1.vt = VT_ERROR
  else:
    var bounds: SAFEARRAYBOUND
    bounds.lLbound = 0
    bounds.cElements = body.len.ULONG

    let psa = SafeArrayCreate(VT_UI1, 1, bounds.addr)

    var p: pointer
    checkHRESULT(SafeArrayAccessData(psa, p.addr))
    copyMem(p, body[0].unsafeAddr, body.len)
    checkHRESULT(SafeArrayUnaccessData(psa))

    variantBody.union1.struct1.vt = (VT_ARRAY or VT_UI1)
    variantBody.union1.struct1.union1.parray = psa

  let hresult = http.i.lpVtbl.Send(http.i, variantBody)
  VariantClear(variantBody.addr)
  checkHRESULT(hresult)

proc status*(http: WinHttp): int =
  var status: LONG
  checkHRESULT(http.i.lpVtbl.get_Status(http.i, status.addr))
  result = status

proc getAllResponseHeaders*(http: WinHttp): string =
  var headers: BSTR
  try:
    checkHRESULT(http.i.lpVtbl.GetAllResponseHeaders(http.i, headers.addr))
    result = $headers
  finally:
    SysFreeString(headers)

proc responseBody*(http: WinHttp): string =
  var variantRes: VARIANT
  VariantInit(variantRes.addr)

  try:
    checkHRESULT(http.i.lpVtbl.get_ResponseBody(http.i, variantRes.addr))

    if variantRes.union1.struct1.vt == 0:
      return

    if variantRes.union1.struct1.vt != (VT_ARRAY or VT_UI1):
      raise newException(PuppyError, "Unexpected response body variant type")

    let dims = SafeArrayGetDim(variantRes.union1.struct1.union1.parray)
    if dims != 1:
      raise newException(PuppyError, "Unexpected response body array dims")

    var lowerBounds, upperBounds: int32
    checkHRESULT(SafeArrayGetLBound(
      variantRes.union1.struct1.union1.parray,
      1,
      lowerBounds.addr
    ))
    checkHRESULT(SafeArrayGetUBound(
      variantRes.union1.struct1.union1.parray,
      1,
      upperBounds.addr
    ))

    result.setLen(upperBounds - lowerBounds + 1) # upperBounds is inclusive

    var p: pointer
    checkHRESULT(SafeArrayAccessData(
      variantRes.union1.struct1.union1.parray,
      p.addr
    ))
    copyMem(result[0].addr, p, result.len)
    checkHRESULT(SafeArrayUnaccessData(
      variantRes.union1.struct1.union1.parray
    ))
  finally:
    VariantClear(variantRes.addr)
