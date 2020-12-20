module Screen.Game.Level.Level0 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Finish,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[]] (1, 1)