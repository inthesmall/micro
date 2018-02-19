buttonRead:
		push r16
		ldi r23, $F0
		ldi r18, $00
		rcall initE
		in r16, PINE
		add r18, r16
		rcall initE
		in r16, PINE
		add r18, r16
		pop r16
		ret

initE:
		out PORTE, r23
		com R23
		out DDRE, r23
		ret
