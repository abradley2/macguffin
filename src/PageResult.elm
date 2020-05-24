module PageResult exposing (..)

import ComponentResult exposing (ComponentResult, applyExternalMsg, mapModel, resolve)


applyExternalMsgWithEffect :
    (Cmd msg -> eff)
    -> (List eff -> eff)
    -> ComponentResult model msg extMsg Never
    ->
        (extMsg
         -> ComponentResult ( model, eff ) msg extMsg Never
         -> ComponentResult ( model, eff ) msg Never Never
        )
    -> ( model, eff )
applyExternalMsgWithEffect cmdToEff batchEff curResult handleExtMsg =
    curResult
        |> mapModel (\m -> ( m, cmdToEff Cmd.none ))
        |> applyExternalMsg handleExtMsg
        |> resolve
        |> (\( ( m, eff ), cmd ) ->
                ( m, batchEff [ eff, cmdToEff cmd ] )
           )

