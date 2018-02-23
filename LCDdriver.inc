#ifndef LCD_DRIVER_INC
#define LCD_DRIVER_INC
; REGISTER [0],[1] writes [1] to LCD register [0]
.MACRO REGISTER
	push r20
	push r19
	push r18
	push r16
	ldi r20, @0
	ldi r19, @1
	call writeRegister
	pop r16
	pop r18
	pop r19
	pop r20
.ENDMACRO
; REGISTERR [0],[1r] writes [1r] to LCD register [0],  where [1r] is a value stored in a register
.MACRO REGISTERR
	push r20
	push r19
	push r18
	push r16
	ldi r20, @0
	mov r19, @1
	rcall writeRegister
	pop r16
	pop r18
	pop r19
	pop r20
.ENDMACRO
; WRITESTRING [0],[1r] writes string [0] of length [1r](register)
.MACRO WRITESTRING
	push r20
	push r19
	push r18
	mov r18, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall stringOut
	pop r18
	pop r19
	pop r20
.ENDMACRO
; WRITECHAR [0] writes character [0]
.MACRO WRITECHAR
	push r20
	push r19
	push r18
	ldi r18, @0
	rcall charOut
	pop r18
	pop r19
	pop r20
.ENDMACRO
; WRITECHARR [0] writes contents of register [0]
.MACRO WRITECHARR
	push r20
	push r19
	push r18
	mov r18, @0
	rcall charOut
	pop r18
	pop r19
	pop r20
.ENDMACRO
; WRITECSTRING [0],[1r] writes string [0] of length [1r](register) using custom characters
.MACRO WRITECSTRING
	push r20
	push r19
	push r18
	mov r18, @1
;	ldi r18, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall cStringOut
	pop r18
	pop r19
	pop r20
.ENDMACRO
; WRITECCHAR [0] writes custom character [0]
.MACRO WRITECCHAR
	push r20
	push r19
	push r18
	ldi r18, @0
	rcall cCharOut
	pop r18
	pop r19
	pop r20
.ENDMACRO
; CREATECHAR [0],[1] creates a custom character given by bytetable [0] with char code [1]
.MACRO CREATECHAR
	push r20
	push r19
	push r18
	ldi r19, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	call addChar
	pop r18
	pop r19
	pop r20
.ENDMACRO
jmp LCDskip
.INCLUDE "char.asm"
LCDskip:
#endif
