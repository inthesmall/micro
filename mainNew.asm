.INCLUDE "setup.asm"
.INCLUDE "LCDdriver.inc"

;###### LCD setup #####

rcall setupLCD		; One-time LCD setup.
CREATECHAR rl , $00	; Creates the custom characters each time the program is loaded.
CREATECHAR rr, $01	; rl/rr = rocket left/right, pl/pr = player left/right, al/ar = alien left/right, bl = custom blank character.
CREATECHAR pl, $02	
CREATECHAR pr, $03
CREATECHAR al, $04
CREATECHAR ar, $05
CREATECHAR bl, $06
rcall clrLCD		; clear LCD in preparation for programme start.

;##############

ldi writeFlag, 0	; This flag will ensure our interrupt doesn't overwrite anything if it is triggered during a screen update.
ldi compFlag, 0		; This flag sets how many times the interrupt fires before being allowed to read the inputs.

;##### The start of the program #####
Main:
/*	rcall initPpl	; Set-up all the rewritable byte tables.
	rcall clrLCD	; Clear the LCD before jumping to menu.
	rcall menu*/	; Load the menu screen.
play:
	/*ldi r17, $00	; r17 = 'laps' of screen - needs to start at 0. Counts how many times aliens move from the right of the screen to the left and back again.
	rcall foeLoop*/	; This actually starts the game - controls aliens and calls the loop to update screen with aliens/player/rockets.

	rjmp Main

;##### Interrupt vector code #####
interruptVector:	; Is called when Timer0 triggers (approx every 0.03s).
	in r4, SREG		; Save the status register so it doesn't get broken.
 	push r16
	push r20
	push r21
	rcall pulse
inputPoll:
	cpi r16, $FF ; Check to see if the analogue comparator has been triggered
	brne inputPoll ; Will only spend a maxium of 0.0005 seconds here since there is a timeout
	rcall moveParser ; Interprets the result
	in r16, PINE
	sbrs r16, 7
	ldi shift, $D7 ; Legacy encoding for shoot from button pad
	pop r21
	pop r20
	pop r16
	cpi compFlag, 4	; If compFlag = 4, we are allowed to interpret the inputs (jump to movLoop), otherwise increment compFlag and exit the loop.
;	breq movLoop
nop
	inc compFlag
	out SREG, r4	; Restore the SREG.
	reti
endP:
	out SREG, r4
	reti

movLoop:
	sbrc writeFlag, 0	; If the writeFlag is set, we're not allowed to edit player/rockets so exit.
	breq endP
	sbrs writeFlag, 1	; Checks 1st bit of writeFlag (general purpose shoot flag) - if it is not set, no rockets have been fired.
	call clrRow			; Deletes any rockets in the same row as the player.
	sbrc writeFlag, 1	; Checks 1st bit of writeFlag - if it is set, a rocket has been fired.
	call nastyHack		; This function checks to see if the playerPosition is 0. If it is it adds 1 so we can still shoot (but a little bit sideways).
	cbr writeFlag, (1<<1); Clears bit 1 to say that nastyHack is dealt with.
	ldi compFlag, 0		; Reset compFlag for future inputs.
	rcall playerLoop	; Interpret inputs.
	out SREG, r4
	reti

playerLoop:
	cpi shift, $77		; Corresponds to 1 being pressed on keypad.
	breq movLeft		
	cpi shift, $B7		; Corresponds to 2 being pressed on keypad.
	breq movRight
	cpi shift, $D7		; Corresponds to 3 being pressed on keypad.
	breq shoot
	ret


movLeft:
	cpi playerPos, 0	; Checks to see if we're at the far left of the screen.
	breq movLend		; If yes, we don't move - otherwise we'd get text wrap issues, so go to end.
	dec playerPos		; Decrement player position. (Player position is read to left hand side of player).
movLend:
	ret
	
movRight:
	cpi playerPos, 31	; The same as movLeft except we're checking if we're at the right. Then increments player position.
	breq movRend
	inc playerPos
movRend:
	ret
	

shoot:
	sbr writeFlag, (1<<1); Sets the general purpose shoot flag which says a rocket has been fired.
	sbr writeFlag, (1<<2); Sets the menu shoot flag which says a rocket has been fired in the menu.
	push r30
	push r31
	lds ZL, sixL		; The position in our rocket storage which we need to write to. (Rockets are stored in a circular buffer).
	lds ZH, sixH
	st Z, playerPos		; Store the player offset as this is == rocket offset.
	pop r31
	pop r30
	ret

clrRow:
	push r16
	push r30
	push r31
	ldi r16, 0			
	lds ZH, sixH		; Loads the position in the buffer we wrote to previously.
	lds ZL, sixL
	st Z, r16			; Delete the rocket.
	pop r31
	pop r30
	pop r16
	ret

nastyHack:
	cpi playerPos, 0	; Checks to see is playerPos = 0.
	jne noNastyHack
	push r16
	push r30
	push r31
	ldi r16, 1			; If it's 0, make it 1...
	lds ZL, sixL
	lds ZH, sixH
	st Z, r16			; Store 'new' rocket position.
	pop r31
	pop r30
	pop r16
noNastyHack:	
	ret
	

;##### Loops #####
initPpl:
	ldi foeLength, 20		; Sets length of row of aliens.
	ldi loLength, 13		; Sets left offset to maxiumum so row starts at the far right of the screen.
	ldi roLength, 0			; Sets right offset to minimum for same reason.
	ldi blnkRowl, 33
	ldi playerPos, 0
	ldi ZH, HIGH(2*foe1)	; Populates rewriteable byte table corresponding to 1st alien row.
	ldi ZL, LOW(2*foe1)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe2)	; Populates rewriteable byte table corresponding to 2nd alien row.
	ldi ZL, LOW(2*foe2)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe3)	; Populates rewriteable byte table corresponding to 3rd alien row.
	ldi ZL, LOW(2*foe3)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe4)	; Populates rewriteable byte table corresponding to 4th alien row.
	ldi ZL, LOW(2*foe4)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*rockets)	; Sets rocket circular buffer pointer to the beginning of the rocket position rewriteable byte table.
	ldi ZL, LOW(2*rockets)
	sts sixL, ZL
	sts sixH, ZH
	call rocketRows			; Initialises the rocket postion table to zeroes.
	ldi YH, HIGH(2*foePoint); Sets up the table of pointers which direct the loop for killing aliens to the correct row.
	ldi YL, LOW(2*foePoint)
	ldi ZH, HIGH(2*foe1)	; First two bytes of the foePoint table = address of foe1
	ldi ZL, LOW(2*foe1)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe2)	; Second two bytes of the foePoint table = address of foe2
	ldi ZL, LOW(2*foe2)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe3)	; Third two bytes of the foePoint table = address of foe3
	ldi ZL, LOW(2*foe3)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe4)	; Fourth two bytes of the foePoint table = address of foe4
	ldi ZL, LOW(2*foe4)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	lds r16, score			; Initialises the score to 0.
	ldi r16, 0
	sts score, r16
	ldi r16, 10
	ldi ZH, HIGH(2*foeRem)	; foeRem sees how many aliens in a given row have been killed. Starts as a 4 byte table of 0s.
	ldi ZL, LOW(2*foeRem)
	ldi r16, 0
	st Z+, r16
	st Z+, r16
	st Z+, r16
	st Z, r16
	ret

menu:
	push r16
	ldi r16, 0
	cbr writeFlag, (1<<2) ; Ensures menu shoot flag is clear
	cbr writeFlag, (1<<3) ; Clears the 'you died' flag.
	cbr writeFLag, (1<<7) ; The troll flag.
menuLoop:
	rcall clrLCD			; Clears the LCD so menu can be displayed.
	REGISTER $2A, $00		; Sets the cursor to the top left of the screen.
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00
	ldi r16, 33				
	WRITESTRING options, r16 ; Prints the menu text.
	sbr writeFlag, (1<<0)	; Sets the writeFLag to allow us to update the screen.
	ldi r16, 0
	sts score, r16			; Resets the score between plays.
	call writePlayer		; Writes out player and rockets
	call writeRockets
	cbr writeFlag, (1<<0)
	call BigDel				; A break to allow the interrupt to run.
	sbr writeFlag, (1<<0)
	sbrs writeFLag, 2		; If the menu shoot flag is set, go to option slection.
	jeq menuComp
	jmp menuLoop
menuComp:
	inc r16
	cpi r16, 6				; Tries to wait until rocket hits the top of the screen before triggering options.
	jlo menuLoop
	pop r16
	cpi playerPos, 10		; If playerPos < 10, select play.
	jlo play
	cpi playerPos, 21		; If 10 < playerPos < 21, select extraInfo.
	jlo extraInfo
	cpi playerPos, 33
	jlo undefined			; If 21 < playerPos < 33, trigger debugTime.
	cbr writeFlag, (1<<0)	; Clear the writeFlag so we can proceed with the game.
menu1:
	ret

extraInfo:
	REGISTER $2A, $00		; Sets the cursor to the top left again.
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00
	ldi r16, 189			; Writes out our 'Easter egg' text.
	WRITESTRING extra, r16
	call BiglyDel			; Causes a delay so there is time to read the text.
	call BiglyDel
	call BiglyDel
	call BiglyDel
	jmp menu

undefined:
	sbr writeFlag, (1<<7)	; Sets the troll bit to enable debugtime.
	jmp play


deathScreen:
	REGISTER $2A, $00		; Sets the cursor to the top left again.
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00

	push r16
	ldi r16, 26
	WRITESTRING uDed, r16	; Writes the death screen text.
	ldi r16, 15
	REGISTER $2A, $00		; Moves the cursor down a bit.
	REGISTER $2B, $00
	REGISTER $2C, $3D
	REGISTER $2D, $00
	WRITESTRING uScore, r16	; Writes out 'you scored'.
	lds r16, score
	call scorePrint			; Prints your score as a decimal.
	call BiglyDel
	call BiglyDel
	pop r16
	rjmp Main				; Restarts the program.

winScreen:
	REGISTER $2A, $00		; Sets the cursor to the top left again.
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00
	call clrLCD
	push r16
	ldi r16, 54
	WRITESTRING uWin, r16	; Writes the win screen text.
	ldi r16, 15
	REGISTER $2A, $00
	REGISTER $2B, $00
	REGISTER $2C, $7D		; Moves the cursor down a bit.
	REGISTER $2D, $00
	WRITESTRING uScore, r16	; Writes out 'you scored'.
	lds r16, score
	call scorePrint			; Prints your score as a decimal.
	call BiglyDel
	call BiglyDel
	pop r16
	rjmp Main				; Restarts the program.

foeLoop:
	inc r17					; Increment the lap counter (do this twice so the aliens only do 2 laps not 4).
	inc r17
run1:
	rcall screenUpdate		; Updates the screen.
	dec loLength			; Decrements the left offset and increments the right offset to move the aliens to the left.
	inc roLength
	cpi loLength, $00		; When the left offset reaches 0, jump to reverse.
	breq reverse

	rjmp run1				; Loops after every movement to redraw screen and carry on.


reverse:
	rcall screenUpdate		; This does the same as foeLoop but with loLength and roLength reversed.
	dec roLength
	inc loLength
	cpi roLength, $00
	breq foeLoop

	rjmp reverse


;##### General routines #####
scorePrint:			; This is a hex-decimal converter, only works on numbers <= 99. [REFME]
	push r16
	push r17
	clr r7
	clr r8
calc10:				; Count the number of tens.
	ldi r17,$0A		; Load r19 with 10.
loop10:
	sub r16,r17		; Subtract 10 from the number (only 8 bits needed as <100).
	brpl next10		; still positive, keep going
	breq calc1		; exactly divide by 10
	add r16,r17		; restore the remainder (less than 10, so 8 bit ok)
	jmp calc1
next10:
	inc r8			; we were able to subtract 10 again, so increment r10
	jmp loop10
calc1:
	mov r7,r16		;at this point r8 has 10�s, and r7 has 1�s
	ldi r16, $30	; Convert to hex character codes.
	add r7, r16
	add r8, r16
	WRITECHARR r8	; Write the 10s
	WRITECHARR r7	; Write the 1s
	pop r16
	pop r17
	ret

	
screenUpdate:			; Draws the game screens.
	rcall clrLCD
	REGISTER $2A, $00	; Set the cursor to the top left.
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00
	call row1			; Call the code to write the rows.
	sbrc writeFlag, 3	; Checks bit 3 of the write flag (death flag). If death flag is clear, call esc. Otherwise, call the deathScreen.
	jmp deathScreen
	call esc			 
	ret

row1:
	cpi r17, 5			; Checks to lap counter to see if we need more than one row. (Counter starts at 1, hence an odd no. corresponds to even no. of laps).
	cge row2			; If we need more than one row, jump to row 2. This works as a cascade so the program jumps through until it doesn't meet the lap count criteria to progress further. It then runs back drawing rows as it does so.
	WRITESTRING lo, loLength	; Actually writes row 1.
	WRITECSTRING foe1, foeLength
	WRITESTRING ro, roLength
	ret

row2:
	cpi r17, 9			; This does the same as above for row 2.
	cge row3
	WRITESTRING lo, loLength
	WRITECSTRING foe2, foeLength
	WRITESTRING ro, roLength
	ret

row3:
	cpi r17, 13			
	cge row4
	WRITESTRING lo, loLength
	WRITECSTRING foe3, foeLength
	WRITESTRING ro, roLength
	ret

row4:
	cpi r17, 17
	cge row5
	WRITESTRING lo, loLength
	WRITECSTRING foe4, foeLength
	WRITESTRING ro, roLength
	ret

row5:
	cpi r17, 21
	cge row6
	WRITESTRING blnkRow, blnkRowl
	ret

row6:
	cpi r17, 25				
	cge row7
	WRITESTRING blnkRow, blnkRowl
	ret

row7:
	cpi r17, 29				; This code is for when the aliens reach the bottom of the screen. The program has to check whether there are any aliens on the lowest row above the player before it can move down.
	cge row8
	WRITESTRING blnkRow, blnkRowl
	push r30
	push r31
	ldi ZH, HIGH(2*foeRem)	; Loads the kill counter for the correct alien rown (in this case the bottom row).
	ldi ZL, LOW(2*foeRem)
	ld r16, Z
	pop r31
	pop r30
	cpi r16, 10				; Compares the kill counter to 10. If it is 10, sets the kill flag. Otherwise, returns.
	breq pc + 2
	sbr writeFlag, (1<<3)
	ret

row8:
	cpi r17, 33				; As above but for the second row of aliens.
	cge row9
	WRITESTRING blnkRow, blnkRowl
	push r30
	push r31
	ldi ZH, HIGH(2*foeRem)
	ldi ZL, LOW(2*foeRem)
	adiw Z, 2
	ld r16, Z
	pop r31
	pop r30
	cpi r16, 10
	breq pc + 2
	sbr writeFlag, (1<<3)
	ret

row9:
	cpi r17, 37			; As above but for the third row of aliens.
	WRITESTRING blnkRow, blnkRowl
	push r30
	push r31
	ldi ZH, HIGH(2*foeRem)
	ldi ZL, LOW(2*foeRem)
	adiw Z, 4
	ld r16, Z
	pop r31
	pop r30
	cpi r16, 10
	breq pc + 2
	sbr writeFlag, (1<<3)
	ret
	
esc:
	rcall writePlayer	; This loop runs when all the alien rows have been drawn. The player and rockets are written here.
	rcall writeRockets
	cbr writeFlag, (1<<0)
	rcall BigDel		; Another gap for the interrupt to run in.
	sbr writeFlag, (1<<0)
	ret

writeRockets:
	push r16
	push r17
	push r22
	push r26
	push r27
	push r28
	push r29
	lds ZH, sixH		; Loads in the memory location where the most recent rocket was written.
	lds ZL, sixL
	ldi YL, $40			; These values are going to be the start position of the Y cursor (at the bottom of the screen).
	ldi YH, $01
	ldi r22, 0			; Times round - gives row of rocket.
	dec r17				; These operations turn r17 into the number of rows written to the screen.
	lsr r17
	lsr r17
	inc r17
rockLoop:
	inc r22
	add r17, r22		; Finds the sum of the rocket row (>=1, counted from the bottom, starting above the player) and the alien row (>=1, counted from the top).
	REGISTERR $2C, YL	; Sets the vertical position of the cursor to the bottom row of rockets on the screen.
	REGISTERR $2D, YH
	ldi r26, 24			; This is how much we have to increase the horizonatal cursor by to move a disctance of one character across the screen.
	ld r16, Z			; Loads in the position of the rocket on the row above the player (if 0, there is no rocket).
	cpi r16, 0		
	jeq rockInc			; If there is no rocket, move all the rockets up.
	mul r16, r26		; If there is a rocket, multiply its offset by the cursor value.
	mov r26, r0
	mov r27, r1
	REGISTERR $2A, XL	; Use this to move the cursor to the correct position on the screen.
	REGISTERR $2B, XH
	cpi r17, 7			; r17 >= 7 means there is a rocket on the same row as the aliens and we need to check for a hit.
	jge killThings		
rockOut:
	WRITECCHAR $00		; Write out any rockets.
	WRITECCHAR $01

rockInc:				; This is a circular buffer to move the rockets by looking at a table of pointers and incrementing where in the table we start.
	cpi r22, 6			; See if we've dealt with all the rows, if we have, jump to the end.
	jeq rockEnd
	sbiw Y, $20			; Move the Y cursor up a row.
	sbiw Y, $20
	cpi ZL, LOW(2*rockets) ; If ZL is = LOW(2*rockets), we have reached the end of the pointer table, so jump to add5 which lets the circular buffer continue.
	jeq add5
	sbiw Z, 1			; Change which row we are looking at.
	sub r17, r22		; Change r17 back into the alien row number rather than the overlap for future comparisons.
	jmp rockLoop		; Repeat for the next rocket row.
add5:
	adiw Z, 5			; Moves the pointer back to the beginning of the table and changes r17 back to alien row no.
	sub r17, r22
	jmp rockLoop		; Repeat for next rocket row.
rockEnd:
	sts sixL, ZL		; Stores the current address in the circular buffer so it can be written to when a rocket is fired.
	sts sixH, ZH
	pop r29
	pop r28
	pop r27
	pop r26
	pop r22
	pop r17
	pop r16 
	ret

killThings:
	cpi r17, 11			; Checks if rocket is off the top of the screen (if yes go to rockOut).
	jge rockOut
	cp r16, loLength	; Checks to see if rocket is actually in a position which could have an alien.
	jlo rockOut
	subi r17, 7			; Calculates the number of rows of overlap between the rocket and the alien block.
	lsl r17

killComp:
	push r29
	push r28
	push r16
	ldi XH, HIGH(2*foePoint); Loads the table of pointers which correspond to the four rows of aliens
	ldi XL, LOW(2*foePoint)
	add XL, r17				; Moves X to the correct set of pointers.
	ldi r16, 0
	adc r27, r16			; These lines deal with the possibility of XL overflowing when r17 is added to it.
	pop r16
	ld YL, X+				; Loads the low byte of the alien row pointer and post increments
	ld YH, X				; Loads the high byte of the alien row pointer.
	push r18
	sub r16, loLength		; Rocket offset - alien offset = relative offset (how many characters in from the end of the row the rocket will hit).
	pop r18
	cpi r16, 20				; If r16 > 20, rocket has passed the right hand end of the alien row so jump back to rockOut.
	brlo pc+4
	pop r28
	pop r29
	jmp rockOut
	add YL, r16				; Moves to the correct address in the alien row. (Left hand side of rocket.)
	push r16
	ldi r16, 0
	adc r29, r16			
	pop r16					
	adiw Y, 1				; Moves to the right hand side of the rocket.
	push r19
	ld r19, Y				; Loads in the character from the alien row which is above the right half of the rocket.

	cpi r19, $05			; This is the right hand side of an alien, so delete the alien above.
	ceq delAbove			
	cpi r19, $04			; This is the left hand side of an alien, so delete the alien to the right.
	ceq delRight
	cpi r19, $06			; This is a blank character, so undo changes made to r17, restore registers and jump to rockOut.
	brne pc+10
	pop r19
	lsr r17
	push r18
	ldi r18, 7
	add r17, r18
	pop r18
	pop r28
	pop r29
    rjmp rockOut
	pop r19
	lsr r17
	push r18
	ldi r18, 7
	add r17, r18
	pop r18
	pop r28
	pop r29
	jmp rockInc

delAbove:
	push r16
	push r28
	push r29
	ldi YH, HIGH(2*foeRem)	; Loads the table of values which stores the number of kills on each row.
	ldi YL, LOW(2*foeRem)
	add YL, r17				; Moves the pointer so it sits on the number of kills for the correct row.
	ldi r16, 0
	adc r29, r16
	ld r16, Y
	inc r16					; Increment row kill count.
	st Y, r16
	pop r29
	pop r28
	pop r16
	push r16
	ldi r16, $06			
	st Y, r16				; Change the right hand side of the alien to a blank space.
	sbiw Y, 1				; Look at the left hand side of the alien.
	st Y, r16				; Change the left hand side of the alien to a blank space.
	ldi r16, 0
	st Z, r16				; Delete the rocket.
	lds r16, score			; Update the score.
	inc r16
	sts score, r16
	cpi r16, 40				; If score = 40, all aliens are dead so you win.
	jeq winScreen
	pop r16
	ret

delRight:
	push r16
	push r28
	push r29
	ldi YH, HIGH(2*foeRem)	; Loads the table of values which stores the number of kills on each row.
	ldi YL, LOW(2*foeRem)
	add YL, r17				; Moves the pointer so it sits on the number of kills for the correct row.
	ldi r16, 0
	adc r29, r16
	ld r16, Y
	inc r16					; Increment row kill count.
	st Y, r16				
	pop r29
	pop r28
	pop r16
	push r16
	ldi r16, $06			; Change the left hand side of the alien to a blank space.
	st Y, r16
	adiw Y, 1
	st Y, r16				; Change the right hand side of the alien to a blank space.
	ldi r16, 0
	st Z, r16				; Delete the rocket.
	lds r16, score			; Update the score.
	inc r16
	sts score, r16
	cpi r16, 40
	jeq winScreen			; If score = 40, all aliens are dead so you win.
	pop r16
	ret

	

foeRow:
	push r17				; This code initialises the byte tables for the rows of aliens.
foej:
	ldi r17, $04			
	st Z+, r17				; Starts from the beginning of the selected row, makes the first character a $04 and post increments.
	ldi r17, $05		
	st Z+, r17				; Makes the next character a $05 and post increments.
	subi r16, 2
	cpi r16, 0				; Loops until all the characters in the row are initialised.
	jne foej
	pop r17
	ret

rocketRows:
	push r16
	push r17
	ldi r16, 6				; This code initialises all the elements in the rocket table to 0 so we start with no rockets.
rowj:
	ldi r17, $00
	st Z+, r17			
	subi r16, 1
	cpi r16, 0				; Loops until all 6 rows are 0.
	jne rowj
	pop r17
	pop r16
	ret

writePlayer:
	REGISTER $2C, $80		; Sets the cursor to the bottom row of the screen.
	REGISTER $2D, $01
	WRITESTRING blnkRow, playerPos	; Writes blank spaces followed by the player character.
	WRITECCHAR $02
	WRITECCHAR $03
	ret

.INCLUDE "delayRoutines.asm"
;.INCLUDE "buttons.asm"
.INCLUDE "LCDdriver.asm"
.INCLUDE "variablesAndByteTables.asm"
.INCLUDE "char.asm"
.INCLUDE "comparator.asm"