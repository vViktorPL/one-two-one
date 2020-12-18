module Screen.Game.Level exposing (Level, LevelTile(..), getTileAt, view)

import Array exposing (Array)
import Block3d
import Color
import Length
import Scene3d
import Scene3d.Material as Material
import Screen.Game.Constant


type LevelTile
    = Empty
    | Floor
    | Finish


type alias Level =
    { tiles : Array (Array LevelTile)
    , startingPosition : ( Int, Int )
    }


getTileAt : Level -> ( Int, Int ) -> LevelTile
getTileAt { tiles } ( x, y ) =
    Array.get x tiles
        |> Maybe.map (\row -> Array.get y row |> Maybe.withDefault Empty)
        |> Maybe.withDefault Empty


view { tiles } =
    tiles
        |> Array.indexedMap
            (\x row ->
                Array.indexedMap
                    (\y tile ->
                        case tile of
                            Floor ->
                                floorEntity Color.gray ( x, y )

                            Empty ->
                                Scene3d.nothing

                            Finish ->
                                floorEntity Color.black ( x, y )
                    )
                    row
                    |> Array.toList
            )
        |> Array.toList
        |> List.concatMap identity
        |> Scene3d.group


floorEntity color ( x, y ) =
    let
        tileBorderSizeCm =
            Screen.Game.Constant.tileSizeCm * 0.02
    in
    Scene3d.block
        (Material.matte color)
        (Block3d.with
            { x1 = Length.centimeters (Screen.Game.Constant.tileSizeCm * toFloat x + tileBorderSizeCm)
            , x2 = Length.centimeters (Screen.Game.Constant.tileSizeCm * toFloat (x + 1) - tileBorderSizeCm)
            , y1 = Length.centimeters (Screen.Game.Constant.tileSizeCm * toFloat y + tileBorderSizeCm)
            , y2 = Length.centimeters (Screen.Game.Constant.tileSizeCm * toFloat (y + 1) - tileBorderSizeCm)
            , z1 = Length.centimeters (Screen.Game.Constant.tileSizeCm * -0.1)
            , z2 = Length.centimeters 0
            }
        )
