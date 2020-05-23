module MainTest exposing (..)

import Expect
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Json.Encode as E
import Main exposing (..)
import Test exposing (..)
import Url.Builder exposing (crossOrigin)
import Url

suite : Test
suite =
    describe "Main Test"
        [ appInitialization
        ]


flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


appInitialization : Test
appInitialization =
    describe "Application initialization"
        [ test "pass" <|
            \_ ->
                let
                    mUrl = crossOrigin "http://localhost:1234" [] [] |> Url.fromString
                in
                case mUrl of
                    Just url ->
                        init flagsJson url FakeKey
                            |> (\(m, _) ->
                                case m.page of
                                    Main.LoginPage _ ->
                                        Expect.pass
                                    _ ->
                                        Expect.fail "the app initializing to the root should show the login page"
                            )
                    _ ->
                        Expect.fail "Invalid url"

        ]
