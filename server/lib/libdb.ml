open Core
open Lib
open Runtime
open Types.RuntimeT


let fns : Lib.shortfn list = [

  { n = "DB::insert"
  ; o = []
  ; p = [par "val" TObj; par "table" TDB]
  ; r = TObj
  ; d = "Insert `val` into `table`"
  ; f = InProcess
        (function
          | [DObj value; DDB db] ->
            let id = Db.with_postgres (fun _ -> Db.insert db value) in
            DObj (Map.set value "id" (DID id))
          | args -> fail args)
  ; pr = None
  ; ps = false
  ; i = false
  }
  ;

  { n = "DB::delete"
  ; o = []
  ; p = [par "value" TObj; par "table" TDB]
  ; r = TNull
  ; d = "Delete `value` from `table`"
  ; f = InProcess
        (function
          | [DObj vals; DDB db] ->
            Db.with_postgres (fun _ -> Db.delete db vals);
            DNull
          | args -> fail args)
  ; pr = None
  ; ps = false
  ; i = false
  }
  ;

  { n = "DB::update"
  ; o = []
  ; p = [par "value" TObj; par "table" TDB]
  ; r = TNull
  ; d = "Update `table` value which has the same ID as `value`"
  ; f = InProcess
        (function
          | [DObj vals; DDB db]  ->
            Db.with_postgres (fun _ -> Db.update db vals);
            DObj vals
          | args -> fail args)
  ; pr = None
  ; ps = false
  ; i = false
  }
  ;

  { n = "DB::fetchBy"
  ; o = []
  ; p = [par "value" TAny; par "field" TStr; par "table" TDB]
  ; r = TList
  ; d = "Fetch the value in `table` whose field `field` is `value`"
  ; f = InProcess
        (function
          | [value; DStr field; DDB db]  ->
            Db.with_postgres (fun _ -> Db.fetch_by db field value)
          | args -> fail args)
  ; pr = None
  ; ps = true
  ; i = false
  }
  ;

  { n = "DB::fetchOneBy"
  ; o = []
  ; p = [par "value" TAny; par "field" TStr; par "table" TDB]
  ; r = TAny
  ; d = "Fetch exactly one value in `table` whose field `field` is `value`"
  ; f = InProcess
        (function
          | [value; DStr field; DDB db]  ->
            let result = Db.with_postgres (fun _ -> Db.fetch_by db field value) in
            (match result with
             | DList (x :: xs) -> x
               (* TODO(ian): Maybe/Option *)
             | _ -> DNull)
          | args -> fail args)
  ; pr = None
  ; ps = true
  ; i = false
  }
  ;

  { n = "DB::fetchAll"
  ; o = []
  ; p = [par "table" TDB]
  ; r = TList
  ; d = "Fetch all the values in `table`"
  ; f = InProcess
        (function
          | [DDB db] ->
            Db.with_postgres (fun _ -> Db.fetch_all db)
          | args -> fail args)
  ; pr = None
  ; ps = true
  ; i = false
  }
  ;

  { n = "DB::keys"
  ; o = []
  ; p = [par "table" TDB]
  ; r = TList
  ; d = "Fetch all the keys in `table`"
  ; f = InProcess
        (function
          | [DDB db] ->
            Db.cols_for db
            |> List.map ~f:(fun (k,v) -> DStr k)
            |> DList
          | args -> fail args)
  ; pr = None
  ; ps = true
  ; i = false
  }
  ;

  { n = "DB::schema"
  ; o = []
  ; p = [par "table" TDB]
  ; r = TObj
  ; d = "Fetch all the values in `table`"
  ; f = InProcess
        (function
          | [DDB db] ->
            Db.cols_for db
            |> List.map ~f:(fun (k,v) -> (k, DStr (Dval.tipe_to_string v)))
            |> Dval.to_dobj
          | args -> fail args)
  ; pr = None
  ; ps = true
  ; i = false
  }
  ;

]

