module Screen.Game.Level.Level8 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Empty,Floor,Floor,Floor,Trigger [ToggleBridge (3, 7)]],[Floor,Floor,Floor,Empty,Bridge Up False,Bridge Up False,Bridge Up False],[Floor,Floor,Floor,Floor,RustyFloor,RustyFloor,RustyFloor],[Empty,Floor,Empty,Empty,Empty,Empty,RustyFloor,Bridge Down False],[Empty,RustyFloor,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[Empty,RustyFloor,Empty,Empty,Empty,Empty,Floor,Finish,Floor],[Empty,Trigger [ToggleBridge (1, 4), ToggleBridge (1, 5), ToggleBridge (1, 6)],Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (2, 0)