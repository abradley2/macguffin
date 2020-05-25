module PageResult exposing (resolveEffects, withEffect)

import ComponentResult
    exposing
        ( ComponentResult
        , escape
        , mapModel
        , withCmds
        , withExternalMsg
        , withModel
        , justError
        )


withEffect :
    effect -- effect to add to result
    -> ComponentResult model msg extMsg err -- current result
    -> ComponentResult ( model, effect ) msg extMsg err -- result with effect
withEffect eff =
    mapModel (\m -> ( m, eff ))


resolveEffects :
    (effect -> Cmd msg) -- performEffect
    -> ComponentResult ( model, effect ) msg extMsg error -- result with effect
    -> ComponentResult model msg extMsg error -- normalized result
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

                    Result.Err e ->
                        justError e
           )
