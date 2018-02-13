#ifndef LCD_DRIVER_INC
#define LCD_DRIVER_INC
.MACRO REGISTER
	ldi r20, @0
	ldi r19, @1
	rcall writeRegister
.ENDMACRO
.MACRO WRITESTRING
	ldi r18, @1
	ldi ZH, high(@0*2)
	ldi ZL, low(@0*2)
	rcall stringOut
.ENDMACRO
.MACRO WRITECHAR
	ldi r18, @0
	rcall charOut
.ENDMACRO
#endif
