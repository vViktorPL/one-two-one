module Screen.Game.Level.Level2 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Empty,Empty,Floor,Floor,Floor],[Floor,Floor,Trigger [ToggleBridge (3, 4), ToggleBridge (3, 5)],Floor,Empty,Empty,Floor,Finish,Floor],[Floor,Floor,Floor,Floor,Empty,Empty,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Bridge Left False,Bridge Right False,Floor,Floor,Floor],[]] (3, 1)