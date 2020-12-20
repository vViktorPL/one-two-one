module Screen.Game.Level.Level0 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), fromData)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Finish,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[]] (1, 1)