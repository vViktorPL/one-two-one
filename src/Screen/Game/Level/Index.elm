module Screen.Game.Level.Index exposing (firstLevel, restLevels)

import Screen.Game.Level exposing (Level)
import Screen.Game.Level.Level1
import Screen.Game.Level.Level2
import Screen.Game.Level.Level3


firstLevel : Level
firstLevel = Screen.Game.Level.Level1.data

restLevels : List Level
restLevels = [Screen.Game.Level.Level2.data, Screen.Game.Level.Level3.data]