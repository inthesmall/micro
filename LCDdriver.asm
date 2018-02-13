.MACRO REGISTER
	ldi r20, @0
	ldi r19, @1
	rcall writeRegister
.ENDMACRO

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

clrLCD:
	REGISTER $8E, (0<<6)
	ret



setupLCD:
	ldi r16,0b00010111 ; Pin 4 as output for reset
	out DDRB, r16 ; SS*, SCK, MOSI outputs
	ldi r16, 0
	out PORTB, r16
	ldi r16, 0b01011110 ; set SPR0, CPHA, CPOL, MSTR, SPE (Interupts [7] disabled)
	out SPCR, r16

	ldi r16, 0
	out PORTB, r16 ;reset low
	rcall DEL1ms
	ldi r16, 0b00010000 ;reset high
	out PORTB, r16
	rcall Del10ms

	; PLL Setup
	REGISTER $88, $0A
	rcall DEL1ms
	REGISTER $89, $02
	rcall DEL1ms

	REGISTER $10, $00 ; 8-bit

	REGISTER $04, $81 ; Pixel clock
	rcall DEL1ms

	; Horizonatal
	REGISTER $14, $63
	REGISTER $15, $00
	REGISTER $16, $03
	REGISTER $17, $03
	REGISTER $18, $0B

	; Vertical
	REGISTER $19, $DF
	REGISTER $1A, $01
	REGISTER $1B, $1F ;$20
	REGISTER $1C, $00
	REGISTER $1D, $16
	REGISTER $1E, $00
	REGISTER $1F, $01

	; Active window
	REGISTER $30, $00
	REGISTER $31, $00
	REGISTER $34, $1F
	REGISTER $35, $03
	REGISTER $32, $00
	REGISTER $33, $00
	REGISTER $36, $DF
	REGISTER $37, $01

	REGISTER $8E, $80
	rcall Del10ms

	; Display on
	REGISTER $01, $80
	REGISTER $C7, $01

	; PWM Backlight
	REGISTER $8A, $8A
	REGISTER $8B, $FF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;write [r19] into register [r20]
writeRegister:
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

; Write char [r18] to screen
charOut:
	ldi r20, $40
	rcall writeCommand
	rcall startPacket
	rcall readData
	ori r19, $80
	rcall writeData
	rcall endPacket
	ldi r20, $21
	rcall writeCommand
	rcall startPacket
	rcall readData
	cbr r19, 7
	cbr r19, 5
	rcall writeData
	rcall endPacket
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

	;cursor
	REGISTER $2A, $0A
	REGISTER $2B, $00
	REGISTER $2C, $0A
	REGISTER $2D, $00
	
	ldi r20, $02
	rcall writeCommand
	rcall startPacket
	mv r19, r18
	rcall writeData
	rcall endPacket
	ret