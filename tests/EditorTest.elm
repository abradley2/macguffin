module EditorTest exposing (suite)

import ComponentResult exposing (applyExternalMsg, resolve)
import Expect
import Html.Attributes as A
import Page.Editor as EditorPage exposing (editorSpec)
import RichText.Commands exposing (selectAll)
import RichText.Editor as Editor
import RichText.Html exposing (toHtml)
import RichText.Model.Selection exposing (caret, range)
import RichText.Model.State as EditorState exposing (withRoot, withSelection)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


getModel =
    applyExternalMsg (\_ result -> result)
        >> resolve
        >> Tuple.first


suite : Test
suite =
    describe
        "rich text editor page"
        [ test "Can add an ordered list to the editor" <|
            \_ ->
                EditorPage.init
                    |> getModel
                    |> EditorPage.update EditorPage.InsertOrderedList
                    |> getModel
                    |> .editor
                    |> Editor.state
                    |> withSelection (Just <| range [ 0, 0 ] 0 [ 0, 0 ] 4)
                    |> EditorState.root
                    |> toHtml editorSpec
                    |> String.contains "<ol>"
                    |> Expect.equal True
        , test "Can render the view in a basic way" <|
            \_ ->
                EditorPage.init
                    |> getModel
                    |> EditorPage.view
                    |> Query.fromHtml
                    |> Query.findAll
                        [ Selector.attribute <| A.attribute "data-rte-doc" "true"
                        ]
                    |> Query.count (Expect.equal 1)
        ]
