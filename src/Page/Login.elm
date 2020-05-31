module Page.Login exposing (Model, Msg(..), init, update, view)

import ComponentResult exposing (ComponentResult, withCmds, withExternalMsg, withModel)
import Data.Http exposing (httpErrToString)
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Http
import Json.Decode as D
import Json.Encode as E
import PageResult exposing (resolveEffects, withEffect)
import Url exposing (Url)
import Url.Builder exposing (crossOrigin, string)
import Url.Parser exposing (parse, query)
import Url.Parser.Query as Q


ghUrl : Flags -> String
ghUrl flags =
    crossOrigin
        "https://github.com"
        [ "login", "oauth", "authorize" ]
        [ string "client_id" "c03a348dc743e9a1edc6"
        , string "redirect_uri" flags.pageUrl
        ]


type Effect
    = Eff (Cmd Msg)
    | EffBatch (List Effect)
    | EffFetchToken Flags String


performEffect : Effect -> Cmd Msg
performEffect effect =
    case effect of
        Eff cmd ->
            cmd

        EffBatch effList ->
            effList |> List.map performEffect |> Cmd.batch

        EffFetchToken flags code ->
            getToken flags code


type alias Model =
    {}


type Msg
    = FetchedToken (Result Http.Error Token)


type alias PageResult =
    ComponentResult ( Model, Effect ) Msg ExtMsg Never


getToken : Flags -> String -> Cmd Msg
getToken flags code =
    Http.request
        { body =
            Http.jsonBody
                (E.object [ ( "code", E.string code ) ])
        , expect =
            Http.expectJson
                FetchedToken
                (D.map Token (D.field "access_token" D.string))
        , headers = []
        , method = "POST"
        , timeout = Just 5000
        , tracker = Nothing
        , url = crossOrigin flags.apiUrl [ "token" ] []
        }


queryParser : Q.Parser (Maybe String)
queryParser =
    Q.map (\v -> v) (Q.string "code")



init flags url =
    init_ flags url
        |> resolveEffects performEffect


init_ : Flags -> Url -> PageResult
init_ flags url =
    let
        login =
            parse (query queryParser) url
                |> Maybe.andThen (\v -> v)
                |> Maybe.map (EffFetchToken flags)
                |> Maybe.withDefault (Eff Cmd.none)
    in
    withModel {}
        |> withEffect login


update msg model =
    update_ msg model |> resolveEffects performEffect


update_ : Msg -> Model -> PageResult
update_ msg model =
    case msg of
        FetchedToken (Result.Err httpErr) ->
            withModel model
                |> withExternalMsg
                    (LogError
                        { logMessage = Just <| httpErrToString httpErr
                        , userMessage = Just <| "Login Failed :("
                        }
                    )
                |> withEffect (Eff Cmd.none)

        FetchedToken (Result.Ok tokenResponse) ->
            withModel model
                |> withExternalMsg
                    (Batch
                        [ SetToken tokenResponse
                        , ReplaceUrl "/agent-dashboard"
                        ]
                    )
                |> withEffect (Eff Cmd.none)


view : Flags -> Model -> H.Html Msg
view flags model =
    H.div
        [ A.class "login-container"
        , A.attribute "data-test" "login-page"
        ]
        [ H.div
            []
            []
        , H.div
            []
            []
        , H.div
            []
            [ H.a
                [ A.href (ghUrl flags)
                , A.class "button"
                ]
                [ H.text "LOGIN" ]
            ]
        ]
