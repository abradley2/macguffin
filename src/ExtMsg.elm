module ExtMsg exposing (ExtMsg(..), Log, Token(..), hasRedirect)


type Token
    = Token String


type alias Log =
    { userMessage : Maybe String
    , logMessage : Maybe String
    }


type ExtMsg
    = LogError Log
    | SetToken Token
    | ReplaceUrl String
    | PushUrl String
    | Batch (List ExtMsg)


hasRedirect : ExtMsg -> Bool
hasRedirect extMsg =
    case extMsg of
        PushUrl _ ->
            True

        Batch msgList ->
            List.foldl
                (\cur acc ->
                    if acc then
                        acc

                    else
                        hasRedirect cur
                )
                False
                msgList

        _ ->
            False
