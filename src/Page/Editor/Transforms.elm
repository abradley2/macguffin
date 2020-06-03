module Page.Editor.Transforms exposing (..)

import RichText.Commands exposing (toggleMark)
import RichText.Config.Command exposing (Command(..), transform)
import RichText.Config.MarkDefinition exposing (HtmlToMark, MarkDefinition, MarkToHtml, markDefinition, name)
import RichText.Config.Spec exposing (Spec)
import RichText.Model.Attribute exposing (Attribute(..))
import RichText.Model.HtmlNode exposing (HtmlNode(..))
import RichText.Model.Mark exposing (ToggleAction(..), mark, markOrderFromSpec)


centerAlignFromHtml : HtmlToMark
centerAlignFromHtml definition node =
    let
        n = Debug.log "NODE" node
    in
    case node of
        ElementNode name _ children ->
            if name == "x-align" then
                Just
                    ( mark
                        definition
                        []
                    , children
                    )

            else
                Nothing

        _ ->
            Nothing


centerAlignToHtml : MarkToHtml
centerAlignToHtml m children =
    ElementNode "p" [ ( "style", "display:block; text-align:right;" ) ] children


centerAlign : MarkDefinition
centerAlign =
    markDefinition
        { fromHtmlNode = centerAlignFromHtml
        , toHtmlNode = centerAlignToHtml
        , name = "p"
        }



centerAlignCmd : Spec -> ( String, Command )
centerAlignCmd editorSpec =
    ( name centerAlign
    , transform <|
        toggleMark
            (markOrderFromSpec editorSpec)
            (mark centerAlign [ StringAttribute "direction" "center" ])
            Flip
    )
