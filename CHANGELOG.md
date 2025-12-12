# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - Initial Archival Release

### Features
- Three handcrafted maze layouts (intro, challenge, advanced)
- Ghost AI with multiple states (normal, scared, eaten)
- Power pellets with timed ghost vulnerability
- Fruit bonuses for extra points
- Teleporters for wrapping across the maze
- Sound effects via Win32 MessageBeep
- High score persistence via `highscores.txt`
- Menu system with level selection
- Pause functionality
- Lives and respawn system
- Score tracking with level multipliers

### Technical
- Built with MASM (32-bit) and Visual Studio v143 toolset
- Uses Irvine32 library for console I/O
- Win32 console APIs for display
- Modular procedure architecture
