setupICC:
	; Set I2C frequency to about 330kHz
	ldi r16, 1
	out TWBR, r16

	; Enable ack, Enable TWI(I2C), Disable interupts
	ldi r16, 0b01000100 ;TWEA=1 TWEN=1 TWIE=0
	out TWCR, r16

	; We have to write these because ST says so, but they won't tell us what they do
	ICC_WRITE 0x0207,0x01
	ICC_WRITE 0x0208,0x01
	ICC_WRITE 0x0096,0x00
	ICC_WRITE 0x0097,0xfd
	ICC_WRITE 0x00e3,0x00
	ICC_WRITE 0x00e4,0x04
	ICC_WRITE 0x00e5,0x02
	ICC_WRITE 0x00e6,0x01
	ICC_WRITE 0x00e7,0x03
	ICC_WRITE 0x00f5,0x02
	ICC_WRITE 0x00d9,0x05
	ICC_WRITE 0x00db,0xce
	ICC_WRITE 0x00dc,0x03
	ICC_WRITE 0x00dd,0xf8
	ICC_WRITE 0x009f,0x00
	ICC_WRITE 0x00a3,0x3c
	ICC_WRITE 0x00b7,0x00
	ICC_WRITE 0x00bb,0x3c
	ICC_WRITE 0x00b2,0x09
	ICC_WRITE 0x00ca,0x09
	ICC_WRITE 0x0198,0x01
	ICC_WRITE 0x01b0,0x17
	ICC_WRITE 0x01ad,0x00
	ICC_WRITE 0x00ff,0x05
	ICC_WRITE 0x0100,0x05
	ICC_WRITE 0x0199,0x05
	ICC_WRITE 0x01a6,0x1b
	ICC_WRITE 0x01ac,0x3e
	ICC_WRITE 0x01a7,0x1f
	ICC_WRITE 0x0030,0x00

	; Set sampling averging period to 4.3ms to reduce noise
	ICC_WRITE $010A, $30
	; Perform temperature calibration every 255 measurements
	ICC_WRITE $0031, $FF
	; Set to measure range every 100ms when in continuous mode
	ICC_WRITE $001B, $09
	; To set up interups, write to $0014. $00=off $01=Level low
	; $02=Level high $03=Out of window $04=New sample ready
	; Enable the results buffer and set it to store range
	ICC_WRITE $0012, $03
	; One off temperature calibration to get us started
	ICC_WRITE $002E, $01
	nop nop nop nop
	nop nop nop nop
	; Start continuous ranging measurements
	ICC_WRITE $0018, $03

	ret


writeICC:
	; Start
	in r16, TWCR
	sbr r16, (1<<7) ; Clear interupt flag
	sbr r16, (1<<5) ; Set start bit
	out TWCR, r16
	rcall waitICC

	; Check status register to check start sent
	ICC_CHECKSTATUS $08

	;write address+mode
	ldi r16, SLAW
	out TWDR, r16 ;load address into DR
		; Clear the start and start transmission
	in r16, TWCR
	sbr r16, (1<<7)
	cbr r16, (1<<5) ; Clear start bit
	out TWCR, r16
	rcall waitICC

	;Check status register. Should see send SLA+R/W, ack set
	ICC_CHECKSTATUS $18

	;write register
		; load register high into DR
	ICC_WRITEBYTER r21
		; check status register
	ICC_CHECKSTATUS $28
		; load register low into DR
	ICC_WRITEBYTER r20
		; check status register
	ICC_CHECKSTATUS $28
		; load data into DR
	ICC_WRITEBYTER r19
		; check status register
	ICC_CHECKSTATUS $28

	; send stop
	in r16, TWCR
	sbr r16, (1<<7)
	sbr r16, (1<<4) ; Set stop bit
	out TWCR, r16
	ret


readICC:
	; Start
	in r16, TWCR
	sbr r16, (1<<7)
	sbr r16, (1<<5)
	out TWCR, r16
	rcall waitICC

	; Check status register to check start sent
	ICC_CHECKSTATUS_R $08

	;write address+mode
	ldi r16, SLAW
	out TWDR, r16 ;load address into DR
		; Clear the start and start transmission
	in r16, TWCR
	sbr r16, (1<<7)
	cbr r16, (1<<5)
	out TWCR, r16
	rcall waitICC

	;Check status register. Should see send SLA+R/W, ack set
	ICC_CHECKSTATUS_R $18

	;write register
		; load register high into DR
	ICC_WRITEBYTER r21
		; check status register
	ICC_CHECKSTATUS_R $28
		; load register low into DR
	ICC_WRITEBYTER r20
		; check status register
	ICC_CHECKSTATUS_R $28

		; send repeated start
	in r16, TWCR
	sbr r16, (1<<7)
	sbr r16, (1<<5)
	out TWCR, r16
	rcall waitICC
	ICC_CHECKSTATUS_R $10
		; send SLAR
	ldi r16, SLAR
	out TWDR, r16 
	in r16, TWCR
	sbr r16, (1<<7)
	cbr r16, (1<<5)
	out TWCR, r16
	rcall waitICC
	ICC_CHECKSTATUS_R $40
		;Read out the data
	ICC_READBYTE
		; check status register
	ICC_CHECKSTATUS_R $50

	; send stop
	in r16, TWCR
	sbr r16, (1<<7)
	sbr r16, (1<<4)
	out TWCR, r16
	ret

waitICC:
	; Poll TWCR until bit 7 (interupt flag) is set
    in r16, TWCR
    sbrs r16, 7
    rjmp waitICC
    ret
