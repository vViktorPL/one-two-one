module Screen.Game.Level.Level04 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)
import Color exposing (Color)

data : Level
data = fromData [[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor],[Empty,Floor,Floor,Floor,Empty,Empty,Empty,Floor,Floor],[Empty,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Empty,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Finish,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (1, 2)