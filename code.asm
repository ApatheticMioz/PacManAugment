;-----------------------------------------------------------------------------------------------------------------------
; 8086 Pac-Man Adventure
;-----------------------------------------------------------------------------------------------------------------------

INCLUDE Irvine32.inc
INCLUDELIB winmm.lib  ; For sound effects

; Windows API function for sound effects
MessageBeep PROTO, uType:DWORD

; Keyboard scan codes - these are the raw values from the keyboard
ESC_SCAN_CODE       EQU  01h  ; Escape key for exiting
UP_ARROW_SCAN_CODE  EQU  48h  ; Up arrow for movement
LEFT_ARROW_SCAN_CODE EQU  4Bh  ; Left arrow for movement
RIGHT_ARROW_SCAN_CODE EQU 4Dh  ; Right arrow for movement
DOWN_ARROW_SCAN_CODE EQU  50h  ; Down arrow for movement
P_SCAN_CODE         EQU  19h  ; 'P' key for pause functionality

; Game timing - controls the speed of the game
GAME_SPEED_DELAY    EQU  33   ; Made it 3x faster than original for better gameplay

; Color Constants
WHITE_ON_BLACK      EQU     white + (black * 16)
YELLOW_ON_BLACK     EQU     yellow + (black * 16)
BLUE_ON_BLACK       EQU     blue + (black * 16)
CYAN_ON_BLACK       EQU     cyan + (black * 16)
MAGENTA_ON_BLACK    EQU     magenta + (black * 16)
GREEN_ON_BLACK      EQU     green + (black * 16)
RED_ON_BLACK        EQU     red + (black * 16)
LIGHT_BLUE_ON_BLACK EQU     lightBlue + (black * 16)
LIGHT_GREEN_ON_BLACK EQU    lightGreen + (black * 16)
LIGHT_CYAN_ON_BLACK EQU     lightCyan + (black * 16)
LIGHT_RED_ON_BLACK  EQU     lightRed + (black * 16)
LIGHT_MAGENTA_ON_BLACK EQU  lightMagenta + (black * 16)
LIGHT_GRAY_ON_BLACK EQU     lightGray + (black * 16)
BLACK_ON_BLACK      EQU     black + (black * 16)

; Screen dimensions
SCREEN_COLS         EQU     80
SCREEN_ROWS         EQU     25

; Game Area Layout
GAME_AREA_ROW_TOP   EQU  1
GAME_AREA_ROW_BOTTOM EQU  23
GAME_AREA_COL_LEFT  EQU  0
GAME_AREA_COL_RIGHT EQU  SCREEN_COLS - 1

STATUS_ROW_TOP      EQU  0
STATUS_ROW_BOTTOM   EQU  SCREEN_ROWS - 1

; Maze data
MAZE_WALL_CHAR_DEF  EQU  '#'
MAZE_WALL_CHAR_DRAW EQU  219
MAZE_PATH_CHAR      EQU  ' '
MAZE_DOT_CHAR       EQU  250  ; Small dot character (ASCII 250)
MAZE_PLAYER_START_CHAR EQU 'S'
MAZE_WALL_COLOR     EQU  BLUE_ON_BLACK        ; Blue for walls
MAZE_PATH_COLOR     EQU  BLACK_ON_BLACK
MAZE_DOT_COLOR      EQU  WHITE_ON_BLACK       ; White for dots

; New systems are integrated directly into this file

; Dot collection
DOT_POINTS          EQU  10      ; Points awarded for each dot collected
POWER_PELLET_POINTS EQU  50      ; Points awarded for power pellet
FRUIT_POINTS        EQU  100     ; Points awarded for fruit
GHOST_POINTS        EQU  200     ; Points awarded for eating a ghost

; Power pellet duration (in game ticks)
POWER_PELLET_DURATION EQU 1800   ; 60 seconds at 30fps (longer duration for better gameplay)

; Maze elements
MAZE_POWER_PELLET_CHAR EQU 'O'   ; Power pellet character in maze definition
MAZE_FRUIT_CHAR      EQU 'F'     ; Fruit character in maze definition
MAZE_TELEPORT_CHAR   EQU 'T'     ; Teleport character in maze definition

; Sound types for MessageBeep
SOUND_DEFAULT       EQU  0       ; Default beep
SOUND_INFORMATION   EQU  1       ; Information beep
SOUND_EXCLAMATION   EQU  2       ; Exclamation beep
SOUND_QUESTION      EQU  3       ; Question beep
SOUND_ERROR         EQU  4       ; Error beep

MAZE_MAX_ROWS_VAL   EQU  18     ; Valid maze rows 0-17
MAZE_MAX_COLS_VAL   EQU  72     ; Valid maze cols 0-71

; Pac-Man Directions
DIR_RIGHT           EQU  0
DIR_LEFT            EQU  1
DIR_UP              EQU  2
DIR_DOWN            EQU  3

; Ghost behavior states - each ghost can be in one of these states
GHOST_STATE_NORMAL  EQU  0  ; Regular hunting mode - chasing the player
GHOST_STATE_SCARED  EQU  1  ; Blue/vulnerable state after power pellet
GHOST_STATE_EATEN   EQU  2  ; Ghost was eaten and returning to home

; Player structure - holds all Pac-Man data
Player STRUCT
    mapX            BYTE 1  ; Position in maze (X)
    mapY            BYTE 1  ; Position in maze (Y)
    screenX         BYTE ?  ; Position on screen (X)
    screenY         BYTE ?  ; Position on screen (Y)
    charCurrent     BYTE '<' ; Current visual representation
    ; Different characters for animation in each direction
    charRightOpen   BYTE '<' ; Pac-Man facing right with open mouth
    charLeftOpen    BYTE '>' ; Pac-Man facing left with open mouth
    charUpOpen      BYTE 'v' ; Pac-Man facing up with open mouth
    charDownOpen    BYTE '^' ; Pac-Man facing down with open mouth
    ; Closed mouth versions for animation
    charRightClosed BYTE '-' ; Pac-Man facing right with closed mouth
    charLeftClosed  BYTE '-' ; Pac-Man facing left with closed mouth
    charUpClosed    BYTE '|' ; Pac-Man facing up with closed mouth
    charDownClosed  BYTE '|' ; Pac-Man facing down with closed mouth
    color           WORD YELLOW_ON_BLACK ; Classic yellow color
    direction       BYTE DIR_RIGHT ; Current movement direction
    desiredDirection BYTE DIR_RIGHT ; Where player wants to go next
    mouthOpen       BYTE 1  ; Animation state (open/closed)
    animCounter     BYTE 0  ; For timing the animation
    score           WORD 0  ; Player's current score
    lives           BYTE 3  ; Lives remaining
Player ENDS

; Ghost structure - each ghost uses this template
Ghost STRUCT
    mapX            BYTE ?  ; Position in maze (X)
    mapY            BYTE ?  ; Position in maze (Y)
    screenX         BYTE ?  ; Position on screen (X)
    screenY         BYTE ?  ; Position on screen (Y)
    homeX           BYTE ?  ; Starting position to return to (X)
    homeY           BYTE ?  ; Starting position to return to (Y)
    charNormal      BYTE 'G' ; Character when in normal state
    charScared      BYTE 'S' ; Character when scared (blue)
    charEaten       BYTE 'E' ; Character when eaten
    color           WORD ?  ; Each ghost has a unique color
    direction       BYTE ?  ; Current movement direction
    state           BYTE GHOST_STATE_NORMAL ; Current behavior state
    speed           BYTE 1  ; How fast the ghost moves
    moveCounter     BYTE 0  ; For timing the movement
    tileUnder       BYTE ' ' ; Remembers what's under the ghost
Ghost ENDS

.data
    ; Dot tracking system - keeps track of all dots in the maze
    ; Values: 0 = collected/empty, 1 = regular dot, 2 = power pellet
    dotArray        BYTE    1400 DUP(0)  ; Array sized for the maze (19*73 = 1387)
    totalDots       WORD    0    ; How many dots are in the level
    dotsCollected   WORD    0    ; How many dots the player has eaten

    ; Game state tracking
    gameOverFlag    BYTE    0    ; Tracks if the game has ended
    currentLevel    BYTE    1    ; Which level we're playing (1-3)
    powerPelletActive BYTE  0    ; Is a power pellet currently active?
    powerPelletTimer WORD   0    ; How much time left for power pellet
    fruitActive     BYTE    0    ; Is a bonus fruit on screen?
    fruitX          BYTE    0    ; Where the fruit is (X)
    fruitY          BYTE    0    ; Where the fruit is (Y)
    frameCounter    DWORD   0    ; Used for timing animations

    ; Score formatting
    scoreStr        BYTE    "00000", 0
    livesStr        BYTE    "3", 0

    gameTitleMsg   BYTE    "=== Welcome to 8086 Pac-Man by 23I-2523 ===", 0Dh, 0Ah, 0Dh, 0Ah, 0
    namePromptMsg  BYTE    "Please enter your name: ", 0
    nameEnteredMsg BYTE    0Dh, 0Ah, "Hello, ", 0
    playerName     BYTE    32 DUP(0)
    commaSpace     BYTE    ", welcome to the game!", 0Dh, 0Ah, 0Dh, 0Ah, 0

    menuTitleMsg   BYTE    "--- GAME MENU ---", 0Dh, 0Ah, 0
    menuOption1    BYTE    "1. Start Game - Level 1", 0Dh, 0Ah, 0
    menuOption2    BYTE    "2. Start Game - Level 2", 0Dh, 0Ah, 0
    menuOption3    BYTE    "3. Start Game - Level 3", 0Dh, 0Ah, 0
    menuOption4    BYTE    "4. Instructions", 0Dh, 0Ah, 0
    menuOption5    BYTE    "5. High Scores", 0Dh, 0Ah, 0
    menuOption6    BYTE    "6. Exit", 0Dh, 0Ah, 0
    menuPromptMsg  BYTE    0Dh, 0Ah, "Enter your choice (1-6): ", 0
    invalidChoiceMsg BYTE  "Invalid choice. Please try again.", 0Dh, 0Ah, 0

    actualStartGameMsg  BYTE    "Preparing to start game...", 0Dh, 0Ah, 0
    instrTitle          BYTE    "--- HOW TO PLAY ---", 0Dh, 0Ah, 0Dh, 0Ah, 0
    instrLine1          BYTE    "1. Use Arrow Keys to move Pac-Man.", 0Dh, 0Ah, 0
    instrLine2          BYTE    "2. Collect all the dots in the maze to clear the level.", 0Dh, 0Ah, 0
    instrLine3          BYTE    "3. Avoid colliding with ghosts!", 0Dh, 0Ah, 0
    instrLine4          BYTE    "4. Eat Power Pellets to turn ghosts blue and eat them for bonus points.", 0Dh, 0Ah, 0
    instrLine5          BYTE    "5. Fruits appear for extra points.", 0Dh, 0Ah, 0Dh, 0Ah, 0
    actualHighScoresTitle BYTE  "--- HIGH SCORES ---", 0Dh, 0Ah, 0Dh, 0Ah, 0
    highScoresSavedMsg  BYTE    "High score saved successfully!", 0Dh, 0Ah, 0
    highScoreErrorMsg   BYTE    "Error saving high score.", 0Dh, 0Ah, 0

    ; High score file handling - using simple text file
    highScoreFileName   BYTE    "highscores.txt", 0  ; Simple .txt file that's easy to read
    highScoreFileHandle DWORD   0
    highScoreBuffer     BYTE    256 DUP(0)
    highScoreFormat     BYTE    "%s: %d", 0          ; Simple readable format
    highScoreEntry      BYTE    64 DUP(0)

    ; High score display
    highScoreHeader     BYTE    "Rank  Name                 Score", 0Dh, 0Ah, 0
    highScoreLine       BYTE    "----  -------------------- -----", 0Dh, 0Ah, 0
    exitMessage         BYTE    0Dh, 0Ah, "Exiting Pac-Man. Goodbye!", 0Dh, 0Ah, 0

    gameStatusMsg       BYTE    "Game Running... Press ESC for Menu, P to Pause.", 0
    topStatusLineMsg    BYTE    "8086 PAC-MAN by 23I-2523                                       SCORE: ",0
    scoreDisplay       BYTE    " LIVES: ",0
    livesDisplay       BYTE    "3",0
    levelDisplay       BYTE    " LEVEL: ",0
    levelStr           BYTE    "1",0

    ; Level completion messages
    levelCompleteMsg   BYTE    "LEVEL COMPLETE! CONGRATULATIONS!", 0
    gameOverMsg        BYTE    "GAME OVER!", 0
    scoreMsg           BYTE    "Your score: ", 0
    pressAnyKeyMsg     BYTE    "Press any key to continue...", 0

    ; Pause message
    pauseMsg           BYTE    "GAME PAUSED - Press P to resume", 0

    ; Player initialization with proper starting values
    pacman Player <1, 1, 0, 0, '<', '<', '>', 'v', '^', '-', '-', '|', '|', YELLOW_ON_BLACK, DIR_RIGHT, DIR_RIGHT, 1, 0, 0, 3>

    ; Ghost initialization
    MAX_GHOSTS      EQU 4
    ghostCount      BYTE 1  ; Number of active ghosts (start with 1 for Level 1)

    ; Ghost instances - one for each ghost
    blinky Ghost <9, 9, 0, 0, 9, 9, 'B', 'S', 'E', RED_ON_BLACK, DIR_RIGHT, GHOST_STATE_NORMAL, 2, 0, ' '>  ; Red ghost - original speed
    pinky Ghost <35, 9, 0, 0, 35, 9, 'P', 'S', 'E', MAGENTA_ON_BLACK, DIR_LEFT, GHOST_STATE_NORMAL, 3, 0, ' '>  ; Pink ghost - slower
    inky Ghost <35, 13, 0, 0, 35, 13, 'I', 'S', 'E', CYAN_ON_BLACK, DIR_UP, GHOST_STATE_NORMAL, 2, 0, ' '>  ; Cyan ghost - faster

    ; Level 1 Maze - Basic layout with 4 obstacle bands
    ; This is the introductory level with a simple pattern
maze1Row00 BYTE "########################################################################",0
maze1Row01 BYTE "#S                                                                     #",0 ; Player starts here
maze1Row02 BYTE "# ################################# ################################## #",0 ; First obstacle band
maze1Row03 BYTE "# ################################# ################################## #",0
maze1Row04 BYTE "# ################################# ################################## #",0
maze1Row05 BYTE "#                                                                      #",0 ; Open area
maze1Row06 BYTE "# ############# ############# ############# ############ ############# #",0 ; Second obstacle band
maze1Row07 BYTE "# ############# ############# ############# ############ ############# #",0
maze1Row08 BYTE "# ############# ############# ############# ############ ############# #",0
maze1Row09 BYTE "#                                                                      #",0 ; Ghost territory
maze1Row10 BYTE "# ################################## ################################# #",0 ; Third obstacle band
maze1Row11 BYTE "# ################################## ################################# #",0
maze1Row12 BYTE "# ################################## ################################# #",0
maze1Row13 BYTE "#                                                                      #",0 ; Open area
maze1Row14 BYTE "# ###################### ###################### ###################### #",0 ; Fourth obstacle band
maze1Row15 BYTE "# ###################### ###################### ###################### #",0
maze1Row16 BYTE "#                                                                      #",0 ; Bottom escape route
maze1Row17 BYTE "########################################################################",0

    ; Level 2 Maze - Intermediate difficulty with power pellets
    ; Similar to level 1 but with strategic power pellets and different spacing
maze2Row00 BYTE "########################################################################",0
maze2Row01 BYTE "#S                                                                     #",0 ; Player starts here
    ; First obstacle band - 2 large blocks
maze2Row02 BYTE "# ################################# ################################## #",0
maze2Row03 BYTE "# ################################# ################################## #",0
maze2Row04 BYTE "# ################################# ################################## #",0
    ; Open area for movement
maze2Row05 BYTE "#                                                                      #",0
    ; Second obstacle band - 5 medium blocks
maze2Row06 BYTE "# ############# ############# ############# ############ ############# #",0
maze2Row07 BYTE "# ############# ############# ############# ############ ############# #",0
maze2Row08 BYTE "# ############# ############# ############# ############ ############# #",0
    ; Power pellet row - strategic placement
maze2Row09 BYTE "#                           O                           O              #",0 ; Power pellets here
    ; Third obstacle band - 2 large blocks with gap
maze2Row10 BYTE "# ################################## ################################# #",0
maze2Row11 BYTE "#                                                                      #",0 ; Middle passage
maze2Row12 BYTE "# ################################## ################################# #",0
    ; Open area for movement
maze2Row13 BYTE "#                                                                      #",0
    ; Fourth obstacle band - 3 medium blocks
maze2Row14 BYTE "# ###################### ###################### ###################### #",0
maze2Row15 BYTE "# ###################### ###################### ###################### #",0
    ; Bottom escape route
maze2Row16 BYTE "#                                                                      #",0
maze2Row17 BYTE "########################################################################",0

    ; Current maze layout - will be set based on level
    mazeLayout      DD  OFFSET maze1Row00, OFFSET maze1Row01, OFFSET maze1Row02, OFFSET maze1Row03
                    DD  OFFSET maze1Row04, OFFSET maze1Row05, OFFSET maze1Row06, OFFSET maze1Row07
                    DD  OFFSET maze1Row08, OFFSET maze1Row09, OFFSET maze1Row10, OFFSET maze1Row11
                    DD  OFFSET maze1Row12, OFFSET maze1Row13, OFFSET maze1Row14, OFFSET maze1Row15
                    DD  OFFSET maze1Row16, OFFSET maze1Row17

    ; Level 1 maze layout
    maze1Layout     DD  OFFSET maze1Row00, OFFSET maze1Row01, OFFSET maze1Row02, OFFSET maze1Row03
                    DD  OFFSET maze1Row04, OFFSET maze1Row05, OFFSET maze1Row06, OFFSET maze1Row07
                    DD  OFFSET maze1Row08, OFFSET maze1Row09, OFFSET maze1Row10, OFFSET maze1Row11
                    DD  OFFSET maze1Row12, OFFSET maze1Row13, OFFSET maze1Row14, OFFSET maze1Row15
                    DD  OFFSET maze1Row16, OFFSET maze1Row17

    ; Level 2 maze layout
    maze2Layout     DD  OFFSET maze2Row00, OFFSET maze2Row01, OFFSET maze2Row02, OFFSET maze2Row03
                    DD  OFFSET maze2Row04, OFFSET maze2Row05, OFFSET maze2Row06, OFFSET maze2Row07
                    DD  OFFSET maze2Row08, OFFSET maze2Row09, OFFSET maze2Row10, OFFSET maze2Row11
                    DD  OFFSET maze2Row12, OFFSET maze2Row13, OFFSET maze2Row14, OFFSET maze2Row15
                    DD  OFFSET maze2Row16, OFFSET maze2Row17

    ; Level 3 Maze - Advanced layout with teleporters and tunnels
    ; This is the most challenging level with special features
maze3Row00 BYTE "########################################################################",0
maze3Row01 BYTE "#S                                                                     #",0 ; Player starts here
    ; First obstacle band - 2 large blocks
maze3Row02 BYTE "# ################################# ################################## #",0
maze3Row03 BYTE "# ################################# ################################## #",0
maze3Row04 BYTE "# ################################# ################################## #",0
    ; Open area for movement
maze3Row05 BYTE "#                                                                      #",0
    ; Second obstacle band - 5 medium blocks
maze3Row06 BYTE "# ############# ############# ############# ############ ############# #",0
maze3Row07 BYTE "# ############# ############# ############# ############ ############# #",0
maze3Row08 BYTE "# ############# ############# ############# ############ ############# #",0
    ; Teleport row - allows wrapping from one side to the other
maze3Row09 BYTE "T                                                                      T",0 ; Teleporters!
    ; Third obstacle band - 2 large blocks with gap
maze3Row10 BYTE "# ################################## ################################# #",0
maze3Row11 BYTE "#                                                                      #",0 ; Middle tunnel
maze3Row12 BYTE "# ################################## ################################# #",0
    ; Power pellet row - strategic placement
maze3Row13 BYTE "#                           O                           O              #",0 ; Power pellets
    ; Fourth obstacle band - 3 medium blocks
maze3Row14 BYTE "# ###################### ###################### ###################### #",0
maze3Row15 BYTE "# ###################### ###################### ###################### #",0
    ; Bottom escape route
maze3Row16 BYTE "#                                                                      #",0
maze3Row17 BYTE "########################################################################",0

    ; Level 3 maze layout
    maze3Layout     DD  OFFSET maze3Row00, OFFSET maze3Row01, OFFSET maze3Row02, OFFSET maze3Row03
                    DD  OFFSET maze3Row04, OFFSET maze3Row05, OFFSET maze3Row06, OFFSET maze3Row07
                    DD  OFFSET maze3Row08, OFFSET maze3Row09, OFFSET maze3Row10, OFFSET maze3Row11
                    DD  OFFSET maze3Row12, OFFSET maze3Row13, OFFSET maze3Row14, OFFSET maze3Row15
                    DD  OFFSET maze3Row16, OFFSET maze3Row17

.code
;--------------------------------------------------------------------------------
; IsCollision - Wall detection system
; This checks if a character would hit a wall at the given coordinates
; Inputs: BL = X position, BH = Y position
; Returns: AL = 1 if there's a wall, AL = 0 if the path is clear
;--------------------------------------------------------------------------------
IsCollision PROC USES EBX ECX EDX ESI EDI
    ; First make sure we're not going outside the maze
    cmp bh, MAZE_MAX_ROWS_VAL
    jae IsCollision_ReturnTrue        ; Too far down - hit a wall
    cmp bl, MAZE_MAX_COLS_VAL
    jae IsCollision_ReturnTrue        ; Too far right - hit a wall

    ; Now look up what's at this position in the maze
    mov esi, OFFSET mazeLayout        ; Get the maze data
    movzx ecx, bh                     ; Get the row number
    shl ecx, 2                        ; Multiply by 4 (for pointer size)
    add esi, ecx                      ; Point to the right row
    mov esi, [esi]                    ; Get the actual row data

    ; Make sure we have valid data
    cmp esi, 0
    je IsCollision_ReturnTrue         ; Bad data - just say it's a wall

    ; Now check the specific position in this row
    movzx ecx, bl                     ; Get the column number
    add esi, ecx                      ; Point to the character at this position

    ; Is it a wall?
    cmp BYTE PTR [esi], MAZE_WALL_CHAR_DEF
    je IsCollision_ReturnTrue         ; Yes, it's a wall - can't go here

    ; If we got here, the path is clear
    mov al, 0
    jmp IsCollision_Exit

IsCollision_ReturnTrue:
    ; There's a wall here
    mov al, 1

IsCollision_Exit:
    ret
IsCollision ENDP



;--------------------------------------------------------------------------------
; PauseGame - Pause the game until P is pressed again
;--------------------------------------------------------------------------------
PauseGame PROC USES EAX EDX
    ; Display pause message
    mov dh, 12
    mov dl, 20
    call Gotoxy

    mov eax, LIGHT_CYAN_ON_BLACK
    call SetTextColor

    mov edx, OFFSET pauseMsg
    call WriteString

PauseGame_WaitLoop:
    ; Wait for key press
    call ReadKey
    jz PauseGame_WaitLoop     ; No key pressed, keep waiting

    ; Check if P key was pressed to resume
    cmp ah, P_SCAN_CODE
    jne PauseGame_WaitLoop    ; Not P key, keep waiting

    ; Redraw the game screen to remove pause message
    call RedrawMaze      ; Use RedrawMaze instead of DrawMaze to preserve dots
    call DrawPlayer
    call DrawGhost
    call DrawStatusBar

    ret
PauseGame ENDP



;--------------------------------------------------------------------------------
; HandleKeyInput - Check for keyboard input and update desired direction
; No input parameters
; Output: AH = scan code of pressed key, AL = 0 if no key pressed
;--------------------------------------------------------------------------------
HandleKeyInput PROC USES EBX
    ; Check for key press
    call Readkey
    jz HandleKeyInput_NoKey           ; No key pressed

    ; We got a key - check for arrow keys, ESC, or P
    cmp ah, UP_ARROW_SCAN_CODE
    je HandleKeyInput_Up
    cmp ah, DOWN_ARROW_SCAN_CODE
    je HandleKeyInput_Down
    cmp ah, LEFT_ARROW_SCAN_CODE
    je HandleKeyInput_Left
    cmp ah, RIGHT_ARROW_SCAN_CODE
    je HandleKeyInput_Right
    cmp ah, P_SCAN_CODE
    je HandleKeyInput_Pause

    ; Key was not an arrow key or P - just return the key
    jmp HandleKeyInput_Exit

HandleKeyInput_Up:
    mov pacman.desiredDirection, DIR_UP
    jmp HandleKeyInput_Exit

HandleKeyInput_Down:
    mov pacman.desiredDirection, DIR_DOWN
    jmp HandleKeyInput_Exit

HandleKeyInput_Left:
    mov pacman.desiredDirection, DIR_LEFT
    jmp HandleKeyInput_Exit

HandleKeyInput_Right:
    mov pacman.desiredDirection, DIR_RIGHT
    jmp HandleKeyInput_Exit

HandleKeyInput_Pause:
    call PauseGame
    xor ah, ah      ; Clear scan code after pause to avoid processing it again

HandleKeyInput_Exit:
    ret

HandleKeyInput_NoKey:
    xor ah, ah                        ; Clear scan code
    ret
HandleKeyInput ENDP

;--------------------------------------------------------------------------------
; ErasePlayer - Erase player from current position
;--------------------------------------------------------------------------------
ErasePlayer PROC USES EAX EDX
    ; Set cursor to player position
    mov dh, pacman.screenY
    mov dl, pacman.screenX
    call Gotoxy

    ; Draw blank space
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar

    ret
ErasePlayer ENDP

;--------------------------------------------------------------------------------
; AnimatePacMan - Toggle mouth open/closed state for animation
;--------------------------------------------------------------------------------
AnimatePacMan PROC USES EAX
    ; Increment animation counter
    inc pacman.animCounter

    ; Only toggle mouth every 3 frames for smoother animation
    mov al, pacman.animCounter
    cmp al, 3
    jl AnimatePacMan_Exit

    ; Reset counter
    mov pacman.animCounter, 0

    ; Toggle mouth state
    mov al, pacman.mouthOpen
    xor al, 1          ; Toggle between 0 and 1
    mov pacman.mouthOpen, al

AnimatePacMan_Exit:
    ret
AnimatePacMan ENDP

;--------------------------------------------------------------------------------
; DrawPlayer - Draw player at current position with current direction character
;--------------------------------------------------------------------------------
DrawPlayer PROC USES EAX EDX
    ; Set cursor to player position
    mov dh, pacman.screenY
    mov dl, pacman.screenX
    call Gotoxy

    ; Draw player with proper character and color
    mov ax, pacman.color
    call SetTextColor

    ; Animate Pac-Man (toggle mouth open/closed)
    call AnimatePacMan

    ; Get character based on direction and mouth state
    mov al, pacman.direction

    ; Check if mouth is open or closed
    mov ah, pacman.mouthOpen
    cmp ah, 1
    je DrawPlayer_MouthOpen

    ; Mouth closed - use closed mouth characters
    cmp al, DIR_RIGHT
    jne DrawPlayer_CheckLeftClosed
    mov al, pacman.charRightClosed
    jmp DrawPlayer_Draw

DrawPlayer_CheckLeftClosed:
    cmp al, DIR_LEFT
    jne DrawPlayer_CheckUpClosed
    mov al, pacman.charLeftClosed
    jmp DrawPlayer_Draw

DrawPlayer_CheckUpClosed:
    cmp al, DIR_UP
    jne DrawPlayer_CheckDownClosed
    mov al, pacman.charUpClosed
    jmp DrawPlayer_Draw

DrawPlayer_CheckDownClosed:
    mov al, pacman.charDownClosed
    jmp DrawPlayer_Draw

    ; Mouth open - use open mouth characters
DrawPlayer_MouthOpen:
    cmp al, DIR_RIGHT
    jne DrawPlayer_CheckLeftOpen
    mov al, pacman.charRightOpen
    jmp DrawPlayer_Draw

DrawPlayer_CheckLeftOpen:
    cmp al, DIR_LEFT
    jne DrawPlayer_CheckUpOpen
    mov al, pacman.charLeftOpen
    jmp DrawPlayer_Draw

DrawPlayer_CheckUpOpen:
    cmp al, DIR_UP
    jne DrawPlayer_CheckDownOpen
    mov al, pacman.charUpOpen
    jmp DrawPlayer_Draw

DrawPlayer_CheckDownOpen:
    mov al, pacman.charDownOpen

DrawPlayer_Draw:
    mov pacman.charCurrent, al
    call WriteChar

    ret
DrawPlayer ENDP

;--------------------------------------------------------------------------------
; UpdatePlayerPosition - Update player position based on current direction
; Returns: AL = 1 if player moved, AL = 0 if blocked
;--------------------------------------------------------------------------------
UpdatePlayerPosition PROC USES EBX ECX EDX
    LOCAL targetX:BYTE, targetY:BYTE

    ; Calculate target position based on current direction
    mov al, pacman.mapX
    mov targetX, al

    mov al, pacman.mapY
    mov targetY, al

    ; Adjust target based on direction
    mov al, pacman.direction
    cmp al, DIR_RIGHT
    jne UpdatePos_CheckLeft
    inc targetX
    jmp UpdatePos_CheckCollision

UpdatePos_CheckLeft:
    cmp al, DIR_LEFT
    jne UpdatePos_CheckUp
    dec targetX
    jmp UpdatePos_CheckCollision

UpdatePos_CheckUp:
    cmp al, DIR_UP
    jne UpdatePos_CheckDown
    dec targetY
    jmp UpdatePos_CheckCollision

UpdatePos_CheckDown:
    inc targetY

UpdatePos_CheckCollision:
    ; Check for collision at target position
    mov bl, targetX
    mov bh, targetY
    call IsCollision

    ; If collision, return without moving
    cmp al, 1
    je UpdatePos_Blocked

    ; No collision - check for teleport
    mov esi, OFFSET mazeLayout
    movzx ecx, targetY
    shl ecx, 2
    add esi, ecx
    mov esi, [esi]
    movzx ecx, targetX
    add esi, ecx

    ; Check if teleport
    cmp BYTE PTR [esi], MAZE_TELEPORT_CHAR
    jne UpdatePos_NoTeleport

    ; Handle teleportation
    cmp currentLevel, 3
    jl UpdatePos_NoTeleport  ; Only teleport in Level 3+

    ; Teleport to the other side
    cmp targetX, 0
    je UpdatePos_TeleportRight

    ; Teleport to left
    mov targetX, 1
    jmp UpdatePos_UpdateAfterTeleport

UpdatePos_TeleportRight:
    ; Teleport to right
    mov targetX, 70

UpdatePos_UpdateAfterTeleport:
    ; Play teleport sound
    mov eax, SOUND_EXCLAMATION
    call MessageBeep

UpdatePos_NoTeleport:
    ; Update position
    mov al, targetX
    mov pacman.mapX, al

    mov al, targetY
    mov pacman.mapY, al

    ; Update screen coordinates
    movzx eax, pacman.mapY
    add al, GAME_AREA_ROW_TOP
    mov pacman.screenY, al

    movzx eax, pacman.mapX
    add al, GAME_AREA_COL_LEFT
    mov pacman.screenX, al

    ; Play movement sound
    call PlayMoveSound

    ; Return success
    mov al, 1
    ret

UpdatePos_Blocked:
    ; Return blocked status
    mov al, 0
    ret
UpdatePlayerPosition ENDP

;--------------------------------------------------------------------------------
; TryChangeDirection - Try to change player's direction to desired direction
; Returns: AL = 1 if direction changed, AL = 0 if blocked
;--------------------------------------------------------------------------------
TryChangeDirection PROC USES EBX ECX EDX
    LOCAL targetX:BYTE, targetY:BYTE

    ; Check if desired direction is different from current
    mov al, pacman.direction
    mov ah, pacman.desiredDirection
    cmp al, ah
    je TryChange_NoChange    ; Already moving in desired direction

    ; Calculate target position in desired direction
    mov al, pacman.mapX
    mov targetX, al

    mov al, pacman.mapY
    mov targetY, al

    ; Adjust target based on desired direction
    mov al, pacman.desiredDirection
    cmp al, DIR_RIGHT
    jne TryChange_CheckLeft
    inc targetX
    jmp TryChange_CheckValid

TryChange_CheckLeft:
    cmp al, DIR_LEFT
    jne TryChange_CheckUp
    dec targetX
    jmp TryChange_CheckValid

TryChange_CheckUp:
    cmp al, DIR_UP
    jne TryChange_CheckDown
    dec targetY
    jmp TryChange_CheckValid

TryChange_CheckDown:
    inc targetY

TryChange_CheckValid:
    ; Check if movement in desired direction is possible
    mov bl, targetX
    mov bh, targetY
    call IsCollision

    ; If collision, cannot change direction
    cmp al, 1
    je TryChange_NoChange

    ; Change direction
    mov al, pacman.desiredDirection
    mov pacman.direction, al

    ; Return success
    mov al, 1
    ret

TryChange_NoChange:
    ; Return not changed
    mov al, 0
    ret
TryChangeDirection ENDP

;--------------------------------------------------------------------------------
; LevelComplete - Handle level completion
;--------------------------------------------------------------------------------
LevelComplete PROC USES EAX EDX
    ; Play level complete sound
    call PlayLevelCompleteSound

    ; Clear the screen
    call Clrscr

    ; Display level complete message
    mov dh, 10
    mov dl, 20
    call Gotoxy

    mov eax, LIGHT_GREEN_ON_BLACK
    call SetTextColor

    mov edx, OFFSET levelCompleteMsg
    call WriteString

    ; Display score
    mov dh, 12
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET scoreMsg
    call WriteString

    mov ax, pacman.score
    call WriteDec

    ; Wait for key press
    mov dh, 14
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET pressAnyKeyMsg
    call WriteString

    ; Wait for key press
    call ReadChar

    ; Clear the screen
    call Clrscr

    ; Set ESC flag to signal return to menu
    mov ah, ESC_SCAN_CODE

    ret
LevelComplete ENDP

;--------------------------------------------------------------------------------
; UpdatePlayer - Handle direction changes and movement
;--------------------------------------------------------------------------------
UpdatePlayer PROC USES EAX
    ; First try to change direction if desired
    call TryChangeDirection

    ; Then try to move in current direction
    call UpdatePlayerPosition

    ; Check if player moved successfully
    cmp al, 1
    jne UpdatePlayer_Exit

    ; Check for dot collection at new position
    call CheckForDot

    ; If dot collected, update status bar
    cmp al, 1
    jne UpdatePlayer_Exit

    ; Update status bar with new score
    call DrawStatusBar

    ; Check if all dots collected
    mov ax, dotsCollected
    cmp ax, totalDots
    jne UpdatePlayer_Exit

    ; All dots collected - level complete
    call LevelComplete

    ; LevelComplete sets ESC flag to signal exit to menu

UpdatePlayer_Exit:
    ret
UpdatePlayer ENDP

;--------------------------------------------------------------------------------
; InitializePlayer - Setup player's starting position and state
;--------------------------------------------------------------------------------
InitializePlayer PROC USES EAX
    ; Set player starting position on map
    mov pacman.mapX, 1
    mov pacman.mapY, 1

    ; Calculate screen coordinates
    movzx eax, pacman.mapY
    add al, GAME_AREA_ROW_TOP
    mov pacman.screenY, al

    movzx eax, pacman.mapX
    add al, GAME_AREA_COL_LEFT
    mov pacman.screenX, al

    ; Set initial direction and character
    mov pacman.direction, DIR_RIGHT
    mov pacman.desiredDirection, DIR_RIGHT

    ; Initialize animation state
    mov pacman.mouthOpen, 1
    mov pacman.animCounter, 0

    ; Set initial character based on direction and mouth state
    mov al, pacman.charRightOpen
    mov pacman.charCurrent, al

    ; Reset score and lives
    mov pacman.score, 0
    mov pacman.lives, 3

    ret
InitializePlayer ENDP

;--------------------------------------------------------------------------------
; InitializeDotArray - Set up the dot array based on the maze layout
;--------------------------------------------------------------------------------
InitializeDotArray PROC USES EAX EBX ECX EDX ESI EDI
    LOCAL rowIdx:BYTE, colIdx:BYTE

    ; Reset dot counters
    mov totalDots, 0
    mov dotsCollected, 0

    ; Initialize dot array - clear all dots first
    mov ecx, 1400        ; Size of dotArray
    mov edi, OFFSET dotArray
    mov al, 0
    cld
    rep stosb

    ; Initialize dot array
    mov rowIdx, 0

IDA_RowLoop:
    ; Check if we've processed all rows
    mov al, rowIdx
    cmp al, MAZE_MAX_ROWS_VAL
    jg IDA_Done

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout  ; Start with mazeLayout address
    movzx ebx, rowIdx
    shl ebx, 2                  ; Multiply by 4 (size of pointer)
    add esi, ebx                ; Point to the row pointer
    mov esi, [esi]              ; Get the actual row address

    ; Check if esi is valid (not null)
    cmp esi, 0
    je IDA_NextRow              ; Skip this row if pointer is null

    ; Start at column 0
    mov colIdx, 0

IDA_ColLoop:
    ; Check if we've processed all columns
    mov al, colIdx
    cmp al, MAZE_MAX_COLS_VAL
    jge IDA_NextRow

    ; Get character from maze
    movzx ebx, colIdx
    mov al, [esi + ebx]

    ; Calculate index in dot array
    movzx ecx, rowIdx
    movzx edx, colIdx
    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae IDA_NextCol

    mov edi, OFFSET dotArray
    add edi, ecx

    ; Check if this position should have a dot
    cmp al, MAZE_WALL_CHAR_DEF
    je IDA_NoDot

    cmp al, MAZE_PLAYER_START_CHAR
    je IDA_NoDot

    ; Check for power pellet (Level 2+)
    cmp al, MAZE_POWER_PELLET_CHAR
    je IDA_PowerPellet

    ; Check for fruit (Level 2+)
    cmp al, MAZE_FRUIT_CHAR
    je IDA_Fruit

    ; Check if it's already a dot
    cmp al, MAZE_DOT_CHAR
    je IDA_RegularDot

    ; If it's a space, make it a dot
    cmp al, MAZE_PATH_CHAR
    jne IDA_NoDot

    ; Replace space with dot in the maze layout
    mov BYTE PTR [esi + ebx], MAZE_DOT_CHAR

IDA_RegularDot:
    ; Add a regular dot
    mov BYTE PTR [edi], 1
    inc totalDots
    jmp IDA_NextCol

IDA_PowerPellet:
    ; Add a dot for power pellet (will be drawn differently)
    mov BYTE PTR [edi], 2  ; Use value 2 for power pellets to distinguish them from regular dots
    inc totalDots

    ; Make sure the power pellet character is preserved in the maze layout
    ; This ensures that power pellets are properly displayed
    mov BYTE PTR [esi + ebx], MAZE_POWER_PELLET_CHAR

    jmp IDA_NextCol

IDA_Fruit:
    ; No dot for fruit position
    mov BYTE PTR [edi], 0
    jmp IDA_NextCol

IDA_NoDot:
    mov BYTE PTR [edi], 0

IDA_NextCol:
    inc colIdx
    jmp IDA_ColLoop

IDA_NextRow:
    inc rowIdx
    jmp IDA_RowLoop

IDA_Done:
    ret
InitializeDotArray ENDP

;--------------------------------------------------------------------------------
; PlaySoundEffect - Play a sound using MessageBeep
;--------------------------------------------------------------------------------
PlaySoundEffect PROC USES EAX
    ; EAX = sound type (0-4)
    INVOKE MessageBeep, eax
    ret
PlaySoundEffect ENDP

;--------------------------------------------------------------------------------
; PlayDotSound - Play the dot collection sound
;--------------------------------------------------------------------------------
PlayDotSound PROC USES EAX
    mov eax, SOUND_INFORMATION
    call PlaySoundEffect
    ret
PlayDotSound ENDP

;--------------------------------------------------------------------------------
; PlayMoveSound - Play the movement sound
;--------------------------------------------------------------------------------
PlayMoveSound PROC USES EAX
    ; Disable movement sound as it can be annoying
    ; mov eax, SOUND_DEFAULT
    ; call PlaySoundEffect
    ret
PlayMoveSound ENDP

;--------------------------------------------------------------------------------
; PlayDeathSound - Play the death sound
;--------------------------------------------------------------------------------
PlayDeathSound PROC USES EAX
    mov eax, SOUND_ERROR
    call PlaySoundEffect
    ret
PlayDeathSound ENDP

;--------------------------------------------------------------------------------
; PlayLevelCompleteSound - Play the level complete sound
;--------------------------------------------------------------------------------
PlayLevelCompleteSound PROC USES EAX
    mov eax, SOUND_EXCLAMATION
    call PlaySoundEffect
    ret
PlayLevelCompleteSound ENDP

;--------------------------------------------------------------------------------
; CheckForDot - Check if there's a dot at the player's position and collect it
; Returns: AL = 1 if dot collected, AL = 0 if no dot
;--------------------------------------------------------------------------------
CheckForDot PROC USES EBX ECX EDX ESI EDI
    ; Calculate index in dot array
    movzx ecx, pacman.mapY
    cmp ecx, MAZE_MAX_ROWS_VAL  ; Check row bounds
    ja CFD_NoDot

    movzx edx, pacman.mapX
    cmp edx, MAZE_MAX_COLS_VAL  ; Check column bounds
    ja CFD_NoDot

    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae CFD_NoDot

    mov esi, OFFSET dotArray
    add esi, ecx

    ; Check if there's a dot or power pellet at this position
    mov al, BYTE PTR [esi]
    cmp al, 0
    je CFD_NoDot

    ; Check if it's a power pellet (value 2)
    cmp al, 2
    je CFD_PowerPellet

    ; It's a regular dot (value 1)
    ; Collect the dot
    mov BYTE PTR [esi], 0
    inc dotsCollected
    jmp CFD_RegularDot

CFD_PowerPellet:
    ; It's a power pellet
    ; Collect the power pellet
    mov BYTE PTR [esi], 0
    inc dotsCollected

    ; Check if this is a power pellet (Level 2+)
    cmp currentLevel, 1
    jle CFD_RegularDot

    ; Get the character at this position in the maze
    push eax
    push ebx

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout  ; Start with mazeLayout address
    movzx ebx, pacman.mapY
    shl ebx, 2                  ; Multiply by 4 (size of pointer)
    add esi, ebx                ; Point to the row pointer
    mov esi, [esi]              ; Get the actual row address

    ; Get character from maze
    movzx ebx, pacman.mapX
    mov al, [esi + ebx]

    ; Check if it's a power pellet
    cmp al, MAZE_POWER_PELLET_CHAR
    pop ebx
    pop eax
    jne CFD_RegularDot

    ; It's a power pellet - activate power pellet mode
    mov powerPelletActive, 1
    mov powerPelletTimer, POWER_PELLET_DURATION

    ; Play power pellet sound
    mov eax, SOUND_EXCLAMATION
    call MessageBeep

    ; Reset frame counter for consistent timing
    mov frameCounter, 0

    ; Set ghost states to scared
    mov blinky.state, GHOST_STATE_SCARED

    ; Check if we need to update Pinky (Level 2+)
    cmp ghostCount, 1
    jle CFD_SkipPinkyScared
    mov pinky.state, GHOST_STATE_SCARED

CFD_SkipPinkyScared:
    ; Check if we need to update Inky (Level 3+)
    cmp ghostCount, 2
    jle CFD_SkipInkyScared
    mov inky.state, GHOST_STATE_SCARED

CFD_SkipInkyScared:
    ; Add power pellet points to score based on level
    mov ax, pacman.score

    ; Base points
    mov bx, POWER_PELLET_POINTS

    ; Multiply by level for higher levels
    movzx cx, currentLevel
    imul bx, cx

    ; Add points to score
    add ax, bx
    mov pacman.score, ax

    ; Play power pellet sound
    mov eax, SOUND_EXCLAMATION
    call MessageBeep

    jmp CFD_DotCollected

CFD_RegularDot:
    ; Add regular dot points to score based on level
    mov ax, pacman.score

    ; Base points
    mov bx, DOT_POINTS

    ; Multiply by level for higher levels
    movzx cx, currentLevel
    imul bx, cx

    ; Add points to score
    add ax, bx
    mov pacman.score, ax

    ; Play dot collection sound
    call PlayDotSound

CFD_DotCollected:
    ; Return dot collected
    mov al, 1
    ret

CFD_NoDot:
    ; Return no dot
    mov al, 0
    ret
CheckForDot ENDP

;--------------------------------------------------------------------------------
; DrawMaze - Draw the entire maze on screen
;--------------------------------------------------------------------------------
DrawMaze PROC
    LOCAL currentScreenY :BYTE, currentScreenX :BYTE
    LOCAL mazeMapRowIdx  :BYTE, mazeMapColIdx  :BYTE
    LOCAL charFromMaze   :BYTE
    pushad

    ; Initialize dot array
    call InitializeDotArray

    ; Make sure ESI points to mazeLayout
    mov esi, OFFSET mazeLayout
    mov mazeMapRowIdx, 0

DM_RowLoop:
    ; Check if we've processed all rows
    mov bl, mazeMapRowIdx
    mov al, MAZE_MAX_ROWS_VAL
    cmp bl, al
    jge DM_Done

    ; Get pointer to current row
    movzx ebx, mazeMapRowIdx
    shl ebx, 2
    mov edi, [esi + ebx]

    ; Check if edi is valid (not null)
    cmp edi, 0
    je DM_NextRow              ; Skip this row if pointer is null

    ; Start at column 0
    mov mazeMapColIdx, 0

DM_ColLoop:
    ; Check if we've processed all columns in this row
    mov bl, mazeMapColIdx
    mov al, MAZE_MAX_COLS_VAL
    cmp bl, al
    jge DM_NextRow

    ; Calculate screen coordinates
    mov al, GAME_AREA_ROW_TOP
    add al, mazeMapRowIdx
    mov currentScreenY, al

    mov al, GAME_AREA_COL_LEFT
    add al, mazeMapColIdx
    mov currentScreenX, al

    ; Position cursor
    mov dh, currentScreenY
    mov dl, currentScreenX
    call Gotoxy

    ; Get character from maze
    movzx ebx, mazeMapColIdx
    mov al, [edi + ebx]
    mov charFromMaze, al

    ; Determine what to draw based on maze character
    cmp al, MAZE_WALL_CHAR_DEF
    je DM_DrawWall

    cmp al, MAZE_PLAYER_START_CHAR
    je DM_DrawPlayerStartAsPath

    cmp al, MAZE_POWER_PELLET_CHAR
    je DM_CheckPowerPellet

    cmp al, MAZE_FRUIT_CHAR
    je DM_DrawFruit

    cmp al, MAZE_TELEPORT_CHAR
    je DM_DrawTeleport

    ; Check if this position has a regular dot in the dot array
    pushad                ; Save all registers

    movzx ecx, mazeMapRowIdx
    movzx edx, mazeMapColIdx
    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae DM_CheckDot_Done

    mov ebx, OFFSET dotArray
    add ebx, ecx
    ; Check specifically for regular dot (value 1), not power pellet (value 2)
    cmp BYTE PTR [ebx], 1
    jne DM_CheckDot_Done

    ; Dot found
    popad                ; Restore all registers
    jmp DM_DrawDot

DM_CheckDot_Done:
    popad                ; Restore all registers
    jmp DM_DrawPath

DM_DrawDot:

    ; Draw a dot
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar
    jmp DM_NextChar

DM_DrawPath:
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar
    jmp DM_NextChar

DM_DrawWall:
    mov eax, MAZE_WALL_COLOR
    call SetTextColor
    mov al, MAZE_WALL_CHAR_DRAW
    call WriteChar
    jmp DM_NextChar

DM_DrawPlayerStartAsPath:
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar
    jmp DM_NextChar

DM_CheckPowerPellet:
    ; Check if this position has a power pellet in the dot array (if collected, don't draw)
    pushad                ; Save all registers

    movzx ecx, mazeMapRowIdx
    movzx edx, mazeMapColIdx
    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae DM_PowerPellet_Done

    mov ebx, OFFSET dotArray
    add ebx, ecx
    cmp BYTE PTR [ebx], 2  ; Check for power pellet (value 2)
    jne DM_PowerPellet_Done

    ; Power pellet found and not collected
    popad                ; Restore all registers

    ; CRITICAL FIX: Make sure the power pellet character is preserved in the maze layout
    ; This ensures that power pellets are properly displayed
    pushad
    mov esi, OFFSET mazeLayout
    movzx ebx, mazeMapRowIdx
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]
    movzx ebx, mazeMapColIdx
    mov BYTE PTR [esi + ebx], MAZE_POWER_PELLET_CHAR
    popad

    jmp DM_DrawPowerPellet

DM_PowerPellet_Done:
    popad                ; Restore all registers
    jmp DM_DrawPath

DM_DrawPowerPellet:
    ; Draw a power pellet (larger dot)
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar
    jmp DM_NextChar

DM_DrawFruit:
    ; Draw a fruit
    mov eax, GREEN_ON_BLACK
    call SetTextColor
    mov al, MAZE_FRUIT_CHAR
    call WriteChar
    jmp DM_NextChar

DM_DrawTeleport:
    ; Draw a teleport path
    mov eax, CYAN_ON_BLACK
    call SetTextColor
    mov al, MAZE_TELEPORT_CHAR
    call WriteChar
    jmp DM_NextChar

DM_NextChar:
    inc mazeMapColIdx
    jmp DM_ColLoop

DM_NextRow:
    inc mazeMapRowIdx
    mov esi, OFFSET mazeLayout  ; Restore ESI to mazeLayout for next row
    jmp DM_RowLoop

DM_Done:
    ; Restore ESI to maze layout for other procedures
    mov esi, OFFSET mazeLayout
    popad
    ret
DrawMaze ENDP

;--------------------------------------------------------------------------------
; UpdateScoreDisplay - Convert score to string for display
;--------------------------------------------------------------------------------
UpdateScoreDisplay PROC USES EAX EBX ECX EDX ESI EDI
    ; Convert score to string
    mov ax, pacman.score
    mov ebx, 10
    mov ecx, 5       ; 5 digits for score
    mov edi, OFFSET scoreStr
    add edi, 4       ; Start at rightmost digit

UpdateScoreLoop:
    xor edx, edx     ; Clear EDX for division
    div bx           ; Divide AX by 10, remainder in DL
    add dl, '0'      ; Convert to ASCII
    mov [edi], dl    ; Store digit
    dec edi          ; Move to next digit position
    loop UpdateScoreLoop

    ; Update lives display
    mov al, pacman.lives
    add al, '0'      ; Convert to ASCII
    mov livesStr, al

    ; Update level display
    mov al, currentLevel
    add al, '0'      ; Convert to ASCII
    mov levelStr, al

    ret
UpdateScoreDisplay ENDP

;--------------------------------------------------------------------------------
; DrawStatusBar - Draw the status information at the top and bottom of screen
;--------------------------------------------------------------------------------
DrawStatusBar PROC USES EAX EDX
    ; Update score display first
    call UpdateScoreDisplay

    ; Draw top status bar
    mov dh, STATUS_ROW_TOP
    mov dl, 0
    call Gotoxy

    mov eax, LIGHT_GRAY_ON_BLACK
    call SetTextColor

    ; Display top status line with score and lives
    mov edx, OFFSET topStatusLineMsg
    call WriteString

    mov edx, OFFSET scoreStr
    call WriteString

    mov edx, OFFSET scoreDisplay
    call WriteString

    mov edx, OFFSET livesStr
    call WriteString

    mov edx, OFFSET levelDisplay
    call WriteString

    mov edx, OFFSET levelStr
    call WriteString

    ; Draw bottom status bar
    mov dh, STATUS_ROW_BOTTOM
    mov dl, 0
    call Gotoxy

    mov eax, LIGHT_GRAY_ON_BLACK
    call SetTextColor
    mov edx, OFFSET gameStatusMsg
    call WriteString

    ret
DrawStatusBar ENDP

;--------------------------------------------------------------------------------
; InitializeGhosts - Set up ghosts' starting positions and states
;--------------------------------------------------------------------------------
InitializeGhosts PROC USES EAX
    ; Initialize ghosts based on current level
    cmp currentLevel, 1
    je IG_Level1
    cmp currentLevel, 2
    je IG_Level2

    ; Default to level 1 if invalid level
    jmp IG_Level1

IG_Level1:
    ; Initialize Blinky (Red Ghost) for Level 1
    mov blinky.mapX, 9
    mov blinky.mapY, 9

    ; Calculate screen coordinates
    movzx eax, blinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov blinky.screenY, al

    movzx eax, blinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov blinky.screenX, al

    ; Set initial direction and state
    mov blinky.direction, DIR_RIGHT
    mov blinky.state, GHOST_STATE_NORMAL
    mov blinky.moveCounter, 0
    mov blinky.tileUnder, ' '

    jmp IG_Exit

IG_Level2:
    ; Initialize Blinky (Red Ghost) for Level 2
    mov blinky.mapX, 9
    mov blinky.mapY, 9

    ; Calculate screen coordinates
    movzx eax, blinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov blinky.screenY, al

    movzx eax, blinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov blinky.screenX, al

    ; Set initial direction and state
    mov blinky.direction, DIR_RIGHT
    mov blinky.state, GHOST_STATE_NORMAL
    mov blinky.moveCounter, 0
    mov blinky.tileUnder, ' '

    ; Check if we need to initialize Pinky (Level 2+)
    cmp ghostCount, 1
    jle IG_Exit  ; Skip if only one ghost

    ; Initialize Pinky (Pink Ghost) for Level 2
    mov pinky.mapX, 35
    mov pinky.mapY, 9

    ; Calculate screen coordinates
    movzx eax, pinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov pinky.screenY, al

    movzx eax, pinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov pinky.screenX, al

    ; Set initial direction and state
    mov pinky.direction, DIR_LEFT
    mov pinky.state, GHOST_STATE_NORMAL
    mov pinky.moveCounter, 0
    mov pinky.tileUnder, ' '

    ; Check if we need to initialize Inky (Level 3+)
    cmp ghostCount, 2
    jle IG_Exit  ; Skip if only two ghosts

    ; Initialize Inky (Cyan Ghost) for Level 3
    mov inky.mapX, 35
    mov inky.mapY, 13

    ; Calculate screen coordinates
    movzx eax, inky.mapY
    add al, GAME_AREA_ROW_TOP
    mov inky.screenY, al

    movzx eax, inky.mapX
    add al, GAME_AREA_COL_LEFT
    mov inky.screenX, al

    ; Set initial direction and state
    mov inky.direction, DIR_UP
    mov inky.state, GHOST_STATE_NORMAL
    mov inky.moveCounter, 0
    mov inky.tileUnder, ' '

IG_Exit:
    ret
InitializeGhosts ENDP

;--------------------------------------------------------------------------------
; EraseGhost - Erase ghost from current position
;--------------------------------------------------------------------------------
EraseGhost PROC USES EAX EDX ESI EDI
    ; Erase Blinky (first ghost)
    call EraseGhostBlinky

    ; Check if we need to erase Pinky (Level 2+)
    cmp ghostCount, 1
    jle EG_Exit  ; Skip if only one ghost

    ; Erase Pinky (second ghost)
    call EraseGhostPinky

    ; Check if we need to erase Inky (Level 3+)
    cmp ghostCount, 2
    jle EG_Exit  ; Skip if only two ghosts

    ; Erase Inky (third ghost)
    call EraseGhostInky

EG_Exit:
    ret
EraseGhost ENDP

;--------------------------------------------------------------------------------
; EraseGhostBlinky - Erase Blinky (red ghost) from current position
;--------------------------------------------------------------------------------
EraseGhostBlinky PROC USES EAX EDX ESI EDI
    ; Get ghost position
    mov dh, blinky.screenY
    mov dl, blinky.screenX
    call Gotoxy

    ; Check the saved tile under the ghost
    mov al, blinky.tileUnder

    ; Check what type of tile it is
    cmp al, MAZE_DOT_CHAR
    je EGB_DrawDot

    cmp al, MAZE_POWER_PELLET_CHAR
    je EGB_DrawPowerPellet

    ; Check if we need to check the dot array for a power pellet
    ; This is needed because the ghost might have moved over a power pellet
    pushad

    ; Calculate index in dot array
    movzx ecx, blinky.mapY
    movzx edx, blinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGB_CheckDotArray_Done

    ; Check if there's a power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 2  ; 2 indicates a power pellet
    jne EGB_CheckDotArray_Done

    ; There's a power pellet here in the dot array - restore it
    popad
    jmp EGB_DrawPowerPellet

EGB_CheckDotArray_Done:
    popad

    ; Default to path
    jmp EGB_DrawPath

EGB_DrawDot:
    ; CRITICAL FIX: Check if this dot has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, blinky.mapY
    movzx edx, blinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGB_SkipDotCheck

    ; Check if dot has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGB_DrawDotNormal

    ; Dot has been collected, draw path instead
    popad
    jmp EGB_DrawPath

EGB_DrawDotNormal:
    popad

    ; Draw a dot
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    ; Update the maze layout to show the dot
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, blinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, blinky.mapX
    mov BYTE PTR [esi + ebx], MAZE_DOT_CHAR

    popad

    jmp EGB_Exit

EGB_SkipDotCheck:
    popad

    ; Draw a dot (fallback)
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    jmp EGB_Exit

EGB_DrawPowerPellet:
    ; CRITICAL FIX: Check if this power pellet has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, blinky.mapY
    movzx edx, blinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGB_SkipPowerPelletCheck

    ; Check if power pellet has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGB_DrawPowerPelletNormal

    ; Power pellet has been collected, draw path instead
    popad
    jmp EGB_DrawPath

EGB_DrawPowerPelletNormal:
    popad

    ; Draw a power pellet
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    ; Update the maze layout to show the power pellet
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, blinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, blinky.mapX
    mov BYTE PTR [esi + ebx], MAZE_POWER_PELLET_CHAR

    popad

    jmp EGB_Exit

EGB_SkipPowerPelletCheck:
    popad

    ; Draw a power pellet (fallback)
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    jmp EGB_Exit

EGB_DrawPath:
    ; Draw blank space
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar

EGB_Exit:
    ret
EraseGhostBlinky ENDP

;--------------------------------------------------------------------------------
; EraseGhostPinky - Erase Pinky (pink ghost) from current position
;--------------------------------------------------------------------------------
EraseGhostPinky PROC USES EAX EDX ESI EDI
    ; Get ghost position
    mov dh, pinky.screenY
    mov dl, pinky.screenX
    call Gotoxy

    ; Check the saved tile under the ghost
    mov al, pinky.tileUnder

    ; Check what type of tile it is
    cmp al, MAZE_DOT_CHAR
    je EGP_DrawDot

    cmp al, MAZE_POWER_PELLET_CHAR
    je EGP_DrawPowerPellet

    ; Check if we need to check the dot array for a power pellet
    ; This is needed because the ghost might have moved over a power pellet
    pushad

    ; Calculate index in dot array
    movzx ecx, pinky.mapY
    movzx edx, pinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGP_CheckDotArray_Done

    ; Check if there's a power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 2  ; 2 indicates a power pellet
    jne EGP_CheckDotArray_Done

    ; There's a power pellet here in the dot array - restore it
    popad
    jmp EGP_DrawPowerPellet

EGP_CheckDotArray_Done:
    popad

    ; Default to path
    jmp EGP_DrawPath

EGP_DrawDot:
    ; CRITICAL FIX: Check if this dot has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, pinky.mapY
    movzx edx, pinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGP_SkipDotCheck

    ; Check if dot has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGP_DrawDotNormal

    ; Dot has been collected, draw path instead
    popad
    jmp EGP_DrawPath

EGP_DrawDotNormal:
    popad

    ; Draw a dot
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    ; Update the maze layout to show the dot
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, pinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, pinky.mapX
    mov BYTE PTR [esi + ebx], MAZE_DOT_CHAR

    popad

    jmp EGP_Exit

EGP_SkipDotCheck:
    popad

    ; Draw a dot (fallback)
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    jmp EGP_Exit

EGP_DrawPowerPellet:
    ; CRITICAL FIX: Check if this power pellet has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, pinky.mapY
    movzx edx, pinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGP_SkipPowerPelletCheck

    ; Check if power pellet has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGP_DrawPowerPelletNormal

    ; Power pellet has been collected, draw path instead
    popad
    jmp EGP_DrawPath

EGP_DrawPowerPelletNormal:
    popad

    ; Draw a power pellet
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    ; Update the maze layout to show the power pellet
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, pinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, pinky.mapX
    mov BYTE PTR [esi + ebx], MAZE_POWER_PELLET_CHAR

    popad

    jmp EGP_Exit

EGP_SkipPowerPelletCheck:
    popad

    ; Draw a power pellet (fallback)
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    jmp EGP_Exit

EGP_DrawPath:
    ; Draw blank space
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar

EGP_Exit:
    ret
EraseGhostPinky ENDP

;--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------
; EraseGhostInky - Removes Inky from the screen and restores what was underneath
; This is called whenever Inky moves to a new position
;--------------------------------------------------------------------------------
EraseGhostInky PROC USES EAX EDX ESI EDI
    ; Move cursor to where Inky currently is
    mov dh, inky.screenY
    mov dl, inky.screenX
    call Gotoxy

    ; Get what was under Inky before he moved here
    mov al, inky.tileUnder

    ; Figure out what to draw based on what was here
    cmp al, MAZE_DOT_CHAR
    je EGI_DrawDot        ; There was a dot here

    cmp al, MAZE_POWER_PELLET_CHAR
    je EGI_DrawPowerPellet ; There was a power pellet here

    ; Double-check the dot array to see if there should be a power pellet here
    ; This helps prevent ghosts from "eating" power pellets
    pushad

    ; Calculate index in dot array
    movzx ecx, inky.mapY
    movzx edx, inky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGI_CheckDotArray_Done

    ; Check if there's a power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 2  ; 2 indicates a power pellet
    jne EGI_CheckDotArray_Done

    ; There's a power pellet here in the dot array - restore it
    popad
    jmp EGI_DrawPowerPellet

EGI_CheckDotArray_Done:
    popad

    ; Default to path
    jmp EGI_DrawPath

EGI_DrawDot:
    ; CRITICAL FIX: Check if this dot has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, inky.mapY
    movzx edx, inky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGI_SkipDotCheck

    ; Check if dot has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGI_DrawDotNormal

    ; Dot has been collected, draw path instead
    popad
    jmp EGI_DrawPath

EGI_DrawDotNormal:
    popad

    ; Draw a dot
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    ; Update the maze layout to show the dot
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, inky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, inky.mapX
    mov BYTE PTR [esi + ebx], MAZE_DOT_CHAR

    popad

    jmp EGI_Exit

EGI_SkipDotCheck:
    popad

    ; Draw a dot (fallback)
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar

    jmp EGI_Exit

EGI_DrawPowerPellet:
    ; CRITICAL FIX: Check if this power pellet has been collected
    pushad

    ; Calculate index in dot array
    movzx ecx, inky.mapY
    movzx edx, inky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae EGI_SkipPowerPelletCheck

    ; Check if power pellet has been collected (value 0)
    mov edi, OFFSET dotArray
    add edi, ecx
    cmp BYTE PTR [edi], 0
    jne EGI_DrawPowerPelletNormal

    ; Power pellet has been collected, draw path instead
    popad
    jmp EGI_DrawPath

EGI_DrawPowerPelletNormal:
    popad

    ; Draw a power pellet
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    ; Update the maze layout to show the power pellet
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, inky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Set the character in the maze layout
    movzx ebx, inky.mapX
    mov BYTE PTR [esi + ebx], MAZE_POWER_PELLET_CHAR

    popad

    jmp EGI_Exit

EGI_SkipPowerPelletCheck:
    popad

    ; Draw a power pellet (fallback)
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar

    jmp EGI_Exit

EGI_DrawPath:
    ; Draw blank space
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar

EGI_Exit:
    ret
EraseGhostInky ENDP

;--------------------------------------------------------------------------------
; DrawGhost - Master ghost drawing routine
; Draws all active ghosts based on the current level
;--------------------------------------------------------------------------------
DrawGhost PROC USES EAX EDX
    ; Always draw Blinky (the red ghost) - present in all levels
    call DrawGhostBlinky

    ; For Level 2 and above, we add Pinky (the pink ghost)
    cmp ghostCount, 1
    jle DG_Exit  ; If we're on Level 1, we're done

    ; Draw Pinky for Level 2+
    call DrawGhostPinky

    ; For Level 3, we also add Inky (the cyan ghost)
    cmp ghostCount, 2
    jle DG_Exit  ; If we're on Level 2, we're done

    ; Draw Inky for Level 3
    call DrawGhostInky

DG_Exit:
    ret
DrawGhost ENDP

;--------------------------------------------------------------------------------
; DrawGhostBlinky - Draws Blinky (the red ghost) on the screen
; Appearance changes based on current state (normal, scared, or eaten)
;--------------------------------------------------------------------------------
DrawGhostBlinky PROC USES EAX EDX
    ; Position the cursor where Blinky should appear
    mov dh, blinky.screenY
    mov dl, blinky.screenX
    call Gotoxy

    ; Check what state Blinky is in to determine appearance
    mov al, blinky.state
    cmp al, GHOST_STATE_NORMAL
    jne DGB_CheckScared

    ; Normal hunting state - red and aggressive
    mov ax, blinky.color      ; Red color
    call SetTextColor
    mov al, blinky.charNormal ; 'B' character
    jmp DGB_Draw

DGB_CheckScared:
    cmp al, GHOST_STATE_SCARED
    jne DGB_CheckEaten

    ; Scared/vulnerable state - blue and frightened
    mov eax, BLUE_ON_BLACK    ; Blue color
    call SetTextColor
    mov al, blinky.charScared ; 'S' character
    jmp DGB_Draw

DGB_CheckEaten:
    ; Eaten state - returning to ghost house
    mov eax, WHITE_ON_BLACK   ; White color
    call SetTextColor
    mov al, blinky.charEaten  ; 'E' character

DGB_Draw:
    ; Draw the ghost character
    call WriteChar

    ; Remember what's under the ghost for when it moves
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, blinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character at ghost position
    movzx ebx, blinky.mapX

    ; Calculate index in dot array
    movzx ecx, blinky.mapY
    movzx edx, blinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae DGB_PreserveDone

    ; Check if there's a dot or power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx

    ; Check for regular dot (value 1)
    cmp BYTE PTR [edi], 1
    jne DGB_CheckPowerPellet

    ; There's a regular dot here - preserve it
    mov blinky.tileUnder, MAZE_DOT_CHAR
    jmp DGB_PreserveDone

DGB_CheckPowerPellet:
    ; Check for power pellet (value 2)
    cmp BYTE PTR [edi], 2
    jne DGB_PreserveDone

    ; There's a power pellet here - preserve it
    mov blinky.tileUnder, MAZE_POWER_PELLET_CHAR

DGB_PreserveDone:
    popad

    ret
DrawGhostBlinky ENDP

;--------------------------------------------------------------------------------
; DrawGhostPinky - Draw Pinky (pink ghost) at current position
;--------------------------------------------------------------------------------
DrawGhostPinky PROC USES EAX EDX
    ; Set cursor to ghost position
    mov dh, pinky.screenY
    mov dl, pinky.screenX
    call Gotoxy

    ; Check ghost state
    mov al, pinky.state
    cmp al, GHOST_STATE_NORMAL
    jne DGP_CheckScared

    ; Normal state - draw with proper character and color
    mov ax, pinky.color
    call SetTextColor
    mov al, pinky.charNormal
    jmp DGP_Draw

DGP_CheckScared:
    cmp al, GHOST_STATE_SCARED
    jne DGP_CheckEaten

    ; Scared state - draw with blue color
    mov eax, BLUE_ON_BLACK
    call SetTextColor
    mov al, pinky.charScared
    jmp DGP_Draw

DGP_CheckEaten:
    ; Eaten state - draw with white color
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, pinky.charEaten

DGP_Draw:
    call WriteChar

    ; CRITICAL FIX: Make sure the dot is preserved in the dot array
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, pinky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character at ghost position
    movzx ebx, pinky.mapX

    ; Calculate index in dot array
    movzx ecx, pinky.mapY
    movzx edx, pinky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae DGP_PreserveDone

    ; Check if there's a dot or power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx

    ; Check for regular dot (value 1)
    cmp BYTE PTR [edi], 1
    jne DGP_CheckPowerPellet

    ; There's a regular dot here - preserve it
    mov pinky.tileUnder, MAZE_DOT_CHAR
    jmp DGP_PreserveDone

DGP_CheckPowerPellet:
    ; Check for power pellet (value 2)
    cmp BYTE PTR [edi], 2
    jne DGP_PreserveDone

    ; There's a power pellet here - preserve it
    mov pinky.tileUnder, MAZE_POWER_PELLET_CHAR

DGP_PreserveDone:
    popad

    ret
DrawGhostPinky ENDP

;--------------------------------------------------------------------------------
; DrawGhostInky - Draw Inky (cyan ghost) at current position
;--------------------------------------------------------------------------------
DrawGhostInky PROC USES EAX EDX
    ; Set cursor to ghost position
    mov dh, inky.screenY
    mov dl, inky.screenX
    call Gotoxy

    ; Check ghost state
    mov al, inky.state
    cmp al, GHOST_STATE_NORMAL
    jne DGI_CheckScared

    ; Normal state - draw with proper character and color
    mov ax, inky.color
    call SetTextColor
    mov al, inky.charNormal
    jmp DGI_Draw

DGI_CheckScared:
    cmp al, GHOST_STATE_SCARED
    jne DGI_CheckEaten

    ; Scared state - draw with blue color
    mov eax, BLUE_ON_BLACK
    call SetTextColor
    mov al, inky.charScared
    jmp DGI_Draw

DGI_CheckEaten:
    ; Eaten state - draw with white color
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, inky.charEaten

DGI_Draw:
    call WriteChar

    ; CRITICAL FIX: Make sure the dot is preserved in the dot array
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, inky.mapY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character at ghost position
    movzx ebx, inky.mapX

    ; Calculate index in dot array
    movzx ecx, inky.mapY
    movzx edx, inky.mapX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae DGI_PreserveDone

    ; Check if there's a dot or power pellet at this position in the dot array
    mov edi, OFFSET dotArray
    add edi, ecx

    ; Check for regular dot (value 1)
    cmp BYTE PTR [edi], 1
    jne DGI_CheckPowerPellet

    ; There's a regular dot here - preserve it
    mov inky.tileUnder, MAZE_DOT_CHAR
    jmp DGI_PreserveDone

DGI_CheckPowerPellet:
    ; Check for power pellet (value 2)
    cmp BYTE PTR [edi], 2
    jne DGI_PreserveDone

    ; There's a power pellet here - preserve it
    mov inky.tileUnder, MAZE_POWER_PELLET_CHAR

DGI_PreserveDone:
    popad

    ret
DrawGhostInky ENDP

;--------------------------------------------------------------------------------
; UpdateGhostPosition - Update ghost position based on current direction
; Returns: AL = 1 if ghost moved, AL = 0 if blocked
;--------------------------------------------------------------------------------
UpdateGhostPosition PROC USES EBX ECX EDX
    ; Update Blinky (first ghost)
    call UpdateGhostPositionBlinky

    ; Store result in BL
    mov bl, al

    ; Check if we need to update Pinky (Level 2+)
    cmp ghostCount, 1
    jle UGP_Exit  ; Skip if only one ghost

    ; Update Pinky (second ghost)
    call UpdateGhostPositionPinky

    ; Combine results - if either ghost moved, return 1
    or bl, al

    ; Check if we need to update Inky (Level 3+)
    cmp ghostCount, 2
    jle UGP_Exit  ; Skip if only two ghosts

    ; Update Inky (third ghost)
    call UpdateGhostPositionInky

    ; Combine results - if any ghost moved, return 1
    or bl, al

UGP_Exit:
    ; Return combined result
    mov al, bl
    ret
UpdateGhostPosition ENDP

;--------------------------------------------------------------------------------
; UpdateGhostPositionBlinky - Update Blinky's position based on current direction
; Returns: AL = 1 if ghost moved, AL = 0 if blocked
;--------------------------------------------------------------------------------
UpdateGhostPositionBlinky PROC USES EBX ECX EDX
    LOCAL targetX:BYTE, targetY:BYTE

    ; Increment move counter
    inc blinky.moveCounter

    ; Check if it's time to move based on ghost speed
    mov al, blinky.moveCounter
    cmp al, blinky.speed
    jl UGPB_NoMove

    ; Reset move counter
    mov blinky.moveCounter, 0

    ; Calculate target position based on current direction
    mov al, blinky.mapX
    mov targetX, al

    mov al, blinky.mapY
    mov targetY, al

    ; Adjust target based on direction
    mov al, blinky.direction
    cmp al, DIR_RIGHT
    jne UGPB_CheckLeft
    inc targetX
    jmp UGPB_CheckCollision

UGPB_CheckLeft:
    cmp al, DIR_LEFT
    jne UGPB_CheckUp
    dec targetX
    jmp UGPB_CheckCollision

UGPB_CheckUp:
    cmp al, DIR_UP
    jne UGPB_CheckDown
    dec targetY
    jmp UGPB_CheckCollision

UGPB_CheckDown:
    inc targetY

UGPB_CheckCollision:
    ; Check for collision at target position
    mov bl, targetX
    mov bh, targetY
    call IsCollision

    ; If collision, choose a new random direction
    cmp al, 1
    je UGPB_ChooseNewDirection

    ; No collision - get the character at the target position
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, targetY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character from maze
    movzx ebx, targetX
    mov al, [esi + ebx]

    ; Save the character for later restoration
    mov blinky.tileUnder, al

    ; Check if it's a dot or power pellet
    cmp al, MAZE_DOT_CHAR
    je UGPB_SaveDot

    cmp al, MAZE_POWER_PELLET_CHAR
    je UGPB_SavePowerPellet

    jmp UGPB_DoneSaving

UGPB_SaveDot:
    ; It's a dot - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPB_DoneSaving

    ; Set dot as present in the array
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 1

    ; CRITICAL FIX: Replace the dot with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the dot
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

    jmp UGPB_DoneSaving

UGPB_SavePowerPellet:
    ; It's a power pellet - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPB_DoneSaving

    ; Set dot as present in the array with special value 2 for power pellets
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 2  ; Use value 2 for power pellets

    ; CRITICAL FIX: Replace the power pellet with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the power pellet
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

UGPB_DoneSaving:
    popad

    ; Update position
    mov al, targetX
    mov blinky.mapX, al

    mov al, targetY
    mov blinky.mapY, al

    ; Update screen coordinates
    movzx eax, blinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov blinky.screenY, al

    movzx eax, blinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov blinky.screenX, al

    ; Return success
    mov al, 1
    ret

UGPB_ChooseNewDirection:
    ; Choose a new random direction
    call Randomize
    mov eax, 4      ; 0-3 for directions
    call RandomRange
    mov blinky.direction, al

UGPB_NoMove:
    ; Return no movement
    mov al, 0
    ret
UpdateGhostPositionBlinky ENDP

;--------------------------------------------------------------------------------
; UpdateGhostPositionPinky - Update Pinky's position based on current direction
; Returns: AL = 1 if ghost moved, AL = 0 if blocked
;--------------------------------------------------------------------------------
UpdateGhostPositionPinky PROC USES EBX ECX EDX
    LOCAL targetX:BYTE, targetY:BYTE

    ; Increment move counter
    inc pinky.moveCounter

    ; Check if it's time to move based on ghost speed
    mov al, pinky.moveCounter
    cmp al, pinky.speed
    jl UGPP_NoMove

    ; Reset move counter
    mov pinky.moveCounter, 0

    ; Calculate target position based on current direction
    mov al, pinky.mapX
    mov targetX, al

    mov al, pinky.mapY
    mov targetY, al

    ; Adjust target based on direction
    mov al, pinky.direction
    cmp al, DIR_RIGHT
    jne UGPP_CheckLeft
    inc targetX
    jmp UGPP_CheckCollision

UGPP_CheckLeft:
    cmp al, DIR_LEFT
    jne UGPP_CheckUp
    dec targetX
    jmp UGPP_CheckCollision

UGPP_CheckUp:
    cmp al, DIR_UP
    jne UGPP_CheckDown
    dec targetY
    jmp UGPP_CheckCollision

UGPP_CheckDown:
    inc targetY

UGPP_CheckCollision:
    ; Check for collision at target position
    mov bl, targetX
    mov bh, targetY
    call IsCollision

    ; If collision, choose a new random direction
    cmp al, 1
    je UGPP_ChooseNewDirection

    ; No collision - get the character at the target position
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, targetY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character from maze
    movzx ebx, targetX
    mov al, [esi + ebx]

    ; Save the character for later restoration
    mov pinky.tileUnder, al

    ; Check if it's a dot or power pellet
    cmp al, MAZE_DOT_CHAR
    je UGPP_SaveDot

    cmp al, MAZE_POWER_PELLET_CHAR
    je UGPP_SavePowerPellet

    jmp UGPP_DoneSaving

UGPP_SaveDot:
    ; It's a dot - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPP_DoneSaving

    ; Set dot as present in the array
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 1

    ; Replace the dot with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the dot
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

    jmp UGPP_DoneSaving

UGPP_SavePowerPellet:
    ; It's a power pellet - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPP_DoneSaving

    ; Set dot as present in the array with special value 2 for power pellets
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 2  ; Use value 2 for power pellets

    ; Replace the power pellet with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the power pellet
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

UGPP_DoneSaving:
    popad

    ; Update position
    mov al, targetX
    mov pinky.mapX, al

    mov al, targetY
    mov pinky.mapY, al

    ; Update screen coordinates
    movzx eax, pinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov pinky.screenY, al

    movzx eax, pinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov pinky.screenX, al

    ; Return success
    mov al, 1
    ret

UGPP_ChooseNewDirection:
    ; Choose a new random direction - Pinky is more unpredictable
    call Randomize
    mov eax, 4      ; 0-3 for directions
    call RandomRange
    mov pinky.direction, al

    ; Sometimes make a second random choice to be more unpredictable
    call Randomize
    mov eax, 3      ; 0-2
    call RandomRange
    cmp al, 0       ; 1/3 chance to make another random choice
    jne UGPP_NoMove

    call Randomize
    mov eax, 4      ; 0-3 for directions
    call RandomRange
    mov pinky.direction, al

UGPP_NoMove:
    ; Return no movement
    mov al, 0
    ret
UpdateGhostPositionPinky ENDP

;--------------------------------------------------------------------------------
; UpdateGhostPositionInky - Update Inky's position based on current direction
; Returns: AL = 1 if ghost moved, AL = 0 if blocked
;--------------------------------------------------------------------------------
UpdateGhostPositionInky PROC USES EBX ECX EDX
    LOCAL targetX:BYTE, targetY:BYTE

    ; Increment move counter
    inc inky.moveCounter

    ; Check if it's time to move based on ghost speed
    mov al, inky.moveCounter
    cmp al, inky.speed
    jl UGPI_NoMove

    ; Reset move counter
    mov inky.moveCounter, 0

    ; Calculate target position based on current direction
    mov al, inky.mapX
    mov targetX, al

    mov al, inky.mapY
    mov targetY, al

    ; Adjust target based on direction
    mov al, inky.direction
    cmp al, DIR_RIGHT
    jne UGPI_CheckLeft
    inc targetX
    jmp UGPI_CheckCollision

UGPI_CheckLeft:
    cmp al, DIR_LEFT
    jne UGPI_CheckUp
    dec targetX
    jmp UGPI_CheckCollision

UGPI_CheckUp:
    cmp al, DIR_UP
    jne UGPI_CheckDown
    dec targetY
    jmp UGPI_CheckCollision

UGPI_CheckDown:
    inc targetY

UGPI_CheckCollision:
    ; Check for collision at target position
    mov bl, targetX
    mov bh, targetY
    call IsCollision

    ; If collision, choose a new random direction
    cmp al, 1
    je UGPI_ChooseNewDirection

    ; No collision - get the character at the target position
    pushad

    ; Get pointer to current row in maze
    mov esi, OFFSET mazeLayout
    movzx ebx, targetY
    shl ebx, 2
    add esi, ebx
    mov esi, [esi]

    ; Get character from maze
    movzx ebx, targetX
    mov al, [esi + ebx]

    ; Save the character for later restoration
    mov inky.tileUnder, al

    ; Check if it's a dot or power pellet
    cmp al, MAZE_DOT_CHAR
    je UGPI_SaveDot

    cmp al, MAZE_POWER_PELLET_CHAR
    je UGPI_SavePowerPellet

    jmp UGPI_DoneSaving

UGPI_SaveDot:
    ; It's a dot - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPI_DoneSaving

    ; Set dot as present in the array
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 1

    ; Replace the dot with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the dot
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

    jmp UGPI_DoneSaving

UGPI_SavePowerPellet:
    ; It's a power pellet - make sure it's preserved in the dot array
    ; Calculate index in dot array
    movzx ecx, targetY
    movzx edx, targetX
    imul ecx, 73         ; Fixed width
    add ecx, edx

    ; Bounds check
    cmp ecx, 1400        ; Size of dotArray
    jae UGPI_DoneSaving

    ; Set dot as present in the array with special value 2 for power pellets
    mov edi, OFFSET dotArray
    add edi, ecx
    mov BYTE PTR [edi], 2  ; Use value 2 for power pellets

    ; Replace the power pellet with a space in the maze layout
    ; This is critical to prevent the ghost from "eating" the power pellet
    mov BYTE PTR [esi + ebx], MAZE_PATH_CHAR

UGPI_DoneSaving:
    popad

    ; Update position
    mov al, targetX
    mov inky.mapX, al

    mov al, targetY
    mov inky.mapY, al

    ; Update screen coordinates
    movzx eax, inky.mapY
    add al, GAME_AREA_ROW_TOP
    mov inky.screenY, al

    movzx eax, inky.mapX
    add al, GAME_AREA_COL_LEFT
    mov inky.screenX, al

    ; Return success
    mov al, 1
    ret

UGPI_ChooseNewDirection:
    ; Choose a new random direction - Inky is more intelligent
    ; Try to move towards the player

    ; Get player position
    movzx eax, pacman.mapX
    movzx ebx, pacman.mapY

    ; Compare with ghost position
    movzx ecx, inky.mapX
    movzx edx, inky.mapY

    ; Decide direction based on player position
    cmp eax, ecx
    je UGPI_CheckVertical  ; Same X, check Y
    jl UGPI_TryLeft        ; Player is to the left

    ; Player is to the right
    mov inky.direction, DIR_RIGHT
    jmp UGPI_NoMove

UGPI_TryLeft:
    mov inky.direction, DIR_LEFT
    jmp UGPI_NoMove

UGPI_CheckVertical:
    cmp ebx, edx
    je UGPI_RandomDirection  ; Same position, choose random
    jl UGPI_TryUp            ; Player is above

    ; Player is below
    mov inky.direction, DIR_DOWN
    jmp UGPI_NoMove

UGPI_TryUp:
    mov inky.direction, DIR_UP
    jmp UGPI_NoMove

UGPI_RandomDirection:
    ; Fallback to random direction
    call Randomize
    mov eax, 4      ; 0-3 for directions
    call RandomRange
    mov inky.direction, al

UGPI_NoMove:
    ; Return no movement
    mov al, 0
    ret
UpdateGhostPositionInky ENDP

;--------------------------------------------------------------------------------
; DetectCollision - Check if player and ghost are at the same position
; Returns: AL = 1 if collision detected, AL = 0 if no collision
;--------------------------------------------------------------------------------
DetectCollision PROC USES EBX ECX EDX
    ; Get player position
    movzx edx, pacman.mapX
    movzx ecx, pacman.mapY

    ; Check collision with Blinky
    movzx ebx, blinky.mapX

    ; Compare X coordinates
    cmp edx, ebx
    jne DC_CheckPinky

    ; Compare Y coordinates
    movzx ebx, blinky.mapY
    cmp ecx, ebx
    jne DC_CheckPinky

    ; Collision detected with Blinky - check ghost state
    ; If power pellet is active and ghost is scared, player can eat ghost
    cmp powerPelletActive, 1
    jne DC_NormalCollision_Blinky

    ; Check if ghost is in scared state
    cmp blinky.state, GHOST_STATE_SCARED
    jne DC_NormalCollision_Blinky

    ; Ghost is scared - player can eat it
    mov blinky.state, GHOST_STATE_EATEN

    ; Return 2 to indicate ghost was eaten
    mov al, 2
    ret

DC_NormalCollision_Blinky:
    mov al, 1
    ret

DC_CheckPinky:
    ; Check if we need to check Pinky (Level 2+)
    cmp ghostCount, 1
    jle DC_NoCollision  ; Skip if only one ghost

    ; Check collision with Pinky
    movzx ebx, pinky.mapX

    ; Compare X coordinates
    cmp edx, ebx
    jne DC_CheckInky

    ; Compare Y coordinates
    movzx ebx, pinky.mapY
    cmp ecx, ebx
    jne DC_CheckInky

    ; Collision detected with Pinky - check ghost state
    ; If power pellet is active and ghost is scared, player can eat ghost
    cmp powerPelletActive, 1
    jne DC_NormalCollision_Pinky

    ; Check if ghost is in scared state
    cmp pinky.state, GHOST_STATE_SCARED
    jne DC_NormalCollision_Pinky

    ; Ghost is scared - player can eat it
    mov pinky.state, GHOST_STATE_EATEN

    ; Return 2 to indicate ghost was eaten
    mov al, 2
    ret

DC_NormalCollision_Pinky:
    mov al, 1
    ret

DC_CheckInky:
    ; Check if we need to check Inky (Level 3+)
    cmp ghostCount, 2
    jle DC_NoCollision  ; Skip if only two ghosts

    ; Check collision with Inky
    movzx ebx, inky.mapX

    ; Compare X coordinates
    cmp edx, ebx
    jne DC_NoCollision

    ; Compare Y coordinates
    movzx ebx, inky.mapY
    cmp ecx, ebx
    jne DC_NoCollision

    ; Collision detected with Inky - check ghost state
    ; If power pellet is active and ghost is scared, player can eat ghost
    cmp powerPelletActive, 1
    jne DC_NormalCollision_Inky

    ; Check if ghost is in scared state
    cmp inky.state, GHOST_STATE_SCARED
    jne DC_NormalCollision_Inky

    ; Ghost is scared - player can eat it
    mov inky.state, GHOST_STATE_EATEN

    ; Return 2 to indicate ghost was eaten
    mov al, 2
    ret

DC_NormalCollision_Inky:
    mov al, 1
    ret

DC_NoCollision:
    ; No collision
    mov al, 0
    ret
DetectCollision ENDP

;--------------------------------------------------------------------------------
; HandleCollision - Process collision between player and ghost
; Returns: AH = ESC_SCAN_CODE if game over, AH = 0 otherwise
;--------------------------------------------------------------------------------
HandleCollision PROC USES EAX EBX ECX EDX
    ; Decrement lives
    mov al, pacman.lives
    dec al
    mov pacman.lives, al

    ; Play death sound
    call PlayDeathSound

    ; Reset player position
    mov pacman.mapX, 1
    mov pacman.mapY, 1

    ; Calculate screen coordinates for player
    mov bl, pacman.mapY
    add bl, GAME_AREA_ROW_TOP
    mov pacman.screenY, bl

    mov bl, pacman.mapX
    add bl, GAME_AREA_COL_LEFT
    mov pacman.screenX, bl

    ; Reset ghost position
    mov blinky.mapX, 9
    mov blinky.mapY, 9

    ; Calculate screen coordinates for ghost
    mov bl, blinky.mapY
    add bl, GAME_AREA_ROW_TOP
    mov blinky.screenY, bl

    mov bl, blinky.mapX
    add bl, GAME_AREA_COL_LEFT
    mov blinky.screenX, bl

    ; Update status bar to show new lives count
    call DrawStatusBar

    ; Check if game over (no lives left)
    cmp pacman.lives, 0
    jne HC_Continue

    ; Game over - show game over screen
    call ShowGameOver

    ; ShowGameOver sets ESC_SCAN_CODE in AH
    ; Just return with AH set to ESC_SCAN_CODE
    ret

HC_Continue:
    ; Not game over - continue playing
    xor ah, ah  ; Clear ESC flag
    ret
HandleCollision ENDP

;--------------------------------------------------------------------------------
; GameOver - Handle game over when all lives are lost
;--------------------------------------------------------------------------------
GameOver PROC USES EAX EDX
    ; Play death sound
    call PlayDeathSound

    ; Clear the screen
    call Clrscr

    ; Display game over message
    mov dh, 10
    mov dl, 30
    call Gotoxy

    mov eax, LIGHT_RED_ON_BLACK
    call SetTextColor

    mov edx, OFFSET gameOverMsg
    call WriteString

    ; Display score
    mov dh, 12
    mov dl, 25
    call Gotoxy

    mov eax, LIGHT_GRAY_ON_BLACK
    call SetTextColor

    mov edx, OFFSET scoreMsg
    call WriteString

    mov ax, pacman.score
    call WriteDec

    ; Wait for key press
    mov dh, 14
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET pressAnyKeyMsg
    call WriteString

    ; Wait for key press
    call ReadChar

    ; Clear the screen
    call Clrscr

    ; Set ESC flag to signal return to menu
    mov ah, ESC_SCAN_CODE

    ret
GameOver ENDP

;--------------------------------------------------------------------------------
; HandleGhostCollision - Handle collision between ghost and player
;--------------------------------------------------------------------------------
HandleGhostCollision PROC USES EAX EBX ECX EDX
    ; In this version, ghosts are always in normal state (no power-ups yet)
    ; So player always loses a life when colliding with a ghost

    ; Decrement lives counter
    mov bl, pacman.lives
    dec bl
    mov pacman.lives, bl

    ; Play death sound
    call PlayDeathSound

    ; Reset player position
    call InitializePlayer

    ; Reset ghost position to its starting position
    mov blinky.mapX, 9
    mov blinky.mapY, 9

    ; Calculate screen coordinates for ghost
    movzx eax, blinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov blinky.screenY, al

    movzx eax, blinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov blinky.screenX, al

    ; Update status bar to show new lives count
    call DrawStatusBar

    ; Check if game over (no lives left)
    cmp bl, 0
    jne HGC_Exit

    ; Game over - show game over screen
    call ShowGameOver

    ; Set ESC flag to return to menu
    mov ah, ESC_SCAN_CODE

    ; Set special flag to indicate game over
    mov al, 2

HGC_Exit:
    ret
HandleGhostCollision ENDP

;--------------------------------------------------------------------------------
; UpdateGhost - Update ghost state and position
;--------------------------------------------------------------------------------
UpdateGhost PROC USES EBX ECX EDX
    ; Update ghost position
    call UpdateGhostPosition

    ; Check for collision with player
    call DetectCollision

    ; Store collision result in BL
    mov bl, al

    ; If no collision, skip collision handling
    cmp bl, 0
    je UG_Exit

    ; Collision detected - handle it
    call HandleCollision

    ; Return collision status in AL
    mov al, bl

UG_Exit:
    ret
UpdateGhost ENDP

;--------------------------------------------------------------------------------
; GameLoop - Main game loop to handle input, update state, and render
;--------------------------------------------------------------------------------
GameLoop PROC
    ; Initialize the game
    call Clrscr
    call DrawMaze          ; This also initializes the dot array
    call InitializePlayer
    call InitializeGhosts
    call DrawStatusBar     ; Draw status bar after initializing player
    call DrawPlayer
    call DrawGhost

GameLoop_MainLoop:
    ; Handle key input
    call HandleKeyInput

    ; Check if ESC was pressed or if we need to exit to menu
    cmp ah, ESC_SCAN_CODE
    je GameLoop_Exit

    ; Clear the key code after checking
    xor ah, ah

    ; Erase player and ghosts from current positions
    call ErasePlayer
    call EraseGhost

    ; Update player position and check for dot collection
    call UpdatePlayer

    ; Check if we need to exit (ESC flag might have been set by level completion)
    cmp ah, ESC_SCAN_CODE
    je GameLoop_Exit

    ; Update ghost positions and check for collisions
    call UpdateGhost

    ; Check if ESC key was pressed during ghost update (from HandleGhostCollision)
    mov bl, ah  ; Save AH value

    ; Check if we need to exit (ESC flag might have been set by collision handling)
    cmp bl, ESC_SCAN_CODE
    je GameLoop_Exit

    ; Draw player and ghosts at new positions
    call DrawPlayer
    call DrawGhost

    ; Delay for game speed
    mov eax, GAME_SPEED_DELAY
    call Delay

    jmp GameLoop_MainLoop

GameLoop_Exit:
    ; Make sure to clear the screen before returning to menu
    call Clrscr

    ; Reset game state for next game
    mov pacman.lives, 3
    mov pacman.score, 0
    mov dotsCollected, 0

    ; Return to menu
    ret
GameLoop ENDP

;--------------------------------------------------------------------------------
; DisplayWelcomeScreen - Show welcome screen and get player name
;--------------------------------------------------------------------------------
DisplayWelcomeScreen PROC
    pushad

    call Clrscr

    ; Display title and prompt
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET gameTitleMsg
    call WriteString

    mov edx, OFFSET namePromptMsg
    call WriteString

    ; Get player name
    mov edx, OFFSET playerName
    mov ecx, SIZEOF playerName - 1
    call ReadString

    ; Check if player entered a name (if string length is 0)
    cmp eax, 0
    jne DWS_NameEntered

    ; No name entered, use default name "Player"
    mov edx, OFFSET playerName
    mov BYTE PTR [edx], 'P'
    mov BYTE PTR [edx+1], 'l'
    mov BYTE PTR [edx+2], 'a'
    mov BYTE PTR [edx+3], 'y'
    mov BYTE PTR [edx+4], 'e'
    mov BYTE PTR [edx+5], 'r'
    mov BYTE PTR [edx+6], 0  ; Null terminator

DWS_NameEntered:
    ; Welcome message
    mov edx, OFFSET nameEnteredMsg
    call WriteString
    mov edx, OFFSET playerName
    call WriteString
    mov edx, OFFSET commaSpace
    call WriteString

    call WaitMsg

    popad
    ret
DisplayWelcomeScreen ENDP

;--------------------------------------------------------------------------------
; DisplayGameMenu - Show game menu and handle menu choices
;--------------------------------------------------------------------------------
DisplayGameMenu PROC
    pushad

DisplayGameMenu_Loop:
    call Clrscr

    ; Display menu options
    mov eax, WHITE_ON_BLACK
    call SetTextColor

    mov edx, OFFSET menuTitleMsg
    call WriteString
    mov edx, OFFSET menuOption1
    call WriteString
    mov edx, OFFSET menuOption2
    call WriteString
    mov edx, OFFSET menuOption3
    call WriteString
    mov edx, OFFSET menuOption4
    call WriteString
    mov edx, OFFSET menuOption5
    call WriteString
    mov edx, OFFSET menuOption6
    call WriteString

    ; Prompt for choice
    mov edx, OFFSET menuPromptMsg
    call WriteString
    call ReadDec

    ; Handle menu choice
    cmp eax, 1
    je DisplayGameMenu_StartLevel1

    cmp eax, 2
    je DisplayGameMenu_StartLevel2

    cmp eax, 3
    je DisplayGameMenu_StartLevel3

    cmp eax, 4
    je DisplayGameMenu_Instructions

    cmp eax, 5
    je DisplayGameMenu_HighScores

    cmp eax, 6
    je DisplayGameMenu_Exit

    ; Invalid choice
    mov edx, OFFSET invalidChoiceMsg
    call WriteString
    call WaitMsg
    jmp DisplayGameMenu_Loop

DisplayGameMenu_StartLevel1:
    call Clrscr
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET actualStartGameMsg
    call WriteString

    ; Brief delay before starting game
    mov eax, 1000
    call Delay

    ; Set level to 1 and start game
    mov currentLevel, 1
    call StartGame

    ; Always return to menu after game ends
    jmp DisplayGameMenu_Loop

DisplayGameMenu_StartLevel2:
    call Clrscr
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET actualStartGameMsg
    call WriteString

    ; Brief delay before starting game
    mov eax, 1000
    call Delay

    ; Set level to 2 and start game
    mov currentLevel, 2
    call StartGame

    ; Always return to menu after game ends
    jmp DisplayGameMenu_Loop

DisplayGameMenu_StartLevel3:
    call Clrscr
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET actualStartGameMsg
    call WriteString

    ; Brief delay before starting game
    mov eax, 1000
    call Delay

    ; Set level to 3 and start game
    mov currentLevel, 3
    call StartGame

    ; Always return to menu after game ends
    jmp DisplayGameMenu_Loop

DisplayGameMenu_Instructions:
    call Clrscr

    ; Display instructions
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET instrTitle
    call WriteString
    mov edx, OFFSET instrLine1
    call WriteString
    mov edx, OFFSET instrLine2
    call WriteString
    mov edx, OFFSET instrLine3
    call WriteString
    mov edx, OFFSET instrLine4
    call WriteString
    mov edx, OFFSET instrLine5
    call WriteString

    call WaitMsg
    jmp DisplayGameMenu_Loop

DisplayGameMenu_HighScores:
    call Clrscr

    ; Display high scores
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET actualHighScoresTitle
    call WriteString

    ; Load and display high scores
    call LoadHighScores

    call WaitMsg
    jmp DisplayGameMenu_Loop

DisplayGameMenu_Exit:
    popad
    ret
DisplayGameMenu ENDP

;--------------------------------------------------------------------------------
; main - Program entry point
;--------------------------------------------------------------------------------
main PROC
    ; Show welcome screen
    call DisplayWelcomeScreen

    ; Show game menu
    call DisplayGameMenu

    ; Display exit message
    call Clrscr
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov edx, OFFSET exitMessage
    call WriteString
    call Crlf

    exit
main ENDP

;--------------------------------------------------------------------------------
; ShowGameOver - Display game over screen and wait for key press
; Returns: Nothing
;--------------------------------------------------------------------------------
ShowGameOver PROC
    ; Don't save EAX - we'll return the ESC flag in AH
    push edx

    ; Play death sound
    call PlayDeathSound

    ; Clear the screen
    call Clrscr

    ; Display game over message
    mov dh, 10
    mov dl, 30
    call Gotoxy

    mov eax, RED_ON_BLACK
    call SetTextColor

    mov edx, OFFSET gameOverMsg
    call WriteString

    ; Display score
    mov dh, 12
    mov dl, 25
    call Gotoxy

    mov eax, WHITE_ON_BLACK
    call SetTextColor

    mov edx, OFFSET scoreMsg
    call WriteString

    mov ax, pacman.score
    call WriteDec

    ; Wait for key press
    mov dh, 14
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET pressAnyKeyMsg
    call WriteString

    ; Wait for key press
    call ReadChar

    ; Clear the screen
    call Clrscr

    ; Save high score
    call SaveHighScore

    ; Display result
    cmp al, 1
    jne SG_SkipSaveMsg

    mov edx, OFFSET highScoresSavedMsg
    call WriteString
    call Crlf

    ; Wait for another key press
    call WaitMsg

SG_SkipSaveMsg:
    ; Clear the screen again
    call Clrscr

    ; Restore EDX
    pop edx

    ; Set global game over flag
    mov gameOverFlag, 1

    ; Reset power pellet state
    mov powerPelletActive, 0
    mov powerPelletTimer, 0

    ; Set ESC flag to return to menu
    mov ah, ESC_SCAN_CODE
    mov al, 1  ; Set AL to indicate game over

    ret
ShowGameOver ENDP

;--------------------------------------------------------------------------------
; ShowLevelComplete - Display level complete screen and wait for key press
; Returns: Nothing
;--------------------------------------------------------------------------------
ShowLevelComplete PROC
    ; Don't save EAX - we'll return the ESC flag in AH
    push edx

    ; Play level complete sound
    call PlayLevelCompleteSound

    ; Clear the screen
    call Clrscr

    ; Display level complete message
    mov dh, 10
    mov dl, 20
    call Gotoxy

    mov eax, GREEN_ON_BLACK
    call SetTextColor

    mov edx, OFFSET levelCompleteMsg
    call WriteString

    ; Display score
    mov dh, 12
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET scoreMsg
    call WriteString

    mov ax, pacman.score
    call WriteDec

    ; Wait for key press
    mov dh, 14
    mov dl, 20
    call Gotoxy

    mov edx, OFFSET pressAnyKeyMsg
    call WriteString

    ; Wait for key press
    call ReadChar

    ; Clear the screen
    call Clrscr

    ; Restore EDX
    pop edx

    ; Increment level
    inc currentLevel

    ; Check if we've completed all levels
    cmp currentLevel, 3
    jg SLC_AllLevelsComplete

    ; Set up next level
    call SetupLevel

    ; Return without ESC flag to continue to next level
    xor ah, ah
    ret

SLC_AllLevelsComplete:
    ; All levels complete - save high score before returning to menu
    call SaveHighScore

    ; Display result of saving
    cmp al, 1
    jne SLC_SkipSaveMsg

    mov edx, OFFSET highScoresSavedMsg
    call WriteString
    call Crlf

    ; Wait for another key press
    call WaitMsg

SLC_SkipSaveMsg:
    ; Clear the screen again
    call Clrscr

    ; All levels complete - return to menu
    mov ah, ESC_SCAN_CODE
    mov al, 1  ; Set AL to indicate level complete

    ret
ShowLevelComplete ENDP

;--------------------------------------------------------------------------------
; CheckLevelComplete - Check if all dots are collected
; Returns: AH = ESC_SCAN_CODE if level complete, AH = 0 otherwise
;--------------------------------------------------------------------------------
CheckLevelComplete PROC
    ; Check if all dots collected
    mov ax, dotsCollected
    cmp ax, totalDots
    jne CLC_NotComplete

    ; Level complete - show level complete screen
    call ShowLevelComplete

    ; ShowLevelComplete sets ESC_SCAN_CODE in AH
    ; Just return with AH set to ESC_SCAN_CODE
    ret

CLC_NotComplete:
    ; Not complete - continue playing
    xor ah, ah
    ret
CheckLevelComplete ENDP

;--------------------------------------------------------------------------------
; UpdateGhostWithCollision - Ghost movement and player interaction system
; This is the heart of the ghost AI and collision detection
; Returns: AH = ESC_SCAN_CODE if game over, AH = 0 if safe, AL = 2 if ghost eaten
;--------------------------------------------------------------------------------
UpdateGhostWithCollision PROC
    ; First, handle the power pellet timer if one is active
    cmp powerPelletActive, 1
    jne UGWC_SkipPowerPelletTimer

    ; We slow down the timer by only decrementing every 8 frames
    ; This makes the power pellet last longer for better gameplay
    mov eax, frameCounter
    and eax, 7  ; Check if divisible by 8
    jnz UGWC_SkipPowerPelletDecrement

    ; Time to decrease the power pellet timer
    mov ax, powerPelletTimer
    dec ax
    mov powerPelletTimer, ax

UGWC_SkipPowerPelletDecrement:
    ; Check if the power pellet effect has worn off
    mov ax, powerPelletTimer
    cmp ax, 0
    jne UGWC_SkipPowerPelletTimer

    ; Power pellet has expired - ghosts return to normal
    mov powerPelletActive, 0

    ; Reset Blinky to normal hunting mode
    mov blinky.state, GHOST_STATE_NORMAL

    ; For Level 2+, also reset Pinky
    cmp ghostCount, 1
    jle UGWC_SkipPinkyReset
    mov pinky.state, GHOST_STATE_NORMAL

UGWC_SkipPinkyReset:
    ; For Level 3, also reset Inky
    cmp ghostCount, 2
    jle UGWC_SkipInkyReset
    mov inky.state, GHOST_STATE_NORMAL

UGWC_SkipInkyReset:

UGWC_SkipPowerPelletTimer:
    ; Move all active ghosts to their new positions
    call UpdateGhostPosition

    ; Check if any ghost collided with the player
    call DetectCollision

    ; If no collision occurred, we're done
    cmp al, 0
    je UGWC_NoCollision

    ; Special case: player ate a ghost (AL = 2)
    cmp al, 2
    je UGWC_EatGhost

    ; Normal collision - player hit a ghost and loses a life
    call HandleCollision

    ; HandleCollision will set ESC_SCAN_CODE in AH if game over
    ; We pass this back to the main game loop
    ret

UGWC_EatGhost:
    ; Player successfully ate a ghost! Award points and handle the ghost
    mov ax, pacman.score

    ; Start with the base ghost points
    mov bx, GHOST_POINTS

    ; Higher levels give more points for eating ghosts
    movzx cx, currentLevel
    imul bx, cx

    ; Update the player's score
    add ax, bx
    mov pacman.score, ax

    ; Play a satisfying sound effect
    mov eax, SOUND_EXCLAMATION
    call MessageBeep

    ; Figure out which ghost was eaten and send it back home
    ; We only reset the eaten ghost, not all ghosts
    cmp blinky.state, GHOST_STATE_EATEN
    jne UGWC_CheckPinkyEaten

    ; Reset Blinky position
    mov al, blinky.homeX
    mov blinky.mapX, al
    mov al, blinky.homeY
    mov blinky.mapY, al

    ; Calculate screen coordinates
    movzx eax, blinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov blinky.screenY, al

    movzx eax, blinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov blinky.screenX, al

    ; Reset state to normal
    mov blinky.state, GHOST_STATE_NORMAL
    jmp UGWC_GhostReset

UGWC_CheckPinkyEaten:
    ; Check if Pinky was eaten
    cmp pinky.state, GHOST_STATE_EATEN
    jne UGWC_CheckInkyEaten

    ; Reset Pinky position
    mov al, pinky.homeX
    mov pinky.mapX, al
    mov al, pinky.homeY
    mov pinky.mapY, al

    ; Calculate screen coordinates
    movzx eax, pinky.mapY
    add al, GAME_AREA_ROW_TOP
    mov pinky.screenY, al

    movzx eax, pinky.mapX
    add al, GAME_AREA_COL_LEFT
    mov pinky.screenX, al

    ; Reset state to normal
    mov pinky.state, GHOST_STATE_NORMAL
    jmp UGWC_GhostReset

UGWC_CheckInkyEaten:
    ; Check if Inky was eaten
    cmp inky.state, GHOST_STATE_EATEN
    jne UGWC_GhostReset

    ; Reset Inky position
    mov al, inky.homeX
    mov inky.mapX, al
    mov al, inky.homeY
    mov inky.mapY, al

    ; Calculate screen coordinates
    movzx eax, inky.mapY
    add al, GAME_AREA_ROW_TOP
    mov inky.screenY, al

    movzx eax, inky.mapX
    add al, GAME_AREA_COL_LEFT
    mov inky.screenX, al

    ; Reset state to normal
    mov inky.state, GHOST_STATE_NORMAL

UGWC_GhostReset:
    ; Set ghost states to scared when power pellet is active
    cmp powerPelletActive, 1
    jne UGWC_SkipScaredState

    ; Only set scared state for ghosts that aren't eaten
    cmp blinky.state, GHOST_STATE_EATEN
    je UGWC_SkipBlinkyScared
    mov blinky.state, GHOST_STATE_SCARED
UGWC_SkipBlinkyScared:

    ; Check if we need to update Pinky (Level 2+)
    cmp ghostCount, 1
    jle UGWC_SkipScaredState

    cmp pinky.state, GHOST_STATE_EATEN
    je UGWC_SkipPinkyScared
    mov pinky.state, GHOST_STATE_SCARED
UGWC_SkipPinkyScared:

    ; Check if we need to update Inky (Level 3+)
    cmp ghostCount, 2
    jle UGWC_SkipScaredState

    cmp inky.state, GHOST_STATE_EATEN
    je UGWC_SkipInkyScared
    mov inky.state, GHOST_STATE_SCARED
UGWC_SkipInkyScared:

UGWC_SkipScaredState:
    ; Update status bar to show new score
    call DrawStatusBar

    ; CRITICAL FIX: Set AL to 2 to indicate ghost was eaten
    ; This will be checked in the main game loop
    mov al, 2

    ; No collision - clear ESC flag
    xor ah, ah
    ret

UGWC_NoCollision:
    ; No collision - clear ESC flag
    xor ah, ah
    ret
UpdateGhostWithCollision ENDP

;--------------------------------------------------------------------------------
; StartGame - Main game controller and loop
; This is where all the game action happens - the core gameplay loop
;--------------------------------------------------------------------------------
StartGame PROC
    ; Initialize a fresh game with default values
    mov pacman.lives, 3            ; Player starts with 3 lives
    mov pacman.score, 0            ; Reset score to zero
    mov dotsCollected, 0           ; No dots collected yet
    mov gameOverFlag, 0            ; Game is active
    mov powerPelletActive, 0       ; No power pellet active
    mov powerPelletTimer, 0        ; Power pellet timer reset
    mov frameCounter, 0            ; Animation frame counter reset

    ; Set up the specific level (maze, ghosts, etc.)
    call SetupLevel

    ; Draw everything on screen to start the game
    call DrawMaze                  ; Draw the maze with walls and dots
    call DrawPlayer                ; Draw Pac-Man at starting position
    call DrawGhost                 ; Draw all active ghosts
    call DrawStatusBar             ; Show score, lives, and level

NGL_MainLoop:
    ; First check if the game is over
    cmp gameOverFlag, 1
    je NGL_Exit                    ; If game over, exit to menu

    ; Update our animation counter
    inc frameCounter

    ; Control game speed with a delay
    mov eax, GAME_SPEED_DELAY
    call Delay

    ; Check if player pressed any keys
    call HandleKeyInput

    ; Check if ESC was pressed
    cmp ah, ESC_SCAN_CODE
    je NGL_Exit

    ; Erase player and ghost at current positions
    call ErasePlayer
    call EraseGhost

    ; Update player position and handle direction changes
    call UpdatePlayer

    ; Check if level complete
    call CheckLevelComplete

    ; Check if ESC flag was set by level completion
    cmp ah, ESC_SCAN_CODE
    je NGL_Exit

    ; Update ghost position and check for collision
    call UpdateGhostWithCollision

    ; Store the result in BL for later checking
    mov bl, al

    ; Check if ESC flag was set (game over)
    cmp ah, ESC_SCAN_CODE
    jne NGL_SkipExitCheck

    ; Check if it's a ghost-eaten event (AL = 2)
    cmp bl, 2
    je NGL_SkipExitCheck

    ; It's a real game over, exit
    jmp NGL_Exit

NGL_SkipExitCheck:

    ; Clear any flags that might have been set
    xor ah, ah

    ; Draw player and ghost at new positions
    call DrawPlayer
    call DrawGhost

    ; Loop back
    jmp NGL_MainLoop

NGL_Exit:
    ; Clear screen before returning to menu
    call Clrscr

    ; Make sure gameOverFlag is reset before returning to menu
    mov gameOverFlag, 0

    ; Reset power pellet state
    mov powerPelletActive, 0
    mov powerPelletTimer, 0

    ret
StartGame ENDP

;--------------------------------------------------------------------------------
; InitializeGame - Set up initial game state
;--------------------------------------------------------------------------------
InitializeGame PROC
    ; Initialize player
    call InitializePlayer

    ; Initialize ghost
    call InitializeGhosts

    ; Initialize dot array
    call InitializeDotArray

    ; Reset score and lives
    mov pacman.score, 0
    mov pacman.lives, 3

    ; Reset dots collected
    mov dotsCollected, 0

    ; Reset game over flag
    mov gameOverFlag, 0

    ; Calculate total dots
    call CountTotalDots

    ret
InitializeGame ENDP

;--------------------------------------------------------------------------------
; CountTotalDots - Count the total number of dots in the maze
;--------------------------------------------------------------------------------
CountTotalDots PROC USES EAX EBX ECX EDX ESI
    ; Initialize dot counter
    mov totalDots, 0

    ; Loop through dot array
    mov esi, OFFSET dotArray
    mov ecx, 1400  ; Size of dotArray

CTD_Loop:
    ; Check if current position has a dot or power pellet
    mov al, BYTE PTR [esi]
    cmp al, 0
    je CTD_Continue

    ; Increment dot counter for both regular dots (1) and power pellets (2)
    inc totalDots

CTD_Continue:
    ; Move to next position
    inc esi
    loop CTD_Loop

    ret
CountTotalDots ENDP

;--------------------------------------------------------------------------------
; SetupLevel - Configure the game for the current level
;--------------------------------------------------------------------------------
SetupLevel PROC USES EAX EBX ECX EDX ESI EDI
    ; Set up maze layout based on current level
    mov al, currentLevel
    cmp al, 1
    je SL_Level1
    cmp al, 2
    je SL_Level2
    cmp al, 3
    je SL_Level3
    ; Default to level 1 if invalid level
    jmp SL_Level1

SL_Level1:
    ; Set up Level 1
    mov esi, OFFSET maze1Layout
    mov edi, OFFSET mazeLayout
    mov ecx, 18  ; Number of rows

SL_CopyLevel1Layout:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    loop SL_CopyLevel1Layout

    ; Set ghost count to 1
    mov ghostCount, 1

    ; Reset ghost states
    mov blinky.state, GHOST_STATE_NORMAL

    ; Reset power pellet state
    mov powerPelletActive, 0
    mov powerPelletTimer, 0

    ; Reset fruit state
    mov fruitActive, 0

    jmp SL_Done

SL_Level2:
    ; Set up Level 2
    mov esi, OFFSET maze2Layout
    mov edi, OFFSET mazeLayout
    mov ecx, 18  ; Number of rows

SL_CopyLevel2Layout:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    loop SL_CopyLevel2Layout

    ; Set ghost count to 2
    mov ghostCount, 2

    ; Reset ghost states
    mov blinky.state, GHOST_STATE_NORMAL
    mov pinky.state, GHOST_STATE_NORMAL

    ; Reset power pellet state
    mov powerPelletActive, 0
    mov powerPelletTimer, 0

    ; Reset fruit state
    mov fruitActive, 0

    jmp SL_Done

SL_Level3:
    ; Set up Level 3
    mov esi, OFFSET maze3Layout
    mov edi, OFFSET mazeLayout
    mov ecx, 18  ; Number of rows

SL_CopyLevel3Layout:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    loop SL_CopyLevel3Layout

    ; Set ghost count to 3
    mov ghostCount, 3

    ; Reset ghost states
    mov blinky.state, GHOST_STATE_NORMAL
    mov pinky.state, GHOST_STATE_NORMAL
    mov inky.state, GHOST_STATE_NORMAL

    ; Reset power pellet state
    mov powerPelletActive, 0
    mov powerPelletTimer, 0

    ; Reset fruit state
    mov fruitActive, 0

SL_Done:
    ; Reset game state
    mov gameOverFlag, 0

    ; Initialize player and ghosts
    call InitializePlayer
    call InitializeGhosts

    ; Update level display
    mov al, currentLevel
    add al, '0'      ; Convert to ASCII
    mov levelStr, al

    ; Initialize dot array
    call InitializeDotArray

    ; Reset dots collected
    mov dotsCollected, 0

    ; Calculate total dots
    call CountTotalDots

    ret
SetupLevel ENDP









;--------------------------------------------------------------------------------
; RedrawMaze - Redraw the maze without reinitializing the dot array
;--------------------------------------------------------------------------------
RedrawMaze PROC
    LOCAL currentScreenY :BYTE, currentScreenX :BYTE
    LOCAL mazeMapRowIdx  :BYTE, mazeMapColIdx  :BYTE
    LOCAL charFromMaze   :BYTE
    pushad

    ; Make sure ESI points to mazeLayout
    mov esi, OFFSET mazeLayout
    mov mazeMapRowIdx, 0

RM_RowLoop:
    ; Check if we've processed all rows
    mov bl, mazeMapRowIdx
    mov al, MAZE_MAX_ROWS_VAL
    cmp bl, al
    jge RM_Done

    ; Get pointer to current row
    movzx ebx, mazeMapRowIdx
    shl ebx, 2
    mov edi, [esi + ebx]

    ; Check if edi is valid (not null)
    cmp edi, 0
    je RM_NextRow              ; Skip this row if pointer is null

    ; Start at column 0
    mov mazeMapColIdx, 0

RM_ColLoop:
    ; Check if we've processed all columns in this row
    mov bl, mazeMapColIdx
    mov al, MAZE_MAX_COLS_VAL
    cmp bl, al
    jge RM_NextRow

    ; Calculate screen coordinates
    mov al, GAME_AREA_ROW_TOP
    add al, mazeMapRowIdx
    mov currentScreenY, al

    mov al, GAME_AREA_COL_LEFT
    add al, mazeMapColIdx
    mov currentScreenX, al

    ; Position cursor
    mov dh, currentScreenY
    mov dl, currentScreenX
    call Gotoxy

    ; Get character from maze
    movzx ebx, mazeMapColIdx
    mov al, [edi + ebx]
    mov charFromMaze, al

    ; Determine what to draw based on maze character
    cmp al, MAZE_WALL_CHAR_DEF
    je RM_DrawWall

    cmp al, MAZE_PLAYER_START_CHAR
    je RM_DrawPlayerStartAsPath

    cmp al, MAZE_POWER_PELLET_CHAR
    je RM_CheckPowerPellet

    cmp al, MAZE_FRUIT_CHAR
    je RM_DrawFruit

    cmp al, MAZE_TELEPORT_CHAR
    je RM_DrawTeleport

    ; Check if this position has a regular dot in the dot array
    pushad                ; Save all registers

    movzx ecx, mazeMapRowIdx
    movzx edx, mazeMapColIdx
    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae RM_CheckDot_Done

    mov ebx, OFFSET dotArray
    add ebx, ecx
    ; Check specifically for regular dot (value 1), not power pellet (value 2)
    cmp BYTE PTR [ebx], 1
    jne RM_CheckDot_Done

    ; Dot found
    popad                ; Restore all registers
    jmp RM_DrawDot

RM_CheckDot_Done:
    popad                ; Restore all registers
    jmp RM_DrawPath

RM_DrawDot:
    ; Draw a dot
    mov eax, MAZE_DOT_COLOR
    call SetTextColor
    mov al, MAZE_DOT_CHAR
    call WriteChar
    jmp RM_NextChar

RM_DrawPath:
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar
    jmp RM_NextChar

RM_DrawWall:
    mov eax, MAZE_WALL_COLOR
    call SetTextColor
    mov al, MAZE_WALL_CHAR_DRAW
    call WriteChar
    jmp RM_NextChar

RM_DrawPlayerStartAsPath:
    mov eax, MAZE_PATH_COLOR
    call SetTextColor
    mov al, MAZE_PATH_CHAR
    call WriteChar
    jmp RM_NextChar

RM_CheckPowerPellet:
    ; Check if this position has a power pellet in the dot array (if collected, don't draw)
    pushad                ; Save all registers

    movzx ecx, mazeMapRowIdx
    movzx edx, mazeMapColIdx
    imul ecx, 73         ; Fixed width instead of MAZE_MAX_COLS_VAL+1
    add ecx, edx

    ; Bounds check to avoid array overflow
    cmp ecx, 1400        ; Size of dotArray
    jae RM_PowerPellet_Done

    mov ebx, OFFSET dotArray
    add ebx, ecx
    cmp BYTE PTR [ebx], 2  ; Check for power pellet (value 2)
    jne RM_PowerPellet_Done

    ; Power pellet found and not collected
    popad                ; Restore all registers
    jmp RM_DrawPowerPellet

RM_PowerPellet_Done:
    popad                ; Restore all registers
    jmp RM_DrawPath

RM_DrawPowerPellet:
    ; Draw a power pellet (larger dot)
    mov eax, WHITE_ON_BLACK
    call SetTextColor
    mov al, MAZE_POWER_PELLET_CHAR
    call WriteChar
    jmp RM_NextChar

RM_DrawFruit:
    ; Draw a fruit
    mov eax, GREEN_ON_BLACK
    call SetTextColor
    mov al, MAZE_FRUIT_CHAR
    call WriteChar
    jmp RM_NextChar

RM_DrawTeleport:
    ; Draw a teleport path
    mov eax, CYAN_ON_BLACK
    call SetTextColor
    mov al, MAZE_TELEPORT_CHAR
    call WriteChar
    jmp RM_NextChar

RM_NextChar:
    inc mazeMapColIdx
    jmp RM_ColLoop

RM_NextRow:
    inc mazeMapRowIdx
    mov esi, OFFSET mazeLayout  ; Restore ESI to mazeLayout for next row
    jmp RM_RowLoop

RM_Done:
    ; Restore ESI to maze layout for other procedures
    mov esi, OFFSET mazeLayout
    popad
    ret
RedrawMaze ENDP

;--------------------------------------------------------------------------------
; SaveHighScore - Simple high score saving to a text file
; Returns: AL = 1 if successful, AL = 0 if error
;--------------------------------------------------------------------------------
SaveHighScore PROC USES EBX ECX EDX ESI EDI
    ; First check if the player name is set
    mov esi, OFFSET playerName
    cmp BYTE PTR [esi], 0
    jne SHS_NameOK

    ; No name set, use default "Player"
    mov BYTE PTR [esi], 'P'
    mov BYTE PTR [esi+1], 'l'
    mov BYTE PTR [esi+2], 'a'
    mov BYTE PTR [esi+3], 'y'
    mov BYTE PTR [esi+4], 'e'
    mov BYTE PTR [esi+5], 'r'
    mov BYTE PTR [esi+6], 0  ; Null terminator

SHS_NameOK:
    ; Create a simple text file for the high score - always overwrite
    mov edx, OFFSET highScoreFileName
    call CreateOutputFile
    mov highScoreFileHandle, eax

    ; Check if file was created successfully
    cmp eax, INVALID_HANDLE_VALUE
    je SHS_Error

    ; Format a simple high score entry: "Name: Score"
    ; First copy the player name
    mov esi, OFFSET playerName
    mov edi, OFFSET highScoreEntry

    ; Debug - print player name to console
    mov edx, OFFSET playerName
    call WriteString
    call Crlf

SHS_CopyName:
    mov al, [esi]
    cmp al, 0
    je SHS_NameDone
    mov [edi], al
    inc esi
    inc edi
    jmp SHS_CopyName

SHS_NameDone:
    ; Add ": " after the name
    mov BYTE PTR [edi], ':'
    inc edi
    mov BYTE PTR [edi], ' '
    inc edi

    ; Convert score to string directly using WriteDec
    mov ax, pacman.score
    call ParseDecimal    ; Convert AX to string at EDI

    ; Debug - print score to console
    mov eax, 0
    mov ax, pacman.score
    call WriteDec
    call Crlf

    ; Add newline
    mov al, 0Dh  ; CR
    mov [edi], al
    inc edi
    mov al, 0Ah  ; LF
    mov [edi], al
    inc edi
    mov BYTE PTR [edi], 0    ; Null terminator

    ; Write the entry to the file
    mov eax, highScoreFileHandle
    mov edx, OFFSET highScoreEntry
    call WriteString

    ; Debug - confirm write operation
    mov edx, OFFSET highScoreEntry
    call WriteString
    call Crlf

    ; Flush and close the file
    mov eax, highScoreFileHandle
    call CloseFile

    ; Debug - confirm file was closed
    mov edx, OFFSET highScoreFileName
    call WriteString
    call Crlf

    ; Success
    mov al, 1
    ret

SHS_Error:
    ; Error occurred
    mov al, 0
    ret
SaveHighScore ENDP

;--------------------------------------------------------------------------------
; ParseDecimal - Convert AX to decimal string at EDI
; Input: AX = number to convert, EDI = destination buffer
; Output: EDI updated to point after the string
;--------------------------------------------------------------------------------
ParseDecimal PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    ; Handle special case of 0
    cmp ax, 0
    jne PD_NonZero

    mov BYTE PTR [edi], '0'
    inc edi
    jmp PD_Done

PD_NonZero:
    ; Convert number to string
    mov cx, 0          ; Digit counter
    mov bx, 10         ; Divisor

    ; Use stack for temporary storage
    sub esp, 16        ; Allocate space on stack
    mov esi, esp       ; ESI points to stack buffer

PD_ConvertLoop:
    xor dx, dx         ; Clear DX for division
    div bx             ; AX / 10, quotient in AX, remainder in DX

    ; Convert remainder to ASCII
    add dl, '0'
    mov [esi], dl      ; Store digit
    inc esi
    inc cx             ; Count digits

    ; Continue until number is 0
    cmp ax, 0
    jne PD_ConvertLoop

    ; Now copy digits in reverse order
    dec esi            ; Point to last digit

PD_CopyLoop:
    mov al, [esi]
    mov [edi], al
    inc edi
    dec esi
    loop PD_CopyLoop

    ; Clean up stack
    add esp, 16

PD_Done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ParseDecimal ENDP

;--------------------------------------------------------------------------------
; LoadHighScores - Load and display high scores from text file
;--------------------------------------------------------------------------------
LoadHighScores PROC USES EAX EBX ECX EDX ESI EDI
    ; Try to open the high score file
    mov edx, OFFSET highScoreFileName
    call OpenInputFile
    mov highScoreFileHandle, eax

    ; Check if file exists
    cmp eax, INVALID_HANDLE_VALUE
    je LHS_NoFile

    ; Display header
    mov edx, OFFSET actualHighScoresTitle
    call WriteString

    ; Read and display up to 10 high scores
    mov ecx, 1  ; Start with rank 1

LHS_ReadLoop:
    ; Read a line from the file
    mov edx, OFFSET highScoreBuffer
    mov ecx, SIZEOF highScoreBuffer
    mov eax, highScoreFileHandle
    call ReadString

    ; Check if we reached end of file
    cmp eax, 0
    jle LHS_Done

    ; Display the rank number
    mov eax, ecx
    call WriteDec
    mov al, '.'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov al, ' '
    call WriteChar

    ; Display the high score entry as is
    mov edx, OFFSET highScoreBuffer
    call WriteString
    call Crlf

    ; Move to next rank
    inc ecx
    cmp ecx, 11  ; Only show top 10
    jle LHS_ReadLoop

LHS_Done:
    ; Close the file
    mov eax, highScoreFileHandle
    call CloseFile
    ret

LHS_NoFile:
    ; No high scores file exists yet - create a default one
    ; Display header
    mov edx, OFFSET actualHighScoresTitle
    call WriteString

    ; Show current player with score 0
    mov edx, OFFSET playerName
    call WriteString
    mov al, ':'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov eax, 0
    call WriteDec
    call Crlf
    call Crlf

    ; Create a default high score file with the current player
    call SaveHighScore

    ; Show message about saving
    cmp al, 1
    jne LHS_SaveError

    mov edx, OFFSET highScoresSavedMsg
    call WriteString
    jmp LHS_SaveDone

LHS_SaveError:
    mov edx, OFFSET highScoreErrorMsg
    call WriteString

LHS_SaveDone:
    ; Wait for key press
    call Crlf
    call WaitMsg
    ret
LoadHighScores ENDP

END main
