module Screen.Game exposing (Game, Msg, MsgOut(..), init, subscriptions, update, view)

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
import Json.Decode as Decode
import Length
import Pixels
import Point3d
import Scene3d
import Screen.Game.Direction as Direction exposing (Direction)
import Screen.Game.Level as Level exposing (Level)
import Screen.Game.Level.Index as LevelIndex
import Screen.Game.Player as Player exposing (Player)
import Vector3d
import Viewpoint3d


type Game
    = Game
        { player : Player
        , level : Level
        , levelsLeft : List Level
        , control : Maybe Direction
        , mobile : Bool
        }


type Msg
    = Tick Float
    | KeyDown String
    | KeyUp String


type MsgOut
    = NoOp
    | SaveGame Int
    | GameFinished


init : Bool -> Int -> Game
init mobile levelStartIndex =
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
    Game
        { player = Player.init (Level.getStartingPosition LevelIndex.firstLevel)
        , level = level
        , levelsLeft = levelsLeft
        , control = Nothing
        , mobile = mobile
        }


controlPlayer : Maybe Direction -> Player -> Player
controlPlayer control player =
    case control of
        Just direction ->
            Player.move direction player

        Nothing ->
            player


update : Msg -> Game -> ( Game, MsgOut )
update msg (Game game) =
    case msg of
        Tick delta ->
            let
                ( updatedPlayer, interactionMsg ) =
                    game.player
                        |> controlPlayer game.control
                        |> Player.update delta
                        |> Player.interact game.level

                updatedLevel =
                    game.level
                        |> Level.update delta
            in
            case interactionMsg of
                Player.InternalUpdate ->
                    ( Game { game | player = updatedPlayer, level = updatedLevel }, NoOp )

                Player.FinishedLevel ->
                    case game.levelsLeft of
                        nextLevel :: rest ->
                            ( Game
                                { player = Player.init (Level.getStartingPosition nextLevel)
                                , level = nextLevel
                                , levelsLeft = rest
                                , control = Nothing
                                , mobile = game.mobile
                                }
                            , SaveGame (List.length LevelIndex.restLevels - List.length rest)
                            )

                        [] ->
                            ( Game game, GameFinished )

                Player.PushDownTile zOffset ->
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level = Level.shiftTile (Player.getPosition updatedPlayer) zOffset game.level
                        }
                    , NoOp
                    )

                Player.TriggerActions actions ->
                    let
                        previousInteractionMsg =
                            game.player
                                |> Player.interact game.level
                                |> Tuple.second
                    in
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level =
                                case previousInteractionMsg of
                                    Player.TriggerActions _ ->
                                        updatedLevel

                                    _ ->
                                        -- Trigger only if not trigged in last update already
                                        Level.triggerActions actions updatedLevel
                        }
                    , NoOp
                    )

                Player.RestartedLevel ->
                    ( Game
                        { game
                            | player = updatedPlayer
                            , level = Level.restart game.level
                        }
                    , NoOp
                    )

        KeyDown key ->
            ( key
                |> keyToDirection
                |> Maybe.map (\direction -> { game | control = Just direction })
                |> Maybe.withDefault game
                |> Game
            , NoOp
            )

        KeyUp key ->
            ( if keyToDirection key == game.control then
                Game { game | control = Nothing }

              else
                Game game
            , NoOp
            )


view : ( Int, Int ) -> Game -> Html Msg
view ( width, height ) (Game { player, level, mobile }) =
    let
        zoomOut =
            max (800 / toFloat width) 1

        camera =
            Camera3d.perspective
                { viewpoint =
                    Viewpoint3d.orbitZ
                        { focalPoint = Point3d.centimeters 5 5 0
                        , azimuth = Angle.degrees 25
                        , elevation = Angle.degrees 45
                        , distance = Length.centimeters (25 * zoomOut)
                        }
                , verticalFieldOfView = Angle.degrees 30
                }
    in
    Html.div []
        [ Scene3d.sunny
            { entities = [ Player.view player, Level.view level ]
            , camera = camera
            , upDirection = Direction3d.z
            , sunlightDirection = Direction3d.yz (Angle.degrees -120)
            , background = Scene3d.transparentBackground
            , clipDepth = Length.centimeters 1
            , shadows = False
            , dimensions = ( Pixels.int width, Pixels.int height )
            }
        , if mobile then
            mobileControls

          else
            Html.text ""
        ]


onTouchStart msg =
    Event.on "touchstart" (Decode.succeed msg)


onTouchEnd msg =
    Event.on "touchend" (Decode.succeed msg)


mobileControls : Html Msg
mobileControls =
    Html.div
        [ style "position" "absolute"
        , style "right" "0"
        , style "bottom" "0"
        , style "width" "30vw"
        , style "height" "30vw"
        , style "font-size" "10vw"
        , style "user-select" "none"
        , style "-webkit-user-select" "none"
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
        ]


subscriptions : Game -> Sub Msg
subscriptions game =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
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
