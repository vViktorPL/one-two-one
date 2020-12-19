module Screen.Game.Player exposing (Player, fall, getPosition, hasFelt, hasSlidedIn, init, lyingDirection, move, occupiedTiles, slideIn, update, view)

import Angle
import Axis3d
import Block3d
import Color
import Direction3d
import Length exposing (Length)
import Point3d
import Scene3d
import Scene3d.Material as Material
import Screen.Game.Constant as Constant
import Screen.Game.Direction as Direction exposing (Direction)
import Vector3d


type Player
    = Player BlockAnimationState ( Int, Int )


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


init : ( Int, Int ) -> Player
init ( x, y ) =
    Player Standing ( x, y )


update : Float -> Player -> Player
update delta player =
    case player of
        Player (KnockingOver direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed
            in
            if newProgress >= 1 then
                Player
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
                Player (KnockingOver direction newProgress) ( x, y )

        Player (GettingUp direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed
            in
            if newProgress >= 1 then
                Player Standing ( x, y )

            else
                Player (GettingUp direction newProgress) ( x, y )

        Player (Rolling direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed
            in
            if newProgress >= 1 then
                case direction of
                    Direction.Left ->
                        Player (Lying Direction.Up) ( x, y - 1 )

                    Direction.Right ->
                        Player (Lying Direction.Up) ( x, y + 1 )

                    Direction.Up ->
                        Player (Lying Direction.Right) ( x - 1, y )

                    Direction.Down ->
                        Player (Lying Direction.Right) ( x + 1, y )

            else
                Player (Rolling direction newProgress) ( x, y )

        Player (SlideIn progress) ( x, y ) ->
            let
                newProgress =
                    min (progress + delta * Constant.animationSpeed * 0.5) 1
            in
            Player (SlideIn newProgress) ( x, y )

        Player (FallingUnbalanced direction progress) ( x, y ) ->
            let
                newProgress =
                    min (progress + delta * Constant.animationSpeed) 1
            in
            if newProgress == 1 then
                Player (FallingInVerticalOrientation { zOffset = Length.centimeters (0.5 * Constant.playerHeightCm), progress = 0 })
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

            else
                Player (FallingUnbalanced direction newProgress) ( x, y )

        Player (FallingInVerticalOrientation { zOffset, progress }) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            Player (FallingInVerticalOrientation { zOffset = zOffset, progress = newProgress }) ( x, y )

        Player (FallingInHorizontalOrientation direction progress) ( x, y ) ->
            let
                newProgress =
                    progress + delta * Constant.animationSpeed * min (progress + 1) 5
            in
            Player (FallingInHorizontalOrientation direction newProgress) ( x, y )

        a ->
            a


view : Player -> Scene3d.Entity coordinates
view (Player orientation ( x, y )) =
    let
        positionX =
            toFloat x * Constant.tileSizeCm

        positionY =
            toFloat y * Constant.tileSizeCm

        block =
            Scene3d.block
                (Material.metal { baseColor = Color.orange, roughness = 2.5 })
                (Block3d.with
                    { x1 = Length.centimeters 0
                    , x2 = Length.centimeters Constant.playerWidthCm
                    , y1 = Length.centimeters 0
                    , y2 = Length.centimeters Constant.playerWidthCm
                    , z1 = Length.centimeters 0
                    , z2 = Length.centimeters Constant.playerHeightCm
                    }
                )
    in
    (case orientation of
        -- +
        Standing ->
            block

        -- |
        -- 0
        Lying Direction.Up ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.x Constant.tileSize

        -- 0-
        Lying Direction.Right ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeY Constant.tileSize

        -- 0
        -- |
        Lying Direction.Down ->
            block
                |> Scene3d.rotateAround bottomAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeX Constant.tileSize

        -- -0
        Lying Direction.Left ->
            block
                |> Scene3d.rotateAround leftAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.y Constant.tileSize

        KnockingOver Direction.Up progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees (progress * 90))

        KnockingOver Direction.Right progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees (progress * 90))

        KnockingOver Direction.Down progress ->
            block
                |> Scene3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

        KnockingOver Direction.Left progress ->
            block
                |> Scene3d.rotateAround leftAxis (Angle.degrees (progress * 90))

        GettingUp Direction.Up progress ->
            block
                |> Scene3d.rotateAround bottomAxis (Angle.degrees ((1 - progress) * 90))

        GettingUp Direction.Right progress ->
            block
                |> Scene3d.rotateAround leftAxis (Angle.degrees ((1 - progress) * 90))

        GettingUp Direction.Down progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees ((1 - progress) * 90))

        GettingUp Direction.Left progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees ((1 - progress) * 90))

        Rolling Direction.Left progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.x Constant.tileSize
                |> Scene3d.rotateAround leftAxis (Angle.degrees (progress * 90))

        Rolling Direction.Right progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.x Constant.tileSize
                |> Scene3d.rotateAround rightAxis (Angle.degrees (progress * 90))

        Rolling Direction.Up progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeY Constant.tileSize
                |> Scene3d.rotateAround topAxis (Angle.degrees (progress * 90))

        Rolling Direction.Down progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeY Constant.tileSize
                |> Scene3d.rotateAround bottomAxis (Angle.degrees (progress * 90))

        SlideIn progress ->
            Scene3d.block
                (Material.metal { baseColor = Color.orange, roughness = 2.5 })
                (Block3d.with
                    { x1 = Length.centimeters 0
                    , x2 = Length.centimeters Constant.playerWidthCm
                    , y1 = Length.centimeters 0
                    , y2 = Length.centimeters Constant.playerWidthCm
                    , z1 = Length.centimeters 0
                    , z2 = Length.centimeters (Constant.playerHeightCm - (progress * progress * 2))
                    }
                )

        FallingUnbalanced Direction.Left progress ->
            block
                |> Scene3d.rotateAround leftAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.y Constant.tileSize
                |> Scene3d.rotateAround leftAxis (Angle.degrees (90 * progress))

        FallingUnbalanced Direction.Right progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeY Constant.tileSize
                |> Scene3d.rotateAround rightAxis (Angle.degrees (90 * progress))

        FallingUnbalanced Direction.Up progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.x Constant.tileSize
                |> Scene3d.rotateAround topAxis (Angle.degrees (90 * progress))

        FallingUnbalanced Direction.Down progress ->
            block
                |> Scene3d.rotateAround bottomAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeX Constant.tileSize
                |> Scene3d.rotateAround bottomAxis (Angle.degrees (90 * progress))

        FallingInVerticalOrientation { zOffset, progress } ->
            block
                |> Scene3d.translateIn Direction3d.negativeZ zOffset
                |> Scene3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

        FallingInHorizontalOrientation Direction.Left progress ->
            block
                |> Scene3d.rotateAround leftAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.y Constant.tileSize
                |> Scene3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

        FallingInHorizontalOrientation Direction.Up progress ->
            block
                |> Scene3d.rotateAround topAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.x Constant.tileSize
                |> Scene3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

        FallingInHorizontalOrientation Direction.Right progress ->
            block
                |> Scene3d.rotateAround rightAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeY Constant.tileSize
                |> Scene3d.translateIn Direction3d.negativeZ (Length.centimeters progress)

        FallingInHorizontalOrientation Direction.Down progress ->
            block
                |> Scene3d.rotateAround bottomAxis (Angle.degrees 90)
                |> Scene3d.translateIn Direction3d.negativeX Constant.tileSize
                |> Scene3d.translateIn Direction3d.negativeZ (Length.centimeters progress)
    )
        |> Scene3d.translateBy
            (Vector3d.centimeters positionX positionY 0)


topAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.negativeY


rightAxis =
    Axis3d.through (Point3d.centimeters 0 Constant.playerWidthCm 0) Direction3d.negativeX


bottomAxis =
    Axis3d.through (Point3d.centimeters Constant.playerWidthCm 0 0) Direction3d.y


leftAxis =
    Axis3d.through (Point3d.centimeters 0 0 0) Direction3d.x


move : Direction -> Player -> Player
move direction (Player orientation ( x, y )) =
    case ( orientation, direction ) of
        ( Standing, fallDirection ) ->
            Player (KnockingOver fallDirection 0) ( x, y )

        -- Lying Up
        ( Lying Direction.Up, Direction.Left ) ->
            Player (Rolling Direction.Left 0) ( x, y )

        ( Lying Direction.Up, Direction.Right ) ->
            Player (Rolling Direction.Right 0) ( x, y )

        ( Lying Direction.Up, Direction.Up ) ->
            Player (GettingUp Direction.Up 0) ( x - 2, y )

        ( Lying Direction.Up, Direction.Down ) ->
            Player (GettingUp Direction.Down 0) ( x + 1, y )

        -- Lying Right
        ( Lying Direction.Right, Direction.Up ) ->
            Player (Rolling Direction.Up 0) ( x, y )

        ( Lying Direction.Right, Direction.Down ) ->
            Player (Rolling Direction.Down 0) ( x, y )

        ( Lying Direction.Right, Direction.Left ) ->
            Player (GettingUp Direction.Left 0) ( x, y - 1 )

        ( Lying Direction.Right, Direction.Right ) ->
            Player (GettingUp Direction.Right 0) ( x, y + 2 )

        -- Lying Down
        ( Lying Direction.Down, Direction.Up ) ->
            Player (GettingUp Direction.Up 0) ( x - 1, y )

        ( Lying Direction.Down, Direction.Down ) ->
            Player (GettingUp Direction.Down 0) ( x + 2, y )

        ( Lying Direction.Down, Direction.Left ) ->
            Player (Rolling Direction.Left 0) ( x + 1, y )

        ( Lying Direction.Down, Direction.Right ) ->
            Player (Rolling Direction.Right 0) ( x + 1, y )

        -- Lying Left
        ( Lying Direction.Left, Direction.Up ) ->
            Player (Rolling Direction.Up 0) ( x, y - 1 )

        ( Lying Direction.Left, Direction.Down ) ->
            Player (Rolling Direction.Down 0) ( x, y - 1 )

        ( Lying Direction.Left, Direction.Left ) ->
            Player (GettingUp Direction.Left 0) ( x, y - 2 )

        ( Lying Direction.Left, Direction.Right ) ->
            Player (GettingUp Direction.Right 0) ( x, y + 1 )

        -- Player already in motion (ignore)
        _ ->
            Player orientation ( x, y )


getPosition : Player -> ( Int, Int )
getPosition (Player _ position) =
    position


slideIn : Player -> Player
slideIn (Player _ position) =
    Player (SlideIn 0) position


hasSlidedIn : Player -> Bool
hasSlidedIn player =
    case player of
        Player (SlideIn progress) _ ->
            progress >= 1

        _ ->
            False


lyingDirection : Player -> Maybe Direction
lyingDirection (Player state _) =
    case state of
        Lying direction ->
            Just direction

        _ ->
            Nothing


fall : Maybe Direction -> Player -> Player
fall unbalancedDirection (Player state ( x, y )) =
    case ( unbalancedDirection, state ) of
        ( _, Standing ) ->
            Player (FallingInVerticalOrientation { zOffset = Length.centimeters 0, progress = 0 }) ( x, y )

        ( Just Direction.Left, Lying Direction.Left ) ->
            Player (FallingUnbalanced Direction.Left 0) ( x, y )

        ( Just Direction.Left, Lying Direction.Right ) ->
            Player (FallingUnbalanced Direction.Left 0) ( x, y + 1 )

        ( Just Direction.Right, Lying Direction.Left ) ->
            Player (FallingUnbalanced Direction.Right 0) ( x, y + 1 )

        ( Just Direction.Right, Lying Direction.Right ) ->
            Player (FallingUnbalanced Direction.Right 0) ( x, y )

        ( Just Direction.Up, Lying Direction.Up ) ->
            Player (FallingUnbalanced Direction.Up 0) ( x, y )

        ( Just Direction.Up, Lying Direction.Down ) ->
            Player (FallingUnbalanced Direction.Up 0) ( x + 1, y )

        ( Just Direction.Down, Lying Direction.Up ) ->
            Player (FallingUnbalanced Direction.Down 0) ( x - 1, y )

        ( Just Direction.Down, Lying Direction.Down ) ->
            Player (FallingUnbalanced Direction.Down 0) ( x + 1, y )

        ( Nothing, Lying direction ) ->
            Player (FallingInHorizontalOrientation direction 0) ( x, y )

        _ ->
            Player state ( x, y )


hasFelt : Player -> Bool
hasFelt (Player orientation _) =
    case orientation of
        FallingInHorizontalOrientation _ progress ->
            progress >= 30

        FallingInVerticalOrientation { progress } ->
            progress >= 30

        _ ->
            False


occupiedTiles : Player -> List ( Int, Int )
occupiedTiles player =
    case player of
        Player Standing ( x, y ) ->
            [ ( x, y ) ]

        Player (Lying Direction.Left) ( x, y ) ->
            [ ( x, y - 1 ), ( x, y ) ]

        Player (Lying Direction.Up) ( x, y ) ->
            [ ( x - 1, y ), ( x, y ) ]

        Player (Lying Direction.Right) ( x, y ) ->
            [ ( x, y ), ( x, y + 1 ) ]

        Player (Lying Direction.Down) ( x, y ) ->
            [ ( x, y ), ( x + 1, y ) ]

        _ ->
            []
