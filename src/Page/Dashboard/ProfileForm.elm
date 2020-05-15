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


currentPoints : Model -> Int
currentPoints model =
    model.charisma
        + model.intelligence
        + model.wisdom
        + model.strength
        + model.dexterity
        + model.constitution


remainingPoints : Model -> Int
remainingPoints model =
    (8 * 6) + 27 - currentPoints model


init : Model
init =
    { charisma = 8
    , intelligence = 8
    , wisdom = 8
    , strength = 8
    , dexterity = 8
    , constitution = 8
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
    H.div []
        [ H.div [] []
        , H.div [] [ statsTabView model ]
        ]


statsTabView : Model -> H.Html Msg
statsTabView model =
    H.div
        []
        [ H.div
            []
            [ H.b [] [ H.text <| "Points remaining: " ++ String.fromInt (remainingPoints model) ]
            ]
        , H.div
            []
            [ rangeSliderView "Charisma" model.charisma CharismaChanged
            , rangeSliderView "Intelligence" model.intelligence IntelligenceChanged
            , rangeSliderView "Wisdom" model.wisdom WisdomChanged
            , rangeSliderView "Strength" model.strength StrengthChanged
            , rangeSliderView "Dexterity" model.dexterity DexterityChanged
            , rangeSliderView "Constitution" model.constitution ConstitutionChanged
            ]
        ]


rangeSliderView : String -> Int -> (Int -> Msg) -> H.Html Msg
rangeSliderView title currentValue handler =
    H.div
        [ A.class "profilemodal__range"
        , A.attribute "data-test-range" title
        ]
        [ H.span
            [ A.class "profilemodal__range__title" ]
            [ H.text title ]
        , H.input
            [ A.type_ "range"
            , A.class "profilemodal__range__slider"
            , A.min "0"
            , A.max "20"
            , A.value (String.fromInt currentValue)
            , E.onInput (String.toInt >> Maybe.withDefault -1 >> handler)
            ]
            []
        , H.b
            [ A.class "profilemodal__range__valuedisplay"
            ]
            [ H.text (String.fromInt currentValue) ]
        ]
