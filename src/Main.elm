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
import Level exposing (Level)
import Level.Index

type Player = Player BlockAnimationState (Int, Int)


type BlockAnimationState
    = Standing
    | Lying Direction
    | KnockingOver Direction Float
    | GettingUp Direction Float
    | Rolling Direction Float
    | SlideIn Float



type Direction
    = Up
    | Right
    | Left
    | Down


type Model
    = LevelScreen LevelScreenData
    | GameFinished


type alias LevelScreenData =
    { player: Player
    , level: Level
    , levelsLeft: List Level
    , control: Maybe Direction
    }

type Msg
    = Tick Float
    | KeyDown String
    | KeyUp String

tileSize = Length.centimeters 1


init : () -> (Model, Cmd Msg)
init flags =
    ( LevelScreen
          { player = Player Standing Level.Index.firstLevel.startingPosition
          , level = Level.Index.firstLevel
          , levelsLeft = Level.Index.restLevels
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


animatePlayer : Float -> Player -> Player
animatePlayer delta player =
    case player of
        Player (KnockingOver direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if newProgress >= 1 then
                    (Player
                        (Lying direction)
                        ( case direction of
                            Up -> (x - 1, y)
                            Right -> (x, y + 1)
                            Left -> (x, y - 1)
                            Down -> (x + 1, y)
                        )
                    )
                else
                    Player (KnockingOver direction newProgress) (x, y)

        Player (GettingUp direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if newProgress >= 1 then
                    Player Standing (x, y)

                else
                    Player (GettingUp direction newProgress) (x, y)

        Player (Rolling direction progress) (x, y) ->
            let
                newProgress = progress + delta * animationSpeed
            in
                if (newProgress >= 1) then
                      (case direction of
                          Left -> Player (Lying Up) (x, y - 1)
                          Right -> Player (Lying Up) (x, y + 1)
                          Up -> Player (Lying Right) (x - 1, y)
                          Down -> Player (Lying Right) (x + 1, y)
                      )

                else
                    Player (Rolling direction newProgress) (x, y)

        Player (SlideIn progress) (x, y) ->
            let
                newProgress = min (progress + delta * animationSpeed * 0.5) 1
            in
                Player (SlideIn newProgress) (x, y)

        a -> a


restartPlayer : Level -> Player
restartPlayer { startingPosition } = Player Standing startingPosition

getPlayerPosition : Player -> (Int, Int)
getPlayerPosition (Player _ position) =
    position

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case model of
        LevelScreen levelScreen ->
                case msg of
                    Tick delta ->
                        let
                            updatedPlayer = levelScreen.player |> controlPlayer levelScreen.control |> animatePlayer delta
                        in
                            if shouldAdvanceToNextLevel model then
                                (nextLevel model, Cmd.none)
                            else
                                ( LevelScreen
                                    { levelScreen | player =
                                        if shouldDie levelScreen.level updatedPlayer then
                                            restartPlayer levelScreen.level
                                        else if isLevelCompleted levelScreen then
                                            Player (SlideIn 0) (getPlayerPosition updatedPlayer)
                                        else
                                            updatedPlayer
                                    }
                                , Cmd.none
                                )

                    KeyDown key ->
                        ( key
                            |> toDirection
                            |> Maybe.map (\direction -> { levelScreen | control = Just direction })
                            |> Maybe.withDefault levelScreen
                            |> LevelScreen
                        , Cmd.none
                        )

                    KeyUp key ->
                        ( if toDirection key == levelScreen.control then
                            LevelScreen { levelScreen | control = Nothing }
                          else
                            LevelScreen levelScreen
                        , Cmd.none
                        )

        a -> (a, Cmd.none)



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
view model =
    case model of
        LevelScreen { player, level } ->
            let
                camera =
                    Camera3d.perspective
                        { viewpoint =
                            Viewpoint3d.lookAt
                                { focalPoint = Point3d.centimeters 5 5 0
                                , eyePoint = Point3d.centimeters 20 10 15
                                , upDirection = Direction3d.z
                                }
                        , verticalFieldOfView = Angle.degrees 30
                        }
            in
            Scene3d.sunny
                { entities = [ playerEntity player, levelEntity level ]
                , camera = camera
                , upDirection = Direction3d.z
                , sunlightDirection = Direction3d.yz (Angle.degrees -120)
                , background = Scene3d.transparentBackground
                , clipDepth = Length.centimeters 1
                , shadows = False
                , dimensions = ( Pixels.int 400, Pixels.int 300 )
                }

        GameFinished ->
            Html.div [] [Html.text "Congratulations!"]


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

levelEntity { tiles } =
    tiles
        |> Array.indexedMap
            ( \x row ->
                Array.indexedMap
                    ( \y tile ->
                      case tile of
                          Level.Floor ->
                            floorEntity Color.gray (x, y)

                          Level.Empty ->
                            Scene3d.nothing

                          Level.Finish ->
                            floorEntity Color.black (x, y)

                    )
                    row
                |> Array.toList
            )
        |> Array.toList
        |> List.concatMap identity
        |> Scene3d.group

floorEntity color (x, y) =
    let
        tileBorderSizeCm = tileSizeCm * 0.02
    in
      Scene3d.block
            ( Material.matte color )
            (
                Block3d.with
                    { x1 = Length.centimeters (tileSizeCm * toFloat x + tileBorderSizeCm)
                    , x2 = Length.centimeters (tileSizeCm * toFloat (x + 1) - tileBorderSizeCm)
                    , y1 = Length.centimeters (tileSizeCm * toFloat y + tileBorderSizeCm)
                    , y2 = Length.centimeters (tileSizeCm * toFloat (y + 1) - tileBorderSizeCm)
                    , z1 = Length.centimeters 0
                    , z2 = Length.centimeters (tileSizeCm * 0.1)
                    }
            )

playerEntity (Player orientation (x, y)) =
    let

        positionX = toFloat x * tileSizeCm
        positionY = toFloat y * tileSizeCm

        block =
            Scene3d.block
                ( Material.metal { baseColor = Color.orange, roughness = 2.5 } )
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


           KnockingOver Up progress ->
                block
                    |> Scene3d.rotateAround topAxis (Angle.degrees (progress * 90))

           KnockingOver Right progress ->
                block
                    |> Scene3d.rotateAround rightAxis (Angle.degrees (progress * 90))

           KnockingOver Down progress ->
                block
                    |> Scene3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

           KnockingOver Left progress ->
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

           SlideIn progress ->
                Scene3d.block
                    ( Material.metal { baseColor = Color.orange, roughness = 2.5 } )
                    (
                        Block3d.with
                            { x1 = Length.centimeters 0
                            , x2 = Length.centimeters playerWidth
                            , y1 = Length.centimeters 0
                            , y2 = Length.centimeters playerWidth
                            , z1 = Length.centimeters 0
                            , z2 = Length.centimeters (playerHeight - (progress * progress * 2))
                            }
                    )

       )
           |> Scene3d.translateBy
                (Vector3d.centimeters positionX positionY 0)





controlPlayer : Maybe Direction -> Player -> Player
controlPlayer maybeDirection (Player orientation (x, y)) =
    maybeDirection
        |> Maybe.map
            (\direction ->
                case (orientation, direction) of
                    (Standing, fallDirection) ->
                        Player (KnockingOver fallDirection 0) (x, y)

                    -- Lying up
                    (Lying Up, Left) ->
                        Player (Rolling Left 0) (x, y)

                    (Lying Up, Right) ->
                        Player (Rolling Right 0) (x, y)

                    (Lying Up, Up) ->
                        Player (GettingUp Up 0) (x - 2, y)

                    (Lying Up, Down) ->
                        Player (GettingUp Down 0) (x + 1, y)

                    -- Lying right
                    (Lying Right, Up) ->
                        Player (Rolling Up 0) (x, y)

                    (Lying Right, Down) ->
                        Player (Rolling Down 0) (x, y)

                    (Lying Right, Left) ->
                        Player (GettingUp Left 0) (x, y - 1)

                    (Lying Right, Right) ->
                        Player (GettingUp Right 0) (x, y + 2)

                    -- Lying down
                    (Lying Down, Up) ->
                        Player (GettingUp Up 0) (x - 1, y)

                    (Lying Down, Down) ->
                        Player (GettingUp Down 0) (x + 2, y)

                    (Lying Down, Left) ->
                        Player (Rolling Left 0) (x + 1, y)

                    (Lying Down, Right) ->
                        Player (Rolling Right 0) (x + 1, y)

                    -- Lying left
                    (Lying Left, Up) ->
                        Player (Rolling Up 0) (x, y - 1)

                    (Lying Left, Down) ->
                        Player (Rolling Down 0) (x, y - 1)

                    (Lying Left, Left) ->
                        Player (GettingUp Left 0) (x, y - 2)

                    (Lying Left, Right) ->
                        Player (GettingUp Right 0) (x, y + 1)

                    -- Moving (ignore)
                    _ ->
                        Player orientation (x, y)
            )
        |> Maybe.withDefault (Player orientation (x, y))

isLevelCompleted : LevelScreenData -> Bool
isLevelCompleted { level, player } =
    case player of
        Player Standing (x, y) ->
            Level.getTileAt level (x, y) == Level.Finish
        _ ->
            False


shouldAdvanceToNextLevel : Model -> Bool
shouldAdvanceToNextLevel model =
    case model of
        LevelScreen { player } ->
            case player of
                Player (SlideIn progress) _ -> progress >= 1
                _ -> False

        _ ->
            False

nextLevel : Model -> Model
nextLevel model =
    case model of
        LevelScreen { levelsLeft } ->
            (case List.head levelsLeft of
                Just level ->
                    LevelScreen
                        { player = Player Standing level.startingPosition
                        , level = level
                        , levelsLeft = List.drop 1 levelsLeft
                        , control = Nothing
                        }

                Nothing ->
                    GameFinished
            )

        a -> a


shouldDie : Level -> Player -> Bool
shouldDie level player =
    case player of
        Player Standing (x, y) -> Level.getTileAt level (x, y) == Level.Empty
        Player (Lying Left) (x, y) ->
            Level.getTileAt level (x, y - 1) == Level.Empty
            ||
            Level.getTileAt level (x, y) == Level.Empty

        Player (Lying Up) (x, y) ->
            Level.getTileAt level (x - 1, y) == Level.Empty
            ||
            Level.getTileAt level (x, y) == Level.Empty

        Player (Lying Right) (x, y) ->
            Level.getTileAt level (x, y) == Level.Empty
            ||
            Level.getTileAt level (x, y + 1) == Level.Empty

        Player (Lying Down) (x, y) ->
            Level.getTileAt level (x, y) == Level.Empty
            ||
            Level.getTileAt level (x + 1, y) == Level.Empty

        _ -> False
