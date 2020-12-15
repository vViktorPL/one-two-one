module Level.Index exposing (firstLevel, restLevels)

import Level exposing (Level)
import Level.Level1
import Level.Level2


firstLevel : Level
firstLevel = Level.Level1.data

restLevels : List Level
restLevels = [Level.Level2.data]