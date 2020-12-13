const fs = require('fs').promises;
const path = require('path');

const levelsPath = path.join(__dirname, '../levels');
const outputPath = path.join(__dirname, '../src/Level');

fs.readdir(path.join(__dirname, '../levels')).then(
  files => files
    .filter(filename => filename.split('.').pop() === "txt")
    .forEach(filename => {
      fs.readFile(path.join(levelsPath, filename)).then(
        content => {
          const outputFilePath = path.join(outputPath, filename.replace('.txt', '.elm'));
          const rows = String(content).split('\n');

          const tileRows = rows.map(
            row => `fromList [${[...row].map(asciiToTile).join(',')}]`
          );
          const tiles = `fromList [${tileRows.join(',')}]`;


          const startingPosX = rows.findIndex(row => row.includes('S'));
          const startingPosY = rows[startingPosX].indexOf("S");

          const code = [
            `module Level.${filename.replace(".txt", "")} exposing (data)`,
            'import Array exposing (fromList)',
            'import Level exposing (Level, LevelTile(..))',
            '',
            'data : Level',
            'data = ',
            `  { tiles = ${tiles}`,
            `  , startingPosition = (${startingPosX}, ${startingPosY})`,
            '  }',
          ].join('\n');

          fs.writeFile(outputFilePath, code);
        }
      )
    })
);


const asciiToTile = ascii => {
  switch (ascii) {
    case '#':
    case 'S':
      return "Floor";

    case "F":
      return "Finish";

    default:
      return "Empty";
  }
};
