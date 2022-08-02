module TraceData = {
  @ppx.deriving(show({with_path: false}))
  type rec t = {trace: AnalysisTypes.Trace.t}
  let decode = (j): t => {
    open Json_decode_extended
    {trace: field("trace", AnalysisTypes.Trace.decode, j)}
  }

  module Params = {
    @ppx.deriving(show({with_path: false}))
    type rec t = {tlid: TLID.t, traceID: TraceID.t}
    let encode = (params: t): Js.Json.t => {
      open Json_encode_extended
      object_(list{
        ("tlid", TLID.encode(params.tlid)),
        ("trace_id", TraceID.encode(params.traceID)),
      })
    }
  }
}

module AllTraces = {
  @ppx.deriving(show({with_path: false}))
  type rec t = {traces: list<(TLID.t, TraceID.t)>}

  let decode = (j): t => {
    open Json_decode_extended
    {
      traces: field("traces", list(pair(TLID.decode, TraceID.decode)), j),
    }
  }
  let encode = (traces: t): Js.Json.t => {
    open Json_encode_extended
    object_(list{("traces", list(pair(TLID.encode, TraceID.encode), traces.traces))})
  }
}
