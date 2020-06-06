module View.Folder exposing (view)

import Html as H
import Html.Attributes as A


view : List (H.Attribute a) -> String -> H.Html a
view attrs text =
    H.div
        (A.class "folder"
            :: attrs
        )
        [ H.div
            [ A.class "folder__top" ]
            []
        , H.div
            [ A.class "folder__body" ]
            []
        , H.div
            [ A.class "folder__bottom" ]
            [ H.span [] [ H.text text ]
            ]
        ]
