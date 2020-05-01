module Page.Dashboard exposing (Model, Msg(..), init, update, view)

import ComponentResult exposing (ComponentResult, withCmds, withModel)
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import RemoteData exposing (RemoteData(..), WebData)
import Url.Builder exposing (crossOrigin, string)


type alias MacguffinItem =
    { name : String
    , threatLevel : String
    , id : String
    , authorId : String
    , createdDate : String
    }


decodeMacguffinItem : D.Decoder MacguffinItem
decodeMacguffinItem =
    D.map5 MacguffinItem
        (D.field "name" D.string)
        (D.field "threatLevel" D.string)
        (D.field "id" D.string)
        (D.field "authorId" D.string)
        (D.field "createdDate" D.string)


getItemsTracker : String
getItemsTracker =
    "getItemsTracker"


getMacguffinItems : Flags -> Cmd Msg
getMacguffinItems flags =
    Http.request
        { body = Http.emptyBody
        , expect =
            Http.expectJson
                FetchedMacguffinItems
                (D.list decodeMacguffinItem)
        , headers = []
        , method = "GET"
        , tracker = Just getItemsTracker
        , url = crossOrigin flags.apiUrl [ "/articles" ] [ string "sort" "createdDate" ]
        , timeout = Just 1000
        }


type alias Model =
    { macguffinItems : WebData (List MacguffinItem)
    }


type Msg
    = NoOp
    | FetchedMacguffinItems (Result Http.Error (List MacguffinItem))


type alias PageResult =
    ComponentResult Model Msg Never Never


init : Flags -> PageResult
init flags =
    withModel
        { macguffinItems = Loading
        }
        |> withCmds
            [ getMacguffinItems flags
            ]


update : Flags -> Msg -> Model -> PageResult
update flags msg model =
    withModel model


view : Flags -> Model -> H.Html Msg
view flags model =
    H.div [ A.class "dashboard-page" ]
        [ mainWindowView flags model
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
                ]
            ]
        ]