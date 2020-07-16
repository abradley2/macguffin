module Page.Editor.Keybind exposing (..)

import Array
import RichText.Commands as Commands
    exposing
        ( toggleMark
        )
import RichText.Config.Command as Command exposing (CommandMap, inputEvent, key, set, transform)
import RichText.Config.Keys exposing (short)
import RichText.Config.Spec exposing (Spec)
import RichText.Definitions exposing (bold, italic, paragraph)
import RichText.List
import RichText.Model.Element exposing (element)
import RichText.Model.Mark exposing (ToggleAction(..), mark, markOrderFromSpec)
import RichText.Model.Node exposing (Block, block, inlineChildren, plainText)
import RichText.Node exposing (Node(..))


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
