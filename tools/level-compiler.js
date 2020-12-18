const fs = require('fs').promises;
const path = require('path');

const levelsPath = path.join(__dirname, '../levels');
const outputPath = path.join(__dirname, '../src/Screen/Game/Level');

fs.readdir(path.join(__dirname, '../levels')).then(
  files => {
    const levelFiles = files.filter(filename => filename.split('.').pop() === "txt");
    const levelModules = levelFiles.map(levelFilename => `Screen.Game.Level.${levelFilename.replace('.txt', '')}`);

    levelFiles.forEach(filename => {
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
            `module Screen.Game.Level.${filename.replace(".txt", "")} exposing (data)`,
            'import Array exposing (fromList)',
            'import Screen.Game.Level exposing (Level, LevelTile(..))',
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
    });

    const levelsData = levelModules.map(levelModule => `${levelModule}.data`);

    fs.writeFile(path.join(outputPath, "Index.elm"), [
      'module Screen.Game.Level.Index exposing (firstLevel, restLevels)',
      '',
      'import Screen.Game.Level exposing (Level)',
      ...levelModules.map(levelModule => `import ${levelModule}`),
      '',
      '',
      'firstLevel : Level',
      `firstLevel = ${levelsData[0]}`,
      '',
      'restLevels : List Level',
      `restLevels = [${levelsData.slice(1).join(', ')}]`,
    ].join('\n'));
  }
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
