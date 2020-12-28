module Screen.Game.Level.Level11 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)
import Color exposing (Color)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Trigger Color.red [ToggleTriggerColor (1, 3) Color.green, ToggleBridge (3, 3)],Floor,Trigger Color.green [SetTriggerColor (1, 5) Color.red, OpenBridge (7, 3)],Floor,Trigger Color.red [ToggleTriggerColor (1, 7) Color.green, ToggleBridge (5, 3)],Floor],[Floor,Floor,Floor,Floor,Floor,Floor,RustyFloor,RustyFloor,RustyFloor],[Empty,Empty,Empty,Bridge Up False],[Empty,Empty,Empty,Floor],[Empty,Empty,Empty,Bridge Up False],[Empty,Empty,Empty,Floor],[Empty,Empty,Empty,Bridge Up True],[Empty,Floor,Floor,Floor,Floor],[Empty,Floor,Finish,Floor,Floor],[Empty,Floor,Floor,Floor,Floor],[]] (2, 1)