module Screen.Game.Level.Index exposing (firstLevel, restLevels)

import Screen.Game.Level exposing (Level)
import Screen.Game.Level.Level0
import Screen.Game.Level.Level1
import Screen.Game.Level.Level2
import Screen.Game.Level.Level3
import Screen.Game.Level.Level4
import Screen.Game.Level.Level5
import Screen.Game.Level.Level6
import Screen.Game.Level.Level7
import Screen.Game.Level.Level8
import Screen.Game.Level.Level9


firstLevel : Level
firstLevel = Screen.Game.Level.Level0.data

restLevels : List Level
restLevels = [Screen.Game.Level.Level1.data, Screen.Game.Level.Level2.data, Screen.Game.Level.Level3.data, Screen.Game.Level.Level4.data, Screen.Game.Level.Level5.data, Screen.Game.Level.Level6.data, Screen.Game.Level.Level7.data, Screen.Game.Level.Level8.data, Screen.Game.Level.Level9.data]