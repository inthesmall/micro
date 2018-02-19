/*;
; spaceInvaders.asm
;
; Created: 05/02/2018 16:14:26
; Author : cbl15
;
			; start address well above interrupt table
		jmp Init
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
		reti			; Timer 2 Overflow Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer 1 Capture  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer1 CompareA  Vector 
		nop			; Vector Addresses are 2 words apart
		reti			; Timer 1 CompareB  Vector 
		;nop			; Vector Addresses are 2 words apart
		;reti
		nop			; Timer 1 Overflow  Vector 
		jmp playerPoll		; Timer 0 Compare  Vector 
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
		nop			; Vector Addresses are 2 words apart
		reti			; Analog Comparator  Vector 

.org		$0080			; start address well above interrupt table

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
	ldi r16, $C0		; Idle Mode - SE bit in MCUCR not set
	out MCUCR, r16		; External SRAM Enable Wait State Enabled
   
;##### Comparator Setup Code #####
	;CHECKME
	ldi r16,$80			; Comparator Disabled, Input Capture Disabled 
	out ACSR, r16		; Comparator Settings

;##### ADC setup code #####
	ldi r16, $83		; ADC interrupt disabled, ADC enable
	out ADCSR, r16		; Single shot mode, prescaler: CK/8
	ldi r18, $20
	;CHECKME
	out ADMUX, r18

;##### Magical display setup code of magicalness #####
	ldi r18, $00
	rcall Idisp
	ldi r23, $F0
	ldi r24, $00
	push r18
	ldi r18, $01
	out PIND, r18
	pop r18

;##### Input setup #####
		; ******* Port A Setup Code ****  
		ldi r16, $FF		; Address AD7 to AD0
		out DDRA, r16		; Port A Direction Register
		ldi r16, $00		; Init value 
		out PORTA, r16		; Port A value
   
		; ******* Port B Setup Code ****  
		ldi r16, $00		; 
		out DDRB , r16		; Port B Direction Register
		ldi r16, $FF		; Who cares what is it....
		out PORTB, r16		; Port B value
   
		; ******* Port C Setup Code ****  
		ldi r16, $00		; Address AD15 to AD8
		out PORTC, r16		; Port C value

		; ******* Port D Setup Code ****  
		ldi r16, $FF		; I/O: Output now
		out DDRD, r16		; Port D Direction Register
		ldi r16, $00		; Init value 
		out PORTD, r16		; Port D value*

;##### Timer0 Setup Code #####
	ldi r16,$0F			; Timer 0 Setup
	out TCCR0, r16		; Timer - PRESCALE TCK0 BY 256
						; (devide the 8 Mhz clock by 256)
						; clear timer on OCR0 match
	ldi r16,$9C			; load OCR0 with n=78
	out OCR0,r16		; The counter will go every
                           ; n*256*125 nsec

;##### Interrupts #####
	ldi r16, $02		; OCIE0
	out TIMSK, r16		; T0: Output compare match 

	sei

	ldi writeFlag, 0
	ldi compFlag, 0

Main:
	rcall initFoe
	rcall screenUpdate
retPt:
	rcall menu
	rcall modeSelect
	ldi r17, $00
	rcall foeLoop
	rcall deathScreen
*/
	/*rjmp Main*/

;##### Main Function Calls #####
	
/*initFoe:
	ldi foeLength, 10
	ldi loLength, 6
	ldi roLength, 0
	ldi blnkRowl, 20 

	ret

menu:
	cpi writeFlag, 1
	breq menu1
	ldi writeFlag, 1

	ldi writeFlag, 0
menu1:
	ret

modeSelect:

	ret*/

/*playerPoll:

	in r4, SREG
 	rcall control
	cpi compFlag, 250
	breq movLoop
	inc compFlag
	out SREG, r4
	reti

endP:
	out SREG, r4
	reti

control:
	push r18
	push r23
	ldi r23, $F0
	ldi r18, $00
	rcall initE
	in r16, PINE
	rcall store
	rcall initE
	in r16, PINE
	rcall store
	mov shift, r18
	pop r23
	pop r18
	ret


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
	dec playerPos
	rcall screenUpdate
	ret
	
movRight:
	inc playerPos
	rcall screenUpdate
	ret

shoot:
	rcall screenUpdate
	ret
	*/


/*foeLoop:
	rcall run
	ret

run:
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
	breq run

	rjmp reverse

screenUpdate:
	rcall CLRDIS
	mov r16, loLength
	rcall writeLo
	mov r16, foeLength
	rcall writeFoe
	mov r16, roLength
	rcall writeRo
	mov r16, playerPos
	cpi r17, 5
	brge screenUpdate
	cpi r17, 9
	brge screenUpdate
	cpi r17, 13
	brge deathScreen
	rcall writeBlnkRow
	ldi r16, $FB
	sts $C000, r16
	rcall BigDel
	ldi writeFlag, 0
	ret*/

/*row2:
	cpi r17, 9
	brge row3
	rcall screenUpdate
	rcall writeBlnkRow
	ret

row3:
	cpi r17, 13
	breq deathScreen
	rcall screenUpdate
	rcall screenUpdate
	ret


compare:
	rcall screenUpdate
	cpi r17, 5
	brge row2
	ret*/

/*deathScreen:
	ldi ZH, HIGH(2*uDed)
	ldi ZL, LOW(2*uDed)
	ldi r16, 26
	rcall writeOut

	rjmp retPt*/

/*;##### Buttons #####
btnLoop:
		mov r17, r23
		com r17
btnLoop1:	
		in r16, PINE
		cp r16, r17
		breq btnLoop1
		ret

btnRead:
		rcall DEL4P1ms
		in r16, PINE
		ret

store:	add r18, r16
		;or
		ret

initE:
		out PORTE, r23
		com R23
		out DDRE, r23
		ret

buttonRec:
		ldi r18, $00
		rcall initE
		
		rcall btnLoop
		rcall store
		rcall initE
		rcall btnLoop
		rcall store


;Check if a button is being pressed
checkBtnUp:
		in r24, PINE
		cpi r24, $0F
		brne checkBtnUp
		rcall DEL49ms
		in r24, PINE
		cpi r24, $0F
		brne checkBtnUp
		ret
*/



/*;##### Byte tables #####
lo:
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

ro:
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

foe:
.db $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC

blnkRow:
.db $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F, $6F


uDed:
.db "Congratulations! You died."

.def loLength = r18
.def roLength = r19
.def foeLength = r20
.def playerPos = r21
.def blnkRowl = r22
.def compFlag = r23
.def shift = r24
.def writeFlag = r25*/

;##### General routines #####
/*screenUpdate:
	rcall CLRDIS
	mov r16, loLength
	rcall writeLo
	mov r16, foeLength
	rcall writeFoe
	mov r16, roLength
	rcall writeRo
	mov r16, playerPos
	cpi r17, 5
	brge screenUpdate
	cpi r17, 9
	brge screenUpdate
	cpi r17, 13
	brge Main
	rcall writeBlnkRow
	ldi r16, $FB
	sts $C000, r16
	rcall BigDel
	ldi writeFlag, 0
	ret*/

/*writeLo:
		ldi ZH, HIGH(2*lo)
		ldi ZL, LOW(2*lo)
		rcall writeOut

writeFoe:
		ldi ZH, HIGH(2*foe)
		ldi ZL, LOW(2*foe)
		rcall writeOut

writeRo:
		ldi ZH, HIGH(2*ro)
		ldi ZL, LOW(2*ro)
		rcall writeOut

writeBlnkRow:
		ldi ZH, HIGH(2*blnkRow)
		ldi ZL, LOW(2*blnkRow)
		rcall writeOut


writeOut:
		push r17
writeOut1:
		cpi r16, $00
		breq end	
		lpm
		mov r17, r0
		sts $C000, r17
		rcall busylcd
		dec r16
		adiw Z, $01
		rjmp writeOut1
		
end:	pop r17
		ret
*/
/*busylcd:
		push r16        
busylcd1:
	    lds r16, $8000   ;access 
        sbrc r16, 7      ;check busy bit  7
        rjmp busylcd1
        rcall DEL100mus
		pop r16
        ret   */

/*Idisp:		
		rcall DEL15ms            ; wait 15ms for things to relax after power up           
		ldi r16,    $30	         ; Hitachi says do it...
		sts   $8000,r16                      ; so i do it....
		rcall DEL4P1ms             ; Hitachi says wait 4.1 msec
		sts   $8000,r16	         ; and again I do what I'm told
		rcall DEL100mus                 ; wait 100 mus
		sts   $8000,r16	         ; here we go again folks
        rcall busylcd		
		ldi r16, $3F	         ; Function Set : 2 lines + 5x7 Font
		sts  $8000,r16
        rcall busylcd
		ldi r16,  $08	         ;display off
		sts  $8000, r16
        rcall busylcd		
		ldi r16,  $01	         ;display on
		sts  $8000,  r16
        rcall busylcd
        ldi r16, $38	        ;function set
		sts  $8000, r16
		rcall busylcd
		ldi r16, $0E	        ;display on
		sts  $8000, r16
		rcall busylcd
		ldi r16, $06            ;entry mode set increment no shift
		sts  $8000,  r16
        rcall busylcd

        clr r16
        ret*/


/*CLRDIS:
	    ldi r16,$01	; Clear Display send cursor 
		sts $8000,r16   ; to the most left position
		rcall busylcd
        ret
*/
;##### Delay Routines #####

/*DEL15ms:push r26
		push r27
        ldi XH, HIGH(19997)
        ldi XL, LOW (19997)
COUNT:  
        sbiw XL, 1
        brne COUNT
		pop r27
		pop r26
        ret
;
DEL4P1ms:
		push r26
		push r27
        ldi XH, HIGH(5464)
        ldi XL, LOW (5464)
COUNT1:
        sbiw XL, 1
        brne COUNT1
		pop r27
		pop r26
        ret 
;bigdel
DEL100mus:
		push r26
		push r27
        ldi XH, HIGH(131)
        ldi XL, LOW (131)
COUNT2:
        sbiw XL, 1
        brne COUNT2
		pop r27
		pop r26
        ret 
;
DEL49ms:
		push r26
		push r27
        ldi XH, HIGH(65535)
        ldi XL, LOW (65535)
COUNT3:
        sbiw XL, 1
        brne COUNT3
		pop r27
		pop r26
        ret

BigDel:
        rcall Del49ms
        rcall Del49ms
        rcall Del49ms
	    rcall Del49ms
        rcall Del49ms
        ret
;
BiglyDel:   rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			rcall BigDel
			
			ret*/