.export INIT_PPU
.export RESET_OBJECTS
.export INIT_VARIABLES
.export INIT_AUDIO

.include "../data/display.asm"

;==============================================================================
; Initialize PPU
;==============================================================================

.proc INIT_PPU

    JSR CLEAR_BG_TABLES
    JSR DRAW_DISPLAY
    JSR LOAD_COLORS

    RTS

.endproc

;==============================================================================
; Clear Background Tables
;==============================================================================

.proc CLEAR_BG_TABLES

    LDA #>BG_RAM1
    STA NES_VRAM_AR
    LDA #<BG_RAM1
    STA NES_VRAM_AR

    ; 8 pages x 256 bytes = 2048 bytes = one full background table.
    LDX #>$0800
    LDY #>$0800
    LDA #$00
@loop:
    STA NES_VRAM
    INY
    BNE @loop
    DEX
    BNE @loop
    
    RTS

.endproc

;==============================================================================
; Load Colors 
;==============================================================================

.proc LOAD_COLORS

    ; Set to Color Table
    LDA #>COLOR_TABLE
    STA NES_VRAM_AR
    LDA #<COLOR_TABLE
    STA NES_VRAM_AR
    
    LDX #0
@loop:
    LDA COLOR_DATA, X
    STA NES_VRAM
    INX
    CPX #32
    BNE @loop
    
    RTS

.endproc

;==============================================================================
; COLOR PALETTE
;==============================================================================

COLOR_DATA:

    ; Background palette
    .byte $0F, $00, $11, $09  ; Palette 0
    .byte $0F, $1B, $11, $00  ; Palette 1
    .byte $0F, $25, $30, $21  ; Palette 2
    .byte $0F, $21, $3C, $16  ; Palette 3
    
    ; Object palette
    .byte $0F, $30, $0F, $27  ; Palette 0
    .byte $0F, $30, $0F, $05  ; Palette 1
    .byte $0F, $30, $0F, $30  ; Palette 2
    .byte $0F, $30, $0F, $30  ; Palette 3

;==============================================================================
; Reset Objects
;==============================================================================

.proc RESET_OBJECTS

    ; Clear OBJ buffer
    LDX #$00
    LDA #$F0
@loop:
    STA OBJ, X
    INX
    INX
    INX
    INX
    BNE @loop

    RTS

.endproc

;==============================================================================
; Initialize Main Variables
;==============================================================================

.proc INIT_VARIABLES

    LDA #FRAME_WAIT
    STA frame_state

    RTS

.endproc

;==============================================================================
; Initialize Audio
;==============================================================================

.proc INIT_AUDIO

    ; Enable all APU channels
    LDA #ST_D | ST_C | ST_B | ST_A
    STA NES_ST
    
    ; Reset audio software clock
    LDA #SOFTCLK_INT
    STA NES_SOFTCLK

    RTS

.endproc

;==============================================================================
; Initialize Display
;==============================================================================

.macro DRAW_LINE addr, src, len
    .local next
    LDA #>(addr)
    STA NES_VRAM_AR
    LDA #<(addr)
    STA NES_VRAM_AR

    LDX #0
next:
    LDA src,X
    STA NES_VRAM
    INX
    CPX #(len)
    BNE next
.endmacro

.proc DRAW_DISPLAY
    LDX #$00
    STX current_tune

    ; Draw tune header
    LDA #>$2041
    STA NES_VRAM_AR
    LDA #<$2041
    STA NES_VRAM_AR
    
    LDA TUNE_NAME_LO,X
    STA tmp0
    LDA TUNE_NAME_HI,X
    STA tmp0+1
    LDY #0
@loop_name:
    LDA (tmp0),Y
    CMP #$FF
    BEQ @over
    STA NES_VRAM
    INY
    JMP @loop_name
@over:

    ; Draw Lines
    DRAW_LINE $2021, VERSION,   30
    DRAW_LINE $2081, SIZE,      30
    DRAW_LINE $20C1, SELECTION, 30
    DRAW_LINE $2109, CHANNEL,   22
    DRAW_LINE $2121, NOTE,      28
    DRAW_LINE $2141, LENGTH,    28
    DRAW_LINE $2161, COUNT,     28
    DRAW_LINE $2181, TRANS,     22
    DRAW_LINE $21A1, FOR,       28
    DRAW_LINE $21C1, NEXT,      28
    DRAW_LINE $21E1, FREQ,      24
    DRAW_LINE $2201, DIST,      22
    DRAW_LINE $2241, WOB_SET,   28
    DRAW_LINE $2261, WOB_VAR,   28
    DRAW_LINE $22A1, VIB_DEL,   22
    DRAW_LINE $22C1, VIB_RAT,   22
    DRAW_LINE $22E1, VIB_LIM,   22
    DRAW_LINE $2301, VIB_DIR,   22
    DRAW_LINE $2341, VOLUME,    28

    RTS
.endproc