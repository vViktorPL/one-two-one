module Level.Level1 exposing (data)
import Array exposing (fromList)
import Level exposing (Level, LevelTile(..))

data : Level
data = 
  { tiles = fromList [fromList [Floor,Floor,Floor],fromList [Floor,Floor,Floor,Floor,Floor,Floor],fromList [Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],fromList [Empty,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor,Floor],fromList [Empty,Empty,Empty,Empty,Empty,Floor,Floor,Finish,Floor,Floor],fromList [Empty,Empty,Empty,Empty,Empty,Empty,Floor,Floor,Floor],fromList []]
  , startingPosition = (1, 1)
  }