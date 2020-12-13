module Level exposing (Level, LevelTile(..))

import Array exposing (Array)

type LevelTile
    = Empty
    | Floor
    | Finish


type alias Level =
    { tiles: Array (Array LevelTile)
    , startingPosition: (Int, Int)
    }
