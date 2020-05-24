module PageResult exposing (applyExternalMsgWithEffect, withEffect, resolveEffects)

import ComponentResult
    exposing
        ( ComponentResult
        , applyExternalMsg
        , escape
        , mapModel
        , resolve
        , withCmds
        , withExternalMsg
        , withModel
        )

withEffect :
    effect
    -> ComponentResult model msg extMsg err
    -> ComponentResult ( model, effect ) msg extMsg err
withEffect eff =
    mapModel (\m -> ( m, eff ))


applyExternalMsgWithEffect :
    (Cmd msg -> eff)
    -> (List eff -> eff)
    ->
        (extMsg
         -> model
         -> ( model, eff )
        )
    -> ComponentResult model msg extMsg Never
    -> ( model, eff )
applyExternalMsgWithEffect cmdToEff batchEff handleExtMsg curResult =
    curResult
        |> mapModel (\m -> ( m, cmdToEff Cmd.none ))
        |> applyExternalMsg
            (\extMsg result ->
                result
                    |> mapModel
                        (\( model, _ ) ->
                            handleExtMsg extMsg model
                        )
            )
        |> resolve
        |> (\( ( m, eff ), cmd ) ->
                ( m, batchEff [ eff, cmdToEff cmd ] )
           )


resolveEffects :
    (effect -> Cmd msg)
    -> ComponentResult ( model, effect ) msg extMsg error
    -> ComponentResult model msg extMsg error
resolveEffects performEffect effectfulResult =
    effectfulResult
        |> escape
        |> (\r ->
                case r of
                    Result.Ok ( ( model, effs ), msg, mExtMsg ) ->
                        let
                            res =
                                withModel model
                                    |> withCmds
                                        [ performEffect effs
                                        , msg
                                        ]
                        in
                        Maybe.map
                            (\extMsg ->
                                res |> withExternalMsg extMsg
                            )
                            mExtMsg
                            |> Maybe.withDefault res

                    Result.Err _ ->
                        effectfulResult
                            |> mapModel (\( m, _ ) -> m)
           )
