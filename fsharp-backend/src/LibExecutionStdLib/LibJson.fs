module LibExecutionStdLib.LibJson

open System.Threading.Tasks
open System.Numerics
open FSharp.Control.Tasks

open LibExecution.RuntimeTypes
open Prelude

module Errors = LibExecution.Errors
module DvalRepr = LibExecution.DvalRepr

let fn = FQFnName.stdlibFnName

let err (str : string) = Ply(Dval.errStr str)

let incorrectArgs = LibExecution.Errors.incorrectArgs

let varErr = TVariable "err"
let varA = TVariable "a"
let varB = TVariable "b"

let fns : List<BuiltInFn> =
  [ { name = fn "JSON" "read" 0
      parameters = [ Param.make "json" TStr "" ]
      returnType = varA
      description =
        "Parses a json string and returns its value. HTTPClient functions, and our request handler, automatically parse JSON into the `body` and `jsonbody` fields, so you probably won't need this. However, if you need to consume bad JSON, you can use string functions to fix the JSON and then use this function to parse it."
      fn =
        (function
        | _, [ DStr json ] ->
          (try
            json |> DvalRepr.ofUnknownJsonV0 |> Ply
           with
           | _ -> Ply DNull)
        | _ -> incorrectArgs ())
      sqlSpec = NotYetImplementedTODO
      previewable = Pure
      deprecated = ReplacedBy(fn "JSON" "read" 1) }
    { name = fn "JSON" "read" 1
      parameters = [ Param.make "json" TStr "" ]
      returnType = varA
      description =
        "Parses a json string and returns its value. HTTPClient functions, and our request handler, automatically parse JSON into the `body` and `jsonbody` fields, so you probably won't need this. However, if you need to consume bad JSON, you can use string functions to fix the JSON and then use this function to parse it."
      fn =
        (function
        | _, [ DStr json ] ->
          match DvalRepr.ofUnknownJsonV1 json with
          | Ok dv -> Ply dv
          | Error msg -> Ply(DError(SourceNone, msg))
        | _ -> incorrectArgs ())
      sqlSpec = NotYetImplementedTODO
      previewable = Pure
      deprecated = ReplacedBy(fn "JSON" "parse" 0) }
    { name = fn "JSON" "parse" 0
      parameters = [ Param.make "json" TStr "" ]
      returnType = varA
      description =
        "Parses a json string and returns its value. HTTPClient functions, and our request handler, automatically parse JSON into the `body` and `jsonbody` fields, so you probably won't need this. However, if you need to consume bad JSON, you can use string functions to fix the JSON and then use this function to parse it."
      fn =
        (function
        | _, [ DStr json ] ->
          match DvalRepr.ofUnknownJsonV1 json with
          | Ok dv -> Ply dv
          | Error msg -> Ply(DError(SourceNone, msg))
        | _ -> incorrectArgs ())
      sqlSpec = NotYetImplementedTODO
      previewable = Pure
      deprecated = ReplacedBy(fn "JSON" "parse" 1) }
    { name = fn "JSON" "parse" 1
      parameters = [ Param.make "json" TStr "" ]
      returnType = TResult(varA, varErr)
      description =
        "Parses a json string and returns its value. HTTPClient functions, and our request handler, automatically parse JSON into the `body` and `jsonbody` fields, so you probably won't need this. However, if you need to consume bad JSON, you can use string functions to fix the JSON and then use this function to parse it."
      fn =
        (function
        | _, [ DStr json ] ->
          json |> DvalRepr.ofUnknownJsonV1 |> Result.mapError DStr |> DResult |> Ply
        | _ -> incorrectArgs ())
      sqlSpec = NotYetImplementedTODO
      previewable = Pure
      deprecated = NotDeprecated } ]