# one-two-one

A 3D game that has been submitted to the [5th Elm Game Jam](https://itch.io/jam/elm-game-jam-5). 
It is strongly inspired by the Bloxorz Flash game.

## Rules

As a player, you are controlling a metal block which is a cuboid that can be orientated vertically or horizontally.
Each level consists of tiles that has different characteristics and function and there is always one black (rectangular hole) tile where your block
has to slide in to complete the level.


## Name genesis

The name is based on one of the player block's possible movements. Namely, if your block starting orientation is
vertical and you press arrow key twice the block goes like this: `|` → `__` → `|` and in such case the number of 
tiles that it occupies goes like this 1 → 2 → 1. Hence, the `one-two-one` name.


## Tech stack

* [Elm](https://elm-lang.org/) v0.19
* [ianmackenzie/elm-3d-scene](https://package.elm-lang.org/packages/ianmackenzie/elm-3d-scene/1.0.1/) v1.0.1
    * Used for rendering main scene of the game
* JavaScript ⇆ Elm interop
    * Port using `LocalStorage` for auto save game feature
    * Port using [`AudioContext`](https://developer.mozilla.org/en-US/docs/Web/API/AudioContext) to decode and play couple of sound effects
* Node.js
    * Script that compiles special ASCII-art like level formatted files to an Elm source code files
* [Parcel](https://parceljs.org/) as a build & bundling tool



## Development setup

To initialize dev environment you need Node.js and to install dependencies through `npm`:
```bash
npm i
```

To run app in dev mode just use standard `start` script:

```bash
npm start
```

For level development please refer to the "Level sources" section.

## Production build

To build a zip file that is ready to upload to the [itch.io](https://itch.io/) just use `build` script:

```bash
npm run build
```

## Level sources

Levels are stored in `levels` directory and have `txt` extension. They are in a special format that
is easily editable through any text editor.

### Simple levels

Simple levels are just an ASCII-art representation of the level
like you would view it from the top (from the bird's eye view) and every character represents one tile:

|Character|Description |
|---------|------------|
|`#`        |Normal floor|
|`S`        |Player starting position & normal floor|
|`F`        |Level end (hole)|
|`R`        |Rusty floor (player cannot stand on it vertically)|
|` ` (space)| Empty tile |

### Complex levels

Some levels however need some logic. For such more complex levels, the content is divided to particular sections:
1. level tiles ASCII-art
2. `---` separator line
3. legend that describes custom tile characters

Through the "legend" (3rd section) you can define custom tiles that can be used in 1st section like this:

```text
####  ###
##o#  #F#
####  ###
#S##[]###

---
[ Bridge Left False
] Bridge Right False
o Trigger Color.red [ToggleTriggerColor @o Color.green, ToggleBridge @[, ToggleBridge @]]
```

In the above example there are 3 extra tiles:

* `[` - opened bridge tile that is anchored to the left
* `]` - opened bridge tile that is anchored to the right
* `o` - trigger tile (button) with red color that on toggle turns green and toggles (closes or opens) the `[` and `]` bridge tiles

So the syntax for each legend item is:
`<TILE ASCII CHARACTER> <ELM CODE WITH @ REFERENCES TO THE TILE LOCATIONS>`

The `@` characters followed by custom tile character from the legend is replaced with
the position tuple of first occurrence (first match) of such tile on the level ASCII art section.

For reference what tile types are available please see `LevelTile` type in `src/Screen/Game/Level.elm` module.

### Build levels

To compile levels (`txt` → `elm`) just run:

```bash
npm run generate-levels
```
