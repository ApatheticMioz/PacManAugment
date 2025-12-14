# 8086 Pac-Man Adventure

An assembly-language Pac-Man clone for 32-bit Windows built with MASM and the Irvine32 library. Features three handcrafted maze levels, ghost AI with multiple states, power pellets, fruit bonuses, teleporters, and basic sound effects.

> **Status:** Archived

## Features

- **Three Maze Layouts** — Intro, challenge, and advanced levels with increasing difficulty
- **Ghost AI** — Normal hunting mode, scared/vulnerable state, and eaten state with respawn
- **Power Pellets** — Collect to make ghosts vulnerable for a limited time
- **Fruit Bonuses** — Appear for extra points
- **Teleporters** — Wrap from one side of the maze to the other (Level 3)
- **Score System** — Points scale with level, persistent high scores
- **Sound Effects** — Win32 MessageBeep for game events
- **Menu System** — Level selection, instructions, high scores

## Project Structure

```
.
├── code.asm              # Main game source (all logic integrated)
├── PacManAugment.vcxproj # Visual Studio project file
├── .editorconfig         # Editor configuration
├── .gitignore            # Git ignore rules
├── CHANGELOG.md          # Version history
├── CONTRIBUTING.md       # Contribution guidelines
├── LICENSE               # MIT License
└── README.md             # This file
```

## Prerequisites

- **Visual Studio** — Desktop development with C++ workload
- **MASM** — Microsoft Macro Assembler (included with VS)
- **Irvine32 Library** — Installed to `c:\Irvine` ([download](https://kipirvine.com/asm/))
- **Windows** — 32-bit console capable of 80×25 text mode

## Build

Open a **Developer Command Prompt** and run:

```bat
msbuild PacManAugment.vcxproj /p:Configuration=Debug /p:Platform=Win32
```

The executable will be output to `Debug\PacManAugment.exe`.

## Run

From the project root:

```bat
Debug\PacManAugment.exe
```

## Controls

| Key | Action |
|-----|--------|
| ↑ ↓ ← → | Move Pac-Man |
| P | Pause / Resume |
| ESC | Return to menu |

## High Scores

Scores are automatically saved to `highscores.txt` in the working directory when a game ends. This file is created on first run and updated with each new score.

## License

This project is licensed under the [MIT License](LICENSE).
