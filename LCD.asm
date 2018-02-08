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
ldi r16,23 ; Pin 4 as output for reset
out DDRB, r16 ; SS*, SCK, MOSI outputs 
ldi r16, 0b010111001 ; set SPR0, CPHA, CPOL, MSTR, SPE (Interupts [7] disabled)
out SPCR, r16

	rcall initLCD
	rcall test
main:
	nop
	rjmp main
	
	
hello:
	.db "Hello world"
test:
	ldi ZH, high(hello*2)
	ldi ZL, low(hello*2)
	ldi r18, 11
	rcall stringOut

initLCD:
	in r16, PORTB
	andi r16, 0b11101111 ; reset low
	out PORTB, r16
	; 1ms delay
	ori r16, 0b00010000 ; reset high
	; 10ms delay

	; PLL settings
	REGISTER $88, $0B
	; 1ms delay
	REGISTER $89, $02
	; 1ms delay

	; 8bit, 256 color
	REGISTER $10, $00


	;;;;;;;;;;;;;;;;;;;;;;;;;
	;This may need to change;
	;;;;;;;;;;;;;;;;;;;;;;;;;

	REGISTER $04, $81
	; 1ms delay
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

	REGISTER $8A, $8A
	REGISTER $8B, $55 ; PWM Duty Cycle
	; LCD ON
	;REGISTER $01, $80
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
	REGISTER $21, $A0
	;ldi r19, $FF ; Background color
	;ldi r20, $60
	;rcall writeRegister
	REGISTER $60, $FF
	inc r20
	rcall writeRegister
	inc r20
	rcall writeRegister
	ldi r19, 0 ; Foreground color
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
	cbr r19, 6
	rcall startPacket
	rcall writeData
	rcall endPacket
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
	sbi SPSR, SPIF
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
	



waitTransmit:
	sbis SPSR, SPIF
	rjmp waitTransmit
	ret

endPacket:
	ldi r16, (1<<0)
	out PORTB, r16 ; End packet
	nop nop nop nop
	nop nop nop nop
	ret

startPacket:
	ldi r16, (0<<0)
	out PORTB, r16 ; Start packet
	nop nop nop nop
	nop nop nop nop
	ret


