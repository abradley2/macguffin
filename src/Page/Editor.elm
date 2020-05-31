module Page.Editor exposing (Model, Msg(..), PageResult, init, update, view)

import ComponentResult exposing (ComponentResult, withModel)
import ExtMsg exposing (ExtMsg(..))
import Html as H
import Html.Attributes as A
import PageResult exposing (resolveEffects, withEffect)


type Effect
    = Eff (Cmd Msg)


performEffect : Effect -> Cmd Msg
performEffect eff =
    case eff of
        Eff cmd ->
            cmd


type Msg
    = NoOp


type alias Model =
    {}


type alias PageResult =
    ComponentResult Model Msg ExtMsg Never


init_ : ComponentResult ( Model, Effect ) Msg ExtMsg Never
init_ =
    withModel {}
        |> withEffect (Eff Cmd.none)


init =
    init_ |> resolveEffects performEffect


update_ : Msg -> Model -> ComponentResult ( Model, Effect ) Msg ExtMsg Never
update_ msg model =
    withModel model
        |> withEffect (Eff Cmd.none)


update : Msg -> Model -> PageResult
update msg model =
    update_ msg model
        |> resolveEffects performEffect


view : Model -> H.Html Msg
view model =
    H.div
        [ A.attribute "data-test" "editor-page"
        ]
        [ H.text "Editor page"
        ]
