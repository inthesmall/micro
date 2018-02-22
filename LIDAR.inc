#ifndef LIDARinc
#define LIDARinc
; Write [1] to register [0w] (A w indicates 16bit word)
.MACRO ICC_WRITE
    push r16
    push r18
    push r19
    push r20
    push r21
    ldi r20, low(@0)
    ldi r21, high(@0)
    ldi r19, @1
    call writeICC
    pop r21
    pop r20
    pop r19
    pop r18
    pop r16
.ENDMACRO
; Read [0w] into r18
.MACRO ICC_READ
    push r16
    push r20
    push r21
    ldi r20, low(@0)
    ldi r21, high(@0)
    call readICC
    pop r21
    pop r20
    pop r16
.ENDMACRO
; Private. Write byte from register [0] to ICC
.MACRO ICC_WRITEBYTER
	mov r18, @0
	out TWDR, r18
	in r16, TWCR
	sbr r16, (1<<7)
	out TWCR, r16
	rcall waitICC
.ENDMACRO
; Private. Ensure status code is [0]. If not, rjmp writeICC
.MACRO ICC_CHECKSTATUS
	in r16, TWSR
	andi r16, $F8 ; only care about most significant 5 bits
	cpi r16, @0 ; Check correct code, ACK received (if appropriate)?
	jne writeICC
.ENDMACRO
; Private. Ensure status code is [0]. If not, rjmp readICC
.MACRO ICC_CHECKSTATUS_R
	in r16, TWSR
	andi r16, $F8 ; only care about most significant 5 bits
	cpi r16, @0 ; Check correct code, ACK received (if appropriate)?
	jne readICC
.ENDMACRO
; Private. Read byte into r18 from ICC
.MACRO ICC_READBYTE
	in r16, TWCR
	sbr r16, (1<<7)
	out TWCR, r16
	rcall waitICC
	in r18, TWDR
.ENDMACRO
; Read the latest range from the buffer into r18
.MACRO ICC_READRANGE
	ICC_READ $0052
.ENDMACRO

; I2C slave write address 
.equ SLAW = $52
; I2C slave read address
.equ SLAR = $53
#endif