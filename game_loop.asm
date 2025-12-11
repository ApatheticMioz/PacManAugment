;--------------------------------------------------------------------------------
; GAME LOOP SYSTEM - COMPLETELY NEW IMPLEMENTATION
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; NewGameLoop - Main game loop with proper collision and game over handling
;--------------------------------------------------------------------------------
NewGameLoop PROC
    ; Initialize game state
    call InitializeGame
    
    ; Draw initial game state
    call DrawMaze
    call DrawPlayer
    call DrawGhost
    call DrawStatusBar
    
NGL_MainLoop:
    ; Delay for game speed
    mov eax, GAME_SPEED_DELAY
    call Delay
    
    ; Check for keyboard input
    call HandleKeyInput
    
    ; Check if ESC was pressed
    cmp ah, ESC_SCAN_CODE
    je NGL_Exit
    
    ; Erase player and ghost at current positions
    call ErasePlayer
    call EraseGhost
    
    ; Update player position
    call UpdatePlayerPosition
    
    ; Check for dot collection
    call CheckForDot
    
    ; Check if level complete
    call CheckLevelComplete
    
    ; Check if ESC flag was set by level completion
    cmp ah, ESC_SCAN_CODE
    je NGL_Exit
    
    ; Update ghost position and check for collision
    call UpdateGhostWithCollision
    
    ; Check if ESC flag was set by collision handling
    cmp ah, ESC_SCAN_CODE
    je NGL_Exit
    
    ; Draw player and ghost at new positions
    call DrawPlayer
    call DrawGhost
    
    ; Loop back
    jmp NGL_MainLoop
    
NGL_Exit:
    ; Clear screen before returning to menu
    call Clrscr
    
    ; Reset game state for next game
    mov pacman.lives, 3
    mov pacman.score, 0
    mov dotsCollected, 0
    
    ret
NewGameLoop ENDP

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
    
    ; Calculate total dots
    call CountTotalDots
    
    ret
InitializeGame ENDP
