module PageInitTest exposing (..)

import Expect exposing (Expectation)
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Html.Attributes as A
import Json.Encode as E
import Main exposing (..)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as Selector exposing (Selector)
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)


rootUrl =
    crossOrigin "http://localhost:1234" [] []
        |> Url.fromString


dashboardUrl =
    crossOrigin "http://localhost:1234" [ "agent-dashboard" ] []
        |> Url.fromString


editorPageUrl =
    crossOrigin "http://localhost:1234" [ "editor" ] []
        |> Url.fromString


type alias Urls =
    { rootUrl : Url
    , dashboardUrl : Url
    , editorPageUrl : Url
    }


suite_ : Urls -> Test
suite_ urls =
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
            urls.rootUrl
        , pageInitializationTest
            "Initializes dashboard page"
            (\page ->
                case page of
                    Main.DashboardPage _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Did not load agent dashboard page"
            )
            urls.dashboardUrl
        , pageInitializationTest
            "Initializes editor page"
            (\page ->
                case page of
                    Main.EditorPage _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Did not load editor page"
            )
            urls.editorPageUrl
        , pageViewInitializationTest
            "Initializes the editor page"
            (Selector.attribute <| A.attribute "data-test" "editor-page")
            urls.editorPageUrl
        , pageViewInitializationTest
            "Initializes the login page"
            (Selector.attribute <| A.attribute "data-test" "login-page")
            urls.rootUrl
        , pageViewInitializationTest
            "initializes the dashboard page"
            (Selector.attribute <| A.attribute "data-test" "dashboard-page")
            urls.dashboardUrl
        ]


suite : Test
suite =
    Maybe.map3
        Urls
        rootUrl
        dashboardUrl
        editorPageUrl
        |> Maybe.map suite_
        |> Maybe.withDefault
            (test "Page init test setup" <|
                \_ -> Expect.fail "Test setup failed, did not build all urls"
            )


flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


pageViewInitializationTest : String -> Selector -> Url -> Test
pageViewInitializationTest title selector url =
    test title <|
        \_ ->
            init flagsJson url FakeKey
                |> Tuple.first
                |> Main.pageBodyView
                |> Query.fromHtml
                |> Query.findAll [ selector ]
                |> Query.count (Expect.equal 1)


pageInitializationTest : String -> (Page -> Expectation) -> Url -> Test
pageInitializationTest title expect url =
    test title <|
        \_ ->
            init flagsJson url FakeKey
                |> (\( m, _ ) ->
                        expect m.page
                   )
