.INCLUDE "setup.asm"
ldi r16, 1
out TWBR, r16
ldi r16, 0b01000100 ;TWEA=1 TWIE=0 TWEN=1
out TWCR, r16




in r16, TWCR
sbr r16, (1<<5)
out TWCR, r16
rcall waitICC
;check status reguster to check start sent
in r16, TWCR
cbr r16 (1<<5)
out TWCR, r16
;write address+mode
    ;load address (high then low) into DR
    ;Set bit 7 to one to initaite
rcall waitICC
;Check status register. Should see send SLA+R/W, ack set 
;write data
    ;load data into DR
    ;set bit 7 to one to initatiate
;check status reg to see data sent and ack set
in r16, TWCR
sbr r16, (1<<4)
out TWCR, r16 ;send stop
rcall waitICC


waitICC:
    in r16 TWCR
    sbrs r16, 7
    rjmp waitICC
    ret


    ICCWRITE 0x0207,0x01
    ICCWRITE 0x0208,0x01
    ICCWRITE 0x0096,0x00
    ICCWRITE 0x0097,0xfd
    ICCWRITE 0x00e3,0x00
    ICCWRITE 0x00e4,0x04
    ICCWRITE 0x00e5,0x02
    ICCWRITE 0x00e6,0x01
    ICCWRITE 0x00e7,0x03
    ICCWRITE 0x00f5,0x02
    ICCWRITE 0x00d9,0x05
    ICCWRITE 0x00db,0xce
    ICCWRITE 0x00dc,0x03
    ICCWRITE 0x00dd,0xf8
    ICCWRITE 0x009f,0x00
    ICCWRITE 0x00a3,0x3c
    ICCWRITE 0x00b7,0x00
    ICCWRITE 0x00bb,0x3c
    ICCWRITE 0x00b2,0x09
    ICCWRITE 0x00ca,0x09
    ICCWRITE 0x0198,0x01
    ICCWRITE 0x01b0,0x17
    ICCWRITE 0x01ad,0x00
    ICCWRITE 0x00ff,0x05
    ICCWRITE 0x0100,0x05
    ICCWRITE 0x0199,0x05
    ICCWRITE 0x01a6,0x1b
    ICCWRITE 0x01ac,0x3e
    ICCWRITE 0x01a7,0x1f
    ICCWRITE 0x0030,0x00

.MACRO ICCWRITE
    push r16
    push r18
    push r19
    push r20
    push r21
    ldi r20, low(@0)
    ldi r21, high(@0)
    ldi r19, @1
    call writeicc
    pop r21
    pop r20
    pop r19
    pop r18
    pop r16
.ENDMACRO