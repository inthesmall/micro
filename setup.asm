 		jmp Init ;[REFME]
		reti		                 
		nop			; Vector Addresses are 2 words apart
		reti			; External 0 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 1 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 2 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 3 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 4 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 5 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 6 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; External 7 interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer 2 Compare Vector 
		nop			; Vector Addresses are 2 words apart

		jmp inputs			; Timer 1 Capture  Vector 
					; Vector Addresses are 2 words apart
		jmp timeout			; Timer1 CompareA  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer 1 CompareB  Vector 
		nop	
		nop		; Timer 1 Overflow  Vector 
		jmp interruptVector		; Timer 0 Compare  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer 0 Overflow interrupt  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; SPI  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; UART Receive  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; UDR Empty  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; UART Transmit  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; ADC Conversion Complete Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; EEPROM Ready Vector 
		nop	
		reti		; Vector Addresses are 2 words apart
		;jmp analogComparator			; Analog Comparator  Vector 

.org		$0080			; start address well above interrupt table

Init: 
;##### Stack Pointer Setup Code #####

	ldi r16, $0F		; Stack Pointer Setup to 0x0FFF
	out SPH,r16			; Stack Pointer High Byte 
	ldi r16, $FF		
	out SPL,r16			; Stack Pointer Low Byte 
   
;###### RAMPZ Setup Code #####
; Lower memory page arithmetic
	ldi  r16, $00		; 1 = EPLM acts on upper 64K
	out RAMPZ, r16		; 0 = EPLM acts on lower 64K
   
;##### Comparator Setup Code #####
	;CHECKME
	; I think this - Ethan
	; Disable comparator
	; Disable bandgap
	; Disable output to pin
	; Don't touch interupt flag
	; Disable interupt
	; Enable input capture
	; These two don't matter, but may as well set them to rising edge in case
		; we use interupts later
	ldi r16, 0b10000111 ;$F0 ;0b00001111 ; Comparator disabled, Input Capture enabled
	out ACSR, r16		; Comparator Settings

;##### Timer0 Setup Code #####
	ldi r16,$0F			; Timer 0 Setup
	out TCCR0, r16		; Timer - PRESCALE TCK0 BY 256
						; (devide the 8 Mhz clock by 256)
						; clear timer on OCR0 match
	ldi r16,$FF			; load OCR0 with n=1024
	out OCR0,r16		; The counter will go every
                           ; n*256*125 nsec

;##### PORTE setup code #####
	ldi r16, 0b01110011
	out DDRE, r16
	ldi r16, 0b10000000
	out PORTE, r16

;##### Timer1 Setup Code #####
	ldi r16, 0 ; Disable all output comparisons
	out TCCR1A, r16 ; And set to normal mode
	ldi r16, 0b11000000 ; Enable input capture filtering, trigger on leading edge
	out TCCR1B, r16 ; No clock input, timer stopped
	ldi r16, $10 ; Set the overflow value to 0x1000 ~ 0.0005ms
	out OCR1AH, r16
	ldi r16, 0
	out OCR1AL, r16


;##### Interrupts setup #####
	ldi r16, 0b00111010		; Enable Timer 1, Timer 0 output compare match
	out TIMSK, r16		; Enable timer one input capture

	sei

jmp setupSkip
.INCLUDE "comparator.asm"
setupSkip:

;##### Macros #####
; jump to [0] if register equal to given value.
.MACRO jeq
   brne pc+2
   rjmp @0
.ENDMACRO
; jump to [0] if register not equal to given value.
.MACRO jne
   breq pc+2
   rjmp @0
.ENDMACRO
; jump to [0] if register less than or equal to given value.
.MACRO jlo
   brsh pc+2
   rjmp @0
.ENDMACRO
; jump to [0] if register greater than or equal to given value.
.MACRO jge
	brlo pc+2
	rjmp @0
.ENDMACRO
; jump to [0] if register less than given value.
.MACRO jlt
	brge pc+2
	rjmp @0
.ENDMACRO
; call [0] if register greater than given value.
.MACRO cge
	brlo pc+3
	call @0
.ENDMACRO
; call [0] if register equal to given value.
.MACRO ceq
   brne pc+3
   call @0
.ENDMACRO