module PageResult exposing (applyExternalMsgWithEffect)

import ComponentResult exposing (ComponentResult, applyExternalMsg, mapModel, resolve)


applyExternalMsgWithEffect :
    (Cmd msg -> eff)
    -> (List eff -> eff)
    ->
        (extMsg
         -> model
         -> (model, eff)
        )
    -> ComponentResult model msg extMsg Never
    -> ( model, eff )
applyExternalMsgWithEffect cmdToEff batchEff handleExtMsg curResult =
    curResult
        |> mapModel (\m -> ( m, cmdToEff Cmd.none ))
        |> applyExternalMsg (\extMsg result -> 
            result
                |> mapModel (\(model, _) ->
                    handleExtMsg extMsg model
                )
        )
        |> resolve
        |> (\( ( m, eff ), cmd ) ->
                ( m, batchEff [ eff, cmdToEff cmd ] )
           )

