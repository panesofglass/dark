open Prelude
include Types.FunctionExecutionT

let withinTLID tlid t =
  List.filterMap t ~f:(fun (tlid_, id) ->
      if tlid_ = tlid then Some id else None)


let recordExecutionEnd tlid id t = List.filter t ~f:(( <> ) (tlid, id))

let recordExecutionStart tlid id t =
  t |> recordExecutionEnd tlid id |> ( @ ) [(tlid, id)]


let update (msg : msg) (t : t) : t * msg CrossComponentMsg.t =
  match msg with
  | ExecuteFunction (p, moveToCaller) ->
      let selectionTarget : tlidSelectTarget =
        (* Note that the intent here is to make the live value visible, which
         * is a side-effect of placing the caret right after the function name
         * in the handler where the function is being called.  We're relying on
         * the length of the function name representing the offset into the
         * tokenized function call node corresponding to this location. Eg:
         * foo|v1 a b *)
        STCaret {astRef = ARFnCall p.callerID; offset = String.length p.fnName}
      in
      let select =
        if moveToCaller = MoveToCaller
        then CrossComponentMsg.CCMSelect (p.tlid, selectionTarget)
        else CCMNothing
      in
      ( recordExecutionStart p.tlid p.callerID t
      , CCMMany
          [ CCMMakeAPICall
              { endpoint = "/execute_function"
              ; body = Encoders.executeFunctionAPIParams p
              ; callback =
                  (fun result ->
                    APICallback
                      ( p
                      , match result with
                        | Ok js ->
                            Ok (Decoders.executeFunctionAPIResult js)
                        | Error v ->
                            Error v )) }
          ; select ] )
  | APICallback (p, Ok (dval, hash, hashVersion, tlids, unlockedDBs)) ->
      let traces =
        List.map
          ~f:(fun tlid -> (TLID.toString tlid, [(p.traceID, Error NoneYet)]))
          tlids
      in
      ( recordExecutionEnd p.tlid p.callerID t
      , CCMMany
          [ CrossComponentMsg.CCMTraceUpdateFunctionResult
              { tlid = p.tlid
              ; traceID = p.traceID
              ; callerID = p.callerID
              ; fnName = p.fnName
              ; hash
              ; hashVersion
              ; dval }
          ; CCMTraceOverrideTraces (StrDict.fromList traces)
          ; CCMUnlockedDBsSetUnlocked unlockedDBs ] )
  | APICallback (p, Error err) ->
      ( recordExecutionEnd p.tlid p.callerID t
      , CCMHandleAPIError
          { context = "ExecuteFunction"
          ; importance = ImportantError
          ; requestParams = Some (Encoders.executeFunctionAPIParams p)
          ; reload = false
          ; originalError = err } )