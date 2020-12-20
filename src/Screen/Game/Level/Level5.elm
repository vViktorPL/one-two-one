module Screen.Game.Level.Level5 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Empty,Empty,Floor,RustyFloor,RustyFloor,RustyFloor,RustyFloor,Floor],[Empty,Empty,Floor,RustyFloor,RustyFloor,RustyFloor,RustyFloor,Floor],[Floor,Floor,Floor,Floor,Empty,Empty,Floor,Floor],[Floor,Floor,Floor,Floor,Empty,Empty,Floor,Floor],[Floor,Floor,Floor,Floor,Empty,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Empty,Floor,Finish,Floor],[Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],[]] (4, 1)