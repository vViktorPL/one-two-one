module Screen.Game.Player exposing (InteractionMsg(..), Player, centerPosition, fall, getPosition, init, interact, isSplit, move, toggleSelectedCube, update, view)

import Angle
import Axis3d
import Block3d exposing (Block3d)
import Color
import Cone3d
import Direction3d
import Length exposing (Length)
import Point3d exposing (Point3d)
import Scene3d
import Scene3d.Material as Material
import Screen.Game.Constant as Constant
import Screen.Game.Direction as Direction exposing (Direction)
import Screen.Game.Level as Level exposing (Level)
import Sound
import Vector3d


type Player
    = Cuboid BlockAnimationState ( Int, Int )
    | Cubes ( Cube, Cube )


type BlockAnimationState
    = Standing
    | Lying Direction
    | KnockingOver Direction Float
    | GettingUp Direction Float
    | Rolling Direction Float
    | SlideIn Float
    | FallingUnbalanced Direction Float
    | FallingInHorizontalOrientation Direction Float
    | FallingInVerticalOrientation { zOffset : Length, progress : Float }
    | FallingFromTheSky Float
    | FallingWithTheFloor Float


type Cube
    = Cube CubeAnimationState ( Int, Int )


type CubeAnimationState
    = Stable
    | Rotating Direction Float
    | Falling Float


type InteractionMsg
    = InternalUpdate
    | FinishedLevel
    | PushDownTile Length
    | RestartedLevel
    | TriggerActions (List Level.TriggerAction)
    | EmitSound String


init : ( Int, Int ) -> Player
init ( x, y ) =
    Cuboid (FallingFromTheSky 0) ( x, y )


initCubes : ( Int, Int ) -> ( Int, Int ) -> Player
initCubes position1 position2 =
    Cubes ( Cube Stable position1, Cube Stable position2 )


update : Float -> Level -> Player -> ( Player, Cmd msg )
update delta level player =
    case player of
        Cuboid (KnockingOver direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed

                newPlayer =
                    if newProgress >= 1 then
                        Cuboid
                            (Lying direction)
                            (case direction of
                                Direction.Up ->
                                    ( x - 1, y )

                                Direction.Right ->
                                    ( x, y + 1 )

                                Direction.Left ->
                                    ( x, y - 1 )

                                Direction.Down ->
                                    ( x + 1, y )
                            )

                    else
                        Cuboid (KnockingOver direction newProgress) ( x, y )
            in
            ( newPlayer
            , if newProgress < 1 || unstablePosition newPlayer level then
                Cmd.none

              else
                Sound.playSound "lay"
            )

        Cuboid (GettingUp direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed

                newPlayer =
                    if newProgress >= 1 then
                        Cuboid Standing ( x, y )

                    else
                        Cuboid (GettingUp direction newProgress) ( x, y )
            in
            ( newPlayer
            , if newProgress < 1 || unstablePosition newPlayer level then
                Cmd.none

              else
                Sound.playSound "stand"
            )

        Cuboid (Rolling direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed

                newPlayer =
                    if newProgress >= 1 then
                        case direction of
                            Direction.Left ->
                                Cuboid (Lying Direction.Up) ( x, y - 1 )

                            Direction.Right ->
                                Cuboid (Lying Direction.Up) ( x, y + 1 )

                            Direction.Up ->
                                Cuboid (Lying Direction.Right) ( x - 1, y )

                            Direction.Down ->
                                Cuboid (Lying Direction.Right) ( x + 1, y )

                    else
                        Cuboid (Rolling direction newProgress) ( x, y )
            in
            ( newPlayer
            , if newProgress < 1 || unstablePosition newPlayer level then
                Cmd.none

              else
                Sound.playSound "lay"
            )

        Cuboid (SlideIn progress) ( x, y ) ->
            let
                newProgress =
                    min (progress + delta * Constant.animationSpeed * 0.5) 1
            in
            ( Cuboid (SlideIn newProgress) ( x, y ), Cmd.none )

        Cuboid (FallingUnbalanced direction progress) ( x, y ) ->
            let
                newProgress =
                    min (progress + delta * Constant.animationSpeed) 1
            in
            if newProgress == 1 then
                ( Cuboid (FallingInVerticalOrientation { zOffset = Length.centimeters (0.5 * Constant.playerHeightCm), progress = 0 })
                    (case direction of
                        Direction.Left ->
                            ( x, y - 1 )

                        Direction.Right ->
                            ( x, y + 1 )

                        Direction.Down ->
                            ( x + 1, y )

                        Direction.Up ->
                            ( x - 1, y )
                    )
                , Cmd.none
                )

            else
                ( Cuboid (FallingUnbalanced direction newProgress) ( x, y ), Cmd.none )

        Cuboid (FallingInVerticalOrientation { zOffset, progress }) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            ( Cuboid (FallingInVerticalOrientation { zOffset = zOffset, progress = newProgress }) ( x, y ), Cmd.none )

        Cuboid (FallingInHorizontalOrientation direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            ( Cuboid (FallingInHorizontalOrientation direction newProgress) ( x, y ), Cmd.none )

        Cuboid (FallingFromTheSky progress) ( x, y ) ->
            let
                newProgress =
                    min (progress + delta * Constant.animationSpeed * 0.3) 1
            in
            if newProgress == 1 then
                ( Cuboid Standing ( x, y )
                , Sound.playSound "stand"
                )

            else
                ( Cuboid (FallingFromTheSky newProgress) ( x, y ), Cmd.none )

        Cuboid (FallingWithTheFloor progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            ( Cuboid (FallingWithTheFloor newProgress) ( x, y ), Cmd.none )

        Cubes ( Cube (Rotating direction progress) ( x, y ), anotherCube ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed

                targetPosition =
                    case direction of
                        Direction.Up ->
                            ( x - 1, y )

                        Direction.Down ->
                            ( x + 1, y )

                        Direction.Left ->
                            ( x, y - 1 )

                        Direction.Right ->
                            ( x, y + 1 )
            in
            if newProgress >= 1 then
                ( Cubes ( Cube Stable targetPosition, anotherCube )
                , Sound.playSound "stand"
                )

            else
                ( Cubes ( Cube (Rotating direction newProgress) ( x, y ), anotherCube )
                , Cmd.none
                )

        Cubes cubes ->
            ( cubes
                |> Tuple.mapBoth (cubeFallInteraction delta) (cubeFallInteraction delta)
                |> Cubes
            , Cmd.none
            )

        plr ->
            ( plr, Cmd.none )


cubeFallInteraction : Float -> Cube -> Cube
cubeFallInteraction delta cube =
    case cube of
        Cube (Falling progress) position ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            Cube (Falling newProgress) position

        _ ->
            cube


getBlocks : Player -> List (Block3d Length.Meters coordinates)
getBlocks player =
    case player of
        Cuboid orientation ( x, y ) ->
            let
                positionX =
                    toFloat x * Constant.tileSizeCm

                positionY =
                    toFloat y * Constant.tileSizeCm

                block =
                    Block3d.with
                        { x1 = Length.centimeters 0
                        , x2 = Length.centimeters Constant.playerWidthCm
                        , y1 = Length.centimeters 0
                        , y2 = Length.centimeters Constant.playerWidthCm
                        , z1 = Length.centimeters 0
                        , z2 = Length.centimeters Constant.playerHeightCm
                        }
            in
            (case orientation of
                -- +
                Standing ->
                    block

                -- |
                -- 0
                Lying Direction.Up ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.x Constant.tileSize

                -- 0-
                Lying Direction.Right ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeY Constant.tileSize

                -- 0
                -- |
                Lying Direction.Down ->
                    block
                        |> Block3d.rotateAround bottomAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeX Constant.tileSize

                -- -0
                Lying Direction.Left ->
                    block
                        |> Block3d.rotateAround leftAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.y Constant.tileSize

                KnockingOver Direction.Up progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees (progress * 90))

                KnockingOver Direction.Right progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees (progress * 90))

                KnockingOver Direction.Down progress ->
                    block
                        |> Block3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

                KnockingOver Direction.Left progress ->
                    block
                        |> Block3d.rotateAround leftAxis (Angle.degrees (progress * 90))

                GettingUp Direction.Up progress ->
                    block
                        |> Block3d.rotateAround bottomAxis (Angle.degrees ((1 - progress) * 90))

                GettingUp Direction.Right progress ->
                    block
                        |> Block3d.rotateAround leftAxis (Angle.degrees ((1 - progress) * 90))

                GettingUp Direction.Down progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees ((1 - progress) * 90))

                GettingUp Direction.Left progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees ((1 - progress) * 90))

                Rolling Direction.Left progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.x Constant.tileSize
                        |> Block3d.rotateAround leftAxis (Angle.degrees (progress * 90))

                Rolling Direction.Right progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.x Constant.tileSize
                        |> Block3d.rotateAround rightAxis (Angle.degrees (progress * 90))

                Rolling Direction.Up progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeY Constant.tileSize
                        |> Block3d.rotateAround topAxis (Angle.degrees (progress * 90))

                Rolling Direction.Down progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeY Constant.tileSize
                        |> Block3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

                SlideIn progress ->
                    Block3d.with
                        { x1 = Length.centimeters 0
                        , x2 = Length.centimeters Constant.playerWidthCm
                        , y1 = Length.centimeters 0
                        , y2 = Length.centimeters Constant.playerWidthCm
                        , z1 = Length.centimeters 0
                        , z2 = Length.centimeters (Constant.playerHeightCm - (progress * progress * 2))
                        }

                FallingUnbalanced Direction.Left progress ->
                    block
                        |> Block3d.rotateAround leftAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.y Constant.tileSize
                        |> Block3d.rotateAround leftAxis (Angle.degrees (90 * progress))

                FallingUnbalanced Direction.Right progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeY Constant.tileSize
                        |> Block3d.rotateAround rightAxis (Angle.degrees (90 * progress))

                FallingUnbalanced Direction.Up progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.x Constant.tileSize
                        |> Block3d.rotateAround topAxis (Angle.degrees (90 * progress))

                FallingUnbalanced Direction.Down progress ->
                    block
                        |> Block3d.rotateAround bottomAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeX Constant.tileSize
                        |> Block3d.rotateAround bottomAxis (Angle.degrees (90 * progress))

                FallingInVerticalOrientation { zOffset, progress } ->
                    block
                        |> Block3d.translateIn Direction3d.negativeZ zOffset
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

                FallingInHorizontalOrientation Direction.Left progress ->
                    block
                        |> Block3d.rotateAround leftAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.y Constant.tileSize
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

                FallingInHorizontalOrientation Direction.Up progress ->
                    block
                        |> Block3d.rotateAround topAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.x Constant.tileSize
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

                FallingInHorizontalOrientation Direction.Right progress ->
                    block
                        |> Block3d.rotateAround rightAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeY Constant.tileSize
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

                FallingInHorizontalOrientation Direction.Down progress ->
                    block
                        |> Block3d.rotateAround bottomAxis (Angle.degrees 90)
                        |> Block3d.translateIn Direction3d.negativeX Constant.tileSize
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

                FallingFromTheSky progress ->
                    block
                        |> Block3d.translateIn Direction3d.z (Length.centimeters ((1 - progress) * 10))

                FallingWithTheFloor progress ->
                    block
                        |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)
            )
                |> Block3d.translateBy
                    (Vector3d.centimeters positionX positionY 0)
                |> List.singleton

        Cubes ( cube1, cube2 ) ->
            [ cubeToBlock cube1
            , cubeToBlock cube2
            ]


view : Player -> Scene3d.Entity coordinates
view player =
    let
        blocks =
            List.map
                (Scene3d.blockWithShadow (Material.metal { baseColor = Color.orange, roughness = 2.5 }))
                (getBlocks player)
    in
    case player of
        Cuboid _ _ ->
            Scene3d.group blocks

        Cubes ( selectedCube, _ ) ->
            Scene3d.group (viewSelectedCubeMarker selectedCube :: blocks)


viewSelectedCubeMarker : Cube -> Scene3d.Entity coordinates
viewSelectedCubeMarker (Cube state ( x, y )) =
    let
        ( offsetX, offsetY ) =
            case state of
                Rotating Direction.Up progress ->
                    ( -progress, 0 )

                Rotating Direction.Down progress ->
                    ( progress, 0 )

                Rotating Direction.Left progress ->
                    ( 0, -progress )

                Rotating Direction.Right progress ->
                    ( 0, progress )

                _ ->
                    ( 0, 0 )

        positionX =
            toFloat x + 0.5 + offsetX * Constant.tileSizeCm

        positionY =
            toFloat y + 0.5 + offsetY * Constant.tileSizeCm
    in
    Scene3d.cone
        (Material.color Color.red)
        (Cone3d.along Axis3d.z
            { base = Length.centimeters (Constant.tileSizeCm * 1.5)
            , tip = Length.centimeters (Constant.tileSizeCm * 1.2)
            , radius = Length.centimeters (Constant.tileSizeCm * 0.1)
            }
        )
        |> Scene3d.translateBy
            (Vector3d.centimeters positionX positionY 0)


cubeToBlock : Cube -> Block3d Length.Meters coordinates
cubeToBlock (Cube state ( x, y )) =
    let
        positionX =
            toFloat x * Constant.tileSizeCm

        positionY =
            toFloat y * Constant.tileSizeCm

        cube =
            Block3d.with
                { x1 = Length.centimeters 0
                , x2 = Length.centimeters Constant.playerWidthCm
                , y1 = Length.centimeters 0
                , y2 = Length.centimeters Constant.playerWidthCm
                , z1 = Length.centimeters 0
                , z2 = Length.centimeters Constant.playerWidthCm
                }
    in
    (case state of
        Stable ->
            cube

        Rotating Direction.Up progress ->
            cube
                |> Block3d.rotateAround topAxis (Angle.degrees (90 * progress))

        Rotating Direction.Down progress ->
            cube
                |> Block3d.rotateAround bottomAxis (Angle.degrees (90 * progress))

        Rotating Direction.Right progress ->
            cube
                |> Block3d.rotateAround rightAxis (Angle.degrees (90 * progress))

        Rotating Direction.Left progress ->
            cube
                |> Block3d.rotateAround leftAxis (Angle.degrees (90 * progress))

        Falling progress ->
            cube
                |> Block3d.translateIn Direction3d.negativeZ (Length.centimeters progress)
    )
        |> Block3d.translateBy
            (Vector3d.centimeters positionX positionY 0)


topAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.negativeY


rightAxis =
    Axis3d.through (Point3d.centimeters 0 Constant.playerWidthCm 0) Direction3d.negativeX


bottomAxis =
    Axis3d.through (Point3d.centimeters Constant.playerWidthCm 0 0) Direction3d.y


leftAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.x


toggleSelectedCube : Player -> Player
toggleSelectedCube player =
    case player of
        Cubes ( Cube Stable previouslySelectedCubePosition, anotherCube ) ->
            Cubes ( anotherCube, Cube Stable previouslySelectedCubePosition )

        _ ->
            player


move : Direction -> Player -> Player
move direction player =
    case player of
        Cuboid orientation ( x, y ) ->
            case ( orientation, direction ) of
                ( Standing, fallDirection ) ->
                    Cuboid (KnockingOver fallDirection 0) ( x, y )

                -- Lying Up
                ( Lying Direction.Up, Direction.Left ) ->
                    Cuboid (Rolling Direction.Left 0) ( x, y )

                ( Lying Direction.Up, Direction.Right ) ->
                    Cuboid (Rolling Direction.Right 0) ( x, y )

                ( Lying Direction.Up, Direction.Up ) ->
                    Cuboid (GettingUp Direction.Up 0) ( x - 2, y )

                ( Lying Direction.Up, Direction.Down ) ->
                    Cuboid (GettingUp Direction.Down 0) ( x + 1, y )

                -- Lying Right
                ( Lying Direction.Right, Direction.Up ) ->
                    Cuboid (Rolling Direction.Up 0) ( x, y )

                ( Lying Direction.Right, Direction.Down ) ->
                    Cuboid (Rolling Direction.Down 0) ( x, y )

                ( Lying Direction.Right, Direction.Left ) ->
                    Cuboid (GettingUp Direction.Left 0) ( x, y - 1 )

                ( Lying Direction.Right, Direction.Right ) ->
                    Cuboid (GettingUp Direction.Right 0) ( x, y + 2 )

                -- Lying Down
                ( Lying Direction.Down, Direction.Up ) ->
                    Cuboid (GettingUp Direction.Up 0) ( x - 1, y )

                ( Lying Direction.Down, Direction.Down ) ->
                    Cuboid (GettingUp Direction.Down 0) ( x + 2, y )

                ( Lying Direction.Down, Direction.Left ) ->
                    Cuboid (Rolling Direction.Left 0) ( x + 1, y )

                ( Lying Direction.Down, Direction.Right ) ->
                    Cuboid (Rolling Direction.Right 0) ( x + 1, y )

                -- Lying Left
                ( Lying Direction.Left, Direction.Up ) ->
                    Cuboid (Rolling Direction.Up 0) ( x, y - 1 )

                ( Lying Direction.Left, Direction.Down ) ->
                    Cuboid (Rolling Direction.Down 0) ( x, y - 1 )

                ( Lying Direction.Left, Direction.Left ) ->
                    Cuboid (GettingUp Direction.Left 0) ( x, y - 2 )

                ( Lying Direction.Left, Direction.Right ) ->
                    Cuboid (GettingUp Direction.Right 0) ( x, y + 1 )

                -- Player already in motion (ignore)
                _ ->
                    Cuboid orientation ( x, y )

        Cubes ( Cube Stable ( x, y ), anotherCube ) ->
            Cubes ( Cube (Rotating direction 0) ( x, y ), anotherCube )

        _ ->
            player


getPosition : Player -> ( Int, Int )
getPosition player =
    case player of
        Cuboid _ position ->
            position

        Cubes ( Cube _ position, _ ) ->
            position


fall : Maybe Direction -> Player -> Player
fall unbalancedDirection player =
    case player of
        Cubes ( Cube _ ( x, y ), anotherCube ) ->
            Cubes ( Cube (Falling 0) ( x, y ), anotherCube )

        Cuboid state ( x, y ) ->
            case ( unbalancedDirection, state ) of
                ( _, Standing ) ->
                    Cuboid (FallingInVerticalOrientation { zOffset = Length.centimeters 0, progress = 0 }) ( x, y )

                ( Just Direction.Left, Lying Direction.Left ) ->
                    Cuboid (FallingUnbalanced Direction.Left 0) ( x, y )

                ( Just Direction.Left, Lying Direction.Right ) ->
                    Cuboid (FallingUnbalanced Direction.Left 0) ( x, y + 1 )

                ( Just Direction.Right, Lying Direction.Left ) ->
                    Cuboid (FallingUnbalanced Direction.Right 0) ( x, y + 1 )

                ( Just Direction.Right, Lying Direction.Right ) ->
                    Cuboid (FallingUnbalanced Direction.Right 0) ( x, y )

                ( Just Direction.Up, Lying Direction.Up ) ->
                    Cuboid (FallingUnbalanced Direction.Up 0) ( x, y )

                ( Just Direction.Up, Lying Direction.Down ) ->
                    Cuboid (FallingUnbalanced Direction.Up 0) ( x + 1, y )

                ( Just Direction.Down, Lying Direction.Up ) ->
                    Cuboid (FallingUnbalanced Direction.Down 0) ( x - 1, y )

                ( Just Direction.Down, Lying Direction.Down ) ->
                    Cuboid (FallingUnbalanced Direction.Down 0) ( x, y )

                ( Nothing, Lying direction ) ->
                    Cuboid (FallingInHorizontalOrientation direction 0) ( x, y )

                _ ->
                    Cuboid state ( x, y )


occupiedPositions : Player -> List ( Int, Int )
occupiedPositions player =
    case player of
        Cuboid Standing ( x, y ) ->
            [ ( x, y ) ]

        Cuboid (Lying Direction.Left) ( x, y ) ->
            [ ( x, y - 1 ), ( x, y ) ]

        Cuboid (Lying Direction.Up) ( x, y ) ->
            [ ( x - 1, y ), ( x, y ) ]

        Cuboid (Lying Direction.Right) ( x, y ) ->
            [ ( x, y ), ( x, y + 1 ) ]

        Cuboid (Lying Direction.Down) ( x, y ) ->
            [ ( x, y ), ( x + 1, y ) ]

        Cubes ( cube1, cube2 ) ->
            [ cube1, cube2 ]
                |> List.filterMap
                    (\cube ->
                        case cube of
                            Cube Stable ( x, y ) ->
                                Just ( x, y )

                            _ ->
                                Nothing
                    )

        _ ->
            []


occupiedTiles : Player -> Level -> List Level.LevelTile
occupiedTiles player level =
    player
        |> occupiedPositions
        |> List.map (Level.getTileAt level)


unstablePosition : Player -> Level -> Bool
unstablePosition player level =
    occupiedTiles player level
        |> List.any ((==) Level.Empty)


interact : Level -> Player -> ( Player, InteractionMsg )
interact level player =
    let
        playerOccupiedTiles =
            occupiedTiles player level
    in
    case player of
        Cubes ( Cube selectedCubeState ( x1, y1 ), Cube _ ( x2, y2 ) ) ->
            let
                dX =
                    abs (x1 - x2)

                dY =
                    abs (y1 - y2)
            in
            if List.any ((==) Level.Empty) playerOccupiedTiles then
                -- Cube fall
                ( fall Nothing player, EmitSound "fall" )

            else if dX == 1 && dY == 0 then
                -- Merge cubes into cuboid (lying up or down)
                ( Cuboid (Lying Direction.Down) ( min x1 x2, y1 ), EmitSound "bridge-open" )

            else if dX == 0 && dY == 1 then
                -- Merge cubes into cuboid (lying right or left)
                ( Cuboid (Lying Direction.Right) ( x1, min y1 y2 ), EmitSound "bridge-open" )

            else
                case selectedCubeState of
                    Falling progress ->
                        if progress >= 30 then
                            ( init (Level.getStartingPosition level), RestartedLevel )

                        else
                            ( player, InternalUpdate )

                    _ ->
                        ( player, InternalUpdate )

        Cuboid state ( x, y ) ->
            case ( playerOccupiedTiles, state ) of
                -- Falling off the stage
                ( [ Level.Empty ], _ ) ->
                    ( fall Nothing player, EmitSound "fall" )

                ( [ Level.Empty, Level.Empty ], _ ) ->
                    ( fall Nothing player, EmitSound "fall" )

                ( [ Level.Empty, _ ], Lying Direction.Left ) ->
                    ( fall (Just Direction.Left) player, EmitSound "fall" )

                ( [ Level.Empty, _ ], Lying Direction.Right ) ->
                    ( fall (Just Direction.Left) player, EmitSound "fall" )

                ( [ Level.Empty, _ ], Lying Direction.Up ) ->
                    ( fall (Just Direction.Up) player, EmitSound "fall" )

                ( [ Level.Empty, _ ], Lying Direction.Down ) ->
                    ( fall (Just Direction.Up) player, EmitSound "fall" )

                ( [ _, Level.Empty ], Lying Direction.Left ) ->
                    ( fall (Just Direction.Right) player, EmitSound "fall" )

                ( [ _, Level.Empty ], Lying Direction.Right ) ->
                    ( fall (Just Direction.Right) player, EmitSound "fall" )

                ( [ _, Level.Empty ], Lying Direction.Up ) ->
                    ( fall (Just Direction.Down) player, EmitSound "fall" )

                ( [ _, Level.Empty ], Lying Direction.Down ) ->
                    ( fall (Just Direction.Down) player, EmitSound "fall" )

                -- Stomp on rusty tile
                ( [ Level.RustyFloor ], Standing ) ->
                    ( Cuboid (FallingWithTheFloor 0) ( x, y ), EmitSound "break-tile" )

                ( [], FallingWithTheFloor progress ) ->
                    if progress >= 30 then
                        ( init (Level.getStartingPosition level), RestartedLevel )

                    else
                        ( player, PushDownTile (Length.centimeters progress) )

                -- Success
                ( [ Level.Finish ], _ ) ->
                    ( Cuboid (SlideIn 0) ( x, y ), EmitSound "slide-in" )

                ( [], SlideIn progress ) ->
                    ( player
                    , if progress >= 1 then
                        FinishedLevel

                      else
                        InternalUpdate
                    )

                -- Restart
                ( [], FallingInHorizontalOrientation _ progress ) ->
                    if progress >= 30 then
                        ( init (Level.getStartingPosition level), RestartedLevel )

                    else
                        ( player, InternalUpdate )

                ( [], FallingInVerticalOrientation { progress } ) ->
                    if progress >= 30 then
                        ( init (Level.getStartingPosition level), RestartedLevel )

                    else
                        ( player, InternalUpdate )

                -- Trigger activation
                ( [ Level.Trigger _ actions, _ ], Lying _ ) ->
                    ( handlePlayerActions actions player, TriggerActions actions )

                ( [ _, Level.Trigger _ actions ], Lying _ ) ->
                    ( handlePlayerActions actions player, TriggerActions actions )

                ( [ Level.Trigger _ actions ], Standing ) ->
                    ( handlePlayerActions actions player, TriggerActions actions )

                -- Nothing to be done
                _ ->
                    ( player, InternalUpdate )


handlePlayerActions : List Level.TriggerAction -> Player -> Player
handlePlayerActions actions player =
    List.foldl
        (\action playerAcc ->
            case action of
                Level.SplitToCubes position1 position2 ->
                    initCubes position1 position2

                _ ->
                    player
        )
        player
        actions


isSplit : Player -> Bool
isSplit player =
    case player of
        Cubes _ ->
            True

        _ ->
            False


centerPosition : Player -> Point3d Length.Meters coordinates
centerPosition player =
    case getBlocks player of
        [ block ] ->
            Block3d.centerPoint block

        [ selectedCube, _ ] ->
            Block3d.centerPoint selectedCube

        _ ->
            Point3d.origin
