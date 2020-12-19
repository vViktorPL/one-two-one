module Screen.Game.Level.Level1 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), fromData)

data : Level
data = fromData [[Floor,Floor,Floor],[Floor,Floor,Floor,Floor,RustyFloor,RustyFloor],[Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Floor,Floor,Finish,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (1, 1)