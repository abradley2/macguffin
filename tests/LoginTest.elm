module LoginTest exposing (..)

import Expect exposing (..)
import ExtMsg exposing (Token(..))
import Http
import Json.Encode as E
import Main
import Page.Login as LoginPage
import Test exposing (..)
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)


flagsJson : E.Value
flagsJson =
    E.object
        [ ( "apiUrl", E.string "api-url" )
        , ( "pageUrl", E.string "page-url" )
        , ( "token", E.string "test-token" )
        ]


withLoginModel : Url -> Main.Model
withLoginModel url =
    Main.init
        flagsJson
        url
        Main.FakeKey
        |> Tuple.first


withFetchedToken : Main.Model -> ( Main.Model, Main.Effect )
withFetchedToken prevModel =
    Main.update
        (Result.Ok (Token "some-token")
            |> LoginPage.FetchedToken
            |> Main.LoginMsg
            |> Main.PageMsg
        )
        prevModel


mLoginUrl : Maybe Url
mLoginUrl =
    crossOrigin "http://localhost:1234" [] []
        |> Url.fromString


suite : Test
suite =
    case mLoginUrl of
        Just url ->
            suite_ url

        Nothing ->
            test "LoginTest setup failed" (\_ -> Expect.fail "Could not parse url")


suite_ : Url -> Test
suite_ url =
    describe "Login Test"
        [ test "Should cause a redirect to dashboard when we get a token" <|
            \_ ->
                url
                    |> withLoginModel
                    |> withFetchedToken
                    |> Tuple.second
                    |> findEffect
                        (\eff ->
                            case eff of
                                Main.EffReplaceUrl Main.FakeKey "/agent-dashboard" ->
                                    True

                                _ ->
                                    False
                        )
                    |> Expect.equal True
        , test "Should log an error when we fail to get a token" <|
            \_ ->
                url
                    |> withLoginModel
                    |> (\model ->
                            Main.update
                                (Http.NetworkError
                                    |> Result.Err
                                    |> LoginPage.FetchedToken
                                    |> Main.LoginMsg
                                    |> Main.PageMsg
                                )
                                model
                       )
                    |> Tuple.second
                    |> findEffect (\eff ->
                        case eff of
                            Main.EffLogErrorMessage _ _ ->
                                True
                            _ ->
                                False
                    )
                    |> Expect.equal True
        ]


findEffect : (Main.Effect -> Bool) -> Main.Effect -> Bool
findEffect filter eff =
    case eff of
        Main.EffBatch effList ->
            List.foldl
                (\curEff found ->
                    if found then
                        True

                    else
                        findEffect filter curEff
                )
                False
                effList

        _ ->
            filter eff
