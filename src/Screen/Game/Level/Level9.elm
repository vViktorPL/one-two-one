module Screen.Game.Level.Level9 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor],[Floor,Empty,Floor,Floor,Floor],[Floor,Empty,Floor,Floor,Trigger [ToggleBridge (2, 5), ToggleBridge (2, 6), ToggleBridge (2, 8), ToggleBridge (2, 9)],Bridge Left True,Bridge Right True,Floor,Bridge Left False,Bridge Right False,Floor],[Floor,Empty,Empty,Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor],[Floor,Floor,Floor,Trigger [ToggleBridge (2, 8), ToggleBridge (2, 9)],Empty,Empty,Empty,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Empty,Empty,Empty,Floor,Finish,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor,Floor]] (1, 2)