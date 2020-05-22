module ProfileFormTest exposing (..)

import ComponentResult exposing (applyExternalMsg, resolve)
import Expect
import ExtMsg exposing (ExtMsg(..), Token(..))
import Flags exposing (Flags)
import Html as H
import Html.Attributes as A
import Json.Decode as D
import Json.Encode as E
import Page.Dashboard as Dashboard exposing (Msg(..), decodeUserProfile)
import Page.Dashboard.ProfileForm as ProfileForm
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


defaultStrength =
    10


profileResponse =
    E.object
        [ ( "userID", E.string "1234" )
        , ( "strength", E.int defaultStrength )
        , ( "constitution", E.int 8 )
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
        [ test "Can decode an expected userProfile"
            (\_ ->
                case D.decodeString decodeUserProfile (E.encode 2 profileResponse) of
                    Result.Ok _ ->
                        Expect.pass

                    Result.Err err ->
                        Expect.fail (D.errorToString err)
            )
        , test "When we load a users profile this should pre-populate the profile form"
            (\_ ->
                case D.decodeString decodeUserProfile (E.encode 2 profileResponse) of
                    Result.Ok userProfile ->
                        let
                            withUserProfile =
                                Dashboard.init token flags
                                    |> getModel
                                    |> Dashboard.update flags (FetchedUserProfile <| Result.Ok userProfile)
                                    |> getModel
                        in
                        withUserProfile
                            |> Dashboard.view token flags
                            |> Query.fromHtml
                            |> Query.find [ Selector.attribute <| A.attribute "data-test" "profile-form-button" ]
                            |> Event.simulate Event.click
                            |> Event.toResult
                            |> Result.map (\msg -> Dashboard.update flags msg withUserProfile)
                            |> Result.map getModel
                            |> Result.map (Dashboard.view token flags >> Query.fromHtml)
                            |> Result.map
                                (Query.find
                                    [ Selector.attribute <|
                                        A.attribute "data-test-range" "Strength"
                                    ]
                                )
                            |> Result.map (Query.contains [ H.text <| String.fromInt defaultStrength ])
                            |> Result.withDefault (Expect.fail "click event failed to register")

                    Result.Err err ->
                        Expect.fail (D.errorToString err)
            )
        , test "All sliders should effect their respective state"
            (\_ ->
                ProfileForm.init
                    |> ProfileForm.view Nothing
                    |> Query.fromHtml
                    |> Query.find
                        [ Selector.attribute <|
                            A.attribute "data-test-range" "Strength"
                        ]
                    |> Query.find
                        [ Selector.tag "range"
                        ]
                    |> Event.simulate (Event.input "100")
                    |> Event.toResult
                    |> Result.map (\msg -> ProfileForm.update msg ProfileForm.init)
                    |> Result.map getModel
                    |> Result.map (\model -> Expect.equal model.strength 100)
                    |> Result.withDefault (Expect.fail "Did not fire event")
            )
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
