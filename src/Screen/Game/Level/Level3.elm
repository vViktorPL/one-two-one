module Screen.Game.Level.Level3 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), fromData)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Floor,Floor],[Empty,Floor,Floor,Floor,Floor,Floor,Empty,Empty,Floor,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Finish,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (1, 1)