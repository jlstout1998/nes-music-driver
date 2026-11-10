;------------------------------------------------------------------------------
; Music and FX data
;------------------------------------------------------------------------------

DATA_size = DATA_end - DATA_start

;------------------------------------------------------------------------------
; TUNE TABLES
;------------------------------------------------------------------------------

Start_A_LO: ; Tune Pointers for Channel A Here
Start_A_HI:

Start_B_LO: ; Tune Pointers for Channel B Here
Start_B_HI:

Start_C_LO: ; Tune Pointers for Channel C Here
Start_C_HI:

Start_D_LO: ; Tune Pointers for Channel D Here
Start_D_HI:

;------------------------------------------------------------------------------
; EFFECT TABLES
;------------------------------------------------------------------------------

Start_FX_LO: ; SFX Pointers Here
Start_FX_HI:

;------------------------------------------------------------------------------
; COMMANDS
;------------------------------------------------------------------------------
command = $80

for     = command
next    = for+1
length  = next+1
stop    = length+1
gosub   = stop+1
return  = gosub+1
trans   = return+1
distort = trans+1
goto    = distort+1
send    = goto+1
adsr    = send+1
envon   = adsr+1
wobble  = envon+1
port    = wobble+1
duty    = port+1
vib     = duty+1
ignore  = vib+1
effect  = ignore+1
table   = effect+1
cutoff  = table+1
endit   = cutoff+1
sweep   = endit+1

minus   = trans
plus    = distort

finish  = $FF
restart = $42

rest    = $60

DATA_start:

;------------------------------------------------------------------------------
; TUNE DATA
;------------------------------------------------------------------------------

; Tune Data Here

; EXAMPLE TUNE
SURFER_A: ; PLAY ON CHANNEL A
    .BYTE send, <$4015,%00001111, <$4001,%00000000, <$4005,%00000000, <$4008,%11111111, finish
    .BYTE duty,%10110000, envon,1
    .BYTE adsr,$30,$00,2
    .BYTE vib,$01,$08,$00,$00
    .BYTE $0A,$70
SURFER_A_LOOP:
    .BYTE adsr,$60,$00,1
    .BYTE endit,$00, cutoff,$00
    .BYTE table,1,<SURFER_E2,>SURFER_E2
    .BYTE vib,$01,$01,$00,$01
    .BYTE envon,$FF
    .BYTE $46,$E0
    .BYTE vib,$01,$04,$00,$00
    .BYTE $0A,$E0

    .BYTE table,1,<SURFER_E3,>SURFER_E3
    .BYTE vib,$00
    .BYTE wobble,$0C,$01,$FF
    .BYTE duty,%00110000
    .BYTE for,4
        .BYTE $0D,$1C, $0D,$1C, $0B,$07, $0D,$0E, $0B,$07, $10,$0E, $10,$07, $12,$07
        .BYTE $0D,$1C, $0D,$1C, $0B,$0E, $0B,$07, $0D,$07, $10,$0E, $10,$07, $0F,$07
    .BYTE next

    .BYTE wobble,$00,$00,$00
    .BYTE vib,$0E,$03,$03,$00
    .BYTE duty,%11110000
    .BYTE table,1,<SURFER_E5,>SURFER_E5
    .BYTE port,$01
    .BYTE $27,$A8, $28,$38, $2A,$2A, $29,$07, $28,$07, $27,$38

    .BYTE envon,1, port,$00, duty,%10110000
    .BYTE trans,$03, gosub,<SURFER_P4,>SURFER_P4
    .BYTE trans,$05, gosub,<SURFER_P4,>SURFER_P4
    .BYTE duty,%11110000, trans,$00, envon,$FF
    .BYTE vib,$0E,$02,$03,$00
    .BYTE port,$02
    .BYTE $2C,$A8, $23,$38, $25,$2A, $27,$07, $28,$07, $27,$38

    .BYTE envon,1, port,$00, duty,%10110000
    .BYTE gosub,<SURFER_P4,>SURFER_P4
    .BYTE trans,$07, gosub,<SURFER_P4,>SURFER_P4
    .BYTE duty,%11110000
    .BYTE trans,$0C, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$0A, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$07, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$05, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$03, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$02, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$00, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$FE, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$FB, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$F9, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$FB, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$00, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$02, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$03, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$05, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$03, gosub,<SURFER_P5,>SURFER_P5
    .BYTE trans,$02, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$03, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$00, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$FE, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$00, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$02, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$03, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$05, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$07, gosub,<SURFER_P6,>SURFER_P6
    .BYTE trans,$0A, gosub,<SURFER_P6,>SURFER_P6

    .BYTE vib,$0E,$04,$00,$01
    .BYTE table,$01,<SURFER_E6,>SURFER_E6
    .BYTE envon,$FF, trans,$00
    .BYTE gosub,<SURFER_P1,>SURFER_P1
    .BYTE gosub,<SURFER_P2,>SURFER_P2
    .BYTE wobble,$13,$01,$FF
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next
    .BYTE for,8
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next
    
    .BYTE length,$00, duty,%10110000
    .BYTE wobble,$00,$00,$00
    .BYTE goto,<SURFER_A_LOOP,>SURFER_A_LOOP

SURFER_B: ; PLAY ON CHANNEL B
    .BYTE envon,1, duty,%00110000
    .BYTE adsr,$50,$00,2
    .BYTE vib,$01,$0A,$00,$01
    .BYTE for,4
        .BYTE $50,$07
    .BYTE next
    .BYTE vib,$01,$05,$00,$01
    .BYTE $50,$1C, $50,$07, $50,$07, $50,$0E, $50,$1C
SURFER_B_LOOP:
    .BYTE endit,$00, cutoff,$00
    .BYTE table,1,<SURFER_E2,>SURFER_E2
    .BYTE vib,$01,$01,$00,$01
    .BYTE envon,$FF
    .BYTE $50,$E0
    .BYTE vib,$01,$01,$00,$00
    .BYTE $21,$E0
    
    .BYTE table,1,<SURFER_E3,>SURFER_E3
    .BYTE vib,$00
    .BYTE distort,$04, duty,%00110000
    .BYTE for,2
        .BYTE $0D,$1C, $0D,$1C, $0B,$07, $0D,$0E, $0B,$07, $10,$0E, $10,$07, $12,$07
        .BYTE $0D,$1C, $0D,$1C, $0B,$0E, $0B,$07, $0D,$07, $10,$0E, $10,$07, $0F,$07
        .BYTE duty,%10110000
    .BYTE next

    .BYTE distort,$00, duty,%00110000, length,$02
    .BYTE table,$15,<SURFER_E4,>SURFER_E4
    .BYTE for,5
        .BYTE gosub,<SURFER_P7,>SURFER_P7
        .BYTE gosub,<SURFER_P8,>SURFER_P8
        .BYTE gosub,<SURFER_P9,>SURFER_P9
        .BYTE trans,$FE, gosub,<SURFER_P9,>SURFER_P9
        .BYTE trans,$00
    .BYTE next

    .BYTE vib,$0E,$06,$00,$01
    .BYTE length,$00
    .BYTE table,1,<SURFER_E7,>SURFER_E7
    .BYTE envon,$FF, trans,$00
    .BYTE rest,$15, gosub,<SURFER_P1,>SURFER_P1
    .BYTE distort,$02, gosub,<SURFER_P2,>SURFER_P2
    .BYTE wobble,$13,$01,$FF, gosub,<SURFER_P3,>SURFER_P3
    .BYTE $0D, $0B, $0D, $10, $12, $14, $17, $19, $1C, $17, $16, $19, $14

    .BYTE adsr,$20,$00,2
    .BYTE envon,1, distort,$00
    .BYTE wobble,$00,$00,$00
    .BYTE trans,$13
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next

    .BYTE wobble,$0C,$01,$01
    .BYTE envon,$FF, trans,$18
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next
    .BYTE trans,$13
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next

    .BYTE wobble,$00,$00,$00
    .BYTE envon,1
    .BYTE vib,$03,$1E,$00,$01
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next

    .BYTE length,$00, trans,$00, duty,%11110000
    .BYTE vib,$00
    .BYTE goto,<SURFER_B_LOOP,>SURFER_B_LOOP

SURFER_C: ; PLAY ON CHANNEL C
    .BYTE rest,$70
SURFER_C_LOOP:
    .BYTE for,2
        .BYTE gosub,<SURFER_P10,>SURFER_P10, rest,$09, $1B,$01, rest,$0D
        .BYTE gosub,<SURFER_P11,>SURFER_P11, rest,$10, $1B,$01, rest,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, rest,$02, $1B,$01, rest,$0D, $1B,$01, rest,$06
        .BYTE gosub,<SURFER_P11,>SURFER_P11, rest,$09, $1B,$01, rest,$06, $20,$01, rest,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, rest,$02, $21,$01, rest,$06, $1B,$01, rest,$0D
        .BYTE gosub,<SURFER_P11,>SURFER_P11, rest,$10, $20,$01, rest,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, rest,$09, $1B,$01, rest,$0D
        .BYTE gosub,<SURFER_P11,>SURFER_P11, rest,$09, $20,$01, rest,$06, $20,$01, rest,$06
    .BYTE next
    .BYTE for,18
        .BYTE gosub,<SURFER_P10,>SURFER_P10, $0D,$09, $1B,$01, rest,$0D
        .BYTE gosub,<SURFER_P11,>SURFER_P11, $0D,$09, rest,$07, $1B,$01, rest,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, $0B,$02, $1B,$01, $0D,$0D, $1B,$01, $0B,$06
        .BYTE gosub,<SURFER_P11,>SURFER_P11, $10,$09, $1B,$01, $10,$06, $20,$01, $12,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, $0D,$02, $21,$01, $0D,$06, $1B,$01, rest,$0D
        .BYTE gosub,<SURFER_P11,>SURFER_P11, $0D,$09, rest,$07, $20,$01, rest,$06
        .BYTE gosub,<SURFER_P10,>SURFER_P10, $0B,$09, $1B,$01, $0B,$06, $0D,$07
        .BYTE gosub,<SURFER_P11,>SURFER_P11, $10,$09, $20,$01, $10,$06, $20,$01, $0F,$06
    .BYTE next
    .BYTE for,8
        .BYTE gosub,<SURFER_P10,>SURFER_P10, $0D,$09, rest,$0E
        .BYTE gosub,<SURFER_P11,>SURFER_P11, $0D,$09, rest,$0E
    .BYTE next
    .BYTE for,8
        .BYTE gosub,<SURFER_P10, >SURFER_P10, $0D,$09, rest,$0E
        .BYTE gosub,<SURFER_P11, >SURFER_P11, $0D,$09, rest,$07, $20,$01, rest,$06
    .BYTE next
    .BYTE goto,<SURFER_C_LOOP,>SURFER_C_LOOP

SURFER_D: ; PLAY ON CHANNEL D
    .BYTE plus
    .BYTE adsr,$40,$00,2
    .BYTE envon,1
    .BYTE table,1,<SURFER_E1,>SURFER_E1
    .BYTE envon,1, cutoff,$00, endit,$00, length,$07
    .BYTE $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $0F

    .BYTE length,$00
SURFER_D_LOOP:
    .BYTE for,20
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$00,$00,2,  $02,$06
        .BYTE adsr,$50,$00,1,  $03,$01, $02,$06
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$0D
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$0C
        .BYTE envon,1
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$0D
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$00,$00,2,  $02,$06
        .BYTE adsr,$50,$00,1,  $03,$01, $02,$06
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$0D
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$0C
        .BYTE envon,1
        .BYTE adsr,$40,$03,$01,  $03,$01, $02,$06
        .BYTE envon,$FF
        .BYTE $06,$07
        .BYTE envon,1
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$00,$00,2,  $02,$06
        .BYTE envon,$FF
        .BYTE $06,$07
        .BYTE envon,1
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$0D
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$0C
        .BYTE envon,1
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$06
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$06
        .BYTE envon,1
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$00,$00,2,  $02,$06
        .BYTE adsr,$50,$00,1,  $03,$01, $02,$06
        .BYTE envon,$FF
        .BYTE $06,$0E, $05,$01, $06,$0D, $06,$07, $06,$07
        .BYTE envon,1
    .BYTE next
    .BYTE for,8
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$00,$00,2,  $06,$1B
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$1B
        .BYTE envon,1
    .BYTE next
    .BYTE for,8
        .BYTE adsr,$50,$00,2,  $06,$01
        .BYTE adsr,$30,$00,1,  $06,$0D
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$0D
        .BYTE envon,$FF
        .BYTE $05,$01, $06,$0D
        .BYTE envon,1
        .BYTE adsr,$40,$03,1,  $03,$01, $02,$06
        .BYTE envon,$FF
        .BYTE $06,$07
        .BYTE envon,1
    .BYTE next
    .BYTE goto,<SURFER_D_LOOP,>SURFER_D_LOOP

; PULSE PATTERNS

SURFER_P1:
    .BYTE duty,%00110000, envon,$FF
    .BYTE for,2
        .BYTE port,$00,  $31,$0E
        .BYTE port,$01,  $25,$1C
        .BYTE port,$00,  $2F,$0E
        .BYTE port,$01,  $23,$1C
        .BYTE port,$00, port,$00,  $31,$0E
        .BYTE port,$01,  $24,$1C
        .BYTE port,$00,  $33,$0E
        .BYTE port,$01,  $27,$1C
        .BYTE port,$00, port,$00,  $34,$0E
        .BYTE port,$01,  $28,$0E
        .BYTE port,$00,  $33,$0E
        .BYTE port,$01,  $27,$0E
        .BYTE port,$00
    .BYTE next
    .BYTE for,2
        .BYTE duty,%10110000
        .BYTE port,$00,  $31,$0E
        .BYTE port,$01,  $25,$1C
        .BYTE port,$00,  $2F,$0E
        .BYTE port,$01,  $23,$1C
        .BYTE port,$00, duty,%11110000
        .BYTE port,$00,  $31,$0E
        .BYTE port,$01,  $25,$1C
        .BYTE port,$00,  $33,$0E
        .BYTE port,$01,  $27,$1C
        .BYTE port,$00, duty,%00110000
        .BYTe port,$00,  $34,$0E
        .BYTE port,$01,  $28,$0E
        .BYTE port,$00, duty,%11110000,  $33,$0E
        .BYTE port,$01,  $27,$0E
        .BYTE port,$00
    .BYTE next
    .BYTE return

SURFER_P2:
    .BYTE length,$07, duty,%10110000, cutoff,$05
    .BYTE vib,$00
    .BYTE for,2
        .BYTE gosub,<SURFER_P3,>SURFER_P3
    .BYTE next
    .BYTE return

SURFER_P3:
    .BYTE $0D, $0B, $0D, $10, $12, $14, $17, $19, $1C, $17, $16, $19, $14, $10, $0F, $12
    .BYTE return

SURFER_P4:
    .BYTE adsr,$30,$00,2,  $25,$0E
    .BYTE port,$01,  $19,$0E
    .BYTE port,$00, adsr,$20,$00,2,  $25,$0E
    .BYTE port,$01,  $19,$0E
    .BYTE port,$00
    .BYTE return

SURFER_P5:
    .BYTE adsr,$30,$00,2,  $25,$0E
    .BYTE port,$01,  $19,$07
    .BYTE port,$00, adsr,$20,$00,2,  $25,$0E
    .BYTE port,$01,  $19,$07
    .BYTE port,$00
    .BYTE return

SURFER_P6:
    .BYTE adsr,$30,$00,2,  $25,$0E
    .BYTE port,$01,  $19,$07
    .BYTE port,$00, adsr,$20,$00,2,  $25,$07
    .BYTE return

SURFER_P7:
    .BYTE $20
    .BYTE envon,0
    .BYTE      $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE $20, $1C, $17, $14, $20, $1C, $17, $14
    .BYTE envon,$FF
    .BYTE return

SURFER_P8:
    .BYTE $20
    .BYTE envon,0
    .BYTE      $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE $20, $1C, $19, $15, $20, $1C, $19, $15
    .BYTE envon,$FF
    .BYTE return

SURFER_P9:
    .BYTE $1E
    .BYTE envon,0
    .BYTE      $1B, $17, $12, $1E, $1B, $17, $12
    .BYTe $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE $1E, $1B, $17, $12, $1E, $1B, $17, $12
    .BYTE envon,$FF
    .BYTE return

; VOLUME ENVELOPES

SURFER_E1:
    .BYTE $03, $04, $03, $03, $02, $02, $01, $01, $01, $00, finish

SURFER_E2:
    .BYTE $03, $03, $03, $03, $00, $00, $00, $03, $03, $03, $00, $00, $00, $00, $03, $03
    .BYTE $03, $00, $00, $00, $00, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .BYTE $00, $00, $00, $03, $03, $03, $00, $00, $00, $00, $03, $03, $03, $00, $00, $00
    .BYTE $00, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $00, $00, $00, $03
    .BYTE $03, $03, $00, $00, $00, $00, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .BYTE $03, $00, $00, $00, $03, $03, $03, $03, $00, $00, $00, $03, $03, $00, $00, $00
    .BYTE $00, $00, restart

SURFER_E3:
    .BYTE $06, $05, $04, $03, $02, $01, $02, $03, $04, $05, $06, $00, $00, $00, $06, $00
    .BYTE $00, $00, $00, $00, $00, $06, $00, $00, $00, $00, $00, $00, finish

SURFER_E4:
    .BYTE $01, $02, $03, $04, $05, $06, finish

SURFER_E5:
    .BYTE $01, $03, finish

SURFER_E6:
    .BYTE $03, finish, $02, $01, $00, finish

SURFER_E7:
    .BYTE $02, finish, $02, $01, $00, finish

; TRIANGLE PATTERNS

SURFER_P10:
    .BYTE ignore, $16,$01
    .BYTE ignore, $10,$01
    .BYTE ignore, $0C,$01
    .BYTE ignore, $09,$01
    .BYTE ignore, $08,$01
    .BYTE return

SURFER_P11:
    .BYTE ignore, $20,$01
    .BYTE ignore, $10,$01
    .BYTE ignore, $0C,$01
    .BYTE ignore, $09,$01
    .BYTE ignore, $08,$01
    .BYTE return

;------------------------------------------------------------------------------
; SOUND EFFECTS DATA
;------------------------------------------------------------------------------

; FX Data Here

; EXAMPLE FX
fire:
    .BYTE 5*2, <Xfiret, >Xfiret                 ; PLAY ON CHANNEL F
    .BYTE 4*2, <Xfiren, >Xfiren                 ; PLAY ON CHANNEL E
    .BYTE finish

Xfiret:
    .BYTE adsr,$C0,$00,2, envon,1, duty,%10110000
    .BYTE wobble,0,0,0
    .BYTE 25,1, port,4, 9,5, port,0
    .BYTE stop
Xfiren:
    .BYTE plus, adsr,$F0,$00,1, envon,1, 12,2
    .BYTE envon,$FF, 13,2, 14,3, 15,10
    .BYTE stop

DATA_end:
