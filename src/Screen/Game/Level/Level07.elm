module Screen.Game.Level.Level07 exposing (data)
import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)
import Screen.Game.Direction exposing (..)

data : Level
data = fromData [[Floor,Floor,Floor,Floor,Floor,Floor],[Empty,Empty,Empty,Empty,Floor,Floor],[Empty,Floor,Floor,RustyFloor,RustyFloor,RustyFloor,RustyFloor,RustyFloor],[Floor,Floor,Floor,RustyFloor,RustyFloor,RustyFloor,RustyFloor,RustyFloor],[Floor,Finish,Floor,Empty,RustyFloor,RustyFloor,Floor,RustyFloor],[Floor,Floor,Floor,Empty,RustyFloor,RustyFloor,RustyFloor,RustyFloor],[]] (0, 0)