@ppx.deriving(show({with_path: false}))
type rec t =
  | TInt
  | TFloat
  | TBool
  | TNull
  | TStr
  | TChar
  | TList(t)
  | TTuple(t, t, list<t>)
  | TObj //TDict(t)
  | TIncomplete
  | TError
  | THttpResponse(t)
  | TDB(t)
  | TDate
  | TPassword
  | TUuid
  | TOption
  | TErrorRail
  | TUserType(string, int)
  | TBytes
  | TResult //(t, t)
  | TAny //TVariable(string)
  | TBlock //TFn of List<DType> * DType
  | TDbList(t)
// | TRecord of List<string * DType>

let rec tipe2str = (t: t): string =>
  switch t {
  | TAny => "Any"
  | TInt => "Int"
  | TFloat => "Float"
  | TBool => "Bool"
  | TChar => "Char"
  | TNull => "Null"
  | TStr => "String"
  | TList(_) => "List"
  | TTuple(_, _, _) => "Tuple"
  | TObj => "Dict"
  | TBlock => "Block"
  | TIncomplete => "Incomplete"
  | TError => "Error"
  | THttpResponse(_) => "Response"
  | TDB(_) => "Datastore"
  | TDate => "Date"
  | TOption => "Option"
  | TPassword => "Password"
  | TUuid => "UUID"
  | TErrorRail => "ErrorRail"
  | TResult => "Result"
  | TDbList(a) => "[" ++ (tipe2str(a) ++ "]")
  | TUserType(name, _) => name
  | TBytes => "Bytes"
  }

let rec decode = (j): t => {
  open Json_decode_extended
  let d = decode
  let dv0 = variant0
  let dv1 = variant1
  let dv2 = variant2
  let dv3 = variant3
  variants(
    list{
      ("TInt", dv0(TInt)),
      ("TAny", dv0(TAny)),
      ("TFloat", dv0(TFloat)),
      ("TBool", dv0(TBool)),
      ("TNull", dv0(TNull)),
      ("TStr", dv0(TStr)),
      ("TList", dv1(t => TList(t), d)),
      ("TDbList", dv1(t => TDbList(t), d)),
      ("TTuple", dv3((first, second, theRest) => TTuple(first, second, theRest), d, d, list(d))),
      ("TDict", dv1(_ => TObj, d)),
      ("TIncomplete", dv0(TIncomplete)),
      ("TError", dv0(TError)),
      ("THttpResponse", dv1(t1 => THttpResponse(t1), d)),
      ("TDB", dv1(t1 => TDB(t1), d)),
      ("TDate", dv0(TDate)),
      ("TChar", dv0(TChar)),
      ("TPassword", dv0(TPassword)),
      ("TUuid", dv0(TUuid)),
      ("TOption", dv1(_ => TOption, d)),
      ("TErrorRail", dv0(TErrorRail)),
      ("TBytes", dv0(TBytes)),
      ("TResult", dv2((_t1, _t2) => TResult, d, d)),
      ("TVariable", dv1(_ => TAny, string)),
      ("TFn", dv2((_, _) => TBlock, list(d), d)),
      ("TRecord", dv1(_ => TAny, list(pair(string, d)))),
    },
    j,
  )
}

let rec encode = (t: t): Js.Json.t => {
  open Json_encode_extended
  let ev = variant
  switch t {
  | TInt => ev("TInt", list{})
  | TStr => ev("TStr", list{})
  | TChar => ev("TChar", list{})
  | TBool => ev("TBool", list{})
  | TFloat => ev("TFloat", list{})
  | TObj => ev("TObj", list{})
  | TList(t1) => ev("TList", list{encode(t1)})
  | TTuple(first, second, theRest) =>
    ev("TTuple", list{encode(first), encode(second), list(encode, theRest)})
  | TAny => ev("TAny", list{})
  | TNull => ev("TNull", list{})
  | TBlock => ev("TBlock", list{})
  | TIncomplete => ev("TIncomplete", list{})
  | TError => ev("TError", list{})
  | THttpResponse(t1) => ev("THttpResponse", list{encode(t1)})
  | TDB(t1) => ev("TDB", list{encode(t1)})
  | TDate => ev("TDate", list{})
  | TDbList(a) => ev("TDbList", list{encode(a)})
  | TPassword => ev("TPassword", list{})
  | TUuid => ev("TUuid", list{})
  | TOption => ev("TOption", list{})
  | TErrorRail => ev("TErrorRail", list{})
  | TResult => ev("TResult", list{})
  | TUserType(name, version) => ev("TUserType", list{string(name), int(version)})
  | TBytes => ev("TBytes", list{})
  }
}
