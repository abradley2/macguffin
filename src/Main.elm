port module Main exposing (..)

import Browser exposing (Document, UrlRequest(..), application)
import Browser.Navigation exposing (Key, load, pushUrl, replaceUrl)
import ComponentResult exposing (ComponentResult, applyExternalMsg, escape, mapModel, mapMsg, resolve, withCmds)
import ExtMsg exposing (ExtMsg(..), Log, Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import Json.Encode as E
import Page.Dashboard as DashboardPage
import Page.Editor as EditorPage
import Page.Login as LoginPage
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)
import Url.Parser exposing ((</>), map, oneOf, parse, s, string, top)


type AppKey
    = RealKey Key
    | FakeKey


type Effect
    = Eff (Cmd Msg)
    | EffBatch (List Effect)
    | EffReplaceUrl AppKey String
    | EffPushUrl AppKey String
    | EffLoadUrl String
    | EffLogErrorMessage Flags String
    | EffStoreToken String


performEffect : Effect -> Cmd Msg
performEffect eff =
    case eff of
        EffReplaceUrl (RealKey k) url ->
            replaceUrl k url

        EffReplaceUrl FakeKey _ ->
            Cmd.none

        EffPushUrl (RealKey k) url ->
            pushUrl k url

        EffPushUrl FakeKey _ ->
            Cmd.none

        EffLogErrorMessage flags msg ->
            logErrorMessage flags msg

        EffStoreToken token ->
            storeToken token

        EffLoadUrl url ->
            load url

        EffBatch effs ->
            effs
                |> List.map performEffect
                |> Cmd.batch

        Eff cmd ->
            cmd


port storeToken : String -> Cmd msg


type Page
    = NotFound
    | LoginPage LoginPage.Model
    | DashboardPage DashboardPage.Model
    | EditorPage EditorPage.Model


type Route
    = LoginRoute
    | DashboardRoute
    | EditorRoute


urlToRoute : Url -> Maybe Route
urlToRoute url =
    let
        urlParser =
            oneOf
                [ map LoginRoute top
                , map DashboardRoute (s "agent-dashboard")
                , map EditorRoute (s "editor")
                ]
    in
    parse urlParser url


modelWithRoute : Model -> Maybe Route -> ( Model, Effect )
modelWithRoute model route =
    case route of
        Just LoginRoute ->
            LoginPage.init model.flags model.url
                |> mapModel (\login -> { model | page = LoginPage login })
                |> mapMsg (LoginMsg >> PageMsg)
                |> handleExternalMsg model.appKey model.flags

        Just DashboardRoute ->
            DashboardPage.init model.token model.flags
                |> mapModel (\dashboard -> { model | page = DashboardPage dashboard })
                |> mapMsg (DashboardMsg >> PageMsg)
                |> handleExternalMsg model.appKey model.flags

        Just EditorRoute ->
            EditorPage.init
                |> mapModel (\editor -> { model | page = EditorPage editor })
                |> mapMsg (EditorPageMsg >> PageMsg)
                |> handleExternalMsg model.appKey model.flags

        Nothing ->
            ( { model | page = NotFound }, Eff Cmd.none )


logErrorMessage : Flags -> String -> Cmd Msg
logErrorMessage flags logMessage =
    Http.request
        { body =
            Http.jsonBody
                (E.object
                    [ ( "logMessage", E.string logMessage )
                    ]
                )
        , expect = Http.expectWhatever ErrorLogged
        , headers = []
        , method = "POST"
        , timeout = Nothing
        , tracker = Nothing
        , url = crossOrigin flags.apiUrl [ "log" ] []
        }


handleExternalMsg :
    AppKey
    -> Flags
    -> ComponentResult Model Msg ExtMsg Never
    -> ( Model, Effect )
handleExternalMsg appKey flags result =
    case escape result of
        Result.Ok ( model, cmd, mExtMsg ) ->
            case mExtMsg of
                Just extMsg ->
                    handleExternalMsg_ appKey flags ( model, Eff cmd ) extMsg

                Nothing ->
                    ( model, Eff cmd )

        Result.Err never ->
            handleExternalMsg appKey flags result


handleExternalMsg_ :
    AppKey
    -> Flags
    -> ( Model, Effect )
    -> ExtMsg
    -> ( Model, Effect )
handleExternalMsg_ appKey flags ( model, eff ) extMsg =
    case extMsg of
        LogError err ->
            ( { model
                | appErrors = err :: model.appErrors
              }
            , case err.logMessage of
                Just logMessage ->
                    EffLogErrorMessage flags logMessage

                Nothing ->
                    Eff Cmd.none
            )

        SetToken token ->
            ( { model
                | token = Just token
              }
            , case token of
                Token val ->
                    EffStoreToken val
            )

        ReplaceUrl nextUrl ->
            ( model, EffReplaceUrl appKey nextUrl )

        PushUrl nextUrl ->
            ( model, EffPushUrl appKey nextUrl )

        Batch extMsgList ->
            List.foldl
                (\msg ( curModel, curEff ) ->
                    handleExternalMsg_ appKey flags ( curModel, curEff ) msg
                        |> Tuple.mapSecond (\e -> EffBatch [ e, curEff ])
                )
                ( model, eff )
                extMsgList


type alias Model =
    { appErrors : List Log
    , appKey : AppKey
    , url : Url
    , token : Maybe Token
    , flags : Flags
    , appFailure : Bool
    , page : Page
    }


type PageMsg
    = LoginMsg LoginPage.Msg
    | DashboardMsg DashboardPage.Msg
    | EditorPageMsg EditorPage.Msg


type Msg
    = OnUrlRequest UrlRequest
    | OnUrlChange Url
    | DismissErrorMessages
    | ErrorLogged (Result Http.Error ())
    | PageMsg PageMsg


init : D.Value -> Url -> AppKey -> ( Model, Effect )
init flagsValue url appKey =
    let
        decodedFlags =
            D.decodeValue
                (D.map3 Flags
                    (D.field "apiUrl" D.string)
                    (D.field "pageUrl" D.string)
                    (D.field "token" (D.nullable D.string))
                )
                flagsValue
    in
    modelWithRoute
        { appErrors = []
        , appKey = appKey
        , url = url
        , page = NotFound
        , token =
            Result.toMaybe decodedFlags
                |> Maybe.andThen .token
                |> Maybe.map (Token >> Just)
                |> Maybe.withDefault Nothing
        , flags =
            decodedFlags
                |> Result.withDefault
                    { apiUrl = ""
                    , pageUrl = ""
                    , token = Nothing
                    }
        , appFailure =
            decodedFlags
                |> Result.map (\_ -> False)
                |> Result.withDefault True
        }
        (urlToRoute url)


handleExtraneousPageMsg : Model -> ( Model, Effect )
handleExtraneousPageMsg model =
    let
        err =
            { userMessage = Nothing
            , logMessage = Just <| "Unhandled page msg on " ++ Url.toString model.url
            }
    in
    ( { model | appErrors = err :: model.appErrors }
    , EffLogErrorMessage model.flags ("Unhandled page msg on " ++ Url.toString model.url)
    )


update : Msg -> Model -> ( Model, Effect )
update msg model =
    case msg of
        OnUrlRequest (Internal url) ->
            ( model, EffPushUrl model.appKey (Url.toString url) )

        OnUrlRequest (External url) ->
            ( model, EffLoadUrl url )

        OnUrlChange url ->
            modelWithRoute { model | url = url } (urlToRoute url)

        DismissErrorMessages ->
            ( { model | appErrors = [] }, Eff Cmd.none )

        ErrorLogged _ ->
            -- there's nothing to do here. If we logged the error ok.
            -- if it failed to log then we have an error logging an error...
            ( model, Eff Cmd.none )

        PageMsg (LoginMsg loginMsg) ->
            case model.page of
                LoginPage loginPage ->
                    LoginPage.update loginMsg loginPage
                        |> mapMsg (LoginMsg >> PageMsg)
                        |> mapModel (\page -> { model | page = LoginPage page })
                        |> handleExternalMsg model.appKey model.flags

                -- we are no longer on the Login page
                _ ->
                    handleExtraneousPageMsg model

        PageMsg (DashboardMsg dashboardMsg) ->
            case model.page of
                DashboardPage dashboardPage ->
                    DashboardPage.update model.flags dashboardMsg dashboardPage
                        |> mapMsg (DashboardMsg >> PageMsg)
                        |> mapModel (\page -> { model | page = DashboardPage page })
                        |> handleExternalMsg model.appKey model.flags

                _ ->
                    handleExtraneousPageMsg model

        PageMsg (EditorPageMsg editorMsg) ->
            case model.page of
                EditorPage editorPage ->
                    EditorPage.update editorMsg editorPage
                        |> mapMsg (EditorPageMsg >> PageMsg)
                        |> mapModel (\editor -> { model | page = EditorPage editor })
                        |> handleExternalMsg model.appKey model.flags

                _ ->
                    handleExtraneousPageMsg model


view : Model -> Document Msg
view model =
    Document "Kewl elm app" <|
        if model.appFailure then
            [ H.div [] [ H.h3 [] [ H.text "Critical Failure" ] ] ]

        else
            [ H.div []
                [ H.div []
                    [ appErrorsView model.appErrors
                    ]
                , pageBodyView model
                ]
            ]


pageBodyView : Model -> H.Html Msg
pageBodyView model =
    H.div
        []
        [ case model.page of
            LoginPage loginPage ->
                LoginPage.view model.flags loginPage
                    |> H.map (LoginMsg >> PageMsg)

            DashboardPage dashboardPage ->
                DashboardPage.view model.token model.flags dashboardPage
                    |> H.map (DashboardMsg >> PageMsg)

            EditorPage editorPage ->
                EditorPage.view editorPage
                    |> H.map (EditorPageMsg >> PageMsg)

            NotFound ->
                H.h3 [] [ H.text "Not found" ]
        ]


appErrorsView : List Log -> H.Html Msg
appErrorsView errorLogs =
    H.div [ A.class "app-errors" ]
        (errorLogs
            |> List.map (.userMessage >> Maybe.withDefault "")
            |> List.filter ((/=) "")
            |> List.map
                (\msg ->
                    H.div
                        [ A.class "window app-errors__error animated swing"
                        ]
                        [ H.div [ A.class "window__header" ]
                            [ H.span
                                [ A.class "window__header__title" ]
                                [ H.text "OH FUCK OH SHIT" ]
                            , H.button
                                [ A.class "window__header__button"
                                , E.onClick DismissErrorMessages
                                ]
                                [ H.text "X" ]
                            ]
                        , H.div [ A.class "window__body" ]
                            [ H.text msg
                            ]
                        ]
                )
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program D.Value Model Msg
main =
    application
        { view = view
        , update =
            \msg model ->
                update msg model |> Tuple.mapSecond performEffect
        , init =
            \flags url key ->
                init flags url (RealKey key) |> Tuple.mapSecond performEffect
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
