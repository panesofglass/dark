module PropertyTests.All

// This aims to find test cases that violate certain properties that we expect.
// Desired properties include that OCaml Dark programs and functions work the
// same as F# ones, and things related to serialization and output.

open Expecto
open Expecto.ExpectoFsCheck

open Prelude

module PT = LibBackend.ProgramSerialization.ProgramTypes

let (.=.) left right : bool =
  (if left = right then
    true
   else
     printfn $"{left}\n = \n{right}"
     false)


// This allows us to control the values of the types that are generated. We can
// write our own generators, or filter existing ones. To add new type
// generators, add new static members
module DarkFsCheck =
  open FsCheck

  let ownerName : Gen<string> =
    gen {
      let otherOptions =
        Gen.elements (List.concat [ [ 'a' .. 'z' ]; [ '0' .. '9' ] ])

      let! length = Gen.choose (0, 20)
      let! head = Gen.elements [ 'a' .. 'z' ]
      let! tail = Gen.listOfLength length otherOptions
      return System.String(List.toArray (head :: tail))
    }

  let packageName = ownerName

  let modName : Gen<string> =
    gen {
      let otherOptions =
        Gen.elements (
          List.concat [ [ 'a' .. 'z' ]; [ '0' .. '9' ]; [ 'A' .. 'Z' ]; [ '_' ] ]
        )

      let! length = Gen.choose (0, 20)
      let! head = Gen.elements [ 'A' .. 'Z' ]
      let! tail = Gen.listOfLength length otherOptions
      return System.String(List.toArray (head :: tail))
    }

  let fnName : Gen<string> =
    gen {
      let otherOptions =
        Gen.elements (
          List.concat [ [ 'a' .. 'z' ]; [ '0' .. '9' ]; [ 'A' .. 'Z' ]; [ '_' ] ]
        )

      let! length = Gen.choose (0, 20)
      let! head = Gen.elements [ 'a' .. 'z' ]
      let! tail = Gen.listOfLength length otherOptions
      return System.String(List.toArray (head :: tail))
    }

  type MyGenerators =
    static member Expr() =
      Arb.Default.Derive()
      |> Arb.filter
           (function
           // characters are not yet supported in OCaml
           | PT.ECharacter _ -> false
           | _ -> true)

    static member Pattern() =
      Arb.Default.Derive()
      |> Arb.filter
           (function
           // characters are not yet supported in OCaml
           | PT.PCharacter _ -> false
           | _ -> true)

    static member SafeString() : Arbitrary<string> =
      Arb.Default.String() |> Arb.filter (fun (s : string) -> s <> null)

    static member FQFnType() =
      { new Arbitrary<PT.FQFnName.T>() with
          member x.Generator =
            gen {
              let! owner = ownerName
              let! package = packageName
              let! module_ = modName
              let! function_ = fnName
              let! NonNegativeInt version = Arb.generate<NonNegativeInt>

              return
                { owner = owner
                  package = package
                  module_ = module_
                  function_ = function_
                  version = version }
            } }

let config : FsCheckConfig =
  { FsCheckConfig.defaultConfig with
      maxTest = 10000
      arbitrary = [ typeof<DarkFsCheck.MyGenerators> ] }

let testProperty (name : string) (x : 'a) : Test =
  testPropertyWithConfig config name x


// Tests
// These tests are like this so they can be reused from LibBackend.Tests

let fqFnNameRoundtrip (a : PT.FQFnName.T) : bool =
  a.ToString() |> PT.FQFnName.parse .=. a

let ocamlInteropJsonRoundtrip (a : PT.Expr) : bool =
  a
  |> LibBackend.ProgramSerialization.OCamlInterop.Yojson.pt2ocamlExpr
  |> LibBackend.ProgramSerialization.OCamlInterop.Yojson.ocamlExpr2PT
  |> LibBackend.ProgramSerialization.OCamlInterop.Yojson.pt2ocamlExpr
  |> LibBackend.ProgramSerialization.OCamlInterop.Yojson.ocamlExpr2PT
  |> fun e ->
       (if e.testEqualIgnoringIDs a then
         true
        else
          printfn $"Expected\n{a}, got\n{e}"
          false)

let roundtrips =
  testList
    "roundtripping"
    [ testProperty "roundtripping FQFnName" fqFnNameRoundtrip
      testProperty "roundtripping OCamlInteropJson" ocamlInteropJsonRoundtrip ]

let tests = testList "propertyTests" [ roundtrips ]

[<EntryPoint>]
let main args =
  // LibBackend.ProgramSerialization.OCamlInterop.Binary.init ()
  runTestsWithCLIArgs [] args tests
