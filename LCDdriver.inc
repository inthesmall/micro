#ifndef LCD_DRIVER_INC
#define LCD_DRIVER_INC
; REGISTER [0],[1] writes [1] to [0]
.MACRO REGISTER
	ldi r20, @0
	ldi r19, @1
	rcall writeRegister
.ENDMACRO
; WRITESTRING [0],[1] writes string [1] of length [0]
.MACRO WRITESTRING
	ldi r18, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall stringOut
.ENDMACRO
; WRITECHAR [0] writes character [0]
.MACRO WRITECHAR
	ldi r18, @0
	rcall charOut
.ENDMACRO
; WRITECSTRING [0],[1] writes string [1] of length [0] using custom characters
.MACRO WRITECSTRING
	ldi r18, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall cStringOut
.ENDMACRO
; WRITECCHAR [0] writes custom character [0]
.MACRO WRITECCHAR
	ldi r18, @0
	rcall cCharOut
.ENDMACRO
; CREATECHAR [0],[1] creates a custom character given by bytetable [0] with char code [1]
.MACRO CREATECHAR
	ldi r19, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall addChar
.ENDMACRO
#endif
