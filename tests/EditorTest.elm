module EditorTest exposing (suite)

import ComponentResult exposing (applyExternalMsg, resolve)
import Page.Editor as EditorPage exposing (editorSpec)
import RichText.Editor as Editor
import RichText.Html exposing (toHtml)
import RichText.Model.State as EditorState
import RichText.Commands exposing (selectAll)
import Test exposing (..)
import Expect


getModel =
    applyExternalMsg (\_ result -> result)
        >> resolve
        >> Tuple.first


suite : Test
suite =
    describe
        "stuff"
        [ test "Can add an ordered list to the editor" <|
            \_ ->
                EditorPage.init
                    |> getModel
                    |> EditorPage.update EditorPage.InsertOrderedList
                    |> getModel
                    |> .editor
                    |> Editor.state
                    |> selectAll
                    |> Result.map EditorState.root
                    |> Result.map (toHtml editorSpec)
                    |> Result.map (String.contains "<ol>")
                    |> Result.map (Expect.equal True)
                    |> Result.withDefault (Expect.fail "Editor setup failed")
        ]
