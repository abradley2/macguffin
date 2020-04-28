port module Main exposing (..)

import Browser exposing (Document, UrlRequest(..), application)
import Browser.Navigation exposing (Key, load, pushUrl, replaceUrl)
import ComponentResult exposing (ComponentResult, applyExternalMsg, mapModel, mapMsg, resolve, withCmds, withExternalMsg, withModel)
import ExtMsg exposing (ExtMsg(..), Log, Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import Json.Encode as E
import Page.Dashboard as DashboardPage
import Page.Login as LoginPage
import Url exposing (Url)
import Url.Builder exposing (crossOrigin)
import Url.Parser exposing ((</>), map, oneOf, parse, s, string, top)


port storeToken : String -> Cmd msg


type Page
    = NotFound
    | LoginPage LoginPage.Model
    | DashboardPage DashboardPage.Model


type Route
    = LoginRoute
    | DashboardRoute


urlToRoute : Url -> Maybe Route
urlToRoute url =
    let
        urlParser =
            oneOf
                [ map LoginRoute top
                , map DashboardRoute (s "agent-dashboard")
                ]
    in
    parse urlParser url


modelWithRoute : Model -> Maybe Route -> ( Model, Cmd Msg )
modelWithRoute model route =
    case route of
        Just LoginRoute ->
            LoginPage.init model.flags model.url
                |> mapModel (\login -> { model | page = LoginPage login })
                |> mapMsg (LoginMsg >> PageMsg)
                |> applyExternalMsg (handleExternalMsg model.key model.flags)
                |> resolve

        Just DashboardRoute ->
            DashboardPage.init model.flags
                |> mapModel (\dashboard -> { model | page = DashboardPage dashboard })
                |> mapMsg (DashboardMsg >> PageMsg)
                |> resolve

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


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


handleExternalMsg : Key -> Flags -> ExtMsg -> ComponentResult Model Msg a b -> ComponentResult Model Msg a b
handleExternalMsg key flags extMsg result =
    case extMsg of
        LogError err ->
            result
                |> mapModel
                    (\model ->
                        { model
                            | appErrors = err :: model.appErrors
                        }
                    )
                |> withCmds
                    [ case err.logMessage of
                        Just logMessage ->
                            logErrorMessage flags logMessage

                        Nothing ->
                            Cmd.none
                    ]

        SetToken token ->
            result
                |> mapModel
                    (\model ->
                        { model | token = Just token }
                    )
                |> withCmds
                    [ case token of
                        Token val ->
                            storeToken val
                    ]

        ReplaceUrl nextUrl ->
            result
                |> withCmds
                    [ replaceUrl key nextUrl
                    ]

        PushUrl nextUrl ->
            result
                |> withCmds
                    [ pushUrl key nextUrl
                    ]

        Batch extMsgList ->
            List.foldl
                (handleExternalMsg key flags)
                result
                extMsgList


type alias Model =
    { appErrors : List Log
    , key : Key
    , url : Url
    , token : Maybe Token
    , flags : Flags
    , appFailure : Bool
    , page : Page
    }


type PageMsg
    = LoginMsg LoginPage.Msg
    | DashboardMsg DashboardPage.Msg


type Msg
    = OnUrlRequest UrlRequest
    | OnUrlChange Url
    | DismissErrorMessages
    | ErrorLogged (Result Http.Error ())
    | PageMsg PageMsg


init : D.Value -> Url -> Key -> ( Model, Cmd Msg )
init flagsValue url key =
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
        , key = key
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


handleExtraneousPageMsg : Model -> ( Model, Cmd Msg )
handleExtraneousPageMsg model =
    withModel model
        |> withExternalMsg
            (LogError
                { userMessage = Nothing
                , logMessage = Just <| "Unhandled page msg on " ++ Url.toString model.url
                }
            )
        |> applyExternalMsg (handleExternalMsg model.key model.flags)
        |> resolve


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnUrlRequest (Internal url) ->
            ( model, pushUrl model.key (Url.toString url) )

        OnUrlRequest (External url) ->
            ( model, load url )

        OnUrlChange url ->
            modelWithRoute { model | url = url } (urlToRoute url)

        DismissErrorMessages ->
            ( { model | appErrors = [] }, Cmd.none )

        ErrorLogged _ ->
            -- there's nothing to do here. If we logged the error ok.
            -- if it failed to log then we have an error logging an error...
            ( model, Cmd.none )

        PageMsg (LoginMsg loginMsg) ->
            case model.page of
                LoginPage loginPage ->
                    LoginPage.update loginMsg loginPage
                        |> mapMsg (LoginMsg >> PageMsg)
                        |> mapModel (\page -> { model | page = LoginPage page })
                        |> applyExternalMsg (handleExternalMsg model.key model.flags)
                        |> resolve

                -- we are no longer on the Login page
                _ ->
                    handleExtraneousPageMsg model

        PageMsg (DashboardMsg dashboardMsg) ->
            case model.page of
                DashboardPage dashboardPage ->
                    DashboardPage.update model.flags dashboardMsg dashboardPage
                        |> mapMsg (DashboardMsg >> PageMsg)
                        |> mapModel (\page -> { model | page = DashboardPage page })
                        |> resolve

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
                , case model.page of
                    LoginPage loginPage ->
                        LoginPage.view model.flags loginPage
                            |> H.map (LoginMsg >> PageMsg)

                    DashboardPage dashboardPage ->
                        DashboardPage.view model.flags dashboardPage
                            |> H.map (DashboardMsg >> PageMsg)

                    NotFound ->
                        H.h3 [] [ H.text "Not found" ]
                ]
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
subscriptions model =
    Sub.none


main : Program D.Value Model Msg
main =
    application
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
