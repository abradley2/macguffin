module Page.Dashboard.MacguffinItem exposing (..)

import Http exposing (Error)
import Json.Decode as D
import Flags exposing (Flags)
import ExtMsg exposing (Token(..))
import Url.Builder exposing (crossOrigin, string)

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


getMacguffinItems : Maybe Token -> Flags -> (Result Error (List MacguffinItem) -> msg) -> Cmd msg
getMacguffinItems mToken flags onCompleted =
    Http.request
        { body = Http.emptyBody
        , expect =
            Http.expectJson
                onCompleted
                (D.list decodeMacguffinItem)
        , headers =
            case mToken of
                Just (Token token) ->
                    [ Http.header "Authorization" token ]

                _ ->
                    []
        , method = "GET"
        , tracker = Just "getItemsTracker"
        , url = crossOrigin flags.apiUrl [ "articles" ] [ string "type" "macguffins" ]
        , timeout = Just 1000
        }
