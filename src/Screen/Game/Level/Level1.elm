module Screen.Game.Level.Level1 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Floor,Floor,Finish,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (1, 1)