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
          const lines = String(content).split('\n');
          const legendSeparator = lines.indexOf('---');
          const rows = legendSeparator !== -1 ? lines.slice(0, legendSeparator) : lines;

          const uniqueTilePositions = Object.fromEntries(rows.flatMap(
            (row, x) => [...row].map((char, y) => [char, `(${x}, ${y})`])
          ));

          const legend = legendSeparator !== -1 ? lines.slice(legendSeparator + 1).reduce(
            (acc, line) => {
              if (line.trim() === "") {
                return acc;
              }

              acc[line.substring(0, 1)] = line.substring(2).replace(/@(.)/g, match => uniqueTilePositions[match[1]]);

              return acc;
            },
            {}
          ) : {};

          const tileRows = rows.map(
            row => `[${[...row].map(asciiToTile(legend)).join(',')}]`
          );
          const tiles = `[${tileRows.join(',')}]`;


          const startingPosX = rows.findIndex(row => row.includes('S'));
          const startingPosY = rows[startingPosX].indexOf("S");

          const code = [
            `module Screen.Game.Level.${filename.replace(".txt", "")} exposing (data)`,
            'import Screen.Game.Level exposing (Level, LevelTile(..), TriggerAction(..), fromData)',
            'import Screen.Game.Direction exposing (..)',
            'import Color exposing (Color)',
            '',
            'data : Level',
            `data = fromData ${tiles} (${startingPosX}, ${startingPosY})`,
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


const asciiToTile = legend => ascii => {
  switch (ascii) {
    case '#':
    case 'S':
      return "Floor";

    case "F":
      return "Finish";

    case 'R':
      return "RustyFloor";

    default:
      if (ascii in legend) {
        return legend[ascii];
      }

      return "Empty";
  }
};
