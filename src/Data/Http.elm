module Data.Http exposing (httpErrToString)

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
