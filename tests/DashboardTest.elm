module DashboardTest exposing (..)

import ComponentResult exposing (applyExternalMsg, escape, mapError, mapModel, mapMsg, resolve)
import Expect exposing (Expectation)
import ExtMsg exposing (Token(..), hasRedirect)
import Flags exposing (Flags)
import Fuzz exposing (Fuzzer, int, list, string)
import Html.Attributes as A
import Http
import Page.Dashboard as DashboardPage
import RemoteData exposing (RemoteData(..))
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


flags : Flags
flags =
    { apiUrl = "apiUrl"
    , pageUrl = "pageUrl"
    , token = Nothing
    }


getModel =
    applyExternalMsg (\_ result -> result)
        >> resolve
        >> Tuple.first


getExtMsg =
    escape >> Result.toMaybe >> Maybe.andThen (\( _, _, extMsg ) -> extMsg)


token =
    Just (Token "token")


suite : Test
suite =
    describe "dashboard page"
        [ test "The initial state of the page should be loading"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> (\model -> Expect.equal model.macguffinItems Loading)
            )
        , test "Should be able to open the profile modal"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> DashboardPage.update flags (DashboardPage.ToggleModal DashboardPage.Profile)
                    |> getModel
                    |> DashboardPage.view token flags
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute <| A.attribute "data-test" "profile-modal" ]
            )
        , test "Should be able to open the containment sites modal"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> DashboardPage.update flags (DashboardPage.ToggleModal DashboardPage.ContainmentSites)
                    |> getModel
                    |> DashboardPage.view token flags
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute <| A.attribute "data-test" "containment-sites-modal" ]
            )
        , test "Should be able to open the protocols modal"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> DashboardPage.update flags (DashboardPage.ToggleModal DashboardPage.Protocols)
                    |> getModel
                    |> DashboardPage.view token flags
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute <| A.attribute "data-test" "protocols-modal" ]
            )
        , test "Should be able to close modals"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> DashboardPage.update flags (DashboardPage.ToggleModal DashboardPage.Protocols)
                    |> getModel
                    |> DashboardPage.update flags DashboardPage.CloseModal
                    |> getModel
                    |> DashboardPage.view token flags
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.attribute <| A.attribute "data-test" "protocols-modal" ]
                    |> Query.count (Expect.equal 0)
            )
        , test "Should redirect to login if agent profile 401's"
            (\_ ->
                DashboardPage.init token flags
                    |> getModel
                    |> DashboardPage.update
                        flags
                        (DashboardPage.FetchedUserProfile <| Result.Err (Http.BadStatus 401))
                    |> getExtMsg
                    |> Maybe.map
                        (\extMsg ->
                            if hasRedirect extMsg then
                                Expect.pass

                            else
                                Expect.fail "Extmsg didn't contain a redirect"
                        )
                    |> Maybe.withDefault (Expect.fail "No extMsg")
            )
        ]
