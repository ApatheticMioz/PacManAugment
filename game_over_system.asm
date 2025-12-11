;--------------------------------------------------------------------------------
; GAME OVER SYSTEM - COMPLETELY NEW IMPLEMENTATION
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; ShowGameOver - Display game over screen and wait for key press
; Returns: Nothing
;--------------------------------------------------------------------------------
ShowGameOver PROC
    ; Save registers
    push eax
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
    
    ; Restore registers
    pop edx
    pop eax
    
    ret
ShowGameOver ENDP

;--------------------------------------------------------------------------------
; ShowLevelComplete - Display level complete screen and wait for key press
; Returns: Nothing
;--------------------------------------------------------------------------------
ShowLevelComplete PROC
    ; Save registers
    push eax
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
    
    ; Restore registers
    pop edx
    pop eax
    
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
    
    ; Set ESC flag to return to menu
    mov ah, ESC_SCAN_CODE
    ret
    
CLC_NotComplete:
    ; Not complete - continue playing
    xor ah, ah
    ret
CheckLevelComplete ENDP
