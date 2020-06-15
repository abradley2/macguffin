module Page.Editor.Keybind exposing (..)

import Array
import RichText.Commands as Commands
    exposing
        ( insertAfterBlockLeaf
        , insertBlock
        , insertNewline
        , insertText
        , insertInline
        , lift
        , liftEmpty
        , splitBlockHeaderToNewParagraph
        , splitTextBlock
        , toggleMark
        , toggleTextBlock
        , wrap
        )
import RichText.Config.Command as Command exposing (CommandMap, Transform, inputEvent, internal, key, set, transform)
import RichText.Config.Keys exposing (enter, return, short)
import RichText.Config.Spec exposing (Spec)
import RichText.Definitions exposing (bold, italic, paragraph)
import RichText.List
import RichText.Model.Element exposing (Element, element, name)
import RichText.Model.Mark as Mark exposing (ToggleAction(..), mark, markOrderFromSpec)
import RichText.Model.Node exposing (Block, block, inlineChildren, plainText, withElement)
import RichText.Model.Selection exposing (anchorNode, anchorOffset, isCollapsed)
import RichText.Model.State exposing (State, root, selection, state, withRoot)
import RichText.Node exposing (Node(..), findClosestBlockPath, isEmptyTextBlock, nodeAt, replace)


listCommandBindings =
    RichText.List.defaultCommandMap RichText.List.defaultListDefinition


commandBindings : Spec -> CommandMap
commandBindings spec =
    let
        markOrder =
            markOrderFromSpec spec
    in
    Command.combine
        listCommandBindings
        (Commands.defaultCommandMap
            |> set [ inputEvent "insertParagraph", key [ enter ], key [ return ] ]
                [ ( "splitBlockHeaderToNewParagraph"
                  , transform <|
                        (splitBlockHeaderToNewParagraph
                            [ "heading" ]
                            (element paragraph [])
                            >> Result.andThen
                                (insertInline
                                    (plainText zeroWidthSpace)
                                )
                        )
                  )
                ]
            |> set [ inputEvent "formatBold", key [ short, "b" ] ]
                [ ( "toggleStyle", transform <| toggleMark markOrder (mark bold []) Flip )
                ]
            |> set [ inputEvent "formatItalic", key [ short, "i" ] ]
                [ ( "toggleStyle", transform <| toggleMark markOrder (mark italic []) Flip )
                ]
        )


emptyParagraph : Block
emptyParagraph =
    block
        (element paragraph [])
        (inlineChildren <| Array.fromList [ plainText "hello" ])


zeroWidthSpace : String
zeroWidthSpace =
    "\u{200B}"
