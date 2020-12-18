module Screen.Game exposing (Game, Msg, MsgOut(..), init, subscriptions, update, view)

import Angle
import Axis3d
import Block3d exposing (Block3d)
import Browser.Events
import Camera3d
import Direction3d
import Duration exposing (Duration)
import Html exposing (Html)
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
        }


type Msg
    = Tick Float
    | KeyDown String
    | KeyUp String


type MsgOut
    = NoOp
    | GameFinished


init : Game
init =
    Game
        { player = Player.init (Level.getStartingPosition LevelIndex.firstLevel)
        , level = LevelIndex.firstLevel
        , levelsLeft = LevelIndex.restLevels
        , control = Nothing
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
                updatedPlayer =
                    game.player
                        |> controlPlayer game.control
                        |> Player.update delta

                occupiedTiles =
                    updatedPlayer
                        |> Player.occupiedTiles
                        |> List.map (Level.getTileAt game.level)

                fail =
                    List.any ((==) Level.Empty) occupiedTiles

                success =
                    occupiedTiles == [ Level.Finish ]

                levelFinishAnimationComplete =
                    Player.hasSlidedIn updatedPlayer
            in
            if fail then
                ( Game { game | player = Player.init (Level.getStartingPosition game.level) }, NoOp )

            else if success then
                ( Game { game | player = Player.slideIn updatedPlayer }, NoOp )

            else if levelFinishAnimationComplete then
                case game.levelsLeft of
                    nextLevel :: rest ->
                        ( Game
                            { player = Player.init (Level.getStartingPosition nextLevel)
                            , level = nextLevel
                            , levelsLeft = rest
                            , control = Nothing
                            }
                        , NoOp
                        )

                    [] ->
                        ( Game game, GameFinished )

            else
                ( Game { game | player = updatedPlayer }, NoOp )

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


view : Game -> Html Msg
view (Game { player, level }) =
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
        { entities = [ Player.view player, Level.view level ]
        , camera = camera
        , upDirection = Direction3d.z
        , sunlightDirection = Direction3d.yz (Angle.degrees -120)
        , background = Scene3d.transparentBackground
        , clipDepth = Length.centimeters 1
        , shadows = False
        , dimensions = ( Pixels.int 400, Pixels.int 300 )
        }


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

        _ ->
            Nothing
