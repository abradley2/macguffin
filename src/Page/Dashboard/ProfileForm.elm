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
    | TabChanged Tab


update : Msg -> Model -> FormResult
update msg model =
    case msg of
        TabChanged tab ->
            withModel { model | activeTab = tab }

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


view : Maybe String -> Model -> H.Html Msg
view mAgentID model =
    H.div
        [ A.class "dashboard-profileform"
        ]
        [ case mAgentID of
            Just initializedAgentID ->
                H.div
                    [ A.attribute "data-test" "profile-form-blocker"
                    , A.class "profileform__blocker"
                    ]
                    []

            Nothing ->
                H.div
                    []
                    []
        , H.div
            [ A.class "tabs" ]
            [ H.div
                [ A.class "tabs__header"
                ]
                [ tabsView model.activeTab ]
            , H.div
                [ A.class "tabs__body"
                ]
                [ case model.activeTab of
                    Stats ->
                        statsTabView model

                    Bio ->
                        bioTabView model
                ]
            ]
        ]


tabBtnClass isActive =
    A.classList
        [ ( "button", True )
        , ( "tabgroup__button", True )
        , ( "tabgroup__button--active", isActive )
        ]


tabsView : Tab -> H.Html Msg
tabsView activeTab =
    H.div
        [ A.class "tabs__headerbuttons"
        ]
        [ H.div
            [ A.class "tabgroup"
            ]
            [ H.button
                [ A.attribute "data-test" "stats-tab"
                , tabBtnClass (activeTab == Stats)
                , E.onClick (TabChanged Stats)
                ]
                [ H.text "Stats"
                ]
            ]
        , H.div
            [ A.class "tabgroup"
            ]
            [ H.button
                [ A.attribute "data-test" "bio-tab"
                , tabBtnClass (activeTab == Bio)
                , E.onClick (TabChanged Bio)
                ]
                [ H.text "Bio"
                ]
            ]
        ]


bioTabView : Model -> H.Html Msg
bioTabView model =
    H.div [] []


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
