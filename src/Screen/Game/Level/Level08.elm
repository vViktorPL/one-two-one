module Screen.Game.Level.Level08 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Empty,Trigger [ToggleBridge (4, 1), ToggleBridge (5, 1)]],[Floor,Floor,Floor,Floor,Empty,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Empty,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Bridge Left False,Floor,Finish,Floor],[Empty,Bridge Up False,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[Empty,Bridge Down False],[Empty,Floor,Floor,Floor],[Empty,Empty,Floor,Trigger [ToggleBridge (3, 6)]],[]] (1, 1)