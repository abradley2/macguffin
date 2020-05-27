module PageInitTest exposing (..)


import Expect exposing (Expectation)
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


dashboardUrl =
    crossOrigin "http://localhost:1234" [ "agent-dashboard" ] []
        |> Url.fromString


suite : Test
suite =
    describe "Page initialization tests"
        [ pageInitializationTest
            "Initializes login page"
            (\page ->
                case page of
                    Main.LoginPage _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Did not load login page on rootUrl"
            )
            rootUrl
        , pageInitializationTest
            "Initializes dashboard page"
            (\page ->
                case page of
                    Main.DashboardPage _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Did not load agent dashboard page"
            )
            dashboardUrl
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


pageInitializationTest : String -> (Page -> Expectation) -> Maybe Url.Url -> Test
pageInitializationTest title expect mUrl =
    case mUrl of
        Just url ->
            test title <|
                \_ ->
                    init flagsJson url FakeKey
                        |> (\( m, _ ) ->
                                expect m.page
                           )

        Nothing ->
            test title <|
                \_ ->
                    Expect.fail "Test setup failed: could not build url"


