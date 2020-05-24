module Page.Dashboard exposing (..)

import ComponentResult exposing (ComponentResult, applyExternalMsg, mapModel, mapMsg, withExternalMsg, withModel)
import Data.Http exposing (handlePossibleSessionTimeout, httpErrToString)
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as D
import Page.Dashboard.ProfileForm as ProfileForm
import PageResult exposing (resolveEffects, withEffect)
import RemoteData exposing (RemoteData(..), WebData)
import Url.Builder exposing (crossOrigin, string)
import View.Folder as Folder


type Effect
    = Eff (Cmd Msg)
    | EffBatch (List Effect)
    | EffFetchUserProfile Flags Token
    | EffFetchMacguffinItems (Maybe Token) Flags


performEffect : Effect -> Cmd Msg
performEffect effect =
    case effect of
        Eff cmd ->
            cmd

        EffBatch effs ->
            effs |> List.map performEffect |> Cmd.batch

        EffFetchUserProfile flags token ->
            getUserProfile flags token

        EffFetchMacguffinItems mToken flags ->
            getMacguffinItems mToken flags


type Modal
    = Profile ProfileForm.Model
    | ContainmentSites
    | Protocols


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


getUserProfile : Flags -> Token -> Cmd Msg
getUserProfile flags token =
    case token of
        Token token_ ->
            Http.request
                { url = Url.Builder.crossOrigin flags.apiUrl [ "profile" ] []
                , method = "GET"
                , timeout = Just 2000
                , expect = Http.expectJson FetchedUserProfile decodeUserProfile
                , headers =
                    [ Http.header "Authorization" token_
                    ]
                , tracker = Just "getUserProfile"
                , body = Http.emptyBody
                }


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
    , userProfile : WebData UserProfile
    , modal : Maybe Modal
    }


{-| When we initialize the profile form, if we have a user loaded then use this
to populate it's default values
-}
initProfileForm : Model -> ProfileForm.Model
initProfileForm model =
    let
        default =
            ProfileForm.init
    in
    case model.userProfile of
        Success profile ->
            { default
                | charisma = profile.charisma
                , wisdom = profile.wisdom
                , intelligence = profile.intelligence
                , strength = profile.strength
                , dexterity = profile.dexterity
                , constitution = profile.constitution
            }

        _ ->
            default


type Msg
    = FetchedMacguffinItems (Result Http.Error (List MacguffinItem))
    | FetchedUserProfile (Result Http.Error UserProfile)
    | ProfileFormMsg ProfileForm.Msg
    | ToggleModal Modal
    | CloseModal


type alias PageResult =
    ComponentResult ( Model, Effect ) Msg ExtMsg Never


init mToken flags =
    init_ mToken flags
        |> resolveEffects performEffect


init_ : Maybe Token -> Flags -> PageResult
init_ mToken flags =
    withModel
        { macguffinItems = Loading
        , modal = Nothing
        , userProfile =
            mToken
                |> Maybe.map (\_ -> Loading)
                |> Maybe.withDefault NotAsked
        }
        |> withEffect
            (EffBatch
                [ EffFetchMacguffinItems mToken flags
                , mToken
                    |> Maybe.map (EffFetchUserProfile flags)
                    |> Maybe.withDefault (Eff Cmd.none)
                ]
            )


update : Flags -> Msg -> Model -> ComponentResult Model Msg ExtMsg Never
update flags msg model =
    update_ flags msg model
        |> resolveEffects performEffect


update_ : Flags -> Msg -> Model -> PageResult
update_ flags msg model =
    case msg of
        FetchedMacguffinItems httpRes ->
            case httpRes of
                Result.Ok macguffinItems ->
                    withModel { model | macguffinItems = Success macguffinItems }
                        |> withEffect (Eff Cmd.none)

                Result.Err httpErr ->
                    withModel model
                        |> withExternalMsg
                            (handlePossibleSessionTimeout httpErr
                                |> Maybe.withDefault
                                    (LogError
                                        { userMessage = Just "Failed to retrieve agent article data"
                                        , logMessage = Just <| httpErrToString httpErr
                                        }
                                    )
                            )
                        |> withEffect (Eff Cmd.none)

        FetchedUserProfile httpRes ->
            case httpRes of
                Result.Ok userProfile ->
                    withModel { model | userProfile = Success userProfile }
                        |> withEffect (Eff Cmd.none)

                Result.Err httpErr ->
                    withModel model
                        |> withExternalMsg
                            (handlePossibleSessionTimeout httpErr
                                |> Maybe.withDefault
                                    (LogError
                                        { userMessage = Just "Failed to retrieve agent profile data"
                                        , logMessage = Just <| httpErrToString httpErr
                                        }
                                    )
                            )
                        |> withEffect (Eff Cmd.none)

        ToggleModal nextModal ->
            withModel { model | modal = Just nextModal }
                |> withEffect (Eff Cmd.none)

        CloseModal ->
            withModel { model | modal = Nothing }
                |> withEffect (Eff Cmd.none)

        ProfileFormMsg formMsg ->
            case model.modal of
                Just (Profile formModel) ->
                    ProfileForm.update formMsg formModel
                        |> mapModel (\form -> { model | modal = Just <| Profile form })
                        |> mapMsg ProfileFormMsg
                        |> applyExternalMsg
                            (\extMsg result ->
                                case extMsg of
                                    ProfileForm.Cancel ->
                                        mapModel (\newModel -> { newModel | modal = Nothing }) result

                                    ProfileForm.Submit _ ->
                                        mapModel (\newModel -> { newModel | modal = Nothing }) result
                            )
                        |> withEffect (Eff Cmd.none)

                _ ->
                    withModel model
                        |> withExternalMsg
                            (LogError
                                { userMessage = Nothing
                                , logMessage = Just "Unhandled profile form message"
                                }
                            )
                        |> withEffect (Eff Cmd.none)


view : Maybe Token -> Flags -> Model -> H.Html Msg
view mToken flags model =
    H.div [ A.class "dashboard-page" ]
        [ H.div [ A.class "dashboard-modalcontainer" ]
            [ case model.modal of
                Just (Profile formModel) ->
                    profileModalView mToken flags model formModel
                        |> modalView "profile-modal"

                Just Protocols ->
                    protocolsModalView mToken flags model
                        |> modalView "protocols-modal"

                Just ContainmentSites ->
                    containmentSitesModalView mToken flags model
                        |> modalView "containment-sites-modal"

                Nothing ->
                    H.text ""
            ]
        , H.div []
            [ H.input [ A.class "textinput", A.placeholder "Search Database" ] []
            , H.button [ A.class "button" ] [ H.text "GO" ]
            ]
        , mainWindowView flags model
        , H.div
            [ A.class "dashboard-folderrow" ]
            [ Folder.view
                [ A.attribute "data-test" "profile-form-button"
                , E.onClick <|
                    ToggleModal
                        (Profile (initProfileForm model))
                ]
                "Agent Profile"
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


modalView : String -> H.Html Msg -> H.Html Msg
modalView title modal =
    H.div
        [ A.attribute "data-test" title
        , A.class "window"
        ]
        [ H.div [ A.class "window__header" ]
            [ H.div [] []
            , H.button
                [ A.class "window__header__button"
                , E.onClick CloseModal
                ]
                [ H.text "X" ]
            ]
        , H.div
            []
            [ modal ]
        ]


profileModalView : Maybe Token -> Flags -> Model -> ProfileForm.Model -> H.Html Msg
profileModalView mToken flags model formModel =
    let
        mPublicAgentID =
            model.userProfile
                |> RemoteData.toMaybe
                |> Maybe.andThen .publicAgentID
    in
    H.div
        [ A.class "window__body dashboard-profilemodal" ]
        [ ProfileForm.view mPublicAgentID formModel
            |> H.map ProfileFormMsg
        ]


containmentSitesModalView : Maybe Token -> Flags -> Model -> H.Html Msg
containmentSitesModalView mToken flags model =
    H.div
        [ A.class "window__body" ]
        [ H.text "Containment sites modal view" ]


protocolsModalView : Maybe Token -> Flags -> Model -> H.Html Msg
protocolsModalView mToken flags model =
    H.div
        [ A.class "window__body" ]
        [ H.text "Protocols modal view" ]
