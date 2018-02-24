;##### Code for recording keypad inputs #####
buttonRead:
		push r16
		ldi r23, $F0
		ldi r18, $00
		rcall initE		; Initialise PORTE to read column number.
		in r16, PINE
		add r18, r16	; Store column number to r18
		rcall initE		; Initialise PORTE to read row number.
		in r16, PINE	
		add r18, r16	; Store row number to r18.
		pop r16
		ret

;##### Initialise PORTE to capture required half of button address #####
initE:
		out PORTE, r23
		com R23
		out DDRE, r23	; Enables pull up resistors on the correct half of the pins.
		ret
