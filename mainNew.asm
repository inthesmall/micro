.INCLUDE "setup.asm"
.INCLUDE "LCDdriver.inc"

;###### LCD setup #####

rcall setupLCD
/*REGISTER $2A, $00
REGISTER $2B, $00
REGISTER $2C, $00
REGISTER $2D, $00*/
CREATECHAR rl , $00
CREATECHAR rr, $01
CREATECHAR pl, $02
CREATECHAR pr, $03
CREATECHAR al, $04
CREATECHAR ar, $05
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
	cpi compFlag, 2
	breq movLoop
	inc compFlag
	out SREG, r4
	reti
endP:
	out SREG, r4
	reti

movLoop:
	sbrc writeFlag, 0
	breq endP
	sbrs writeFlag, 1
	call clrRow
	sbrc writeFlag, 1
	call nastyHack
	cbr writeFlag, (1<<1)
	ldi compFlag, 0
	rcall playerLoop
	out SREG, r4
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
	sbr writeFlag, (1<<1)
	push r30
	push r31
	lds ZL, sixL
	lds ZH, sixH
	st Z, playerPos
	pop r31
	pop r30
	ret

clrRow:
	push r16
	push r30
	push r31
	ldi r16, 0
	lds ZH, sixH
	lds ZL, sixL
	st Z, r16
	pop r31
	pop r30
	pop r16
	ret

nastyHack:
	cpi playerPos, 0
	jne noNastyHack
	push r16
	push r30
	push r31
	ldi r16, 1
	lds ZL, sixL
	lds ZH, sixH
	st Z, r16
	pop r31
	pop r30
	pop r16
noNastyHack:	
	ret
	

;##### Loops #####
initPpl:
	ldi foeLength, 20
	ldi loLength, 13
	ldi roLength, 0
	ldi blnkRowl, 33
	ldi playerPos, 0
	ldi ZH, HIGH(2*foe1)
	ldi ZL, LOW(2*foe1)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe2)
	ldi ZL, LOW(2*foe2)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe3)
	ldi ZL, LOW(2*foe3)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*foe4)
	ldi ZL, LOW(2*foe4)
	mov r16, foeLength
	call foeRow
	ldi ZH, HIGH(2*rockets)
	ldi ZL, LOW(2*rockets)
	sts sixL, ZL
	sts sixH, ZH
	call rocketRows
	ldi YH, HIGH(2*foePoint)
	ldi YL, LOW(2*foePoint)
	ldi ZH, HIGH(2*foe1)
	ldi ZL, LOW(2*foe1)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe2)
	ldi ZL, LOW(2*foe2)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe3)
	ldi ZL, LOW(2*foe3)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1
	ldi ZH, HIGH(2*foe4)
	ldi ZL, LOW(2*foe4)
	st Y, ZL
	adiw Y, 1
	st Y, ZH
	adiw Y, 1

	ret

menu:
	sbrc writeFlag, 0
	breq menu1
	sbr writeFlag, (1<<0)

	cbr writeFlag, (1<<0)
menu1:
	ret

modeSelect:

	ret

deathScreen:
	push r16
	ldi r16, 26
	WRITESTRING uDed, r16
	call BiglyDel
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
	call row1
	call esc
	ret

row1:
	cpi r17, 5
	cge row2
	WRITESTRING lo, loLength
	WRITECSTRING foe1, foeLength
	WRITESTRING ro, roLength
	ret

row2:
	cpi r17, 9
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
	jge deathScreen
	WRITESTRING blnkRow, blnkRowl
	ret
	
esc:
	rcall writePlayer
	rcall writeRockets
	cbr writeFlag, (1<<0)
	rcall BigDel
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
	lds ZH, sixH
	lds ZL, sixL
	ldi YL, $40
	ldi YH, $01
	ldi r22, 0 ;Times round - gives row of rocket
	dec r17
	lsr r17
	lsr r17
	inc r17
rockLoop:
	inc r22
	add r17, r22
	REGISTERR $2C, YL
	REGISTERR $2D, YH
	ldi r26, 24
	ld r16, Z
	cpi r16, 0
	jeq rockInc
	mul r16, r26
	mov r26, r0
	mov r27, r1
	REGISTERR $2A, XL
	REGISTERR $2B, XH
	cpi r17, 7
	jge killThings
rockOut:
	WRITECCHAR $00
	WRITECCHAR $01

rockInc:
	
	cpi r22, 6
	jeq rockEnd
	sbiw Y, $20
	sbiw Y, $20
	cpi ZL, LOW(2*rockets)
	jeq add5
	sbiw Z, 1
	sub r17, r22
	jmp rockLoop
add5:
	adiw Z, 5
	sub r17, r22
	jmp rockLoop
rockEnd:
	sts sixL, ZL
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
	cpi r17, 11
	jge rockOut
	cp r16, loLength
	jlo rockOut
	subi r17, 7
	lsl r17

killComp:
	ldi XH, HIGH(2*foePoint)
	ldi XL, LOW(2*foePoint)
	add XL, r17
	push r16
	ldi r16, 0
	adc r27, r16
	pop r16
	ld YL, X+
	ld YH, X
	push r18
	sub r16, loLength
	add YL, r16
	push r16
	ldi r16, 0
	adc r29, r16
	pop r16
	adiw Y, 1
	push r19
	ld r19, Y
	cpi r19, $05
	ceq delAbove
	cpi r19, $04
	ceq delRight
	;if 6 go to rock Out
	pop r19
	pop r18
	lsr r17
	push r18
	ldi r18, 7
	add r17, r18
	pop r18
	jmp rockInc

delAbove:
	push r16
	ldi r16, $06
	st Y, r16
	sbiw Y, 1
	st Y, r16
	ldi r16, 0
	st Z, r16
	pop r16
	ret

delRight:
	push r16
	ldi r16, $06
	st Y, r16
	adiw Y, 1
	st Y, r16
	ldi r16, 0
	st Z, r16
	pop r16
	ret

	

foeRow:
	push r17
foej:
	ldi r17, $04
	st Z+, r17
	ldi r17, $05
	st Z+, r17
	subi r16, 2
	cpi r16, 0
	jne foej
	pop r17
	ret

rocketRows:
	push r16
	push r17
	ldi r16, 6
rowj:
	ldi r17, $00
	st Z+, r17
	subi r16, 1
	cpi r16, 0
	jne rowj
	pop r17
	pop r16
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