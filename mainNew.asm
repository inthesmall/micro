.INCLUDE "setup.asm"
.INCLUDE "LCDdriver.inc"

;###### LCD setup #####

rcall setupLCD
/*REGISTER $2A, $00
REGISTER $2B, $00
REGISTER $2C, $00
REGISTER $2D, $00*/
/*CREATECHAR rl , $00
CREATECHAR rr, $01
CREATECHAR pl, $02
CREATECHAR pr, $03
CREATECHAR al, $04
CREATECHAR ar, $05*/
rcall clrLCD
/*;Rocket:
WRITECCHAR $00
WRITECCHAR $01
;Player:
WRITECCHAR $02
WRITECCHAR $03
;Alien:
WRITECCHAR $04
WRITECCHAR $05
*/
;##############

ldi writeFlag, 0
ldi compFlag, 0

;##### The start of the program #####
Main:
	rcall initPpl
	rcall clrLCD
retPt:
	rcall menu
	rcall modeSelect
	ldi r17, $00
	rcall foeLoop
	rcall deathScreen

	rjmp Main

;##### Interrupt vector code #####

interruptVector:
	in r4, SREG
 	push r18
	push r23
	rcall buttonRead
	mov shift, r18
	pop r23
	pop r18
	cpi compFlag, 25
	breq movLoop
	inc compFlag
	out SREG, r4
	reti
endP:
	out SREG, r4
	reti

movLoop:
	cpi writeFlag, 1
	breq endP
	ldi compFlag, 0
	rcall playerLoop
	reti

playerLoop:
	cpi shift, $77
	breq movLeft
	cpi shift, $B7
	breq movRight
	cpi shift, $D7
	breq shoot
	ret


movLeft:
	cpi playerPos, 0
	breq movLend
	dec playerPos
movLend:
	ret
	
movRight:
	cpi playerPos, 31
	breq movRend
	inc playerPos
movRend:
	ret
	

shoot:
	ret

;##### Loops #####
initPpl:
	ldi foeLength, 20
	ldi loLength, 13
	ldi roLength, 0
	ldi blnkRowl, 33
	ldi playerPos, 0
	ret

menu:
	cpi writeFlag, 1
	breq menu1
	ldi writeFlag, 1

	ldi writeFlag, 0
menu1:
	ret

modeSelect:

	ret

deathScreen:
	push r16
	ldi r16, 26
	WRITESTRING uDed, r16
	pop r16
	rjmp retPt


foeLoop:
	inc r17
run1:
	rcall screenUpdate
	dec loLength
	inc roLength
	cpi loLength, $00
	breq reverse

	rjmp run1


reverse:
	rcall screenUpdate
	dec roLength
	inc loLength
	cpi roLength, $00
	breq foeLoop

	rjmp reverse


;##### General routines #####

screenUpdate:
	rcall clrLCD
	REGISTER $2A, $00
	REGISTER $2B, $00
	REGISTER $2C, $00
	REGISTER $2D, $00
	WRITESTRING lo, loLength
	WRITECSTRING foe, foeLength
	WRITESTRING ro, roLength
	
	cpi r17, 5
	jlt esc
	WRITESTRING lo, loLength
	WRITECSTRING foe, foeLength
	WRITESTRING ro, roLength
	cpi r17, 9
	jlt esc
	WRITESTRING lo, loLength
	WRITECSTRING foe, foeLength
	WRITESTRING ro, roLength
	cpi r17, 13
	jlt esc
	WRITESTRING lo, loLength
	WRITECSTRING foe, foeLength
	WRITESTRING ro, roLength
	cpi r17, 17
	jge deathScreen
esc:
	rcall writePlayer
	rcall BigDel
	ldi writeFlag, 0
	ret


writeBlnkRow:
	WRITESTRING blnkRow, blnkRowl
	ret

writePlayer:
	REGISTER $2C, $80
	REGISTER $2D, $01
	WRITESTRING blnkRow, playerPos
	WRITECCHAR $02
	WRITECCHAR $03
	ret

.INCLUDE "delayRoutines.asm"
.INCLUDE "buttons.asm"
.INCLUDE "LCDdriver.asm"
.INCLUDE "variablesAndByteTables.asm"
.INCLUDE "char.asm"