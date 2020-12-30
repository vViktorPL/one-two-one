module Screen.Game.Level.Level12 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)
import Color exposing (Color)

data : Level
data = fromData [[Empty,Empty,Trigger Color.yellow [SplitToCubes (1, 10) (7, 10)],Floor,Floor,Empty,Empty,Empty,Empty,Empty,Floor],[Empty,Empty,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Floor,Trigger Color.blue [],Floor],[Empty,Empty,Empty,Empty,Floor,Empty,Empty,Empty,Empty,Empty,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Empty,Empty,Empty,Floor,Floor,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,RustyFloor,RustyFloor,RustyFloor,Floor,Finish,Floor],[Floor,Floor,Floor,Floor,Floor,Floor,Empty,Empty,Empty,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Floor,Empty,Empty,Empty,Empty,Empty,Floor],[Empty,Empty,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Floor,Trigger Color.blue [],Floor],[Empty,Empty,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Empty,Floor]] (4, 1)