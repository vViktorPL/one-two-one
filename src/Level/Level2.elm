module Level.Level2 exposing (data)
import Array exposing (fromList)
import Level exposing (Level, LevelTile(..))

data : Level
data = 
  { tiles = fromList [fromList [Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor],fromList [Empty,Floor,Floor,Floor,Empty,Empty,Empty,Floor,Floor],fromList [Empty,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],fromList [Empty,Floor,Floor,Floor,Empty,Empty,Empty,Empty,Empty,Floor,Floor],fromList [Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor,Floor],fromList [Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Finish,Floor,Floor],fromList [Empty,Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],fromList []]
  , startingPosition = (1, 2)
  }