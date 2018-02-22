.INCLUDE "LCDdriver.inc"
#ifndef dels
#define dels
DEL1ms:
		push r26
		push r27
        ldi XH, HIGH(1330)
        ldi XL, LOW (1330)
COUNT001:
        sbiw XL, 1
        brne COUNT001
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
#endif
clrLCD:
	push r20
	push r19
	push r18
	REGISTER $8E, $80
	ldi r20, $8E
clrLCDLoop:
	rcall writeCommand
	rcall startPacket
	rcall readData
	rcall endPacket
	sbrc r19, 7 ;Poll register $8E until the display has finished clearing
	rjmp clrLCDLoop
	pop r18
	pop r19
	pop r20
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

	; Horizonatal settings
	REGISTER $14, $63
	REGISTER $15, $00
	REGISTER $16, $03
	REGISTER $17, $03
	REGISTER $18, $0B

	; Vertical settings
	REGISTER $19, $DF
	REGISTER $1A, $01
	REGISTER $1B, $1F ;$20
	REGISTER $1C, $00
	REGISTER $1D, $16
	REGISTER $1E, $00
	REGISTER $1F, $01

	; Active window settings
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

	
	ret


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


waitTransmit:
	sbis SPSR, SPIF
	rjmp waitTransmit ; Poll until SPI transaction complete
	ret

endPacket:
	ldi r16, 0b00010001 ; Sets SS* high 
	out PORTB, r16 ; End packet
	nop nop nop nop ; Wait a while, just in case
	nop nop nop nop
	ret

startPacket:
	ldi r16, 0b00010000 ;Sets SS* low
	out PORTB, r16 ; Start packet
	nop nop nop nop ; Wait a while, just in case
	nop nop nop nop
	ret

; Write char [r18] to screen
charOut:
	rcall initTextOut_ ; Load text-writing settings into registers
	ldi r20, $02
	rcall writeCommand ; Start data-write mode
	rcall startPacket
	mov r19, r18
	rcall writeData ; Write the character out
	rcall endPacket
	ret

; write out a string of characters from a byte table, length [r18], starting at [Z]
stringOut:
	rcall initTextOut_ ; Load text-writing settings into registers
	ldi r20, $02
	rcall writeCommand  ; Start data-write mode
	rcall startPacket
	ldi r16, 0
	out SPDR, r16 ; Send data-write packet
	rcall waitTransmit
stringLoop_:
	cpi r18, $00 ; Check vs string length
	breq stringEnd_
	lpm r19, Z+ ; Load character to write
	out SPDR, r19 ; Write character
	rcall waitTransmit
	dec r18
	rjmp stringLoop_
stringEnd_:
	rcall endPacket
	ret

; Write out a custom character (CGRAM)
cCharOut:
	rcall initCTextOut_ ; Set registers to write text from CGRAM
	ldi r20, $02
	rcall writeCommand ; Enter data-write mode
	rcall startPacket
	mov r19, r18
	rcall writeData ; Write character
	rcall endPacket
	ret

; write out a string of custom characters (CGRAM) from a byte table in SRAM, 
; length [r18], starting at [Z]
cStringOut:
	rcall initCTextOut_ ; Set registers to write text from CGRAM
	ldi r20, $02
	rcall writeCommand ; Enter data-write mode
	rcall startPacket
	ldi r19, 0
	out SPDR, r19 ; Send data-write packet
	rcall waitTransmit
cStringLoop_:
	cpi r18, $00 ; Check vs length of string
	breq cStringEnd_
	ld r19, Z+ ; Load character
	out SPDR, r19 ; Write character
	rcall waitTransmit
	dec r18
	rjmp cStringLoop_
cStringEnd_:
	rcall endPacket
	ret

; Set registers for writing text from CGROM
initTextOut_:
	ldi r20, $40 
	rcall writeCommand
	rcall startPacket
	rcall readData
	rcall endPacket
	rcall writeCommand
	ori r19, $80 ; set bit 7 in $40 (text mode)
	rcall startPacket
	rcall writeData
	rcall endPacket
	REGISTER $21, $00 ; Select CGROM
	REGISTER $60, 0 ; Black background
	REGISTER $61, 0
	REGISTER $62, 0
	REGISTER $63, 0 ; Green foreground
	REGISTER $64, 7 
	REGISTER $65, 0
	REGISTER $22, 0b00001011 ; Scale 3x horizontally, 4x vertically
	REGISTER $41, 0 ; Choose screen as write destination
	REGISTER $2E, 0 ; zero gap between characters
	ret

; Set registers for writing text from CGRAM
initCTextOut_:
	REGISTER $40, $80 ; Text mode
	REGISTER $41, $00 ; write to screen
	REGISTER $60, 0 ; black background
	REGISTER $61, 0
	REGISTER $62, 0
	REGISTER $63, 0 ; green foreground
	REGISTER $64, 7
	REGISTER $65, 0
	REGISTER $21, 0b10100000 ; Select CGRAM
	REGISTER $22, 0b00001011 ; Scale 3x horizontally, 4x vertically
	ret

; Create a custom character given by bytetable in program memory
; with starting address [Z] with char code [r19]
addChar:
	push r19
	REGISTER $40, 0 ; Have to exit text mode before writing to CGRAM
	REGISTER $21, 0 ; Cannot read from CGRAM when writing to it
	REGISTER $41, 0b000000100 ; Write to CGRAM
	ldi r20, $23
	pop r19
	rcall writeRegister ; Write out the chosen character code
	ldi r20, $02
	rcall writeCommand ; Enter data-write mode
	ldi r18, 16 ; A character is 16 bytes
	rcall startPacket
	ldi r16, 0
	out SPDR, r16 ; Send data-write packet
	rcall waitTransmit
	rcall stringLoop_ ; We can reuse the code which writes out a string
	ret

