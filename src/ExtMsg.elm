module ExtMsg exposing (ExtMsg(..), Log, Token(..))


type Token =
    Token String

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
