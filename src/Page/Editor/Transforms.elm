module Page.Editor.Transforms exposing (..)

import Html exposing (Html)
import RichText.Commands exposing (toggleMark)
import RichText.Config.Command exposing (Command(..), transform)
import RichText.Config.MarkDefinition exposing (HtmlToMark, MarkDefinition, MarkToHtml, markDefinition, name)
import RichText.Config.Spec exposing (Spec)
import RichText.Model.Attribute exposing (Attribute(..))
import RichText.Model.HtmlNode exposing (HtmlAttribute, HtmlNode(..))
import RichText.Model.Mark exposing (ToggleAction(..), attributes, mark, markOrderFromSpec)


getStringAttribute : String -> List Attribute -> Maybe String
getStringAttribute name attrs =
    List.foldr
        (\cur acc ->
            case acc of
                Just _ ->
                    acc

                Nothing ->
                    case cur of
                        StringAttribute attrName attrValue ->
                            if attrName == name then
                                Just attrValue

                            else
                                Nothing

                        _ ->
                            Nothing
        )
        Nothing
        attrs


fromHtmlAttributes : List HtmlAttribute -> List Attribute
fromHtmlAttributes =
    List.map
        (\( a, b ) -> StringAttribute a b)


textAlignFromHtml : HtmlToMark
textAlignFromHtml definition node =
    case node of
        ElementNode name attrs children ->
            let
                align =
                    attrs
                        |> fromHtmlAttributes
                        |> getStringAttribute "data-alignment"
                        |> Maybe.map (StringAttribute "alignment")
                        |> Maybe.withDefault (StringAttribute "" "")
            in
            if name == "x-align" then
                Just
                    ( mark
                        definition
                        [ align ]
                    , children
                    )

            else
                Nothing

        _ ->
            Nothing


textAlignToHtml : MarkToHtml
textAlignToHtml m children =
    let
        align =
            m
                |> attributes
                |> getStringAttribute "alignment"

        style =
            case align of
                Just "left" ->
                    "display: block; text-align: left;"

                Just "center" ->
                    "display: block; text-align: center;"

                Just "right" ->
                    "display: block; text-align: right;"

                _ ->
                    ""
    in
    ElementNode "x-align" [ ( "style", style ), ( "data-alignment", align |> Maybe.withDefault "" ) ] children


textAlign : MarkDefinition
textAlign =
    markDefinition
        { fromHtmlNode = textAlignFromHtml
        , toHtmlNode = textAlignToHtml
        , name = "x-align"
        }


centerAlignCmd : Spec -> ( String, Command )
centerAlignCmd =
    alignCmd CenterAlign


alignCmd : Alignment -> Spec -> ( String, Command )
alignCmd alignment editorSpec =
    ( name textAlign
    , transform <|
        toggleMark
            (markOrderFromSpec editorSpec)
            (mark textAlign [ StringAttribute "alignment" <| alignmentToString alignment ])
            Add
    )


type Alignment
    = LeftAlign
    | CenterAlign
    | RightAlign


alignmentToString : Alignment -> String
alignmentToString a =
    case a of
        LeftAlign ->
            "left"

        CenterAlign ->
            "center"

        RightAlign ->
            "right"


alignmentFromString : String -> Maybe Alignment
alignmentFromString a =
    case a of
        "left" ->
            Just LeftAlign

        "center" ->
            Just CenterAlign

        "right" ->
            Just RightAlign

        _ ->
            Nothing
