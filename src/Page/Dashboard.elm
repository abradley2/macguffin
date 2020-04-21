module Page.Dashboard exposing (Model, Msg(..), init, update, view)

import Html as H
import ComponentResult exposing (ComponentResult, withModel)
import Flags exposing (Flags)


type alias Model =
    {}


type Msg =
    NoOp


type alias PageResult = ComponentResult Model Msg Never Never


init : Flags -> PageResult
init flags =
    withModel {}


update : Flags -> Msg -> Model -> PageResult
update flags msg model =
    withModel {}

view : Flags -> Model -> H.Html Msg
view flags model =
    H.div [] [ H.text "Dashboard" ]
