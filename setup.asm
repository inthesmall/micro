rjmp Init

Init: 
;##### Stack Pointer Setup Code #####

	ldi r16, $0F		; Stack Pointer Setup to 0x0FFF
	out SPH,r16			; Stack Pointer High Byte 
	ldi r16, $FF		; Stack Pointer Setup 
	out SPL,r16			; Stack Pointer Low Byte 
   
;###### RAMPZ Setup Code #####

;	lower memory page arithmetic
	ldi  r16, $00		; 1 = EPLM acts on upper 64K
	out RAMPZ, r16		; 0 = EPLM acts on lower 64K
   
;###### Sleep Mode And SRAM #####

;	Tell it we want read and write activity on RE WR
/*	ldi r16, $C0		; Idle Mode - SE bit in MCUCR not set
	out MCUCR, r16	*/	; External SRAM Enable Wait State Enabled
   
;##### Comparator Setup Code #####
	;CHECKME
	ldi r16,$80			; Comparator Disabled, Input Capture Disabled 
	out ACSR, r16		; Comparator Settings
