;--------------------------------------------------------------------------------
; GHOST COLLISION SYSTEM - COMPLETELY NEW IMPLEMENTATION
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; DetectCollision - Check if player and ghost are at the same position
; Returns: AL = 1 if collision detected, AL = 0 if no collision
;--------------------------------------------------------------------------------
DetectCollision PROC
    ; Get player position
    mov dl, pacman.mapX
    mov dh, pacman.mapY
    
    ; Get ghost position
    mov cl, blinky.mapX
    mov ch, blinky.mapY
    
    ; Compare X coordinates
    cmp dl, cl
    jne DC_NoCollision
    
    ; Compare Y coordinates
    cmp dh, ch
    jne DC_NoCollision
    
    ; Collision detected - both X and Y match
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
HandleCollision PROC
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
    
    ; Set ESC flag to return to menu
    mov ah, ESC_SCAN_CODE
    ret
    
HC_Continue:
    ; Not game over - continue playing
    xor ah, ah  ; Clear ESC flag
    ret
HandleCollision ENDP

;--------------------------------------------------------------------------------
; UpdateGhostWithCollision - Update ghost position and check for collision
; Returns: AH = ESC_SCAN_CODE if game over, AH = 0 otherwise
;--------------------------------------------------------------------------------
UpdateGhostWithCollision PROC
    ; Update ghost position
    call UpdateGhostPosition
    
    ; Check for collision with player
    call DetectCollision
    
    ; If no collision, return
    cmp al, 0
    je UGWC_NoCollision
    
    ; Collision detected - handle it
    call HandleCollision
    ret
    
UGWC_NoCollision:
    ; No collision - clear ESC flag
    xor ah, ah
    ret
UpdateGhostWithCollision ENDP
