# 8086 Pac-Man Adventure

Assembly-language Pac-Man clone for 32-bit Windows built with MASM and the Irvine32 library. The game ships three handcrafted maze levels, ghost AI with multiple states, power pellets, fruit bonuses, teleporters, and basic sound effects.

## Features
- Three maze layouts (intro, challenge, advanced) with power pellets, fruits, and teleport pads
- Ghost AI states (normal, scared, eaten) plus collision handling, lives, and respawn
- Dot and fruit collection with score tracking, level completion, and game over screens
- Menu, instructions, pause, and high-score views with name input and status bar updates
- Sound effects via Win32 `MessageBeep` and Irvine32 helpers; highscores persisted in `highscores.txt`

## Tech Stack
- Language: x86 assembly (MASM, 32-bit)
- Toolchain: Visual Studio v143 toolset with MASM build customizations
- Libraries: Irvine32 (expected in `c:\Irvine`), Win32 console APIs, `user32.lib`

## Prerequisites
- Visual Studio (Desktop development with C++)
- MASM build tools and Irvine32 library installed to `c:\Irvine`
- Windows console capable of 80x25 text

## Build
From a Developer Command Prompt:

```bat
msbuild PacManAugment.vcxproj /p:Configuration=Debug /p:Platform=Win32
```

Artifacts land under `Debug/` by default (e.g., `Debug\PacManAugment.exe`).

## Run
Launch the built executable from the project root:

```bat
Debug\PacManAugment.exe
```

## Controls
- Arrow keys: move Pac-Man
- P: pause/resume
- ESC: return to menu

## High Scores
Scores persist in `highscores.txt` in the project root. The game reads/writes this file directly as simple text entries.
