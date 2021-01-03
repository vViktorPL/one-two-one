module Screen.Game exposing (Game, Msg, MsgOut(..), Stats, init, initStats, subscriptions, update, view)

import Angle
import Axis3d
import Block3d exposing (Block3d)
import Browser.Events
import Camera3d
import Direction3d
import Duration exposing (Duration)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events as Event
import Html.Lazy
import Json.Decode as Decode
import Length
import Pixels
import Point3d
import Scene3d
import Screen.Game.Direction as Direction exposing (Direction)
import Screen.Game.Level as Level exposing (Level)
import Screen.Game.Level.Index as LevelIndex
import Screen.Game.Player as Player exposing (Player)
import Sound
import Task
import Time
import Vector3d
import Viewpoint3d


type Game
    = Game
        { player : Player
        , level : Level
        , levelsLeft : List Level
        , currentLevelNumber : Int
        , stats : Stats
        , currentLevelTimestamp : Maybe Int
        , currentTimestamp : Int
        , control : Maybe Direction
        , mobile : Bool
        }


type alias Stats =
    { moves : Int
    , fails : Int
    , time : Int
    , continues : Int
    }


type Msg
    = AnimationTick Float
    | KeyDown String
    | KeyUp String
    | TimerTick Time.Posix
    | StartLevelTimer Time.Posix


type MsgOut
    = NoOp
    | SaveGame Int Stats
    | GameFinished Stats


getTimerSecs : Game -> Int
getTimerSecs (Game { stats, currentLevelTimestamp, currentTimestamp }) =
    case currentLevelTimestamp of
        Just startTimestamp ->
            stats.time + (currentTimestamp - startTimestamp)

        Nothing ->
            stats.time


initStats : Stats
initStats =
    { moves = 0
    , fails = 0
    , time = 0
    , continues = 0
    }


bumpFails : Stats -> Stats
bumpFails stats =
    { stats | fails = stats.fails + 1 }


init : Bool -> Int -> Stats -> ( Game, Cmd Msg )
init mobile levelStartIndex stats =
    let
        levels =
            (LevelIndex.firstLevel :: LevelIndex.restLevels)
                |> List.drop levelStartIndex

        ( level, levelsLeft ) =
            case levels of
                first :: rest ->
                    ( first, rest )

                _ ->
                    ( LevelIndex.firstLevel, LevelIndex.restLevels )
    in
    ( Game
        { player = Player.init (Level.getStartingPosition level)
        , level = level
        , levelsLeft = levelsLeft
        , currentLevelNumber = levelStartIndex + 1
        , stats = stats
        , currentLevelTimestamp = Nothing
        , currentTimestamp = 0
        , control = Nothing
        , mobile = mobile
        }
    , Task.perform StartLevelTimer Time.now
    )


controlPlayer : Maybe Direction -> Player -> Player
controlPlayer control player =
    case control of
        Just direction ->
            Player.move direction player

        Nothing ->
            player


updateTimeStats : Game -> Stats
updateTimeStats ((Game { stats }) as game) =
    { stats | time = getTimerSecs game }


update : Msg -> Game -> ( Game, Cmd Msg, MsgOut )
update msg (Game game) =
    case msg of
        TimerTick time ->
            ( Game { game | currentTimestamp = Time.posixToMillis time // 1000 }
            , Cmd.none
            , NoOp
            )

        StartLevelTimer time ->
            let
                timestamp =
                    Time.posixToMillis time // 1000
            in
            ( Game { game | currentLevelTimestamp = Just timestamp, currentTimestamp = timestamp }
            , Cmd.none
            , NoOp
            )

        AnimationTick delta ->
            let
                controlledPlayer =
                    controlPlayer game.control game.player

                lastStats =
                    game.stats

                updatedStats =
                    if controlledPlayer == game.player then
                        lastStats

                    else
                        { lastStats | moves = lastStats.moves + 1 }

                ( animatedPlayer, playerCmd ) =
                    controlledPlayer
                        |> Player.update delta game.level

                ( updatedPlayer, interactionMsg ) =
                    animatedPlayer
                        |> Player.interact game.level

                updatedLevel =
                    game.level
                        |> Level.update delta
            in
            case interactionMsg of
                Player.InternalUpdate ->
                    ( Game { game | player = updatedPlayer, level = updatedLevel, stats = updatedStats }, playerCmd, NoOp )

                Player.FinishedLevel ->
                    let
                        stats =
                            updateTimeStats (Game game)
                    in
                    case game.levelsLeft of
                        nextLevel :: rest ->
                            ( Game
                                { game
                                    | player = Player.init (Level.getStartingPosition nextLevel)
                                    , level = nextLevel
                                    , levelsLeft = rest
                                    , currentLevelNumber = game.currentLevelNumber + 1
                                    , currentLevelTimestamp = Nothing
                                    , stats = stats
                                    , control = Nothing
                                    , mobile = game.mobile
                                }
                            , Cmd.batch [ playerCmd, Task.perform StartLevelTimer Time.now ]
                            , SaveGame (game.currentLevelNumber + 1) stats
                            )

                        [] ->
                            ( Game { game | currentLevelTimestamp = Nothing }
                            , playerCmd
                            , GameFinished stats
                            )

                Player.PushDownTile zOffset ->
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level = Level.shiftTile (Player.getPosition updatedPlayer) zOffset game.level
                        }
                    , playerCmd
                    , NoOp
                    )

                Player.EmitSound filename ->
                    ( Game { game | player = updatedPlayer, level = updatedLevel }, Sound.playSound filename, NoOp )

                Player.TriggerActions actions ->
                    let
                        previousInteractionMsg =
                            game.player
                                |> Player.interact game.level
                                |> Tuple.second

                        ( actionUpdatedLevel, actionCommand ) =
                            case previousInteractionMsg of
                                Player.TriggerActions _ ->
                                    ( updatedLevel, playerCmd )

                                _ ->
                                    -- Trigger only if not trigged in last update already
                                    Level.triggerActions actions updatedLevel
                    in
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level = actionUpdatedLevel
                        }
                    , actionCommand
                    , NoOp
                    )

                Player.RestartedLevel ->
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level = Level.restart game.level
                            , stats = bumpFails game.stats
                        }
                    , playerCmd
                    , NoOp
                    )

        KeyDown " " ->
            ( Game { game | player = Player.toggleSelectedCube game.player }
            , Cmd.none
            , NoOp
            )

        KeyDown key ->
            ( key
                |> keyToDirection
                |> Maybe.map (\direction -> { game | control = Just direction })
                |> Maybe.withDefault game
                |> Game
            , Cmd.none
            , NoOp
            )

        KeyUp key ->
            ( if keyToDirection key == game.control then
                Game { game | control = Nothing }

              else
                Game game
            , Cmd.none
            , NoOp
            )


view : ( Int, Int ) -> Game -> Html Msg
view ( width, height ) ((Game { player, level, mobile, currentLevelNumber, stats }) as game) =
    let
        zoomOut =
            max (800 / toFloat width) 1

        camera =
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.orbitZ
                        { focalPoint =
                            if Level.isBigLevel level then
                                Player.centerPosition player

                            else
                                Point3d.centimeters 5 5 0
                        , azimuth = Angle.degrees 25
                        , elevation = Angle.degrees 45
                        , distance = Length.centimeters (25 * zoomOut)
                        }
                , verticalFieldOfView = Angle.degrees 30
                }

        statsString =
            "LVL_"
                ++ String.fromInt currentLevelNumber
                ++ " MOV_"
                ++ String.fromInt stats.moves
                ++ " ERR_"
                ++ String.fromInt stats.fails
                ++ " TIM_"
                ++ String.fromInt (getTimerSecs game)
    in
    Html.div []
        [ Html.div
            [ style "position" "absolute"
            , style "top" "0"
            , style "left" "0"
            , style "right" "0"
            , style "color" "white"
            , style "font-size" "25px"
            , style "text-align" "center"
            , style "white-space" "pre"
            ]
            [ Html.text
                (if not mobile && Player.isSplit player then
                    statsString ++ "\nPress spacebar to select another cube"

                 else
                    statsString
                )
            ]
        , Html.Lazy.lazy2
            (\playerModel levelModel ->
                Scene3d.sunny
                    { entities = [ Player.view playerModel, Level.view levelModel ]
                    , camera = camera
                    , upDirection = Direction3d.z
                    , sunlightDirection = Direction3d.xz (Angle.degrees -120)
                    , background = Scene3d.transparentBackground
                    , clipDepth = Length.centimeters 1
                    , shadows = True
                    , dimensions = ( Pixels.int width, Pixels.int height )
                    }
            )
            player
            level
        , if mobile then
            mobileControls player

          else
            Html.text ""
        ]


onTouchStart msg =
    Event.on "touchstart" (Decode.succeed msg)


onTouchEnd msg =
    Event.on "touchend" (Decode.succeed msg)


mobileControls : Player -> Html Msg
mobileControls player =
    Html.div
        [ style "position" "absolute"
        , style "right" "0"
        , style "bottom" "0"
        , style "width" "30vw"
        , style "height" "30vw"
        , style "font-size" "10vw"
        ]
        [ Html.div
            [ onTouchStart (KeyDown "ArrowUp")
            , onTouchEnd (KeyUp "ArrowUp")
            , style "position" "absolute"
            , style "top" "0"
            , style "left" "10vw"
            ]
            [ Html.text "⬆️️" ]
        , Html.div
            [ onTouchStart (KeyDown "ArrowLeft")
            , onTouchEnd (KeyUp "ArrowLeft")
            , style "position" "absolute"
            , style "top" "9vw"
            , style "left" "0"
            ]
            [ Html.text "⬅️" ]
        , Html.div
            [ onTouchStart (KeyDown "ArrowRight")
            , onTouchEnd (KeyUp "ArrowRight")
            , style "position" "absolute"
            , style "top" "9vw"
            , style "right" "0"
            ]
            [ Html.text "➡️️" ]
        , Html.div
            [ onTouchStart (KeyDown "ArrowDown")
            , onTouchEnd (KeyUp "ArrowDown")
            , style "position" "absolute"
            , style "bottom" "0"
            , style "left" "10vw"
            ]
            [ Html.text "⬇️️️" ]
        , Html.div
            [ onTouchStart (KeyDown " ")
            , style "display"
                (if Player.isSplit player then
                    "block"

                 else
                    "none"
                )
            , style "position" "absolute"
            , style "top" "9vw"
            , style "left" "10vw"
            , style "right" "9vw"
            ]
            [ Html.text "🔄" ]
        ]


subscriptions : Game -> Sub Msg
subscriptions game =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta AnimationTick
        , Time.every 500 TimerTick
        , Browser.Events.onKeyDown (Decode.map KeyDown keyDecoder)
        , Browser.Events.onKeyUp (Decode.map KeyUp keyDecoder)
        ]


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string


keyToDirection : String -> Maybe Direction
keyToDirection string =
    case string of
        "ArrowLeft" ->
            Just Direction.Left

        "ArrowRight" ->
            Just Direction.Right

        "ArrowUp" ->
            Just Direction.Up

        "ArrowDown" ->
            Just Direction.Down

        "w" ->
            Just Direction.Up

        "W" ->
            Just Direction.Up

        "a" ->
            Just Direction.Left

        "A" ->
            Just Direction.Left

        "d" ->
            Just Direction.Right

        "D" ->
            Just Direction.Right

        "s" ->
            Just Direction.Down

        "S" ->
            Just Direction.Down

        _ ->
            Nothing
