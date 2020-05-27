module Dashboard.PageTest exposing (..)

import Expect
import Json.Encode as E
import Main
import Page.Dashboard as DashboardPage
import Page.Dashboard.UserProfile exposing (UserProfile)
import RemoteData exposing (RemoteData(..))
import Test exposing (..)
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)


flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


dashboardUrl =
    crossOrigin "http://localhost:1234" [ "agent-dashboard" ] []
        |> Url.fromString


withDashboardPage : Url -> Main.Model
withDashboardPage url =
    Main.init
        flagsJson
        url
        Main.FakeKey
        |> Tuple.first


userProfile : UserProfile
userProfile =
    { publicAgentID = Nothing
    , strength = 1
    , constitution = 2
    , dexterity = 3
    , intelligence = 4
    , wisdom = 5
    , charisma = 6
    }


suite_ : Url -> Test
suite_ url =
    describe "Dashboard page test"
        [ test "Our main file properly handles dashboard page updates"
            (\_ ->
                withDashboardPage url
                    |> Main.update
                        (Result.Ok userProfile
                            |> DashboardPage.FetchedUserProfile
                            |> Main.DashboardMsg
                            |> Main.PageMsg
                        )
                    |> Tuple.first
                    |> (\m ->
                            case m.page of
                                Main.DashboardPage page ->
                                    case page.userProfile of
                                        Success _ ->
                                            Expect.pass

                                        _ ->
                                            Expect.fail "Dashboard page did not update to show user profile"

                                _ ->
                                    Expect.fail "Dashboard page not rendered"
                       )
            )
        ]


suite : Test
suite =
    Maybe.map
        suite_
        dashboardUrl
        |> Maybe.withDefault
            (test "Dashboard page test setup" <|
                \_ -> Expect.fail "Invalid url"
            )
