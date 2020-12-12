module Main exposing (..)

import Array exposing (Array)
import Html exposing (Html)
import Point3d
import Scene3d
import Camera3d
import Viewpoint3d
import Angle
import Direction3d
import Pixels
import Length
import Scene3d.Material as Material
import Color
import Block3d exposing (Block3d)
import Axis3d
import Vector3d

type PlayerBlock = PlayerBlock BlockAnimation (Int, Int)


type BlockAnimation
    = Standing
    | Lying Direction
--    | Falling Direction Float
--    | GettingUp Direction Float
--    | Rolling Direction Float



type Direction
    = Up
    | Right
    | Left
    | Down


type LevelTile
    = Empty
    | Floor
    | Finish


type alias Position = (Int, Int)


type alias Level =
    { tiles: Array (Array LevelTile)
    , startingPosition: Position
    }


type alias Model =
    { player: PlayerBlock
    , level: Level
    }

tileSize = Length.centimeters 1


init : Model
init =
    { player = PlayerBlock (Lying Down) (0, 0)
    , level =
        { tiles = Array.fromList [Array.fromList []]
        , startingPosition = (0, 0)
        }
    }


main =
    view init

view : Model -> Html msg
view { player, level } =
    let
        camera =
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.lookAt
                        { focalPoint = Point3d.origin
                        , eyePoint = Point3d.centimeters 40 20 30
                        , upDirection = Direction3d.z
                        }
                , verticalFieldOfView = Angle.degrees 30
                }
    in
    Scene3d.sunny
        { entities = [ playerEntity player ]
        , camera = camera
        , upDirection = Direction3d.z
        , sunlightDirection = Direction3d.yz (Angle.degrees -120)
        , background = Scene3d.transparentBackground
        , clipDepth = Length.centimeters 1
        , shadows = False
        , dimensions = ( Pixels.int 400, Pixels.int 300 )
        }


tileSizeCm = Length.inCentimeters tileSize

playerWidth = 1 * tileSizeCm
playerHeight = 2 * tileSizeCm

topAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.negativeY

rightAxis =
    Axis3d.through (Point3d.centimeters 0 playerWidth 0) Direction3d.negativeX

bottomAxis =
    Axis3d.through (Point3d.centimeters playerWidth 0 0) Direction3d.y

leftAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.x


playerEntity (PlayerBlock animation (x, y)) =
    let

        positionX = toFloat x * tileSizeCm
        positionY = toFloat y * tileSizeCm

        block =
            Scene3d.block
                ( Material.matte Color.lightGreen)
                (
                    Block3d.with
                        { x1 = Length.centimeters 0
                        , x2 = Length.centimeters playerWidth
                        , y1 = Length.centimeters 0
                        , y2 = Length.centimeters playerWidth
                        , z1 = Length.centimeters 0
                        , z2 = Length.centimeters playerHeight
                        }
                )



    in
       (case animation of
           -- +
           Standing ->
               block

           -- |
           -- 0
           Lying Up ->
               block
                   |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                   |> Scene3d.translateIn Direction3d.x tileSize

           -- 0-
           Lying Right ->
               block
                   |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                   |> Scene3d.translateIn Direction3d.negativeY tileSize

           -- 0
           -- |
           Lying Down ->
               block
                   |> Scene3d.rotateAround bottomAxis (Angle.degrees 90)
                   |> Scene3d.translateIn Direction3d.negativeX tileSize

           -- -0
           Lying Left ->
               block
                   |> Scene3d.rotateAround leftAxis (Angle.degrees 90)
                   |> Scene3d.translateIn Direction3d.y tileSize


       )
           |> Scene3d.translateBy
                (Vector3d.centimeters positionX positionY 0)

