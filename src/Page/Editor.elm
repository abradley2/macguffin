module Page.Editor exposing (Model, Msg(..), PageResult, init, update, view)

import Array
import ComponentResult exposing (ComponentResult, withModel)
import ExtMsg exposing (ExtMsg(..))
import Html as H
import Html.Attributes as A
import Html.Events as E
import Page.Editor.Transforms exposing (centerAlignCmd, textAlign)
import PageResult exposing (resolveEffects, withEffect)
import Result.Extra as ResultX
import RichText.Commands exposing (defaultCommandMap)
import RichText.Config.Decorations exposing (emptyDecorations)
import RichText.Config.Spec exposing (Spec, withMarkDefinitions)
import RichText.Definitions as RTE exposing (markdown, paragraph)
import RichText.Editor as Editor exposing (Editor, apply)
import RichText.Html exposing (blockFromHtml, toHtml)
import RichText.Model.Element exposing (element)
import RichText.Model.HtmlNode exposing (HtmlNode(..))
import RichText.Model.Node as EditorNode
import RichText.Model.State as EditorState


type Effect
    = Eff (Cmd Msg)


performEffect : Effect -> Cmd Msg
performEffect eff =
    case eff of
        Eff cmd ->
            cmd


type Alignment
    = LeftAlign
    | CenterAlign
    | RightAlign


type Msg
    = NoOp
    | EditorInternalMsg Editor.Message
    | ChangeAlignment Alignment


type alias Model =
    { editor : Editor
    }


type alias PageResult =
    ComponentResult Model Msg ExtMsg Never


initEditorNode : EditorNode.Block
initEditorNode =
    EditorNode.block
        (element RTE.doc [])
        (EditorNode.blockChildren
            (Array.fromList
                [ initialEditorNode
                ]
            )
        )


initialEditorNode : EditorNode.Block
initialEditorNode =
    EditorNode.block
        (element RTE.paragraph [])
        (EditorNode.inlineChildren (Array.fromList [ EditorNode.plainText "This is some sample text" ]))


init_ : ComponentResult ( Model, Effect ) Msg ExtMsg Never
init_ =
    withModel
        { editor = Editor.init <| EditorState.state initEditorNode Nothing
        }
        |> withEffect (Eff Cmd.none)


init =
    init_ |> resolveEffects performEffect


update_ : Msg -> Model -> ComponentResult ( Model, Effect ) Msg ExtMsg Never
update_ msg model =
    case msg of
        NoOp ->
            withModel model
                |> withEffect (Eff Cmd.none)

        ChangeAlignment align ->
            let
                mSelection =
                    model.editor
                        |> Editor.state
                        |> EditorState.selection
            in
            case ( mSelection, align ) of
                ( Just selection, LeftAlign ) ->
                    withModel model
                        |> withEffect (Eff Cmd.none)

                ( _, CenterAlign ) ->
                    let
                        editor =
                            apply
                                (centerAlignCmd editorSpec)
                                editorSpec
                                model.editor
                                |> Result.withDefault model.editor
                    in
                    withModel { model | editor = editor }
                        |> withEffect (Eff Cmd.none)

                ( _, RightAlign ) ->
                    withModel model
                        |> withEffect (Eff Cmd.none)

                ( Nothing, _ ) ->
                    withModel model
                        |> withEffect (Eff Cmd.none)

        EditorInternalMsg editorMsg ->
            let
                editor =
                    Editor.update editorConfig editorMsg model.editor
            in
            withModel { model | editor = editor }
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
        , H.div
            []
            [ H.button
                [ E.onClick (ChangeAlignment CenterAlign)
                ]
                [ H.text "center"
                ]
            ]
        , H.div
            []
            [ editorView model
            , debugView model
            ]
        ]


editorSpec : Spec
editorSpec =
    RTE.markdown
        |> withMarkDefinitions
            [ textAlign
            ]


editorConfig =
    Editor.config
        { decorations = emptyDecorations
        , spec = editorSpec
        , commandMap = defaultCommandMap
        , toMsg = EditorInternalMsg
        }


debugView : Model -> H.Html Msg
debugView model =
    H.node
        "x-inner"
        [ A.attribute "html"
            (model.editor
                |> Editor.state
                |> EditorState.root
                |> toHtml editorSpec
                |> blockFromHtml editorSpec
                |> Result.map (toHtml editorSpec)
                |> Result.mapError (\err -> "Could not parse html: " ++ err)
                |> ResultX.merge
            )
        ]
        []


editorView : Model -> H.Html Msg
editorView model =
    H.div
        [ A.class "window rte-wrapper" ]
        [ H.div
            [ A.class "window__header" ]
            []
        , H.div
            [ A.class "window__body" ]
            [ Editor.view
                editorConfig
                model.editor
            ]
        ]