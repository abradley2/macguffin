module Page.Dashboard.ProfileForm exposing (..)

import ComponentResult exposing (ComponentResult, withExternalMsg, withModel)
import Html as H
import Html.Attributes as A
import Html.Events as E


type Tab
    = Bio
    | Stats


type alias FormResult =
    ComponentResult Model Msg ExtMsg Never


type alias Model =
    { charisma : Int
    , intelligence : Int
    , wisdom : Int
    , strength : Int
    , dexterity : Int
    , constitution : Int
    , bio : String
    , activeTab : Tab
    }


init : Model
init =
    { charisma = 0
    , intelligence = 0
    , wisdom = 0
    , strength = 0
    , dexterity = 0
    , constitution = 0
    , bio = ""
    , activeTab = Stats
    }


type ExtMsg
    = Submit Model
    | Cancel


type Msg
    = CharismaChanged Int
    | IntelligenceChanged Int
    | WisdomChanged Int
    | StrengthChanged Int
    | DexterityChanged Int
    | ConstitutionChanged Int
    | SubmitForm


update : Msg -> Model -> FormResult
update msg model =
    case msg of
        CharismaChanged charisma ->
            withModel { model | charisma = charisma }

        IntelligenceChanged intelligence ->
            withModel { model | intelligence = intelligence }

        WisdomChanged wisdom ->
            withModel { model | wisdom = wisdom }

        StrengthChanged strength ->
            withModel { model | strength = strength }

        DexterityChanged dexterity ->
            withModel { model | dexterity = dexterity }

        ConstitutionChanged constitution ->
            withModel { model | constitution = constitution }

        SubmitForm ->
            withModel model
                |> withExternalMsg (Submit model)


view : Model -> H.Html Msg
view model =
    H.div [] [ H.text "profile form" ]
