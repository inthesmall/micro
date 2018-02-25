.MACRO SENDPULSE
    ldi r16, 1
    out PORTA, r16
    rcall 200cycles
    ldi r16, 0
    out PORTA, r16
    rcall 200cycles
.ENDMACRO
pulse:
    ; should get called in the timer 0 interupt
    push r16
    ;start timer
    in r16, TCCR1B
    sbr r16, (1<<0) ; set the clock prescaler to 1
    out TCCR1B, r16
    SENDPULSE
    SENDPULSE
    SENDPULSE
    SENDPULSE
    SENDPULSE
    ;start analogue comparator
    ldi r16, 0b00000111
    out ACSR, r16
    pop r16
    ret


inputs:
    in r20, ICR1L ; Read captured value
    in r21, ICR1H
    ldi r16, 0b10000111
    out ACSR, r16 ; Stop analogue comparator
    in r16, TCCR1B
    cbr r16, (1<<0) ; stop the clock
    out TCCR1B, r16
    ldi r16, 0
    out TCNT1H, r16
    out TCNT1L, r16 ; clear timer value
    ldi r16, $FF ; set status
    reti

timeout:
    ; called by output compare after 0.0005s
    ldi r20, $00
    ldi r21, $10
    ldi r16, 0b10000111
    out ACSR, r16 ; Stop analogue comparator
    in r16, TCCR1B
    cbr r16, (1<<0) ; stop the clock
    out TCCR1B, r16
    ldi r16, 0
    out TCNT1H, r16
    out TCNT1L, r16 ; clear timer value
    ldi r16, $FF ; set status
    reti


200cycles:
    push r16
    ldi r16, 100
200cyclesjump:
    dec r16
    brne 200cyclesjump
    pop r16
    ret