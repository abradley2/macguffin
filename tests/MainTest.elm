module MainTest exposing (..)

import Expect
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Json.Encode as E
import Main exposing (..)
import Test exposing (..)
import Url
import Url.Builder exposing (crossOrigin)


rootUrl =
    crossOrigin "http://localhost:1234" [] []
        |> Url.fromString

suite : Test
suite =
    describe "Main Test"
        [ withUrl rootUrl appInitialization
        ]


flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


withUrl : Maybe Url.Url -> (Url.Url -> Test) -> Test
withUrl mUrl t =
    case mUrl of
        Just url ->
            t url

        Nothing ->
            test "Setup failed" <|
                \_ -> Expect.fail "Test setup failed: could not build url"


appInitialization : Url.Url -> Test
appInitialization url =
    describe "Application initialization"
        [ test "pass" <|
            \_ ->
                init flagsJson url FakeKey
                    |> (\( m, _ ) ->
                            case m.page of
                                Main.LoginPage _ ->
                                    Expect.pass

                                _ ->
                                    Expect.fail "the app initializing to the root should show the login page"
                       )
        ]
