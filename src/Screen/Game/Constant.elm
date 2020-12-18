module Screen.Game.Constant exposing (animationSpeed, playerHeightCm, playerWidthCm, tileSize, tileSizeCm)

import Length


tileSize =
    Length.centimeters 1


tileSizeCm =
    Length.inCentimeters tileSize


playerWidthCm =
    1 * tileSizeCm


playerHeightCm =
    2 * tileSizeCm


animationSpeed =
    1 / 250
