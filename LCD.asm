;
; AssemblerApplication1.asm
;
; Created: 07/02/2018 23:23:37
; Author : ethan
;
; Set up SPI as master
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

ldi r16,0b00010111 ; Pin 4 as output for reset
out DDRB, r16 ; SS*, SCK, MOSI outputs
ldi r16, 0
out PORTB, r16
ldi r16, 0b01011110 ; set SPR0, CPHA, CPOL, MSTR, SPE (Interupts [7] disabled)
out SPCR, r16
aq:
	rcall initLCD
	;REGISTER $22, 0
	;REGISTER $52, 0b00000000
	;rcall clrLCD
	rcall stringTest
	;WRITESTRING hello,11
main:
	rcall stringTest
	rjmp main
	
	
hello:
	.db "Hello world"
test:
	rcall clrLCD
	ldi ZH, high(hello*2)
	ldi ZL, low(hello*2)
	ldi r18, 11
	rcall stringOut
	ret

initLCD:
	/*in r16, PORTB
	andi r16, 0b11101111 ; reset low*/
	ldi r16, 0
	out PORTB, r16
	rcall DEL1ms
	;ori r16, 0b00010000 ; reset high
	ldi r16, 0b00010000
	out PORTB, r16
	rcall Del10ms
	; PLL settings
	REGISTER $88, $0B
	rcall DEL1ms
	REGISTER $89, $02
	rcall DEL1ms

	; 8bit, 256 color
	REGISTER $10, $00


	;;;;;;;;;;;;;;;;;;;;;;;;;
	;This may need to change;
	;;;;;;;;;;;;;;;;;;;;;;;;;

	REGISTER $04, $81
	rcall DEL1ms
	REGISTER $14, $63
	REGISTER $15, 0
	REGISTER $16, $03
	REGISTER $17, $03
	REGISTER $18, $0B

	REGISTER $19, $DF
	REGISTER $1A, $01
	REGISTER $1B, $20
	REGISTER $1C, $00
	REGISTER $1D, $16
	REGISTER $1E, $00
	REGISTER $1F, $01
	
	REGISTER $30, $00
	REGISTER $31, $00
	REGISTER $34, $1F
	REGISTER $35, $03
	REGISTER $32, $00
	REGISTER $33, $00
	REGISTER $36, $DF
	REGISTER $37, $01
	;rcall clrLCD
	
	REGISTER $8A, $8A
	REGISTER $8B, $FF ; PWM Duty Cycle
	; LCD ON
	REGISTER $01, $80
	ldi r19, 5
	rcall readStatus
	ret


; Print out an ASCII byte table loaded into Z, with length in r18
stringOut:
/*	ldi r19, (1<<7)
	ldi r20, $40
	rcall writeRegister*/
	REGISTER $40, $80
	/*ldi r20, $21
	ldi r19, (0<<7)|(0<<5)
	rcall writeRegister*/
	REGISTER $2F, $00
	REGISTER $21, $20
	ldi r19, $FF ; Background color
	ldi r20, $60
	rcall writeRegister
	;REGISTER $60, $FF
	inc r20
	rcall writeRegister
	inc r20
	rcall writeRegister
	ldi r19, $00 ; Foreground color
	inc r20
	rcall writeRegister
	inc r20
	rcall writeRegister
	inc r20
	rcall writeRegister
	ldi r20, $02
	rcall writeCommand
	rcall startPacket
stringLoop:
	cpi r18, $00
	breq stringEnd
	lpm r19, Z+
	rcall writeData
	dec r18
	rjmp stringLoop
stringEnd:
	rcall endPacket
	ret


clrLCD:
	ldi r20, $8E
	rcall readRegister
	sbr r19, 6
	REGISTER $8E, (0<<6)
/*	rcall startPacket
	rcall writeData
	rcall endPacket*/
	ret








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;write [r19] into register [r20]
writeRegister:
/*	rcall startPacket
	ldi r16, (1<<7) ; REGISTER write
	out SPDR, r16
	rcall waitTransmit
	out SPDR, r20 ; write address
	rcall waitTransmit
	rcall endPacket
	rcall startPacket
	out SPDR, r16 ; Data write
	rcall waitTransmit
	out SPDR, r19 ; transmit data
	rcall waitTransmit
	rcall endPacket
	ret*/
	rcall writeCommand
	rcall startPacket
	rcall writeData
	rcall endPacket
	ret

; Write command [r20]
writeCommand:
	rcall startPacket
	ldi r16, $80
	out SPDR, r16
	rcall waitTransmit
	out SPDR, r20
	rcall waitTransmit
	rcall endPacket
	ret

; Write byte [r19] as data (no packet control)
writeData:
	ldi r16, 0
	out SPDR, r16
	rcall waitTransmit
	out SPDR, r19
	rcall waitTransmit
	ret

; read a byte into [r19] (no packet control)
readData:
	ldi r16, $40
	out SPDR, r16
	rcall waitTransmit
	;sbi SPSR, SPIF
	ldi r16, $00
	out SPDR, r16
	rcall waitTransmit
	in r19, SPDR
	ret


; Read register [r20] into [r19]
readRegister:
	rcall writeCommand
	rcall startPacket
	rcall readData
	rcall endPacket
	ret
	
readStatus:
	rcall startPacket
	ldi r16, 0b11000000
	out SPDR, r16
	rcall waitTransmit
	;sbi SPSR, SPIF
	ldi r16, $00
	out SPDR, r16
	rcall waitTransmit
	in r19, SPDR
	rcall endPacket
	ret


waitTransmit:
	sbis SPSR, SPIF
	rjmp waitTransmit
	ret

endPacket:
	ldi r16, 0b00010001
	out PORTB, r16 ; End packet
	nop nop nop nop
	nop nop nop nop
	ret

startPacket:
	ldi r16, 0b00010000
	out PORTB, r16 ; Start packet
	nop nop nop nop
	nop nop nop nop
	ret



DEL1ms:
		push r26
		push r27
        ldi XH, HIGH(1330)
        ldi XL, LOW (1330)
COUNT1:
        sbiw XL, 1
        brne COUNT1
		pop r27
		pop r26
        ret 

Del10ms:
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		rcall DEL1ms
		ret


stringTest:
	REGISTER $91, 0
	REGISTER $92, 0
	REGISTER $93, 0
	REGISTER $94, 0
	REGISTER $95, low(799)
	REGISTER $96, 799>>8
	REGISTER $97, low(479)
	REGISTER $98, 479>>8
	REGISTER $63, 7
	REGISTER $64, 0
	REGISTER $65, 0
	;REGISTER $22, 0
	REGISTER $90, $B0
	ldi r20, $90
testLoop:
	rcall readRegister
	sbrc r19, 7
	rjmp testLoop
	ret
