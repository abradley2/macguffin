module ErrDisplayTest exposing (..)

import Expect
import ExtMsg exposing (..)
import Html as H
import Json.Encode as E
import Main
import Test exposing (..)
import Test.Html.Query as Query
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)
import Http exposing (Error(..))
import Data.Http exposing (httpErrToString)

flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


suite : Test
suite =
    describe "Error display" <|
        case crossOrigin "http://localhost:1234" [] [] |> Url.fromString of
            Just url ->
                suite_ url

            Nothing ->
                [ test "setup" <| \_ -> Expect.fail "Setup for ErrDisplayTest failed" ]


errMessage =
    httpErrToString NetworkError ++
    httpErrToString Timeout ++
    httpErrToString (BadBody "") ++
    httpErrToString (BadUrl "")


suite_ : Url -> List Test
suite_ url =
    [ test "Should display an error when a page LogError indicates" <|
        \_ ->
            Main.init flagsJson url Main.FakeKey
                |> (\( model, eff ) ->
                        Main.handleExternalMsg_ Main.FakeKey
                            model.flags
                            ( model, eff )
                            (LogError
                                { userMessage = Just errMessage
                                , logMessage = Just errMessage
                                }
                            )
                   )
                |> (Tuple.first >> .appErrors)
                |> Main.appErrorsView
                |> Query.fromHtml
                |> Query.contains [ H.text errMessage ]
    ]
