lo:
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

ro:
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

extra:
.db "Thank you for playing Space      Invaders! The developers would   like you to note that any        'unexpected' behaviours you      encounter are in fact Easter eggs (http://bit.ly/1lzoRZv)"


.dseg
foe1:
.byte 20


foe2:
.byte 20


foe3:
.byte 20


foe4:
.byte 20


foePoint:
.byte 8

foeRem:
.byte 4

rockets: .byte 8
sixH: .byte 1
sixL: .byte 1
score: .byte 1
.cseg 
blnkRow:
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

rocket:
.db $00, $01

uDed:
.db "Congratulations! You died."

uWin:
.db "Congratulations! You won. Wasn't that a waste of time?"

uScore:
.db "Your score is: "

options:
.db "Play Game |Extra Info| Undefined "

.def loLength = r18
.def roLength = r19
.def foeLength = r20
.def playerPos = r21
.def blnkRowl = r22
.def compFlag = r23
.def shift = r24
.def writeFlag = r25