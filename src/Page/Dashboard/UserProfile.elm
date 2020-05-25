module Page.Dashboard.UserProfile exposing (..)

import ExtMsg exposing (Token(..))
import Flags exposing (Flags)
import Http exposing (Error)
import Json.Decode as D
import Url.Builder


getUserProfile : Flags -> Token -> (Result Error UserProfile -> msg) -> Cmd msg
getUserProfile flags (Token token) onCompleted =
    Http.request
        { url = Url.Builder.crossOrigin flags.apiUrl [ "profile" ] []
        , method = "GET"
        , timeout = Just 2000
        , expect = Http.expectJson onCompleted decodeUserProfile
        , headers =
            [ Http.header "Authorization" token
            ]
        , tracker = Just "getUserProfile"
        , body = Http.emptyBody
        }


type alias UserProfile =
    { publicAgentID : Maybe String
    , strength : Int
    , dexterity : Int
    , constitution : Int
    , intelligence : Int
    , wisdom : Int
    , charisma : Int
    }


decodeUserProfile : D.Decoder UserProfile
decodeUserProfile =
    D.map7 UserProfile
        (D.maybe <| D.field "publicAgentID" D.string)
        (D.field "strength" D.int)
        (D.field "dexterity" D.int)
        (D.field "constitution" D.int)
        (D.field "intelligence" D.int)
        (D.field "wisdom" D.int)
        (D.field "charisma" D.int)
