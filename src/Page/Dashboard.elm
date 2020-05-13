module Page.Dashboard exposing (Modal(..), Model, Msg(..), init, update, view)

import ComponentResult exposing (ComponentResult, withCmds, withModel)
import ExtMsg exposing (Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)
import Url.Builder exposing (crossOrigin, string)
import View.Folder as Folder


type Modal
    = Profile
    | ContainmentSites
    | Protocols


type alias MacguffinItem =
    { name : String
    , thumbnail : Maybe String
    , id : String
    , creator : String
    , createdAt : String
    , approved : Bool
    }


decodeMacguffinItem : D.Decoder MacguffinItem
decodeMacguffinItem =
    D.map6 MacguffinItem
        (D.field "itemTitle" D.string)
        (D.maybe <| D.field "thumbnail" D.string)
        (D.field "_id" D.string)
        (D.field "creator" D.string)
        (D.field "createdAt" D.string)
        (D.field "approved" D.bool)


getItemsTracker : String
getItemsTracker =
    "getItemsTracker"


getMacguffinItems : Maybe Token -> Flags -> Cmd Msg
getMacguffinItems mToken flags =
    Http.request
        { body = Http.emptyBody
        , expect =
            Http.expectJson
                FetchedMacguffinItems
                (D.list decodeMacguffinItem)
        , headers =
            case mToken of
                Just (Token token) ->
                    [ Http.header "Authorization" token ]

                _ ->
                    []
        , method = "GET"
        , tracker = Just getItemsTracker
        , url = crossOrigin flags.apiUrl [ "articles" ] [ string "type" "macguffins" ]
        , timeout = Just 1000
        }


type alias Model =
    { macguffinItems : WebData (List MacguffinItem)
    , modal : Maybe Modal
    }


type Msg
    = FetchedMacguffinItems (Result Http.Error (List MacguffinItem))
    | ToggleModal Modal


type alias PageResult =
    ComponentResult Model Msg Never Never


init : Maybe Token -> Flags -> PageResult
init mToken flags =
    withModel
        { macguffinItems = Loading
        , modal = Nothing
        }
        |> withCmds
            [ getMacguffinItems mToken flags
            ]


update : Flags -> Msg -> Model -> PageResult
update flags msg model =
    case msg of
        FetchedMacguffinItems httpRes ->
            case httpRes of
                Result.Ok macguffinItems ->
                    withModel { model | macguffinItems = Success macguffinItems }

                Result.Err httpErr ->
                    withModel model

        ToggleModal nextModal ->
            withModel { model | modal = Just nextModal }


view : Maybe Token -> Flags -> Model -> H.Html Msg
view mToken flags model =
    H.div [ A.class "dashboard-page" ]
        [ H.div [ A.class "dashboard-modalcontainer" ]
            [ case model.modal of
                Just Profile ->
                    profileModalView mToken flags model

                Just Protocols ->
                    placholderModalView mToken flags model

                Just ContainmentSites ->
                    placholderModalView mToken flags model

                Nothing ->
                    H.text ""
            ]
        , H.div []
            [ H.input [ A.class "textinput", A.placeholder "Search Query" ] []
            , H.button [ A.class "button" ] [ H.text "GO" ]
            ]
        , mainWindowView flags model
        , H.div
            [ A.class "dashboard-folderrow" ]
            [ Folder.view [ E.onClick <| ToggleModal Profile ] "Agent Profile"
            , Folder.view [ E.onClick <| ToggleModal ContainmentSites ] "Containment Sites"
            , Folder.view [ E.onClick <| ToggleModal Protocols ] "Protocols"
            ]
        ]


mainWindowView : Flags -> Model -> H.Html Msg
mainWindowView flags model =
    H.div
        [ A.class "window dashboard-window" ]
        [ H.div
            [ A.class "window__header"
            ]
            []
        , H.div
            [ A.class "window__body"
            ]
            [ H.div
                [ A.class "body__textarea dashboard-textarea" ]
                [ H.p
                    [ A.class "dashboard-textarea__text" ]
                    [ H.text """
                        Agent, please review the following
                        instances of macguffins found in your
                        operating zone.
                            """
                    ]
                , H.div
                    []
                    [ H.div
                        [ A.class "dashboard-list" ]
                        [ H.button [ A.class "button dashboard-listbutton" ] [ H.text "MAC-070 Crystal Skull" ]
                        , H.button [ A.class "button dashboard-listbutton" ] [ H.text "MAC-854 Sith Dagger" ]
                        , H.button [ A.class "button dashboard-listbutton" ] [ H.text "MAC-091 Soul Stone" ]
                        ]
                    ]
                ]
            ]
        ]


profileModalView : Maybe Token -> Flags -> Model -> H.Html Msg
profileModalView mToken flags model =
    H.div
        [ A.attribute "data-test" "profile-modal"
        ]
        []


placholderModalView : Maybe Token -> Flags -> Model -> H.Html Msg
placholderModalView mToken flags model =
    H.div
        [ A.attribute "data-test" "placeholder-modal"
        ]
        []
