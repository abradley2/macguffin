module Data.Http exposing (handlePossibleSessionTimeout, httpErrToString)

import ExtMsg exposing (ExtMsg(..))
import Http exposing (Error(..))


httpErrToString : Error -> String
httpErrToString error =
    case error of
        BadUrl text ->
            "Bad Url: " ++ text

        Timeout ->
            "Http Timeout"

        NetworkError ->
            "Network Error"

        BadStatus statusCode ->
            "Bad Http Status: " ++ String.fromInt statusCode

        BadBody message ->
            "Bad Http Payload: "
                ++ message


handlePossibleSessionTimeout : Error -> Maybe ExtMsg
handlePossibleSessionTimeout error =
    case error of
        BadStatus 401 ->
            Batch
                [ LogError
                    { userMessage = Just "Sorry, your login session expired. For security reasons please login again"
                    , logMessage = Nothing
                    }
                , PushUrl "/"
                ]
                |> Just

        _ ->
            Nothing
