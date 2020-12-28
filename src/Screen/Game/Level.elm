module Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData, getStartingPosition, getTileAt, restart, shiftTile, triggerActions, update, view)

import Angle exposing (Angle)
import Array exposing (Array)
import Axis3d
import Block3d
import Color exposing (Color)
import Dict exposing (Dict)
import Direction3d
import Length exposing (Length)
import Point3d
import Scene3d
import Scene3d.Material as Material
import Screen.Game.Constant as Constant
import Screen.Game.Direction exposing (Direction(..))
import Sound
import Vector3d


type LevelTile
    = Empty
    | Floor
    | RustyFloor
    | Finish
    | Bridge Direction Bool
    | Trigger Color (List TriggerAction)


type TriggerAction
    = ToggleBridge ( Int, Int )
    | CloseBridge ( Int, Int )
    | OpenBridge ( Int, Int )


type TileState
    = PushDown Length
    | BridgeState Bool Float


type Level
    = Level
        { tiles : Array (Array LevelTile)
        , tileStates : Dict ( Int, Int ) TileState
        , startingPosition : ( Int, Int )
        }


fromData : List (List LevelTile) -> ( Int, Int ) -> Level
fromData tiles startingPosition =
    Level
        { tiles =
            tiles
                |> List.map Array.fromList
                |> Array.fromList
        , tileStates = Dict.empty
        , startingPosition = startingPosition
        }


getStartingPosition : Level -> ( Int, Int )
getStartingPosition (Level { startingPosition }) =
    startingPosition


getTileAt : Level -> ( Int, Int ) -> LevelTile
getTileAt ((Level { tileStates }) as level) location =
    let
        originalTile =
            getTileAtInternal level location
    in
    case originalTile of
        Bridge _ initiallyClosed ->
            case Dict.get location tileStates of
                Just (BridgeState closed _) ->
                    if closed then
                        originalTile

                    else
                        Empty

                _ ->
                    if initiallyClosed then
                        originalTile

                    else
                        Empty

        a ->
            a


getTileAtInternal : Level -> ( Int, Int ) -> LevelTile
getTileAtInternal (Level { tiles }) ( x, y ) =
    Array.get x tiles
        |> Maybe.map (\row -> Array.get y row |> Maybe.withDefault Empty)
        |> Maybe.withDefault Empty


shiftTile : ( Int, Int ) -> Length -> Level -> Level
shiftTile location zOffset (Level level) =
    Level { level | tileStates = Dict.insert location (PushDown zOffset) level.tileStates }


triggerActions : List TriggerAction -> Level -> ( Level, Cmd a )
triggerActions actions level =
    List.foldl
        (\action ( levelAcc, cmdAcc ) ->
            (case action of
                ToggleBridge ( x, y ) ->
                    toggleBridge not ( x, y ) levelAcc

                CloseBridge ( x, y ) ->
                    toggleBridge (always True) ( x, y ) levelAcc

                OpenBridge ( x, y ) ->
                    toggleBridge (always False) ( x, y ) levelAcc
            )
                |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmdAcc, cmd ])
        )
        ( level, Cmd.none )
        actions


toggleBridge : (Bool -> Bool) -> ( Int, Int ) -> Level -> ( Level, Cmd a )
toggleBridge mapPreviousState ( x, y ) (Level level) =
    case Dict.get ( x, y ) level.tileStates of
        Just (BridgeState closed progress) ->
            ( Level { level | tileStates = Dict.insert ( x, y ) (BridgeState (mapPreviousState closed) progress) level.tileStates }
            , if mapPreviousState closed then
                Sound.playSound "bridge-close"

              else
                Sound.playSound "bridge-open"
            )

        _ ->
            let
                initiallyClosed =
                    case getTileAtInternal (Level level) ( x, y ) of
                        Bridge _ initValue ->
                            initValue

                        _ ->
                            False

                newClosed =
                    mapPreviousState initiallyClosed

                progress =
                    if newClosed then
                        0

                    else
                        1
            in
            ( Level { level | tileStates = Dict.insert ( x, y ) (BridgeState newClosed progress) level.tileStates }
            , if newClosed then
                Sound.playSound "bridge-close"

              else
                Sound.playSound "bridge-open"
            )


restart : Level -> Level
restart (Level level) =
    Level { level | tileStates = Dict.empty }


update : Float -> Level -> Level
update delta (Level level) =
    Level { level | tileStates = Dict.map (always (updateTileState delta)) level.tileStates }


updateTileState : Float -> TileState -> TileState
updateTileState delta tile =
    case tile of
        BridgeState True progress ->
            BridgeState True (min (progress + Constant.animationSpeed * delta) 1)

        BridgeState False progress ->
            BridgeState False (max (progress - Constant.animationSpeed * delta) 0)

        a ->
            a


view : Level -> Scene3d.Entity coordinates
view (Level { tiles, tileStates }) =
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

                            RustyFloor ->
                                floorEntity Color.lightOrange ( x, y )
                                    |> (case Dict.get ( x, y ) tileStates of
                                            Just (PushDown zOffset) ->
                                                Scene3d.translateIn Direction3d.negativeZ zOffset

                                            _ ->
                                                identity
                                       )

                            Trigger color _ ->
                                floorEntity color ( x, y )

                            Bridge openingDirection initiallyClosed ->
                                floorEntity Color.darkYellow ( x, y )
                                    |> (case
                                            Maybe.withDefault
                                                (BridgeState initiallyClosed
                                                    (if initiallyClosed then
                                                        1

                                                     else
                                                        0
                                                    )
                                                )
                                                (Dict.get ( x, y ) tileStates)
                                        of
                                            BridgeState _ progress ->
                                                let
                                                    axis =
                                                        case openingDirection of
                                                            Up ->
                                                                Axis3d.through (Point3d.centimeters (toFloat x * Constant.tileSizeCm) (toFloat y * Constant.tileSizeCm) -0.1) Direction3d.negativeY

                                                            Right ->
                                                                Axis3d.through (Point3d.centimeters (toFloat x * Constant.tileSizeCm) (toFloat (y + 1) * Constant.tileSizeCm) -0.1) Direction3d.negativeX

                                                            Down ->
                                                                Axis3d.through (Point3d.centimeters (toFloat (x + 1) * Constant.tileSizeCm) (toFloat y * Constant.tileSizeCm) -0.1) Direction3d.y

                                                            Left ->
                                                                Axis3d.through (Point3d.centimeters (toFloat x * Constant.tileSizeCm) (toFloat y * Constant.tileSizeCm) -0.1) Direction3d.x
                                                in
                                                Scene3d.rotateAround axis (Angle.degrees (-180 * (1 - progress)))

                                            _ ->
                                                identity
                                       )
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
            Constant.tileSizeCm * 0.02
    in
    Scene3d.block
        (Material.matte color)
        (Block3d.with
            { x1 = Length.centimeters (Constant.tileSizeCm * toFloat x + tileBorderSizeCm)
            , x2 = Length.centimeters (Constant.tileSizeCm * toFloat (x + 1) - tileBorderSizeCm)
            , y1 = Length.centimeters (Constant.tileSizeCm * toFloat y + tileBorderSizeCm)
            , y2 = Length.centimeters (Constant.tileSizeCm * toFloat (y + 1) - tileBorderSizeCm)
            , z1 = Length.centimeters (Constant.tileSizeCm * -0.1)
            , z2 = Length.centimeters 0
            }
        )
