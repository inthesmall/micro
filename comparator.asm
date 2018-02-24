.MACRO SENDPULSE
    ldi r16, 1
    out PORTA, r16
    rcall 200cycles
    ldi r16, 0
    out PORTA, r16
    rcall 200cycles
.ENDMACRO
pulse:
    ;start timer
    push r16
    SENDPULSE
    SENDPULSE
    SENDPULSE
    SENDPULSE
    SENDPULSE
    ;start analogue comparator
    pop r16
    ret


inputs:
    ; will stop timer
    ;can read stored value
    reti

200cycles:
    push r16
    ldi r16, 100
200cyclesjump:
    dec r16
    brne 200cyclesjump
    pop r16
    ret