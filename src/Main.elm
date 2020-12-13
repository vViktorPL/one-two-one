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
import Duration exposing (Duration)
import Browser
import Browser.Events
import Json.Decode as Decode
import Quantity

type PlayerBlock = PlayerBlock BlockOrientation (Int, Int)


type BlockOrientation
    = Standing
    | Lying Direction
    | Falling Direction Float
    | GettingUp Direction Float
    | Rolling Direction Float



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
    , control: Maybe Direction
    }

type Msg
    = Tick Float
    | KeyDown String
    | KeyUp String

tileSize = Length.centimeters 1


init : () -> (Model, Cmd Msg)
init flags =
    ( { player = PlayerBlock Standing (0, 0)
      , level =
        { tiles = Array.fromList [Array.fromList []]
        , startingPosition = (0, 0)
        }
      , control = Nothing
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , Browser.Events.onKeyDown (Decode.map KeyDown keyDecoder)
        , Browser.Events.onKeyUp (Decode.map KeyUp keyDecoder)
        ]

animationSpeed = 1 / 250


animatePlayer : Float -> PlayerBlock -> PlayerBlock
animatePlayer delta player =
    case player of
        PlayerBlock (Falling direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if newProgress >= 1 then
                    (PlayerBlock
                        (Lying direction)
                        ( case direction of
                            Up -> (x - 1, y)
                            Right -> (x, y + 1)
                            Left -> (x, y - 1)
                            Down -> (x + 1, y)
                        )
                    )
                else
                    PlayerBlock (Falling direction newProgress) (x, y)

        PlayerBlock (GettingUp direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if newProgress >= 1 then
                    PlayerBlock Standing (x, y)

                else
                    PlayerBlock (GettingUp direction newProgress) (x, y)

        PlayerBlock (Rolling direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if (newProgress >= 1) then
                      (case direction of
                          Left -> PlayerBlock (Lying Up) (x, y - 1)
                          Right -> PlayerBlock (Lying Up) (x, y + 1)
                          Up -> PlayerBlock (Lying Right) (x - 1, y)
                          Down -> PlayerBlock (Lying Right) (x + 1, y)
                      )

                else
                    PlayerBlock (Rolling direction newProgress) (x, y)

        a -> a


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Tick delta ->
            ({ model | player = model.player |> controlPlayer model.control |> animatePlayer delta }
            , Cmd.none
            )

        KeyDown key ->
            ( key
                |> toDirection
                |> Maybe.map (\direction -> { model | control = Just direction })
                |> Maybe.withDefault model
            , Cmd.none
            )

        KeyUp key ->
            ( if toDirection key == model.control then
                { model | control = Nothing }
              else
                model
            , Cmd.none
            )



keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string

toDirection : String -> Maybe Direction
toDirection string =
  case string of
        "ArrowLeft" ->
            Just Left

        "ArrowRight" ->
            Just Right

        "ArrowUp" ->
            Just Up

        "ArrowDown" ->
            Just Down

        _ ->
            Nothing

main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

view : Model -> Html msg
view { player, level } =
    let
        camera =
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.lookAt
                        { focalPoint = Point3d.origin
                        , eyePoint = Point3d.centimeters 20 10 15
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


playerEntity (PlayerBlock orientation (x, y)) =
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
       (case orientation of
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


           Falling Up progress ->
                block
                    |> Scene3d.rotateAround topAxis (Angle.degrees (progress * 90))

           Falling Right progress ->
                block
                    |> Scene3d.rotateAround rightAxis (Angle.degrees (progress * 90))

           Falling Down progress ->
                block
                    |> Scene3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

           Falling Left progress ->
                block
                    |> Scene3d.rotateAround leftAxis (Angle.degrees (progress * 90))

           GettingUp Up progress ->
                block
                    |> Scene3d.rotateAround bottomAxis (Angle.degrees ((1 - progress) * 90))

           GettingUp Right progress ->
                block
                    |> Scene3d.rotateAround leftAxis (Angle.degrees ((1 - progress) * 90))

           GettingUp Down progress ->
                block
                    |> Scene3d.rotateAround topAxis (Angle.degrees ((1 - progress) * 90))

           GettingUp Left progress ->
                block
                    |> Scene3d.rotateAround rightAxis (Angle.degrees ((1 - progress) * 90))

           Rolling Left progress ->
                block
                    |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                    |> Scene3d.translateIn Direction3d.x tileSize
                    |> Scene3d.rotateAround leftAxis (Angle.degrees (progress * 90))

           Rolling Right progress ->
                block
                    |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                    |> Scene3d.translateIn Direction3d.x tileSize
                    |> Scene3d.rotateAround rightAxis (Angle.degrees (progress * 90))

           Rolling Up progress ->
                block
                    |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                    |> Scene3d.translateIn Direction3d.negativeY tileSize
                    |> Scene3d.rotateAround topAxis (Angle.degrees (progress * 90))

           Rolling Down progress ->
                block
                    |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                    |> Scene3d.translateIn Direction3d.negativeY tileSize
                    |> Scene3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

       )
           |> Scene3d.translateBy
                (Vector3d.centimeters positionX positionY 0)





controlPlayer : Maybe Direction -> PlayerBlock -> PlayerBlock
controlPlayer maybeDirection (PlayerBlock orientation (x, y)) =
    maybeDirection
        |> Maybe.map
            (\direction ->
                case (orientation, direction) of
                    (Standing, fallDirection) ->
                        PlayerBlock (Falling fallDirection 0) (x, y)

                    -- Lying up
                    (Lying Up, Left) ->
                        PlayerBlock (Rolling Left 0) (x, y)

                    (Lying Up, Right) ->
                        PlayerBlock (Rolling Right 0) (x, y)

                    (Lying Up, Up) ->
                        PlayerBlock (GettingUp Up 0) (x - 2, y)

                    (Lying Up, Down) ->
                        PlayerBlock (GettingUp Down 0) (x + 1, y)

                    -- Lying right
                    (Lying Right, Up) ->
                        PlayerBlock (Rolling Up 0) (x, y)

                    (Lying Right, Down) ->
                        PlayerBlock (Rolling Down 0) (x, y)

                    (Lying Right, Left) ->
                        PlayerBlock (GettingUp Left 0) (x, y - 1)

                    (Lying Right, Right) ->
                        PlayerBlock (GettingUp Right 0) (x, y + 2)

                    -- Lying down
                    (Lying Down, Up) ->
                        PlayerBlock (GettingUp Up 0) (x - 1, y)

                    (Lying Down, Down) ->
                        PlayerBlock (GettingUp Down 0) (x + 2, y)

                    (Lying Down, Left) ->
                        PlayerBlock (Rolling Left 0) (x + 1, y)

                    (Lying Down, Right) ->
                        PlayerBlock (Rolling Right 0) (x + 1, y)

                    -- Lying left
                    (Lying Left, Up) ->
                        PlayerBlock (Rolling Up 0) (x, y - 1)

                    (Lying Left, Down) ->
                        PlayerBlock (Rolling Down 0) (x, y - 1)

                    (Lying Left, Left) ->
                        PlayerBlock (GettingUp Left 0) (x, y - 2)

                    (Lying Left, Right) ->
                        PlayerBlock (GettingUp Right 0) (x, y + 1)

                    -- Moving (ignore)
                    _ ->
                        PlayerBlock orientation (x, y)
            )
        |> Maybe.withDefault (PlayerBlock orientation (x, y))
