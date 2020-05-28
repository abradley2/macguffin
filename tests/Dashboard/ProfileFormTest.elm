module Dashboard.ProfileFormTest exposing (..)

import ComponentResult exposing (applyExternalMsg, resolve)
import Expect
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Json.Decode as D
import Json.Encode as E
import Page.Dashboard as Dashboard exposing (Msg(..))
import Page.Dashboard.ProfileForm as ProfileForm
import Page.Dashboard.UserProfile as UserProfile exposing (UserProfile)
import RemoteData exposing (RemoteData(..))
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


userProfile : UserProfile
userProfile =
    { publicAgentID = Nothing
    , strength = 1
    , constitution = 2
    , dexterity = 3
    , intelligence = 4
    , wisdom = 5
    , charisma = 6
    }


profileResponse =
    E.object
        [ ( "userID", E.string "1234" )
        , ( "strength", E.int userProfile.strength )
        , ( "constitution", E.int userProfile.constitution )
        , ( "dexterity", E.int 8 )
        , ( "intelligence", E.int 8 )
        , ( "wisdom", E.int 8 )
        , ( "charisma", E.int 8 )
        ]


flags : Flags
flags =
    { apiUrl = "apiUrl"
    , pageUrl = "pageUrl"
    , token = Nothing
    }


getModel =
    applyExternalMsg (\_ result -> result)
        >> resolve
        >> Tuple.first


token =
    Just (Token "token")


suite : Test
suite =
    describe "Dashboard ProfileForm"
        [ -- decoder test
          test "Can decode an expected userProfile"
            (\_ ->
                case
                    D.decodeString
                        UserProfile.decodeUserProfile
                        (E.encode 2 profileResponse)
                of
                    Result.Ok _ ->
                        Expect.pass

                    Result.Err err ->
                        Expect.fail (D.errorToString err)
            )

        , test "Can switch to bio tab by clicking on button" <|
            \_ ->
                ProfileForm.init
                    |> ProfileForm.view (Just "agent-id")
                    |> Query.fromHtml
                    |> Query.find [
                        Selector.attribute <| A.attribute "data-test" "bio-tab"
                    ]
                    |> Event.simulate Event.click
                    |> Event.toResult
                    |> Result.map (\msg ->
                        ProfileForm.update msg ProfileForm.init
                    )
                    |> Result.map (getModel >> .activeTab)
                    |> Result.map (\activeTab ->
                        case activeTab of
                            ProfileForm.Bio ->
                                Expect.pass
                            _ ->
                                Expect.fail "Did not open bio tab"
                    )
                    |> Result.withDefault (Expect.fail "Click on tab did not trigger msg")


        -- prefill tests
        , test "Strength prefill should work"
            (\_ -> testFormPrefill "Strength" .strength)
        , test "Dexterity prefill should work"
            (\_ -> testFormPrefill "Dexterity" .dexterity)
        , test "Constitution prefill should work"
            (\_ -> testFormPrefill "Constitution" .constitution)
        , test "Wisdom prefill should work"
            (\_ -> testFormPrefill "Wisdom" .wisdom)
        , test "Intelligence prefill should work"
            (\_ -> testFormPrefill "Intelligence" .intelligence)
        , test "Charisma prefill should work"
            (\_ -> testFormPrefill "Charisma" .charisma)

        -- slider tests
        , test "Strength slider should work"
            (\_ -> testSlider "Strength" 100 .strength)
        , test "Dexterity slider should work"
            (\_ -> testSlider "Dexterity" 100 .dexterity)
        , test "Constitution slider should work"
            (\_ -> testSlider "Constitution" 100 .constitution)
        , test "Wisdom slider should work"
            (\_ -> testSlider "Wisdom" 100 .wisdom)
        , test "Intelligence slider should work"
            (\_ -> testSlider "Intelligence" 100 .intelligence)
        , test "Charisma slider should work"
            (\_ -> testSlider "Charisma" 100 .charisma)
        , test "Should block the form if we already have an initialized agent"
            (\_ ->
                ProfileForm.init
                    |> ProfileForm.view (Just "Agent Tony")
                    |> Query.fromHtml
                    |> Query.findAll
                        [ Selector.attribute <|
                            A.attribute "data-test" "profile-form-blocker"
                        ]
                    |> Query.count (Expect.equal 1)
            )
        ]


testFormPrefill : String -> (UserProfile -> Int) -> Expect.Expectation
testFormPrefill dataTag userProfAttr =
    Dashboard.initProfileForm (Success userProfile)
        |> ProfileForm.view userProfile.publicAgentID
        |> Query.fromHtml
        |> Query.find
            [ Selector.attribute <|
                A.attribute "data-test-range" dataTag
            ]
        |> Query.contains
            [ H.text (String.fromInt <| userProfAttr userProfile) ]


testSlider : String -> Int -> (ProfileForm.Model -> Int) -> Expect.Expectation
testSlider dataTag value getter =
    ProfileForm.init
        |> ProfileForm.view Nothing
        |> Query.fromHtml
        |> Query.find
            [ Selector.attribute <|
                A.attribute "data-test-range" dataTag
            ]
        |> Query.find
            [ Selector.tag "input"
            ]
        |> Event.simulate
            (Event.input <| String.fromInt value)
        |> Event.toResult
        |> Result.map (\msg -> ProfileForm.update msg ProfileForm.init)
        |> Result.map getModel
        |> Result.map (\model -> Expect.equal (getter model) value)
        |> Result.withDefault (Expect.fail "Did not fire event")
