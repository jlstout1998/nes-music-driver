;==============================================================================
; NES DEMO
;==============================================================================

.include "data/constants.asm"
.include "data/ram.asm"

.include "data/header.asm"

;==============================================================================
; VECTORS
;==============================================================================

.segment "VECTORS"

    .word NMI
    .word RESET
    .word IRQ

;==============================================================================
; MAIN CODE
;==============================================================================

.segment "STARTUP"

;==============================================================================
; RESET
;==============================================================================
;
; Cold-boot entry point. Disables interrupts and rendering, clears RAM, waits
; for the PPU to stabilize, initializes all subsystems, then falls into the
; main loop.
;==============================================================================

.proc RESET

    CLD
    SEI

    ; Reset the Stack Pointer
    LDX #$FF
    TXS

    ; Clear RAM ($0000-$07FF)
    LDA #$00
    STA $00
    STA $01
    TAY
    LDX #$08
@clear_ram:
    STA ($00),Y
    INY
    BNE @clear_ram
    INC $01
    DEX
    BNE @clear_ram
    STA $01

    ; Disable Rendering
    LDA #%00000000
    STA NES_CTRL0
    STA NES_CTRL1

    ; Wait for the PPU to complete its power-on reset sequence
    LDX #2
@wait_frame1:
    LDA NES_SR
    BPL @wait_frame1
@wait_frame2:
    LDA NES_SR
    BMI @wait_frame2
    DEX
    BNE @wait_frame1

    ; Initialize
    JSR INIT_PPU
    JSR RESET_OBJECTS
    JSR INIT_AUDIO
    JSR INIT_VARIABLES

    ; Enable Rendering
    LDA #CTRL1_BGBLK | CTRL1_OBJBLK | CTRL1_BGLBLK | CTRL1_OBJLBLK
    STA NES_CTRL1_shadow
    STA NES_CTRL1

    ; Enable VBLANK NMI
    LDA #CTRL0_INT | CTRL0_OBJSEG | CTRL0_BG_2000
    STA NES_CTRL0_shadow
    STA NES_CTRL0

    CLI

;------------------------------------------------------------------------------
; Main Loop
;------------------------------------------------------------------------------

MAIN_LOOP:

@wait_frame:
    LDA frame_state
    BEQ @wait_frame

    LDA #FRAME_WAIT
    STA frame_state

    JSR UPDATE_CONTROLLERS

    JSR UPDATE_ACTIONS

    JSR UPDATE_STEP_AMOUNT
    BEQ @no_ticks

    JSR UPDATE_MUSIC

@no_ticks:
    JSR UPDATE_DISPLAY

    JMP MAIN_LOOP

.endproc

;==============================================================================
; NMI
;==============================================================================
;
; VBlank handler. Order matters:
;
;   1. Disable rendering so VRAM writes are safe.
;   2. Push OAM via DMA.
;   3. Drain the VRAM update queue.
;   4. Refresh palette (if needed).
;   5. Restore the initial PPU scroll for the top of the frame.
;   6. Recompute the IRQ schedule for this frame.
;   7. Re-enable rendering and signal the main loop.
;==============================================================================

.proc NMI

    ; VBlank handler

    PHA
    TXA
    PHA
    TYA
    PHA

    ; Disable rendering during VBLANK updates
    LDA #%00000000
    STA NES_CTRL1

    JSR UPDATE_OAM
    JSR UPDATE_VRAM
    JSR UPDATE_COLOR
    JSR UPDATE_SCROLL

    ; Enable Rendering
    LDA NES_CTRL1_shadow
    STA NES_CTRL1

    LDA #FRAME_READY
    STA frame_state

    INC frame_counter

    PLA
    TAY
    PLA
    TAX
    PLA

    RTI

.endproc

;==============================================================================
; IRQ
;==============================================================================

.proc IRQ

    RTI

.endproc


;==============================================================================
; CODE
;==============================================================================

;==============================================================================
; Update Controllers
;==============================================================================

.proc UPDATE_CONTROLLERS

    ; Maximum number of consecutive reads used to validate the controller state.
    LDA #4
    STA tmp0

    ; Start validation against the previous controller state.
    LDX controller1_state
    TXA
@check:
    STA tmp1

    ; Controller Strobing
    LDA #$01
    STA NES_P0
    LDA #$00
    STA NES_P0

    ; Read Controller 1
    LDY #8
@next:
    LDA NES_P0
    LSR
    ROL controller_read
    DEY
    BNE @next

    ; Accept only a read that matches the previous validated state.
    LDA controller_read
    CMP tmp1
    BEQ @store

    ; Retry until the validation limit is exhausted.
    DEC tmp0
    BNE @check

    JMP @exit

@store:
    ; Update raw state.
    STA controller1_state

    ; Buttons that changed from released to pressed this frame.
    TXA
    EOR controller1_state
    AND controller1_state
    STA controller1_pressed

    ; Buttons that remain pressed from the previous read.
    TXA
    AND controller1_state
    STA controller1_held

@exit:

    RTS

.endproc

;==============================================================================
; CONTROLLER ACTIONS
;==============================================================================
;
;   Up / Down     previous / next tune
;   Left / Right  previous / next effect
;   A             restart the current tune or while paused single-step
;   B             stop the tune
;   Select        fast-forward
;   Start         pause/unpause the tune
;==============================================================================
 
.proc UPDATE_ACTIONS
 
    ; Start: pause
.if ::PAUSE_TOGGLE
    LDA controller1_pressed
    AND #P_START
    BEQ @pause_done
    ; Toggle pause flag
    LDA pause_flag
    EOR #1
    STA pause_flag
@pause_done:
.else
    ; Hold to pause
    LDA controller1_state
    AND #P_START
    STA pause_flag
.endif
 
    ; Up / Down: change tune and play it
@up:
    LDA controller1_pressed
    AND #P_UP
    BEQ @down
    INC current_tune
    LDA current_tune
    CMP #SONG_MAX+1
    BCC @up_go
    LDA #0
    STA current_tune
@up_go:
    JSR TUNEOFF
    JSR START_TUNE
 
@down:
    LDA controller1_pressed
    AND #P_DOWN
    BEQ @right
    DEC current_tune
    LDA current_tune
    CMP #$FF
    BNE @down_go
    LDA #SONG_MAX
    STA current_tune
@down_go:
    JSR TUNEOFF
    JSR START_TUNE
 
    ; Left / Right: change effect and play it
@right:
    LDA controller1_pressed
    AND #P_RIGHT
    BEQ @left
    INC current_effect
    LDA current_effect
    CMP #EFFECT_MAX+1
    BCC @right_go
    LDA #0
    STA current_effect
@right_go:
    JSR START_EFFECT
 
@left:
    LDA controller1_pressed
    AND #P_LEFT
    BEQ @a
    DEC current_effect
    LDA current_effect
    CMP #$FF
    BNE @left_go
    LDA #EFFECT_MAX
    STA current_effect
@left_go:
    JSR START_EFFECT
 
    ; A: restart or single-step while paused
@a:
    LDA controller1_pressed
    AND #P_A
    BEQ @start
    LDA pause_flag
    BEQ @restart
    LDA #STEP
    STA step_flag
    JMP @start
@restart:
    JSR START_TUNE
 
    ; B: stop
@start:
    LDA controller1_pressed
    AND #P_B
    BEQ @done
.if ::PAUSE_TOGGLE
    LDA #0
    STA pause_flag
.endif
    JSR TUNEOFF
 
@done:
    RTS
.endproc

.proc START_TUNE
    LDA #0
    STA timer_divider
    STA timer
    STA timer+1
    STA timer+2
    STA timer+3
.if ::PAUSE_TOGGLE
    STA pause_flag
.endif
    LDA current_tune
    STA playing_tune
    TAX
    JMP TUNE
.endproc
 
.proc START_EFFECT
.if ::PAUSE_TOGGLE
    LDA #0
    STA pause_flag
.endif
    LDX current_effect
    JMP EFFECT
.endproc

;==============================================================================
; Update Timer
;==============================================================================

.proc UPDATE_STEP_AMOUNT
    LDX #1 ; Standard step
    LDA controller1_state
    AND #P_SELECT
    BEQ @ff_done
    LDX #FF_COUNT ; Set to fast forward
@ff_done:
    LDA pause_flag
    BEQ @ticks_set
    LDX #0 ; Pause Step
    LDA step_flag
    BEQ @ticks_set
    LDX #1 ; Step while paused
@ticks_set:
    LDA #NO_STEP
    STA step_flag
    STX step_count
    TXA
    RTS
.endproc

;==============================================================================
; Update Music
;==============================================================================

.proc UPDATE_MUSIC
@refresh:
    JSR REFRESH ; MUSIC DRIVER UPDATE
    CMP #$00
    BNE @tune_ndone
    JSR TUNEOFF
@tune_ndone:
    JSR UPDATE_TIMER
    JSR TRACK_FOR
    DEC step_count
    BNE @refresh
    RTS
.endproc

;==============================================================================
; Update Timer
;==============================================================================

.proc UPDATE_TIMER
    INC timer_divider
    LDA timer_divider
    CMP #60
    BCC @done
    LDA #0
    STA timer_divider

    INC timer
    LDA timer
    CMP #$0A
    BNE @done
    LDA #0
    STA timer
    INC timer+1

    LDA timer+1
    CMP #$06
    BNE @done
    LDA #0
    STA timer+1
    INC timer+2

    LDA timer+2
    CMP #$0A
    BNE @done
    LDA #0
    STA timer+2
    INC timer+3

    LDA timer+3
    CMP #$0A
    BNE @done
    LDA #0
    STA timer+3

@done:
    RTS
.endproc

;==============================================================================
; Track For Variable
;==============================================================================

.macro FORTRACK rep, forv, prev
    .local ended, done
    LDA rep
    BEQ ended               ; repeat finished
    CMP prev
    BEQ done                ; unchanged
    BCC done                ; went down: a NEXT ran, FOR stays
    STA forv                ; went up: a new FOR started
    JMP done
ended:
    STA forv                ; A = 0, so FOR is zeroed
done:
    LDA rep
    STA prev
.endmacro

.proc TRACK_FOR
    FORTRACK repeat_A, for_A, prev_rep_A
    FORTRACK repeat_B, for_B, prev_rep_B
    FORTRACK repeat_C, for_C, prev_rep_C
    FORTRACK repeat_D, for_D, prev_rep_D
    RTS
.endproc

;==============================================================================
; DISPLAY UPDATE
;==============================================================================
 
HEX_CHARS:
    .byte "0123456789ABCDEF"
 
.macro QUEUE_AT addr
    LDA #>addr
    STA screen_hi
    LDA #<addr
    STA screen_lo
.endmacro
 
;------------------------------------------------------------------------------
; Queue one 2-digit hex byte.
; Out: carry set if the queue was full (nothing queued).
;------------------------------------------------------------------------------
.proc QUEUE_HEX
    LDY queue_count
    CPY #QUEUE_MAX
    BCS @full
    PHA
    LSR
    LSR
    LSR
    LSR
    TAX
    LDA HEX_CHARS,X
    STA queue_c0,Y
    PLA
    AND #$0F
    TAX
    LDA HEX_CHARS,X
    STA queue_c1,Y
    LDA screen_hi
    STA queue_hi,Y
    LDA screen_lo
    STA queue_lo,Y
    INC queue_count
    CLC
@full:
    RTS
.endproc
 
.proc BUILD_TIMER
    LDA timer+1
    ASL
    ASL
    ASL
    ASL
    ORA timer+0
    STA seconds
    LDA timer+3
    ASL
    ASL
    ASL
    ASL
    ORA timer+2
    STA minutes
    RTS
.endproc
 
;------------------------------------------------------------------------------
; UPDATE_DISPLAY
;------------------------------------------------------------------------------
.proc UPDATE_DISPLAY
 
    LDA queue_ready         ; NMI has not drained the last batch yet
    BEQ :+
    RTS
:
    LDA #0
    STA queue_count
 
    LDA once_flag
    BNE @scan_setup
 
    ; Sizes Drawn Once
    QUEUE_AT $2088
    LDA DISPLAY_SIZES+1
    JSR QUEUE_HEX
    QUEUE_AT $208A
    LDA DISPLAY_SIZES
    JSR QUEUE_HEX
    QUEUE_AT $2092
    LDA DISPLAY_SIZES+3
    JSR QUEUE_HEX
    QUEUE_AT $2094
    LDA DISPLAY_SIZES+2
    JSR QUEUE_HEX
    QUEUE_AT $209B
    LDA DISPLAY_SIZES
    CLC
    ADC DISPLAY_SIZES+2
    LDA DISPLAY_SIZES+1
    ADC DISPLAY_SIZES+3
    JSR QUEUE_HEX
    QUEUE_AT $209D
    LDA DISPLAY_SIZES
    CLC
    ADC DISPLAY_SIZES+2
    JSR QUEUE_HEX
    INC once_flag
 
@scan_setup:
    JSR BUILD_TIMER
 
    ; scan_ptr = CELLS + scan_idx*4
    LDA scan_idx
    STA scan_ptr
    LDA #0
    STA scan_ptr+1
    ASL scan_ptr
    ROL scan_ptr+1
    ASL scan_ptr
    ROL scan_ptr+1
    LDA scan_ptr
    CLC
    ADC #<CELLS
    STA scan_ptr
    LDA scan_ptr+1
    ADC #>CELLS
    STA scan_ptr+1
 
    LDA #NCELLS
    STA scan_left
 
@scan:
    ; value = *(cell.var)
    LDY #0
    LDA (scan_ptr),Y
    STA scan_vptr
    INY
    LDA (scan_ptr),Y
    STA scan_vptr+1
    LDY #0
    LDA (scan_vptr),Y
    STA scan_val
 
    LDY scan_idx
    CMP shadow,Y
    BEQ @advance            ; unchanged
 
    ; changed: queue (nametable address, value)
    LDY #2
    LDA (scan_ptr),Y
    STA screen_lo
    INY
    LDA (scan_ptr),Y
    STA screen_hi
    LDA scan_val
    JSR QUEUE_HEX
    BCS @stop               ; queue full: resume from this cell next frame
    LDY scan_idx
    LDA scan_val
    STA shadow,Y
 
@advance:
    INC scan_idx
    LDA scan_ptr
    CLC
    ADC #4
    STA scan_ptr
    BCC :+
    INC scan_ptr+1
:   LDA scan_idx
    CMP #NCELLS
    BNE @next
    LDA #0                  ; wrap to first cell
    STA scan_idx
    LDA #<CELLS
    STA scan_ptr
    LDA #>CELLS
    STA scan_ptr+1
@next:
    DEC scan_left
    BEQ @stop
    JMP @scan
 
@stop:
    LDA queue_count
    BEQ @done
    LDA #1
    STA queue_ready
@done:
    RTS
.endproc

.include "system/init.asm"
.include "system/nmi.asm"

.include "system/music_driver.asm"

;==============================================================================
; DATA
;==============================================================================

.segment "RODATA"

;==============================================================================
; DISPLAY CELL TABLE
;==============================================================================
 
.macro CELL var, scr
    .word var, scr
.endmacro
 
CELLS:
    ; effect / tune / time
    CELL current_effect, $20C8
    CELL playing_tune,   $20D2
    CELL minutes,        $20DA
    CELL seconds,        $20DD
 
    ; note
    CELL old_note_A,     $2129
    CELL old_note_B,     $212F
    CELL old_note_C,     $2135
    CELL old_note_D,     $213B
    ; length
    CELL length_A,       $2149
    CELL length_B,       $214F
    CELL length_C,       $2155
    CELL length_D,       $215B
    ; count
    CELL count_A,        $2169
    CELL count_B,        $216F
    CELL count_C,        $2175
    CELL count_D,        $217B
    ; transpose
    CELL transpose_A,    $2189
    CELL transpose_B,    $218F
    CELL transpose_C,    $2195
    ; for
    CELL for_A,          $21A9
    CELL for_B,          $21AF
    CELL for_C,          $21B5
    CELL for_D,          $21BB
    ; repeat
    CELL repeat_A,       $21C9
    CELL repeat_B,       $21CF
    CELL repeat_C,       $21D5
    CELL repeat_D,       $21DB
    ; frequency (high byte, low byte)
    CELL freq_A+1,       $21E9
    CELL freq_A,         $21EB
    CELL freq_B+1,       $21EF
    CELL freq_B,         $21F1
    CELL freq_C+1,       $21F5
    CELL freq_C,         $21F7
    ; distort
    CELL distort_A,      $2209
    CELL distort_B,      $220F
    CELL distort_C,      $2215
    ; wobble delay 1 / offset
    CELL wob_delay1_A,   $2249
    CELL wob_delay1_B,   $224F
    CELL wob_delay1_C,   $2255
    CELL wob_delay1_D,   $225B
    CELL wob_off_A,      $2269
    CELL wob_off_B,      $226F
    CELL wob_off_C,      $2275
    CELL wob_off_D,      $227B
    ; vibrato delay / rate / limit / direction
    CELL vib_delay_A,    $22A9
    CELL vib_delay_B,    $22AF
    CELL vib_delay_C,    $22B5
    CELL vib_rate_A,     $22C9
    CELL vib_rate_B,     $22CF
    CELL vib_rate_C,     $22D5
    CELL vib_limit2_A,   $22E9
    CELL vib_limit2_B,   $22EF
    CELL vib_limit2_C,   $22F5
    CELL vib_dir_A,      $2309
    CELL vib_dir_B,      $230F
    CELL vib_dir_C,      $2315
    ; volume
    CELL volume_A,       $2349
    CELL volume_B,       $234F
    CELL volume_D,       $235B
CELLS_END:
 
NCELLS = (CELLS_END - CELLS) / 4
    .assert NCELLS <= 64, error, "too many display cells for shadow[64]"

DISPLAY_SIZES:
    .word DRIVER_size, DATA_size

;==============================================================================
; CHR-ROM
;==============================================================================

.segment "CHARS"

.incbin "tiles.chr"