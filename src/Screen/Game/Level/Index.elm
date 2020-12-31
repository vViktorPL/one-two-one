module Screen.Game.Level.Index exposing (firstLevel, restLevels)

import Screen.Game.Level exposing (Level)
import Screen.Game.Level.Level01
import Screen.Game.Level.Level02
import Screen.Game.Level.Level03
import Screen.Game.Level.Level04
import Screen.Game.Level.Level05
import Screen.Game.Level.Level06
import Screen.Game.Level.Level07
import Screen.Game.Level.Level08
import Screen.Game.Level.Level09
import Screen.Game.Level.Level10
import Screen.Game.Level.Level11
import Screen.Game.Level.Level12
import Screen.Game.Level.Level13


firstLevel : Level
firstLevel = Screen.Game.Level.Level01.data

restLevels : List Level
restLevels = [Screen.Game.Level.Level02.data, Screen.Game.Level.Level03.data, Screen.Game.Level.Level04.data, Screen.Game.Level.Level05.data, Screen.Game.Level.Level06.data, Screen.Game.Level.Level07.data, Screen.Game.Level.Level08.data, Screen.Game.Level.Level09.data, Screen.Game.Level.Level10.data, Screen.Game.Level.Level11.data, Screen.Game.Level.Level12.data, Screen.Game.Level.Level13.data]