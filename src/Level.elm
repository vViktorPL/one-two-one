module Level exposing (Level, LevelTile(..), getTileAt)

import Array exposing (Array)

type LevelTile
    = Empty
    | Floor
    | Finish


type alias Level =
    { tiles: Array (Array LevelTile)
    , startingPosition: (Int, Int)
    }

getTileAt : Level -> (Int, Int) -> LevelTile
getTileAt { tiles } (x, y) =
    Array.get x tiles
        |> Maybe.map (\row -> (Array.get y row |> Maybe.withDefault Empty))
        |> Maybe.withDefault Empty
