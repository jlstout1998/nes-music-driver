;------------------------------------------------------------------------------
; MUSIC DRIVER by Steven Ruddy and Tim Follin
;------------------------------------------------------------------------------

.export TUNEOFF, TUNE, EFFECT, REFRESH

DRIVER_size = Driver_end - Driver_start

; Channels
CH_A = 0
CH_B = 1
CH_C = 2
CH_D = 3
CH_E = 4
CH_F = 5

.include "ram.asm"

.segment "CODE"

Driver_start:

;------------------------------------------------------------------------------
; Music Driver Jump Tables
;
; Public entry points available through the six-word jump table below.
;------------------------------------------------------------------------------

    JMP TUNEOFF
    JMP TUNE
    JMP REFRESH
    JMP EFFECT
    JMP REFRESH::THE_END
    JMP REFRESH::FX_END

;==============================================================================
; TUNE
;
; Tune initialization routine, enter with X containing the tune number.
;==============================================================================

.proc TUNE
    JSR WIPE_VAR
    LDA Start_A_LO,X                             ; Channel A Stream Pointer
    STA PC_A
    LDA Start_A_HI,X
    STA PC_A+1
    LDA Start_B_LO,X                             ; Channel B Stream Pointer
    STA PC_B
    LDA Start_B_HI,X
    STA PC_B+1
    LDA Start_C_LO,X                             ; Channel C Stream Pointer
    STA PC_C
    LDA Start_C_HI,X
    STA PC_C+1
    LDA Start_D_LO,X                             ; Channel D Stream Pointer
    STA PC_D
    LDA Start_D_HI,X
    STA PC_D+1
    RTS
.endproc

;==============================================================================
; WIPE_VAR
;
; Routine called to initialize/clear variables.
;==============================================================================

.proc WIPE_VAR
    ; Clear Music Driver Zero Page
    LDA #$00
    LDY #CLEAR1
TUNE_1:
    STA Music_ZP-1,Y
    DEY
    BNE TUNE_1
    
    ; Clear Music Driver RAM
    LDY #CLEAR2
TUNE_2:
    STA Music_MEM-1,Y
    DEY
    BNE TUNE_2
    
    ; Disable Channels
    STY stop_E
    STY stop_F

    ; Enable Channels
    DEY
    STY stop_A
    STY stop_B
    STY stop_C
    STY stop_D

    ; Set Default Frequency Period Hi
    STY oldfreq_A
    STY oldfreq_B
    STY oldfreq_C

    ; Set Initial Note Duration
    LDY #1
    STY count_A
    STY count_B
    STY count_C
    STY count_D
    RTS
.endproc

;==============================================================================
; TUNEOFF
;
; Routine called to end a tune.
;==============================================================================

.proc TUNEOFF
    LDA #%00000000
    STA $4015
    JSR WIPE_VAR
    STA $4002
    STA $4003
    STA $4006
    STA $4007
    STA $400A
    STA $400B
    STA $400E
    STA $400F
    STA stop_A
    STA stop_B
    STA stop_C
    STA stop_D
    LDA #%00110000
    STA $4000
    STA $4004
    STA $4008
    STA $400C
    LDA #%00001111
    STA $4015
    RTS
.endproc

;==============================================================================
; EFFECT
;
; SFX initialization routine, enter with X containing the SFX number.
;==============================================================================

.proc EFFECT
    LDA Start_FX_LO,X                            ; Effect List Pointer
    STA EFF_zp
    LDA Start_FX_HI,X
    STA EFF_zp+1

    LDY #$00
@SFX_LOOP:
    LDA (EFF_zp),Y                               ; Get Channel * 2
    BMI @SFX_DONE                                ; bit 7: Set = Done
    
    TAX                                          ; X = Channel * 2
    
    INY
    LDA (EFF_zp),Y                               ; Effect Channel Stream Pointer
    STA PC_A,X
    INY
    LDA (EFF_zp),Y
    STA PC_A+1,X

    TXA
    LSR
    TAX                                          ; X = Channel
    ; Initialize SFX Channel
    LDA #$FF
    STA stop_A,X                                 ; Enable Channel
    LDA #1
    STA count_A,X                                ; Set Initial Note Duration

@TEST_E:
    CPX #CH_E                                    ; Channel E?
    BNE @TEST_F                                  ; No: Check F
    ; Initialize Channel E
    LDA #0
    STA length_E
    STA wob_off_E
    STA wob_delay1_E
    STA wob_delay2_E
    INY                                          ; Next Channel
    BNE @SFX_LOOP

@TEST_F:
    CPX #CH_F                                    ; Channel F?
    BNE @SFX_NEXT                                ; No: Next
    ; Initialize Channel F
    LDA #0
    STA transpose_F
    STA length_F
    STA wob_off_F
    STA wob_delay1_F
    STA wob_delay2_F
    STA port_F
    STA vib_delay_F
    STA vib_rate_F
    STA vib_limit2_F
    STA vib_dir_F
    LDA #$FF
    STA oldfreq_F
@SFX_NEXT:
    INY
    BNE @SFX_LOOP
@SFX_DONE:
    RTS
.endproc

;==============================================================================
; REFRESH
;
; Routine called every screen refresh to update music/effects.
;==============================================================================

.proc REFRESH

;------------------------------------------------------------------------------
; Check Channel A Active
;------------------------------------------------------------------------------

DO_CHANNEL_A:
    LDA stop_A
    BMI TEST_COUNT_A                             ; bit 7: Clear = Stopped and Set = Active
    JMP DO_CHANNEL_F                             ; Stopped: Next Channel

;------------------------------------------------------------------------------
; Check Channel A Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_A:
    DEC count_A                                  ; Reduce note duration
    BEQ DO_A                                     ; Note finished?: Fetch Next Stream Event
    JMP DO_ENV_A                                 ; Note playing

;------------------------------------------------------------------------------
; Advance Channel A Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_A:
    TYA                                          ; PC += Y
    CLC
    ADC PC_A
    STA PC_A
    BCC DO_A
    INC PC_A+1

;------------------------------------------------------------------------------
; Fetch Next Channel A Stream Event
;------------------------------------------------------------------------------

DO_A:
    LDY #0
    LDA (PC_A),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_A                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel A Command Handler
;------------------------------------------------------------------------------

COMMAND_A:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_A-128,X
    PHA
    LDA JUMP_LO_A-128,X
    PHA
    RTS                                          ; Return to the Handler

;------------------------------------------------------------------------------
; Channel A Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_A:

;------------------------------------------------------------------------------
; Channel A - Apply Sweep
;------------------------------------------------------------------------------

    LDX stop_F                                   ; Channel F in Control?
    BMI @NO_SWEEP_A                              ; Yes: No Register Write
    LDX sweep_A
    STX $4001
@NO_SWEEP_A:

;------------------------------------------------------------------------------
; Channel A - Apply Transpose
;------------------------------------------------------------------------------

    LDX ignore_A
    BEQ @TRANS_A                                 ; 0 = Transpose

    INC ignore_A                                 ; Skip Transpose
    BEQ @NO_TRANS_A
@TRANS_A:
    CLC                                          ; Note += Transpose (Signed)
    ADC transpose_A
@NO_TRANS_A:

    TAX                                          ; X = Note

;------------------------------------------------------------------------------
; Channel A - Check Note or Slide Target
;------------------------------------------------------------------------------

    LDA port_A
    BEQ SET_CURRENT_NOTE_A                       ; 0 = Slide Off

    STX target_A                                 ; Slide Target = New Note
    LDX old_note_A                               ; Load Previous Note

;------------------------------------------------------------------------------
; Channel A - Store Current Note
;------------------------------------------------------------------------------

SET_CURRENT_NOTE_A:

    STX old_note_A                               ; Current Note Playing

;------------------------------------------------------------------------------
; Channel A - Lookup Note Period
;------------------------------------------------------------------------------

    LDA Notes_LO,X                               ; Note Period += Distort
    CLC
    ADC distort_A
    STA freq_A
    LDA Notes_HI,X
    ADC #0
    STA freq_A+1

;------------------------------------------------------------------------------
; Channel A - Get Note Duration
;------------------------------------------------------------------------------

    LDA length_A
    BNE @GOT_LENGTH_A                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_A),Y
@GOT_LENGTH_A:
    STA count_A                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_A
    STA PC_A
    BCC @INPAGE_A
    INC PC_A+1
@INPAGE_A:

;------------------------------------------------------------------------------
; Channel A - Initialize Wobble
;------------------------------------------------------------------------------

    LDX wob_delay1_A                             ; Wobble Wait Timer = Up Timer + 1
    INX
    STX wob_wait_A

;------------------------------------------------------------------------------
; Channel A - Initialize Vibrato
;------------------------------------------------------------------------------

INIT_VIB_A:
    LDA vib_delay_A
    BEQ @SET_VIB_DIR_A                           ; 0 = Vibrato Off and Reset Wobble Direction

    STA vib_delay1_A                             ; Set Vibrato Delay Timer
    LDA vib_limit2_A                             ; Set Vibrato Swing Length
    STA vib_limit1_A
    LDA vib_dir_A                                ; Set Initial Vibrato Direction
@SET_VIB_DIR_A:
    STA flip1_A                                  ; If Vibrato Off, Wobble Starts Upward

;------------------------------------------------------------------------------
; Channel A - Initialize Volume Envelope
;------------------------------------------------------------------------------

INIT_ENV_A:
    LDA ADSR_control_A
    BEQ EFF_START_A                              ; 0 = Don't Restart ADSR
    BPL INIT_ADSR_A                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel A - Initialize Volume Envelope Table Mode
;------------------------------------------------------------------------------

    ; Determine the Hold Exit
    LDA cutoff_A
    BEQ @CHECK_ENV_END_A                         ; 0 = No Cutoff

    CMP count_A                                  ; Cutoff < Note Duration?
    BCC @SET_ENV_RELEASE_A                       ; Yes: Hold Exit = cutoff frames after note start

@CHECK_ENV_END_A:
    LDA endit_A
    BEQ @SET_ENV_RELEASE_A                       ; 0 = No Endit

    LDA count_A                                  ; Hold Exit = endit frames before note end
    SEC
    SBC endit_A

@SET_ENV_RELEASE_A:
    STA maul_A                                   ; Store Hold Exit Timer

    LDY #1
    STY ADSR_time_A                              ; Timer = 1
    DEY
    STY ADSR_dec_A                               ; Table Index = 0
    DEY
    STY ADSR_stage_A                             ; Stage = -1
    BMI EFF_START_A

;------------------------------------------------------------------------------
; Channel A - Initialize ADSR Mode
;------------------------------------------------------------------------------

INIT_ADSR_A:
    LDX ADSR_cyc_A                               ; Set Initial Stage
    STX ADSR_stage_A
    LDA ADSR_att_A,X                             ; Set Initial Timer
    STA ADSR_time_A
    LDA ADSR_init_A                              ; Set Initial Volume
    STA volume_A

;------------------------------------------------------------------------------
; Channel A - Write Note Period
;------------------------------------------------------------------------------

EFF_START_A:
    LDA eff_time_A
    BEQ @WRITE_PERIOD_LO_A                       ; 0 = No Effect

    STA eff_wait_A                               ; Store Effect Timer

    LDY stop_F                                   ; Channel F in Control?
    BMI DO_ENV_A                                 ; Yes: No Register Writes

    LDA eff_freq_A                               ; Write Effect Period
    STA $4002
    LDA eff_freq_A+1
    JMP @WRITE_PERIOD_HI_A

@WRITE_PERIOD_LO_A:
    LDY stop_F                                   ; Channel F in Control?
    BMI DO_ENV_A                                 ; Yes: No Register Writes

    LDA freq_A                                   ; Write Note Period
    STA $4002
    LDA freq_A+1
    CMP oldfreq_A
    BEQ DO_ENV_A
    STA oldfreq_A
@WRITE_PERIOD_HI_A:
    STA $4003

;------------------------------------------------------------------------------
; Channel A - Envelope Handler
;------------------------------------------------------------------------------

DO_ENV_A:
    LDA ADSR_stage_A
    BMI START_ENV_A                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel A - Do ADSR Mode
;------------------------------------------------------------------------------

TEST_ATTACK_A:
    BNE @TEST_DECAY_A                            ; Not Stage 0 (Attack), Test Decay Stage

    ; Attack Cycle
    DEC ADSR_time_A                              ; Decrease Attack Timer
    BPL END_ADSR_A                               ; Still Waiting: Current Attack Volume

    LDA ADSR_att_A                               ; Reload Attack Timer
    STA ADSR_time_A
    INC volume_A                                 ; Volume += 1

    LDA volume_A
    CMP #15                                      ; Reached Max Volume?
    BNE END_ADSR_A                               ; No: Stay in Attack Stage
    INC ADSR_stage_A                             ; Set to Stage 1 = Decay
    LDA ADSR_dec_A                               ; Load the Decay Timer
    STA ADSR_time_A
    BNE END_ADSR_A

@TEST_DECAY_A:
    CMP #1
    BNE END_ADSR_A                               ; Not Stage 1 (Decay), Sustain Current Volume

    ; Decay Cycle
    DEC ADSR_time_A                              ; Decrease Decay Timer
    BPL END_ADSR_A                               ; Still Waiting: Current Decay Volume

    LDA ADSR_dec_A                               ; Reload Decay Timer
    STA ADSR_time_A

    LDA volume_A
    CMP ADSR_sus_A                               ; Reached Sustain Volume?
    BEQ @SET_SUS_A                               ; Yes: Set to Sustain Stage

    DEC volume_A                                 ; Volume -= 1
    BPL END_ADSR_A                               ; Stay in Decay Stage

@SET_SUS_A:
    INC ADSR_stage_A                             ; Set to Stage 2 = Sustain
    JMP END_ADSR_A

;------------------------------------------------------------------------------
; Channel A - Do Volume Envelope Table Mode
;------------------------------------------------------------------------------

START_ENV_A:
    LDA maul_A
    BEQ @ENV_STEP_A                              ; 0 = No Hold Exit

    DEC maul_A                                   ; Decrease Hold Exit Timer
    BNE @ENV_STEP_A                              ; Still Waiting: Don't Exit the Hold

    LDA #1                                       ; Force Table Step
    STA ADSR_time_A
    INC ADSR_dec_A                               ; Next Table Index (Step Past Hold Entry)

@ENV_STEP_A:
    DEC ADSR_time_A                              ; Decrease Step Timer
    BNE END_ADSR_A                               ; Still Waiting: Current Volume

    LDY ADSR_dec_A                               ; Read Volume Envelope Entry
    LDA (point_A),Y
    BMI END_ADSR_A                               ; bit 7: Set = Hold Current Volume

    CMP #16
    BCC @ENV_DONE_A                              ; Entry < 16 = Volume
    LDY #0                                       ; Restart Volume Envelope Table
    LDA (point_A),Y

@ENV_DONE_A:
    STA volume_A                                 ; Store New Volume
    LDA time_A                                   ; Reload Step Timer
    STA ADSR_time_A
    INY                                          ; Advance Table Index
    STY ADSR_dec_A

;------------------------------------------------------------------------------
; Channel A - Write Volume
;------------------------------------------------------------------------------

END_ADSR_A:
    LDA volume_A                                 ; Write Duty | Volume
    ORA duty_A
    STA $4000

;------------------------------------------------------------------------------
; Channel A - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_A:
    LDA eff_time_A
    BEQ TEST_VIB_A                               ; 0 = No Effect

    LDA eff_wait_A                               ; Effect Still Playing?
    BEQ TEST_VIB_A                               ; 0 = Effect Done

    DEC eff_wait_A                               ; Decrease Effect Timer
    BEQ @EFF_END_A                               ; 0 = Effect Done
    JMP DO_CHANNEL_F                             ; Next Channel

@EFF_END_A:
    LDY stop_F                                   ; Channel F in Control?
    BMI TEST_VIB_A                               ; Yes: No Register Writes

    LDA freq_A                                   ; Restore Note Period
    STA $4002
    LDA freq_A+1
    STA oldfreq_A
    STA $4003

;------------------------------------------------------------------------------
; Channel A - Vibrato Handler
;------------------------------------------------------------------------------

TEST_VIB_A:
    LDA vib_delay_A
    BEQ TEST_WOB_A                               ; 0 = No Vibrato
    
    LDA vib_delay1_A
    BEQ @VIB_STARTED_A                           ; 0 = Vibrato Delay Done
    
    DEC vib_delay1_A                             ; Decrease Vibrato Delay Timer
    BNE TEST_PORT_A                              ; Still Waiting: Skip Vibrato

@VIB_STARTED_A:
    LDA freq_A                                   ; Get Period
    LDX freq_A+1
    LDY flip1_A                                  ; Get Vibrato Direction
    BEQ @VIB_DOWN_A

@VIB_UP_A:
    CLC                                          ; Period += Vibrato Rate
    ADC vib_rate_A
    BCC @VIB_DONE_A
    INX
    BNE @VIB_DONE_A

@VIB_DOWN_A:
    SEC                                          ; Period -= Vibrato Rate
    SBC vib_rate_A
    BCS @VIB_DONE_A
    DEX

@VIB_DONE_A:
    STA freq_A                                   ; Store New Period
    STX freq_A+1

    LDY stop_F                                   ; Channel F in Control?
    BMI @VIB_CNT_A                               ; Yes: No Register Writes

    STA $4002                                    ; Write New Period
    CPX oldfreq_A
    BEQ @VIB_CNT_A
    STX oldfreq_A
    STX $4003

@VIB_CNT_A:
    DEC vib_limit1_A                             ; Decrease Swing Length
    BNE TEST_PORT_A                              ; Still Waiting: Don't Reverse Direction

    LDA vib_limit2_A
    BEQ TEST_PORT_A                              ; 0 = Don't Reverse Direction
    ASL                                          ; Reload Swing Length * 2
    STA vib_limit1_A

    LDA flip1_A                                  ; Switch Vibrato Direction
    EOR #$FF
    STA flip1_A
    JMP TEST_PORT_A

;------------------------------------------------------------------------------
; Channel A - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_A:
    LDA wob_wait_A
    BEQ TEST_PORT_A                              ; 0 = No Wobble

    DEC wob_wait_A                               ; Decrease Wobble Timer
    BNE TEST_PORT_A                              ; Still Waiting: Skip Wobble
    
    LDA flip1_A                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_A
    BEQ @WOB_DOWN_A

@WOB_UP_A:
    LDA wob_delay1_A                             ; Wobble Timer = Up Timer
    STA wob_wait_A
    LDA old_note_A                               ; Note += Wobble
    CLC
    ADC wob_off_A
    JMP RESOUND_A

@WOB_DOWN_A:
    LDA wob_delay2_A                             ; Wobble Timer = Down Timer
    STA wob_wait_A
    LDA old_note_A                               ; Note -= Wobble
    SEC
    SBC wob_off_A
    JMP RESOUND_A

;------------------------------------------------------------------------------
; Channel A - Slide Handler
;------------------------------------------------------------------------------

TEST_PORT_A:
    LDA port_A
    BEQ DO_CHANNEL_F                             ; 0 = No Slide

    LDA old_note_A                               ; Check Note vs Slide Target
    CMP target_A
    BCC @PORT_UP_A                               ; Note < Slide Target: Slide Up
    BEQ DO_CHANNEL_F                             ; Note = Slide Target: Finished

@PORT_DOWN_A:
    SBC port_A                                   ; Note -= Slide
    CMP target_A
    BCS RESOUND_A                                ; Note >= Slide Target: Use this Note
    BCC @CLAMP_PORT_A                            ; Past Slide Target: Stop at Target

@PORT_UP_A:
    ADC port_A                                   ; Note += Slide
    CMP target_A
    BCC RESOUND_A                                ; Note < Slide Target: Use this Note

@CLAMP_PORT_A:
    LDA target_A                                 ; Note = Slide Target

;------------------------------------------------------------------------------
; Channel A - Update Note Period
;------------------------------------------------------------------------------

RESOUND_A:

    STA old_note_A                               ; Store Updated Note

    TAX                                          ; X = Updated Note

    LDA Notes_LO,X                               ; Store Updated Period Lo += Distort
    CLC
    ADC distort_A
    STA freq_A

    LDY stop_F                                   ; Channel F in Control?
    BMI @SKIP_PERIOD_LO_A                        ; Yes: No Register Write

    STA $4002                                    ; Write Period Lo
@SKIP_PERIOD_LO_A:

    LDA Notes_HI,X                               ; Store Updated Period Hi
    ADC #0
    STA freq_A+1

    CMP oldfreq_A                                ; Same Frequency Hi?
    BEQ DO_CHANNEL_F                             ; Yes: No Register Write
    STA oldfreq_A                                ; Store New Note Period Hi

    LDY stop_F                                   ; Channel F in Control?
    BMI TEST_COUNT_F                             ; Yes: No Register Write

    STA $4003                                    ; Write Period Hi

;------------------------------------------------------------------------------
; Check Channel F Active
;------------------------------------------------------------------------------

DO_CHANNEL_F:
    LDA stop_F
    BMI TEST_COUNT_F                             ; bit 7: Clear = Stopped and Set = Active
    JMP DO_CHANNEL_B                             ; Stopped: Next Channel

;------------------------------------------------------------------------------
; Check Channel F Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_F:
    DEC count_F                                  ; Reduce note duration
    BEQ DO_F                                     ; Note finished?: Fetch Next Stream Event
    JMP DO_ENV_F                                 ; Note playing

;------------------------------------------------------------------------------
; Advance Channel F Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_F:
    TYA                                          ; PC += Y
    CLC
    ADC PC_F
    STA PC_F
    BCC DO_F
    INC PC_F+1

;------------------------------------------------------------------------------
; Fetch Next Channel F Stream Event
;------------------------------------------------------------------------------

DO_F:
    LDY #0
    LDA (PC_F),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_F                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel F Command Handler
;------------------------------------------------------------------------------

COMMAND_F:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_F-128,X
    PHA
    LDA JUMP_LO_F-128,X
    PHA
    RTS                                          ; Return to the Handler

;------------------------------------------------------------------------------
; Channel F Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_F:

;------------------------------------------------------------------------------
; Channel F - Apply Sweep
;------------------------------------------------------------------------------

    LDX sweep_F
    STX $4001

;------------------------------------------------------------------------------
; Channel F - Apply Transpose
;------------------------------------------------------------------------------
 
    LDX ignore_F
    BEQ @TRANS_F                                 ; 0 = Transpose

    INC ignore_F                                 ; Skip Transpose
    BEQ @NO_TRANS_F
@TRANS_F:
    CLC                                          ; Note += Transpose (Signed)
    ADC transpose_F
@NO_TRANS_F:

    TAX                                          ; X = Note

;------------------------------------------------------------------------------
; Channel F - Check Note or Slide Target
;------------------------------------------------------------------------------

    LDA port_F
    BEQ SET_CURRENT_NOTE_F                       ; 0 = Slide Off

    STX target_F                                 ; Slide Target = New Note
    LDX old_note_F                               ; Load Previous Note

;------------------------------------------------------------------------------
; Channel F - Store Current Note
;------------------------------------------------------------------------------

SET_CURRENT_NOTE_F:

    STX old_note_F                               ; Current Note Playing

;------------------------------------------------------------------------------
; Channel F - Lookup Note Period
;------------------------------------------------------------------------------
    
    LDA Notes_LO,X                               ; Note Period += Distort
    CLC
    ADC distort_F
    STA freq_F
    LDA Notes_HI,X
    ADC #0
    STA freq_F+1

;------------------------------------------------------------------------------
; Channel F - Get Note Duration
;------------------------------------------------------------------------------
    
    LDA length_F
    BNE @GOT_LENGTH_F                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_F),Y
@GOT_LENGTH_F:
    STA count_F                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_F
    STA PC_F
    BCC @INPAGE_F
    INC PC_F+1
@INPAGE_F:

;------------------------------------------------------------------------------
; Channel F - Initialize Wobble
;------------------------------------------------------------------------------
    
    LDX wob_delay1_F                             ; Wobble Wait Timer = Up Timer + 1
    INX
    STX wob_wait_F

;------------------------------------------------------------------------------
; Channel F - Initialize Vibrato
;------------------------------------------------------------------------------

INIT_VIB_F:
        LDA vib_delay_F
        BEQ @SET_VIB_DIR_F                       ; 0 = Vibrato Off and Reset Wobble Direction

        STA vib_delay1_F                         ; Set Vibrato Delay Timer
        LDA vib_limit2_F                         ; Set Vibrato Swing Length
        STA vib_limit1_F
        LDA vib_dir_F                            ; Set Initial Vibrato Direction
@SET_VIB_DIR_F:
        STA flip1_F                              ; If Vibrato Off, Wobble Starts Updward

;------------------------------------------------------------------------------
; Channel F - Initialize Volume Envelope
;------------------------------------------------------------------------------

INIT_ENV_F:
    LDA ADSR_control_F
    BEQ EFF_START_F                              ; 0 = Don't Restart ADSR
    BPL INIT_ADSR_F                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel F - Initialize Volume Envelope Table Mode
;------------------------------------------------------------------------------

    ; Determine the Hold Exit
    LDA cutoff_F
    BEQ @CHECK_ENV_END_F                         ; 0 = No Cutoff

    CMP count_F                                  ; Cutoff < Note Duration?
    BCC @SET_ENV_RELEASE_F                       ; Yes: Hold Exit = cutoff frames after note start

@CHECK_ENV_END_F:
    LDA endit_F
    BEQ @SET_ENV_RELEASE_F                       ; 0 = No Endit

    LDA count_F                                  ; Hold Exit = endit frames before note end
    SEC
    SBC endit_F

@SET_ENV_RELEASE_F:
    STA maul_F                                   ; Store Hold Exit Timer

    LDY #1
    STY ADSR_time_F                              ; Timer = 1
    DEY
    STY ADSR_dec_F                               ; Table Index = 0
    DEY
    STY ADSR_stage_F                             ; Stage = -1
    BMI EFF_START_F

;------------------------------------------------------------------------------
; Channel F - Initialize ADSR Mode
;------------------------------------------------------------------------------

INIT_ADSR_F:
    LDX ADSR_cyc_F                               ; Set Initial Stage
    STX ADSR_stage_F
    LDA ADSR_att_F,X                             ; Set Initial Timer
    STA ADSR_time_F
    LDA ADSR_init_F                              ; Set Initial Volume
    STA volume_F

;------------------------------------------------------------------------------
; Channel F - Write Note Period
;------------------------------------------------------------------------------

EFF_START_F:
    LDA eff_time_F
    BEQ @WRITE_PERIOD_LO_F                       ; 0 = No Effect

    STA eff_wait_F                               ; Store Effect Timer

    LDA eff_freq_F                               ; Write Effect Period
    STA $4002
    LDA eff_freq_F+1
    JMP @WRITE_PERIOD_HI_F

@WRITE_PERIOD_LO_F:
    LDA freq_F                                   ; Write Note Period
    STA $4002
    LDA freq_F+1
    CMP oldfreq_F
    BEQ DO_ENV_F
    STA oldfreq_F
@WRITE_PERIOD_HI_F:
    STA $4003

;------------------------------------------------------------------------------
; Channel F - Envelope Handler
;------------------------------------------------------------------------------

DO_ENV_F:
    LDA ADSR_stage_F
    BMI START_ENV_F                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel F - Do ADSR Mode
;------------------------------------------------------------------------------

TEST_ATTACK_F:
    BNE @TEST_DECAY_F                            ; Not Stage 0 (Attack), Test Decay Stage

    ; Attack Cycle
    DEC ADSR_time_F                              ; Decrease Attack Timer
    BPL END_ADSR_F                               ; Still Waiting: Current Attack Volume
    
    LDA ADSR_att_F                               ; Reload Attack Timer
    STA ADSR_time_F
    INC volume_F                                 ; Volume += 1
    
    LDA volume_F
    CMP #15                                      ; Reached Max Volume?
    BNE END_ADSR_F                               ; No: Stay in Attack Stage
    INC ADSR_stage_F                             ; Set to Stage 1 = Decay
    LDA ADSR_dec_F                               ; Load the Decay Timer
    STA ADSR_time_F
    BNE END_ADSR_F

@TEST_DECAY_F:
    CMP #1
    BNE END_ADSR_F                               ; Not Stage 1 (Decay), Sustain Current Volume

    ; Decay Cycle
    DEC ADSR_time_F                              ; Decrease Decay Timer
    BPL END_ADSR_F                               ; Still Waiting: Current Decay Volume
    
    LDA ADSR_dec_F                               ; Reload Decay Timer
    STA ADSR_time_F
    
    LDA volume_F
    CMP ADSR_sus_F                               ; Reached Sustain Volume?
    BEQ @SET_SUS_F                               ; Yes: Set to Sustain Stage
    
    DEC volume_F                                 ; Volume -= 1
    BPL END_ADSR_F                               ; Stay in Decay Stage

@SET_SUS_F:
    INC ADSR_stage_F                             ; Set to Stage 2 = Sustain
    JMP END_ADSR_F

;------------------------------------------------------------------------------
; Channel F - Do Volume Envelope Table Mode
;------------------------------------------------------------------------------

START_ENV_F:
    LDA maul_F
    BEQ @ENV_STEP_F                              ; 0 = No Hold Exit

    DEC maul_F                                   ; Decrease Hold Exit Timer
    BNE @ENV_STEP_F                              ; Still Waiting: Don't Exit the Hold
    
    LDA #1                                       ; Force Table Step
    STA ADSR_time_F
    INC ADSR_dec_F                               ; Next Table Index (Step Past Hold Entry)

@ENV_STEP_F:
    DEC ADSR_time_F                              ; Decrease Step Timer
    BNE END_ADSR_F                               ; Still Waiting: Current Volume

    LDY ADSR_dec_F                               ; Read Volume Envelope Entry
    LDA (point_F),Y
    BMI END_ADSR_F                               ; bit 7: Set = Hold Current Volume
    
    CMP #16
    BCC @ENV_DONE_F                              ; Entry < 16 = Volume
    LDY #0                                       ; Restart Volume Envelope Table
    LDA (point_F),Y

@ENV_DONE_F:
    STA volume_F                                 ; Store New Volume
    LDA time_F                                   ; Reload Step Timer
    STA ADSR_time_F
    INY                                          ; Advance Table Index
    STY ADSR_dec_F

;------------------------------------------------------------------------------
; Channel F - Write Volume
;------------------------------------------------------------------------------

END_ADSR_F:
    LDA volume_F                                 ; Write Duty | Volume
    ORA duty_F
    STA $4000

;------------------------------------------------------------------------------
; Channel F - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_F:
    LDA eff_time_F
    BEQ TEST_VIB_F                               ; 0 = No Effect

    LDA eff_wait_F                               ; Effect Still Playing?
    BEQ TEST_VIB_F                               ; 0 = Effect Done
    
    DEC eff_wait_F                               ; Decrease Effect Timer
    BEQ @EFF_END_F                               ; 0 = Effect Done
    JMP DO_CHANNEL_B                             ; Next Channel

@EFF_END_F:
    LDA freq_F                                   ; Restore Note Period
    STA $4002
    LDA freq_F+1
    STA oldfreq_F
    STA $4003

;------------------------------------------------------------------------------
; Channel F - Vibrato Handler
;------------------------------------------------------------------------------

TEST_VIB_F:
    LDA vib_delay_F
    BEQ TEST_WOB_F                               ; 0 = No Vibrato

    LDA vib_delay1_F                             ; 0 = Vibrato Delay Done
    BEQ @VIB_STARTED_F
    
    DEC vib_delay1_F                             ; Decrease Vibrato Delay Timer
    BNE TEST_PORT_F                              ; Still Waiting: Skip Vibrato

@VIB_STARTED_F:
    LDA freq_F                                   ; Get Period
    LDX freq_F+1
    LDY flip1_F                                  ; Get Vibrato Direction
    BEQ @VIB_DOWN_F

@VIB_UP_F:
    CLC                                          ; Period += Vibrato Rate
    ADC vib_rate_F
    BCC @VIB_DONE_F
    INX
    BNE @VIB_DONE_F

@VIB_DOWN_F:
    SEC                                          ; Period -= Vibrato Rate
    SBC vib_rate_F
    BCS @VIB_DONE_F
    DEX

@VIB_DONE_F:
    STA freq_F                                   ; Store New Period

    STA $4002                                    ; Write New Period
    STX freq_F+1
    CPX oldfreq_F
    BEQ @VIB_CNT_F
    STX oldfreq_F
    STX $4003

@VIB_CNT_F:
    DEC vib_limit1_F                             ; Decrease Swing Length
    BNE TEST_PORT_F                              ; Still Waiting: Don't Reverse Direction

    LDA vib_limit2_F
    BEQ TEST_PORT_F                              ; 0 = Don't Reverse Direction
    ASL                                          ; Reload Swing Length * 2
    STA vib_limit1_F

    LDA flip1_F                                  ; Switch Vibrato Direction
    EOR #$FF
    STA flip1_F
    JMP TEST_PORT_F

;------------------------------------------------------------------------------
; Channel F - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_F:
    LDA wob_wait_F
    BEQ TEST_PORT_F                              ; 0 = No Wobble

    DEC wob_wait_F                               ; Decrease Wobble Timer
    BNE TEST_PORT_F                              ; Still Waiting: Skip Wobble
    
    LDA flip1_F                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_F
    BEQ @WOB_DOWN_F

@WOB_UP_F:
    LDA wob_delay1_F                             ; Wobble Timer = Up Timer
    STA wob_wait_F
    LDA old_note_F                               ; Note += Wobble
    CLC
    ADC wob_off_F
    JMP RESOUND_F

@WOB_DOWN_F:
    LDA wob_delay2_F                             ; Wobble Timer = Down Timer
    STA wob_wait_F
    LDA old_note_F                               ; Note -= Wobble
    SEC
    SBC wob_off_F
    JMP RESOUND_F

;------------------------------------------------------------------------------
; Channel F - Slide Handler
;------------------------------------------------------------------------------

TEST_PORT_F:
    LDA port_F
    BEQ DO_CHANNEL_B                             ; 0 = No Slide

    LDA old_note_F                               ; Check Note vs Slide Target
    CMP target_F
    BCC @PORT_UP_F                               ; Note < Slide Target: Slide Up
    BEQ DO_CHANNEL_B                             ; Note = Slide Target: Finished

@PORT_DOWN_F:
    SBC port_F                                   ; Note -= Slide
    CMP target_F
    BCS RESOUND_F                                ; Note >= Slide Target: Use this Note
    BCC @CLAMP_PORT_F                            ; Past Slide Target: Stop at Target

@PORT_UP_F:
    ADC port_F                                   ; Note += Slide
    CMP target_F
    BCC RESOUND_F                                ; Note < Slide Target: Use this Note

@CLAMP_PORT_F:
    LDA target_F                                 ; Note = Slide Target

;------------------------------------------------------------------------------
; Channel F - Update Note Period
;------------------------------------------------------------------------------

RESOUND_F:

    STA old_note_F                               ; Store Updated Note

    TAX                                          ; X = Updated Note

    LDA Notes_LO,X                               ; Store Updated Period Lo += Distort
    CLC
    ADC distort_F
    STA freq_F
    STA $4002                                    ; Write Period Lo

    LDA Notes_HI,X                               ; Store Updated Period Hi
    ADC #0
    STA freq_F+1

    CMP oldfreq_F                                ; Same Frequency Hi?
    BEQ DO_CHANNEL_B                             ; Yes: No Register Write
    STA oldfreq_F                                ; Store New Period Hi
    STA $4003                                    ; Write Period Hi

;------------------------------------------------------------------------------
; Check Channel B Active
;------------------------------------------------------------------------------

DO_CHANNEL_B:
    LDA stop_B
    BMI TEST_COUNT_B                             ; bit 7: Clear = Stopped and Set = Active
    JMP DO_CHANNEL_C                             ; Stopped: Next Channel

;------------------------------------------------------------------------------
; Check Channel B Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_B:
    DEC count_B                                  ; Reduce note duration
    BEQ DO_B                                     ; Note finished?: Fetch Next Stream Event
    JMP DO_ENV_B                                 ; Note playing

;------------------------------------------------------------------------------
; Advance Channel B Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_B:
    TYA                                          ; PC += Y
    CLC
    ADC PC_B
    STA PC_B
    BCC DO_B
    INC PC_B+1

;------------------------------------------------------------------------------
; Fetch Next Channel B Stream Event
;------------------------------------------------------------------------------

DO_B:
    LDY #0
    LDA (PC_B),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_B                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel B Command Handler
;------------------------------------------------------------------------------

COMMAND_B:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_B-128,X
    PHA
    LDA JUMP_LO_B-128,X
    PHA
    RTS                                          ; Return to the Handler

;------------------------------------------------------------------------------
; Channel B Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_B:

;------------------------------------------------------------------------------
; Channel B - Apply Sweep
;------------------------------------------------------------------------------

    LDX sweep_B
    STX $4005

;------------------------------------------------------------------------------
; Channel B - Apply Transpose
;------------------------------------------------------------------------------

    LDX ignore_B
    BEQ @TRANS_B                                 ; 0 = Transpose

    INC ignore_B                                 ; Skip Transpose
    BEQ @NO_TRANS_B
@TRANS_B:
    CLC                                          ; Note += Transpose (Signed)
    ADC transpose_B
@NO_TRANS_B:
    
    TAX                                          ; X = Note
    
;------------------------------------------------------------------------------
; Channel B - Check Note or Slide Target
;------------------------------------------------------------------------------

    LDA port_B
    BEQ SET_CURRENT_NOTE_B                       ; 0 = Slide Off

    STX target_B                                 ; Slide Target = New Note
    LDX old_note_B                               ; Load Previous Note

;------------------------------------------------------------------------------
; Channel B - Store Current Note
;------------------------------------------------------------------------------

SET_CURRENT_NOTE_B:

    STX old_note_B                               ; Current Note Playing

;------------------------------------------------------------------------------
; Channel B - Lookup Note Period
;------------------------------------------------------------------------------

    LDA Notes_LO,X                               ; Note Period += Distort
    CLC
    ADC distort_B
    STA freq_B
    LDA Notes_HI,X
    ADC #0
    STA freq_B+1

;------------------------------------------------------------------------------
; Channel B - Get Note Duration
;------------------------------------------------------------------------------

    LDA length_B
    BNE @GOT_LENGTH_B                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_B),Y
@GOT_LENGTH_B:
    STA count_B                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_B
    STA PC_B
    BCC @INPAGE_B
    INC PC_B+1
@INPAGE_B:

;------------------------------------------------------------------------------
; Channel B - Initialize Wobble
;------------------------------------------------------------------------------

    LDX wob_delay1_B                             ; Wobble Wait TImer = Up Timer + 1
    INX
    STX wob_wait_B

;------------------------------------------------------------------------------
; Channel B - Initialize Vibrato
;------------------------------------------------------------------------------

INIT_VIB_B:
    LDA vib_delay_B
    BEQ @SET_VIB_DIR_B                           ; 0 = Vibrato Off and Reset Wobble Direction

    STA vib_delay1_B                             ; Set Vibrato Delay Timer
    LDA vib_limit2_B                             ; Set Vibrato Swing Length
    STA vib_limit1_B
    LDA vib_dir_B                                ; Set Initial Vibrato Direction
@SET_VIB_DIR_B:
    STA flip1_B                                  ; If Vibrato Off, Wobble Starts Upward

;------------------------------------------------------------------------------
; Channel B - Initialize Volume Envelope
;------------------------------------------------------------------------------

INIT_ENV_B:
    LDA ADSR_control_B
    BEQ EFF_START_B                              ; 0 = Don't Restart ADSR
    BPL INIT_ADSR_B                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel B - Initialize Volume Envelope Table Mode
;------------------------------------------------------------------------------

    ; Determine the Hold Exit
    LDA cutoff_B
    BEQ @CHECK_ENV_END_B                         ; 0 = No Cutoff

    CMP count_B                                  ; Cutoff < Note Duration?
    BCC @SET_ENV_RELEASE_B                       ; Yes: Hold Exit = cutoff frames after note start

@CHECK_ENV_END_B:
    LDA endit_B
    BEQ @SET_ENV_RELEASE_B                       ; 0 = No Endit

    LDA count_B                                  ; Hold Exit = endit frames before note end
    SEC
    SBC endit_B

@SET_ENV_RELEASE_B:
    STA maul_B                                   ; Store Hold Exit Timer

    LDY #1
    STY ADSR_time_B                              ; Timer = 1
    DEY
    STY ADSR_dec_B                               ; Table Index = 0
    DEY
    STY ADSR_stage_B                             ; Stage = -1
    BMI EFF_START_B

;------------------------------------------------------------------------------
; Channel B - Initialize ADSR Mode
;------------------------------------------------------------------------------

INIT_ADSR_B:
    LDX ADSR_cyc_B                               ; Set Initial Stage
    STX ADSR_stage_B
    LDA ADSR_att_B,X                             ; Set Initial Timer
    STA ADSR_time_B
    LDA ADSR_init_B                              ; Set Initial Volume
    STA volume_B

;------------------------------------------------------------------------------
; Channel B - Write Note Period
;------------------------------------------------------------------------------

EFF_START_B:
    LDA eff_time_B
    BEQ @WRITE_PERIOD_LO_B                       ; 0 = No Effect

    STA eff_wait_B                               ; Store Effect Timer

    LDA eff_freq_B                               ; Write Effect Period
    STA $4006
    LDA eff_freq_B+1
    JMP @WRITE_PERIOD_HI_B

@WRITE_PERIOD_LO_B:
    LDA freq_B                                   ; Write Note Period
    STA $4006
    LDA freq_B+1
    CMP oldfreq_B
    BEQ DO_ENV_B
    STA oldfreq_B
@WRITE_PERIOD_HI_B:
    STA $4007

;------------------------------------------------------------------------------
; Channel B - Envelope Handler
;------------------------------------------------------------------------------

DO_ENV_B:
    LDA ADSR_stage_B
    BMI START_ENV_B                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel B - Do ADSR Mode
;------------------------------------------------------------------------------

TEST_ATTACK_B:
    BNE @TEST_DECAY_B                            ; Not Stage 0 (Attack), Test Decay Stage

    ; Attack Cycle
    DEC ADSR_time_B                              ; Decrease Attack Timer
    BPL END_ADSR_B                               ; Still Waiting: Current Attack Volume

    LDA ADSR_att_B                               ; Reload Attack Timer
    STA ADSR_time_B
    INC volume_B                                 ; Volume += 1

    LDA volume_B
    CMP #15                                      ; Reached Max Volume?
    BNE END_ADSR_B                               ; No: Stay in Attack Stage
    INC ADSR_stage_B                             ; Set to Stage 1 = Decay
    LDA ADSR_dec_B                               ; Load the Decay Timer
    STA ADSR_time_B
    BNE END_ADSR_B

@TEST_DECAY_B:
    CMP #1
    BNE END_ADSR_B                               ; Not Stage 1 (Decay), Sustain Current Volume

    ; Decay Cycle
    DEC ADSR_time_B                              ; Decrease Decay Timer
    BPL END_ADSR_B                               ; Still Waiting: Current Decay Volume
    
    LDA ADSR_dec_B                               ; Reload Decay Timer
    STA ADSR_time_B
    
    LDA volume_B
    CMP ADSR_sus_B                               ; Reached Sustain Volume?
    BEQ @SET_SUS_B                               ; Yes: Set to Sustain Stage
    
    DEC volume_B                                 ; Volume -= 1
    BPL END_ADSR_B                               ; Stay in Decay Stage

@SET_SUS_B:
    INC ADSR_stage_B                             ; Set to Stage 2 = Sustain
    JMP END_ADSR_B

;------------------------------------------------------------------------------
; Channel B - Do Volume Envelope Table Mode
;------------------------------------------------------------------------------

START_ENV_B:
    LDA maul_B
    BEQ @ENV_STEP_B                              ; 0 = No Hold Exit

    DEC maul_B                                   ; Decrease Hold Exit Timer
    BNE @ENV_STEP_B                              ; Still Waiting: Don't Exit the Hold
    
    LDA #1                                       ; Force Table Stop
    STA ADSR_time_B
    INC ADSR_dec_B                               ; Next Table Index (Step Past Hold Entry)

@ENV_STEP_B:
    DEC ADSR_time_B                              ; Decrease Step Timer
    BNE END_ADSR_B                               ; Still Waiting: Current Volume
    
    LDY ADSR_dec_B                               ; Read Volume Envelope Entry
    LDA (point_B),Y
    BMI END_ADSR_B                               ; bit 7: Set = Hold Current Volume
    
    CMP #16
    BCC @ENV_DONE_B                              ; Entry < 16 = Volume
    LDY #0                                       ; Restart Volume Envelope Table
    LDA (point_B),Y

@ENV_DONE_B:
    STA volume_B                                 ; Store New Volume
    LDA time_B                                   ; Reload Step Timer
    STA ADSR_time_B
    INY                                          ; Advance Table Index
    STY ADSR_dec_B

;------------------------------------------------------------------------------
; Channel B - Write Volume
;------------------------------------------------------------------------------

END_ADSR_B:
    LDA volume_B                                 ; Write Duty | Volume
    ORA duty_B
    STA $4004

;------------------------------------------------------------------------------
; Channel B - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_B:
    LDA eff_time_B
    BEQ TEST_VIB_B                               ; 0 = No Effect
    
    LDA eff_wait_B                               ; Effect Still Playing?
    BEQ TEST_VIB_B                               ; 0 = Effect Done
    
    DEC eff_wait_B                               ; Decrease Effect Timer
    BEQ @EFF_END_B                               ; 0 = Effect Done
    JMP DO_CHANNEL_C                             ; Next Channel

@EFF_END_B:
    LDA freq_B                                   ; Restore Note Period
    STA $4006
    LDA freq_B+1
    STA oldfreq_B
    STA $4007

;------------------------------------------------------------------------------
; Channel B - Vibrato Handler
;------------------------------------------------------------------------------

TEST_VIB_B:
    LDA vib_delay_B
    BEQ TEST_WOB_B                               ; 0 = No Vibrato

    LDA vib_delay1_B                             ; 0 = Vibrato Delay Done
    BEQ @VIB_STARTED_B

    DEC vib_delay1_B                             ; Decrease Vibrato Delay Timer
    BNE TEST_PORT_B                              ; Still Waiting: Skip Vibrato

@VIB_STARTED_B:
    LDA freq_B                                   ; Get Period
    LDX freq_B+1
    LDY flip1_B                                  ; Get Vibrato Direction
    BEQ @VIB_DOWN_B

@VIB_UP_B:
    CLC                                          ; Period += Vibrato Rate
    ADC vib_rate_B
    BCC @VIB_DONE_B
    INX
    BNE @VIB_DONE_B

@VIB_DOWN_B:
    SEC                                          ; Period -= Vibrato Rate
    SBC vib_rate_B
    BCS @VIB_DONE_B
    DEX

@VIB_DONE_B:
    STA freq_B                                   ; Write New Period
    STA $4006
    STX freq_B+1
    CPX oldfreq_B
    BEQ @VIB_CNT_B
    STX oldfreq_B
    STX $4007

@VIB_CNT_B:
    DEC vib_limit1_B                             ; Decrease Swing Length
    BNE TEST_PORT_B                              ; Still Waiting: Don't Reverse Direction

    LDA vib_limit2_B
    BEQ TEST_PORT_B                              ; 0 = Don't Reverse Direction
    ASL                                          ; Reload Swing Length * 2
    STA vib_limit1_B

    LDA flip1_B                                  ; Switch Vibrato Direction
    EOR #$FF
    STA flip1_B
    JMP TEST_PORT_B

;------------------------------------------------------------------------------
; Channel B - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_B:
    LDA wob_wait_B
    BEQ TEST_PORT_B                              ; 0 = No Wobble

    DEC wob_wait_B                               ; Decrease Wobble Timer
    BNE TEST_PORT_B                              ; Still Waiting: Skip Wobble
    
    LDA flip1_B                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_B
    BEQ @WOB_DOWN_B

@WOB_UP_B:
    LDA wob_delay1_B                             ; Wobble Timer = Up Timer
    STA wob_wait_B
    LDA old_note_B                               ; Note += Wobble
    CLC
    ADC wob_off_B
    JMP RESOUND_B

@WOB_DOWN_B:
    LDA wob_delay2_B                             ; Wobble Timer = Down Timer
    STA wob_wait_B
    LDA old_note_B                               ; Note -= Wobble
    SEC
    SBC wob_off_B
    JMP RESOUND_B

;------------------------------------------------------------------------------
; Channel B - Slide Handler
;------------------------------------------------------------------------------

TEST_PORT_B:
    LDA port_B
    BEQ DO_CHANNEL_C                             ; 0 = No Slide

    LDA old_note_B                               ; Check Note vs Slide Target
    CMP target_B
    BCC @PORT_UP_B                               ; Note < Slide Target: Slide Up
    BEQ DO_CHANNEL_C                             ; Note = Slide Target: Finished

@PORT_DOWN_B:
    SBC port_B                                   ; Note -= Slide
    CMP target_B
    BCS RESOUND_B                                ; Note >= Slide Target: Use this Note
    BCC @CLAMP_PORT_B                            ; Past Slide Target: Stop at Target

@PORT_UP_B:
    ADC port_B                                   ; Note += Slide
    CMP target_B
    BCC RESOUND_B                                ; Note < Slide Target: Use this Note

@CLAMP_PORT_B:
    LDA target_B                                 ; Note = Slide Target

;------------------------------------------------------------------------------
; Channel B - Update Note Period
;------------------------------------------------------------------------------

RESOUND_B:

    STA old_note_B                               ; Store Updated Note

    TAX                                          ; X = Updated Note

    LDA Notes_LO,X                               ; Store Updated Period Lo += Distort
    CLC
    ADC distort_B
    STA freq_B
    STA $4006                                    ; Write Period Lo
    LDA Notes_HI,X                               ; Store Updated Period Hi
    ADC #0
    STA freq_B+1

    CMP oldfreq_B                                ; Same Frequency Hi?
    BEQ DO_CHANNEL_C                             ; Yes: No Register Write
    STA oldfreq_B                                ; Store New Note Period Hi
    STA $4007                                    ; Write Period Hi

;------------------------------------------------------------------------------
; Check Channel C Active
;------------------------------------------------------------------------------

DO_CHANNEL_C:
    LDA stop_C
    BMI TEST_COUNT_C                             ; bit 7: Clear = Stopped and Set = Active
    JMP DO_CHANNEL_D                             ; Stopped: Next Channel

;------------------------------------------------------------------------------
; Check Channel C Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_C:
    DEC count_C                                  ; Reduce note duration
    BEQ DO_C                                     ; Note finished?: Fetch Next Stream Event
    JMP TEST_EFF_C                               ; Note playing

;------------------------------------------------------------------------------
; Advance Channel C Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_C:
    TYA                                          ; PC += Y
    CLC
    ADC PC_C
    STA PC_C
    BCC DO_C
    INC PC_C+1

;------------------------------------------------------------------------------
; Fetch Next Channel C Stream Event
;------------------------------------------------------------------------------

DO_C:
    LDY #0
    LDA (PC_C),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_C                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel C Command Handler
;------------------------------------------------------------------------------

COMMAND_C:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_C-128,X
    PHA
    LDA JUMP_LO_C-128,X
    PHA
    RTS                                          ; Return to Handler

;------------------------------------------------------------------------------
; Channel C Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_C:

;------------------------------------------------------------------------------
; Channel C - Appply Transpose
;------------------------------------------------------------------------------

    LDX ignore_C
    BEQ @TRANS_C                                 ; 0 = Transpose

    INC ignore_C                                 ; Skip Transpose
    BEQ @NO_TRANS_C
@TRANS_C:
    CLC                                          ; Note += Transpose (Signed)
    ADC transpose_C
@NO_TRANS_C:
    
    TAX                                          ; X = Note
    
;------------------------------------------------------------------------------
; Channel C - Check Note or Slide Target
;------------------------------------------------------------------------------

    LDA port_C
    BEQ SET_CURRENT_NOTE_C                       ; 0 = Slide Off

    STX target_C                                 ; Slide Target = New Note
    LDX old_note_C                               ; Load Previous Note

;------------------------------------------------------------------------------
; Channel C - Store Current Note
;------------------------------------------------------------------------------

SET_CURRENT_NOTE_C:

    STX old_note_C                               ; Current Note Playing
    
;------------------------------------------------------------------------------
; Channel C - Lookup Note Period
;------------------------------------------------------------------------------

    LDA Notes_LO,X                               ; Note Period += Distort
    CLC
    ADC distort_C
    STA freq_C
    LDA Notes_HI,X
    ADC #0
    STA freq_C+1

;------------------------------------------------------------------------------
; Channel C - Get Note Duration
;------------------------------------------------------------------------------

    LDA length_C
    BNE @GOT_LENGTH_C                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_C),Y
@GOT_LENGTH_C:
    STA count_C                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_C
    STA PC_C
    BCC @INPAGE_C
    INC PC_C+1
@INPAGE_C:

;------------------------------------------------------------------------------
; Channel C - Initialize Wobble
;------------------------------------------------------------------------------

    LDX wob_delay1_C                             ; Wobble Wait Timer = Up Timer + 1
    INX
    STX wob_wait_C

;------------------------------------------------------------------------------
; Channel C - Initialize Vibrato
;------------------------------------------------------------------------------

INIT_VIB_C:
    LDA vib_delay_C
    BEQ @SET_VIB_DIR_C                           ; 0 = Vibrato Off and Reset Wobble Direction

    STA vib_delay1_C                             ; Set Vibrato Delay Timer
    LDA vib_limit2_C                             ; Set Vibrato Swing Length
    STA vib_limit1_C
    LDA vib_dir_C                                ; Set Initial Vibrato Direction

@SET_VIB_DIR_C:
    STA flip1_C                                  ; If Vibrato Off, Wobble Starts Upward

;------------------------------------------------------------------------------
; Channel C - Write Note Period
;------------------------------------------------------------------------------

EFF_START_C:
    LDA eff_time_C
    BEQ @WRITE_PERIOD_LO_C                       ; 0 = No Effect

    STA eff_wait_C                               ; Store Effect Timer

    LDA eff_freq_C                               ; Write Effect Period
    STA $400A
    LDA eff_freq_C+1
    JMP @WRITE_PERIOD_HI_C

@WRITE_PERIOD_LO_C:
    LDA freq_C                                   ; Write Note Period
    STA $400A
    LDA freq_C+1
    CMP oldfreq_C
    BEQ TEST_EFF_C
    STA oldfreq_C
@WRITE_PERIOD_HI_C:
    STA $400B

;------------------------------------------------------------------------------
; Channel C - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_C:
    LDA eff_time_C
    BEQ TEST_VIB_C                               ; 0 = No Effect

    LDA eff_wait_C                               ; Effect Still Playing?
    BEQ TEST_VIB_C
    
    DEC eff_wait_C                               ; Decrease Effect Timer
    BEQ @EFF_END_C                               ; 0 = Effect Done
    JMP DO_CHANNEL_D                             ; Next Channel

@EFF_END_C:
    LDA freq_C                                   ; Restore Note Period
    STA $400A
    LDA freq_C+1
    STA oldfreq_C
    STA $400B

;------------------------------------------------------------------------------
; Channel C - Vibrato Handler
;------------------------------------------------------------------------------

TEST_VIB_C:
    LDA vib_delay_C
    BEQ TEST_WOB_C                               ; 0 = No Vibrato

    LDA vib_delay1_C
    BEQ @VIB_STARTED_C                           ; 0 = Vibrato Delay Done
    
    DEC vib_delay1_C                             ; Decrease Vibrato Delay Timer
    BNE TEST_PORT_C                              ; Still Waiting: Skip Vibrato

@VIB_STARTED_C:
    LDA freq_C                                   ; Get Period
    LDX freq_C+1
    LDY flip1_C                                  ; Get Vibrato Direction
    BEQ @VIB_DOWN_C

@VIB_UP_C:
    CLC                                          ; Period += Vibrato Rate
    ADC vib_rate_C
    BCC @VIB_DONE_C
    INX
    BNE @VIB_DONE_C

@VIB_DOWN_C:
    SEC                                          ; Period -= Vibrato Rate
    SBC vib_rate_C
    BCS @VIB_DONE_C
    DEX

@VIB_DONE_C:
    STA freq_C                                   ; Store New Period
    STA $400A                                    ; Write New Period
    STX freq_C+1
    CPX oldfreq_C
    BEQ @VIB_CNT_C
    STX oldfreq_C
    STX $400B

@VIB_CNT_C:
    DEC vib_limit1_C                             ; Decrease Swing Length
    BNE TEST_PORT_C                              ; Still Waiting: Don't Reverse Direction

    LDA vib_limit2_C
    BEQ TEST_PORT_C                              ; 0 = Don't Reverse Direction
    ASL                                          ; Reload Swing Length * 2
    STA vib_limit1_C

    LDA flip1_C                                  ; Switch Vibrato Direction
    EOR #$FF
    STA flip1_C
    JMP TEST_PORT_C

;------------------------------------------------------------------------------
; Channel C - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_C:
    LDA wob_wait_C
    BEQ TEST_PORT_C                              ; 0 = No Wobble

    DEC wob_wait_C                               ; Decrease Wobble Timer
    BNE TEST_PORT_C                              ; Still Waiting: Skip Wobble

    LDA flip1_C                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_C
    BEQ @WOB_DOWN_C

@WOB_UP_C:
    LDA wob_delay1_C                             ; Wobble Timer = Up Timer
    STA wob_wait_C
    LDA old_note_C                               ; Note += Wobble
    CLC
    ADC wob_off_C
    JMP RESOUND_C

@WOB_DOWN_C:
    LDA wob_delay2_C                             ; Wobble Timer = Down Timer
    STA wob_wait_C
    LDA old_note_C                               ; Note -= Wobble
    SEC
    SBC wob_off_C
    JMP RESOUND_C

;------------------------------------------------------------------------------
; Channel C - Slide Handler
;------------------------------------------------------------------------------

TEST_PORT_C:
    LDA port_C
    BEQ DO_CHANNEL_D                             ; 0 = No Slide

    LDA old_note_C                               ; Check Note vs Slide Target
    CMP target_C
    BCC @PORT_UP_C                               ; Note < Slide Target: Slide Up
    BEQ DO_CHANNEL_D                             ; Note = Slide Target: Finished

@PORT_DOWN_C:
    SBC port_C                                   ; Note -= Slide
    CMP target_C
    BCS RESOUND_C                                ; Note >= Slide Target: Use this Note
    BCC @CLAMP_PORT_C                            ; Past Slide Target: Stop at Target

@PORT_UP_C:
    ADC port_C                                   ; Note += Slide
    CMP target_C
    BCC RESOUND_C                                ; Note < Slide Target: Use this Note

@CLAMP_PORT_C:
    LDA target_C                                 ; Note = Slide Target

;------------------------------------------------------------------------------
; Update Note Frequency Period
;------------------------------------------------------------------------------

RESOUND_C:

    STA old_note_C                               ; Store Updated Note

    TAX                                          ; X = Updated Note

    LDA Notes_LO,X                               ; Store Updated Period Lo += Distort
    CLC
    ADC distort_C
    STA freq_C
    STA $400A                                    ; Write Period Lo

    LDA Notes_HI,X                               ; Store Upddated Period Hi
    ADC #0
    STA freq_C+1

    CMP oldfreq_C                                ; Same Frequency Hi?
    BEQ DO_CHANNEL_D                             ; Yes: No Register Write
    STA oldfreq_C                                ; Store New Note Period Hi
    STA $400B                                    ; Write Period Hi

;------------------------------------------------------------------------------
; Check Channel D Active
;------------------------------------------------------------------------------

DO_CHANNEL_D:
    LDA stop_D
    BMI TEST_COUNT_D                             ; bit 7: Clear = Stopped and Set = Active
    JMP DO_CHANNEL_E                             ; Stopped: Next Channel

;------------------------------------------------------------------------------
; Check Channel D Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_D:
    DEC count_D                                  ; Reduce note duration
    BEQ DO_D                                     ; Note finished?: Fetch Next Stream Event
    JMP DO_ENV_D                                 ; Note playing

;------------------------------------------------------------------------------
; Advance Channel D Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_D:
    TYA                                          ; PC += Y
    CLC
    ADC PC_D
    STA PC_D
    BCC DO_D
    INC PC_D+1

;------------------------------------------------------------------------------
; Fetch Next Channel D Stream Event
;------------------------------------------------------------------------------

DO_D:
    LDY #0
    LDA (PC_D),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_D                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel D Command Handler
;------------------------------------------------------------------------------

COMMAND_D:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_D-128,X
    PHA
    LDA JUMP_LO_D-128,X
    PHA
    RTS                                          ; Return to the Handler

;------------------------------------------------------------------------------
; Channel D Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_D:

;------------------------------------------------------------------------------
; Channel D - Store Current Note
;------------------------------------------------------------------------------

    ORA or_D                                     ; Note | Periodic Noise Mode
    STA old_note_D
    
;------------------------------------------------------------------------------
; Channel D - Get Note Duration
;------------------------------------------------------------------------------

    LDA length_D
    BNE @GOT_LENGTH_D                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_D),Y
@GOT_LENGTH_D:
    STA count_D                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_D
    STA PC_D
    BCC @INPAGE_D
    INC PC_D+1
@INPAGE_D:
    
;------------------------------------------------------------------------------
; Channel D Initialize Wobble
;------------------------------------------------------------------------------

    LDX wob_delay1_D                             ; Wobble Wait Timer = Up Timer + 1
    INX
    STX wob_wait_D

    LDA #0                                       ; Store Initial Wobble Direction
    STA flip1_D

;------------------------------------------------------------------------------
; Channel D - Initialize Volume Envelope
;------------------------------------------------------------------------------

INIT_ENV_D:
    LDA ADSR_control_D
    BEQ EFF_START_D                              ; 0 = Don't Restart ADSR
    BPL INIT_ADSR_D                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel D - Initialize Volume Envelope Table Mode
;------------------------------------------------------------------------------

    ; Determine the Hold Exit
    LDA cutoff_D
    BEQ @CHECK_ENV_END_D                          ; 0 = No Cutoff

    CMP count_D                                   ; Cutoff < Note Duration?
    BCC @SET_ENV_RELEASE_D                        ; Yes: Hold Exit = cutoff frames after note start

@CHECK_ENV_END_D:
    LDA endit_D
    BEQ @SET_ENV_RELEASE_D                        ; 0 = No Endit

    LDA count_D                                   ; Hold Exit = endit frames before note end
    SEC
    SBC endit_D

@SET_ENV_RELEASE_D:
    STA maul_D                                   ; Store Hold Exit Timer

    LDY #1
    STY ADSR_time_D                              ; Timer = 1
    DEY
    STY ADSR_dec_D                               ; Table Index = 0
    DEY
    STY ADSR_stage_D                             ; Stage = -1
    BMI EFF_START_D

;------------------------------------------------------------------------------
; Channel D - Intialize ADSR Mode
;------------------------------------------------------------------------------

INIT_ADSR_D:
    LDX ADSR_cyc_D                               ; Set Initial Stage
    STX ADSR_stage_D
    LDA ADSR_att_D,X                             ; Set Initial Timer
    STA ADSR_time_D
    LDA ADSR_init_D                              ; Set Initial Volume
    STA volume_D

;------------------------------------------------------------------------------
; Channel D - Write Note Period
;------------------------------------------------------------------------------

EFF_START_D:
    LDA old_note_D
    BEQ @WRITE_PERIOD_LO_D                       ; 0 = No Volume

    LDA eff_time_D
    BEQ @USE_NOTE_D                              ; 0 = No Effect

    STA eff_wait_D                               ; Store Effect Timer
    
    LDA eff_freq_D                               ; Write Effect Period
    .BYTE $2C                                    ; OpCode Trick
@USE_NOTE_D:
    LDA old_note_D                               ; Write Note Period

@WRITE_PERIOD_LO_D:

    LDY stop_E                                   ; Channel E in Control?
    BMI DO_ENV_D                                 ; Yes: No Register Writes

    STA $400E                                    ; Write Note Period
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; Channel D - Envelope Handler
;------------------------------------------------------------------------------

DO_ENV_D:
    LDA ADSR_stage_D
    BMI START_ENV_D                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel D - Do ADSR Mode
;------------------------------------------------------------------------------

TEST_ATTACK_D:
    BNE @TEST_DECAY_D                             ; Not Stage 0 (Attack), Test Decay Stage

    ; Attack Cycle
    DEC ADSR_time_D                              ; Decrease Attack Timer
    BPL END_ADSR_D                               ; Still Waiting: Current Attack Volume

    LDA ADSR_att_D                               ; Reload Attack Timer
    STA ADSR_time_D
    INC volume_D                                 ; Volume += 1

    LDA volume_D
    CMP #15                                      ; Reached Max Volume?
    BNE END_ADSR_D                               ; No: Stay in Attack Stage
    INC ADSR_stage_D                             ; Set to Stage 1 = Decay
    LDA ADSR_dec_D                               ; Load the Decay Timer
    STA ADSR_time_D
    BNE END_ADSR_D

@TEST_DECAY_D:
    CMP #1
    BNE END_ADSR_D                               ; Not Stage 1 (Decay), Sustain Current Volume

    ; Decay Cycle
    DEC ADSR_time_D                              ; Decrease Decay Timer
    BPL END_ADSR_D                               ; Still Waiting: Current Decay Volume

    LDA ADSR_dec_D                               ; Reload Decay Timer
    STA ADSR_time_D

    LDA volume_D
    CMP ADSR_sus_D                               ; Reached Sustain Volume?
    BEQ @SET_SUS_D                               ; Yes: Set to Sustain Stage

    DEC volume_D                                 ; Volume -= 1
    BPL END_ADSR_D                               ; Stay in Decay Stage

@SET_SUS_D:
    INC ADSR_stage_D                             ; Set to Stage 2 = Sustain
    JMP END_ADSR_D

;------------------------------------------------------------------------------
; Channel D - Do Volume Envelope Table Mode
;------------------------------------------------------------------------------

START_ENV_D:
    LDA maul_D
    BEQ @ENV_STEP_D                              ; 0 = No Hold Exit

    DEC maul_D                                   ; Decrease Hold Exit Timer
    BNE @ENV_STEP_D                              ; Still Waiting: Don't Exit Hold

    LDA #1                                       ; Force Table Step
    STA ADSR_time_D
    INC ADSR_dec_D                               ; Next Table Index (Step Past Hold Entry)

@ENV_STEP_D:
    DEC ADSR_time_D                              ; Decrease Step Timer
    BNE END_ADSR_D                               ; Still Waiting: Current Volume

    LDY ADSR_dec_D                               ; Read Volume Envelope Entry
    LDA (point_D),Y
    BMI END_ADSR_D                               ; bit 7: Set = Hold Current Volume

    CMP #16
    BCC @ENV_DONE_D                              ; Entry < 16 = Volume
    LDY #0                                       ; Restart Volume Envelope Table
    LDA (point_D),Y

@ENV_DONE_D:
    STA volume_D                                 ; Store New Volume
    LDA time_D                                   ; Reload Step Timer
    STA ADSR_time_D
    INY                                          ; Advance Table Index
    STY ADSR_dec_D

;------------------------------------------------------------------------------
; Channel D - Write Volume
;------------------------------------------------------------------------------

END_ADSR_D:
    LDA volume_D
    ORA #%00110000
    STA $400C

;------------------------------------------------------------------------------
; Channel D - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_D:
    LDA eff_time_D
    BEQ TEST_WOB_D                               ; 0 = No Effect

    LDA eff_wait_D                               ; Effect Still Playing?
    BEQ TEST_WOB_D                               ; 0 = Effect Done

    DEC eff_wait_D                               ; Decrease Effect Timer
    BEQ @EFF_END_D                               ; 0 = Effect Done
    JMP DO_CHANNEL_E                             ; Next Channel

@EFF_END_D:
    LDY stop_E                                   ; Channel E in Control?
    BMI TEST_WOB_D                               ; Yes: No Register Writes

    LDA old_note_D                               ; Restore Note Period
    STA $400E
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; Channel D - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_D:
    LDA wob_wait_D
    BEQ DO_CHANNEL_E                             ; 0 = No Wobble

    DEC wob_wait_D                               ; Decrease Wobble Timer
    BNE DO_CHANNEL_E                             ; Still Waiting: Skip Wobble

    LDA flip1_D                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_D
    BEQ @WOB_DOWN_D

@WOB_UP_D:
    LDA wob_delay1_D                             ; Wobble Timer = Up Timer
    STA wob_wait_D
    LDA old_note_D                               ; Note += Wobble
    CLC
    ADC wob_off_D
    JMP RESOUND_D

@WOB_DOWN_D:
    LDA wob_delay2_D                             ; Wobble Timer = Down Timer
    STA wob_wait_D
    LDA old_note_D                               ; Note -= Wobble
    SEC
    SBC wob_off_D

;------------------------------------------------------------------------------
; Channel D - Update Note Period
;------------------------------------------------------------------------------

RESOUND_D:
    STA old_note_D                               ; Store Updated Note

    LDY stop_E                                   ; Channel E in Control?
    BMI TEST_COUNT_E                             ; Yes: No Register Writes

    STA $400E                                    ; Write Period
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; Check Channel E Active
;------------------------------------------------------------------------------

DO_CHANNEL_E:
    LDA stop_E
    BMI TEST_COUNT_E                             ; bit 7: Clear = Stopped and Set = Active
    JMP THE_END                                  ; Stopped: Finish

;------------------------------------------------------------------------------
; Check Channel E Note Duration
;------------------------------------------------------------------------------

TEST_COUNT_E:
    DEC count_E                                  ; Reduce note duration
    BEQ DO_E                                     ; Note finished?: Fetch Next Stream Event
    JMP DO_ENV_E                                 ; Note playing

;------------------------------------------------------------------------------
; Advance Channel E Pointer
;------------------------------------------------------------------------------

ADVANCE_PC_E:
    TYA                                          ; PC += Y
    CLC
    ADC PC_E
    STA PC_E
    BCC DO_E
    INC PC_E+1

;------------------------------------------------------------------------------
; Fetch Next Channel E Stream Event
;------------------------------------------------------------------------------

DO_E:
    LDY #0
    LDA (PC_E),Y                                 ; Read the Stream Event
    BPL GOT_NOTE_E                               ; bit 7: Clear = Note and Set = Command

;------------------------------------------------------------------------------
; Channel E Command Handler
;------------------------------------------------------------------------------

COMMAND_E:
    INY
    TAX                                          ; Push Handler Address - 1
    LDA JUMP_HI_E-128,X
    PHA
    LDA JUMP_LO_E-128,X
    PHA
    RTS                                          ; Return to the Handler

;------------------------------------------------------------------------------
; Channel E Note Handler
;------------------------------------------------------------------------------

GOT_NOTE_E:

;------------------------------------------------------------------------------
; Channel E - Store Current Note
;------------------------------------------------------------------------------

    ORA or_E                                     ; Note | Periodic Noise Mode
    STA old_note_E
    
;------------------------------------------------------------------------------
; Channel E - Get Note Duration
;------------------------------------------------------------------------------

    LDA length_E
    BNE @GOT_LENGTH_E                            ; Non 0 = Fixed Duration

    INY                                          ; Fetch Note Duration
    LDA (PC_E),Y
@GOT_LENGTH_E:
    STA count_E                                  ; Store Note Duration

    INY                                          ; Advance Pointer
    TYA
    CLC
    ADC PC_E
    STA PC_E
    BCC @INPAGE_E
    INC PC_E+1
@INPAGE_E:
    
;------------------------------------------------------------------------------
; Channel E - Initialize Wobble
;------------------------------------------------------------------------------

    LDX wob_delay1_E                             ; Wobble Wait Timer = Up Timer + 1
    INX
    STX wob_wait_E
    
    LDA #0                                       ; Set Initial Wobble Direction
    STA flip1_E

;------------------------------------------------------------------------------
; Channel E - Initialize Volume Envelope
;------------------------------------------------------------------------------

INIT_ENV_E:
    LDA ADSR_control_E
    BEQ EFF_START_E                              ; 0 = Don't Restart ADSR
    BPL INIT_ADSR_E                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Volume Envelope Table
;------------------------------------------------------------------------------

    ; Determine the Hold Exit
    LDA cutoff_E
    BEQ @CHECK_ENV_END_E                          ; 0 = No Cutoff

    CMP count_E                                   ; Cutoff < Note Duration
    BCC @SET_ENV_RELEASE_E                        ; Yes: Hold Exit = cutoff frames after note start

@CHECK_ENV_END_E:
    LDA endit_E
    BEQ @SET_ENV_RELEASE_E                        ; 0 = No Endit

    LDA count_E                                   ; Hold Exit = endit frames before note end
    SEC
    SBC endit_E

@SET_ENV_RELEASE_E:
    STA maul_E                                    ; Store Hold Exit Timer

    LDY #1
    STY ADSR_time_E                               ; Timer = 1
    DEY
    STY ADSR_dec_E                                ; Table Index = 0
    DEY
    STY ADSR_stage_E                              ; Stage = -1
    BMI EFF_START_E

;------------------------------------------------------------------------------
; Channel E - Initialize ADSR Mode
;------------------------------------------------------------------------------

INIT_ADSR_E:
    LDX ADSR_cyc_E                               ; Set Initial Stage
    STX ADSR_stage_E
    LDA ADSR_att_E,X                             ; Set Initial Timer
    STA ADSR_time_E
    LDA ADSR_init_E                              ; Set Initial Volume
    STA volume_E

;------------------------------------------------------------------------------
; Channel E - Write Note Period
;------------------------------------------------------------------------------

EFF_START_E:
    LDA old_note_E
    BEQ @WRITE_PERIOD_LO_E                       ; 0 = No Volume

    LDA eff_time_E
    BEQ @USE_NOTE_E                              ; 0 = No Effect

    STA eff_wait_E                               ; Store Effect Timer

    LDA eff_freq_E                               ; Write Effect Period
    .BYTE $2C                                    ; OpCode Trick
@USE_NOTE_E:
    LDA old_note_E                               ; Write Note Period
@WRITE_PERIOD_LO_E:
    STA $400E                                    ; Write Frequency Period
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; Channel E - Envelope Handler
;------------------------------------------------------------------------------

DO_ENV_E:
    LDA ADSR_stage_E
    BMI START_ENV_E                              ; bit 7: Clear = ADSR and Set = Volume Envelope Table

;------------------------------------------------------------------------------
; Channel E - Do ADSR Mode
;------------------------------------------------------------------------------

TEST_ATTACK_E:
    BNE @TEST_DECAY_E                            ; Not Stage 0 (Attack), Test Decay Stage

    ; Attack Cycle
    DEC ADSR_time_E                              ; Decrease Attack Timer
    BPL END_ADSR_E                               ; Still Waiting: Current Attack Volume

    LDA ADSR_att_E                               ; Reload Attack Timer
    STA ADSR_time_E
    INC volume_E                                 ; Volume += 1

    LDA volume_E
    CMP #15                                      ; Reached Max Volume?
    BNE END_ADSR_E                               ; No: Stay in Attack Stage
    INC ADSR_stage_E                             ; Set to Stage 1 = Decay
    LDA ADSR_dec_E                               ; Load the Decay Timer
    STA ADSR_time_E
    BNE END_ADSR_E

@TEST_DECAY_E:
    CMP #1
    BNE END_ADSR_E                               ; Not Stage 1 (Decay), Sustain Current Volume

    ; Decay Cyle
    DEC ADSR_time_E                              ; Decrease Decay Timer
    BPL END_ADSR_E                               ; Still Waiting: Current Decay Volume

    LDA ADSR_dec_E                               ; Reload Decay Timer
    STA ADSR_time_E

    LDA volume_E
    CMP ADSR_sus_E                               ; Reached Sustain Volume?
    BEQ @SET_SUS_E                               ; Yes: Set to Sustain Stage

    DEC volume_E                                 ; Volume -= 1
    BPL END_ADSR_E                               ; Stay in Decay Stage

@SET_SUS_E:
    INC ADSR_stage_E                             ; Set to Stage 2 = Sustain
    JMP END_ADSR_E

;------------------------------------------------------------------------------
; Channel E - Do Volume Envelope Table Mode
;------------------------------------------------------------------------------

START_ENV_E:
    LDA maul_E
    BEQ @ENV_STEP_E                              ; 0 = No Hold Exit

    DEC maul_E                                   ; Decrease Hold Exit Timer
    BNE @ENV_STEP_E                              ; Still Waiting: Don't Exit Hold

    LDA #1                                       ; Force Table Stop
    STA ADSR_time_E
    INC ADSR_dec_E                               ; Next Table Index (Step Past Hold Entry)

@ENV_STEP_E:
    DEC ADSR_time_E                              ; Decrease Step Timer
    BNE END_ADSR_E                               ; Still Waiting: Current Volume

    LDY ADSR_dec_E                               ; Read Volume Envelope Entry
    LDA (point_E),Y
    BMI END_ADSR_E                               ; bit 7: Set = Hold Current Volume

    CMP #16
    BCC @ENV_DONE_E                              ; Entry < 16 = Volume
    LDY #0                                       ; Restart Volume Envelope Table
    LDA (point_E),Y

@ENV_DONE_E:
    STA volume_E                                 ; Store New Volume
    LDA time_E                                   ; Reload Step Timer
    STA ADSR_time_E
    INY                                          ; Advance Table Index
    STY ADSR_dec_E

;------------------------------------------------------------------------------
; Channel E - Write Volume
;------------------------------------------------------------------------------

END_ADSR_E:
    LDA volume_E
    ORA #%00110000
    STA $400C

;------------------------------------------------------------------------------
; Channel E - Frequency Effect Handler
;------------------------------------------------------------------------------

TEST_EFF_E:
    LDA eff_time_E
    BEQ TEST_WOB_E                               ; 0 = No Effect

    LDA eff_wait_E                               ; Effect Still Playing?
    BEQ TEST_WOB_E                               ; 0 = Effect Done

    DEC eff_wait_E                               ; Decrease Effect Timer
    BEQ @EFF_END_E                               ; 0 = Effect Done
    JMP THE_END                                  ; Next Channel

@EFF_END_E:
    LDA old_note_E                               ; Restore Note Period
    STA $400E
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; Channel E - Wobble Handler
;------------------------------------------------------------------------------

TEST_WOB_E:
    LDA wob_wait_E
    BEQ THE_END                                  ; 0 = No Wobble

    DEC wob_wait_E                               ; Decrease Wobble Timer
    BNE THE_END                                  ; Still Waiting: Skip Wobble

    LDA flip1_E                                  ; Flip Wobble Direction
    EOR #$FF
    STA flip1_E
    BEQ @WOB_DOWN_E

@WOB_UP_E:
    LDA wob_delay1_E                             ; Wobble Timer = Up Timer
    STA wob_wait_E
    LDA old_note_E                               ; Note += Wobble
    CLC
    ADC wob_off_E
    JMP RESOUND_E

@WOB_DOWN_E:
    LDA wob_delay2_E                             ; Wobble Timer = Down Timer
    STA wob_wait_E
    LDA old_note_E                               ; Note -= Wobble
    SEC
    SBC wob_off_E

;------------------------------------------------------------------------------
; Channel E - Update Note Period
;------------------------------------------------------------------------------

RESOUND_E:
    STA old_note_E                               ; Store Updated Note
    STA $400E                                    ; Write Period
    LDA #%00000011
    STA $400F

;------------------------------------------------------------------------------
; THE_END
;
; Routine called to determine if tune is active ($FF = active and $00 = off).
;------------------------------------------------------------------------------

THE_END:
    .export THE_END
    LDA stop_A
    ORA stop_B
    ORA stop_C
    ORA stop_D
; NOTE: some versions contain one or both of channel E and F here.
;    ORA stop_E
;    ORA stop_F
    RTS

;------------------------------------------------------------------------------
; FX_END
;
; Routine called to determine if SFX is active ($FF = active and $00 = off).
;------------------------------------------------------------------------------

FX_END:
    .export FX_END
    LDA stop_E
    ORA stop_F
    RTS

NONE:
    RTS

;------------------------------------------------------------------------------
; Channel A Commands
;------------------------------------------------------------------------------

JUMP_LO_A:
    .LOBYTES A_FOR-1, A_NEXT-1, A_LEN-1, A_STOP-1, A_GOSUB-1, A_RETURN-1, A_TRANS-1, A_DISTORT-1
    .LOBYTES A_GOTO-1, A_SEND-1, A_ADSR-1, A_ENVON-1, A_WOBBLE-1, A_PORT-1, A_DUTY-1, A_VIBRATO-1
    .LOBYTES A_IGNORE-1, A_EFFECT-1, A_TABLE-1, A_CUTOFF-1, A_ENDIT-1, A_SWEEP-1

JUMP_HI_A:
    .HIBYTES A_FOR-1, A_NEXT-1, A_LEN-1, A_STOP-1, A_GOSUB-1, A_RETURN-1, A_TRANS-1, A_DISTORT-1
    .HIBYTES A_GOTO-1, A_SEND-1, A_ADSR-1, A_ENVON-1, A_WOBBLE-1, A_PORT-1, A_DUTY-1, A_VIBRATO-1
    .HIBYTES A_IGNORE-1, A_EFFECT-1, A_TABLE-1, A_CUTOFF-1, A_ENDIT-1, A_SWEEP-1

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

A_FOR:
    LDA (PC_A),Y                                 ; Repeat Count
    INY
    STA repeat_A
    LDA PC_A                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_A                                  ; Save Loop Start Address
    STA PC_A
    LDA PC_A+1
    ADC #0
    STA stack_A+1
    STA PC_A+1
    JMP DO_A

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

A_NEXT:
    DEC repeat_A                                 ; Repeat Count -= 1
    BEQ A_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_A                                  ; Back to Loop Start Address
    STA PC_A
    LDA stack_A+1
    STA PC_A+1
    JMP DO_A

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

A_LEN:
    LDA (PC_A),Y
    STA length_A                                 ; Fixed Note Duration
    INY
A_GOADDY:
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

A_STOP:
    INC stop_A                                   ; $FF -> $00: bit 7 Clear = Stopped
    LDA #%00110000                               ; Silence A Channel
    STA $4000
    JMP DO_CHANNEL_F

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

A_GOSUB:
    LDX sp_A                                     ; Get Stack Slot
    LDA PC_A                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_A,X
    LDA PC_A+1
    ADC #0
    STA stack_HI_A,X
    INX                                          ; Next Stack Slot
    STX sp_A
A_GOTO:
    LDA (PC_A),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_A),Y                                 ; Target Address Hi
    STA PC_A+1
    STX PC_A
    JMP DO_A

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

A_RETURN:
    DEC sp_A                                     ; Previous Stack Slot
    LDX sp_A
    LDA stack_LO_A,X                             ; Return Address
    STA PC_A
    LDA stack_HI_A,X
    STA PC_A+1
    JMP DO_A

;------------------------------------------------------------------------------
; $86 - TRANS semitones
;
; Applies a signed semitone offset to all following notes.
;------------------------------------------------------------------------------

A_TRANS:
    LDA (PC_A),Y
    STA transpose_A                              ; Transpose in Semitones (signed)
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $87 - DISTORT value
;
; Applies an unsigned detune offset. The value is added directly to all
; following note periods.
;------------------------------------------------------------------------------

A_DISTORT:
    LDA (PC_A),Y
    STA distort_A                                ; Period Offset (unsigned)
A_GOADDY1:
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

A_SEND:
    LDA (PC_A),Y                                 ; Register to Write
    BMI A_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_A),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE A_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8A - ADSR volumes, speeds, stage
;
; Configures the ADSR envelope parameters. Use ENVON to select the envelope
; mode.
;   byte 1:   iiiissss   i = Starting Volume (0-15), s = Sustain Volume (0-15)
;   byte 2:   aaaadddd   a = Attack Speed (0-15), d = Decay Speed (0-15)
;   byte 3:   starting stage: 0 = Attack, 1 = Decay, 2 = Sustain
; Both speed values act as frame timers: volume updates once every (speed + 1)
; frames. Attack always ramps to 15 before Decay drops to the Sustain Volume.
; WARNING: Avoid invoking ADSR when table mode is active.
;------------------------------------------------------------------------------

A_ADSR:
    LDA (PC_A),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_init_A                              ; Initial Volume
    LDA (PC_A),Y
    AND #$0F
    STA ADSR_sus_A                               ; Sustain Volume
    INY
    LDA (PC_A),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_att_A                               ; Attack Speed Timer
    LDA (PC_A),Y
    AND #$0F
    STA ADSR_dec_A                               ; Decay Speed Timer
    INY
    LDA (PC_A),Y
    STA ADSR_cyc_A                               ; Initial Stage
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $8B - ENVON mode
;
; Select which volume envelope mode will be used when each new note starts.
;   $00 = Legato mode: ADSR envelope persists across notes without resetting
;   $01-$7F = ADSR mode (configured with ADSR)
;   $80-$FF = Envelope Table Mode (configured with TABLE)
;------------------------------------------------------------------------------

A_ENVON:
    LDA (PC_A),Y
    STA ADSR_control_A                           ; Envelope Mode
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

A_WOBBLE:
    LDA (PC_A),Y
    STA wob_off_A                                ; Note Offset in Semitones
    INY
    LDA (PC_A),Y
    STA wob_delay1_A                             ; Up Timer
    INY
    LDA (PC_A),Y
    STA wob_delay2_A                             ; Down Timer
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $8D - PORT speed
;
; Sets the speed of the pitch slide in semitones per frame. A value of 0
; disables. When active, each following note acts as a target frequency and the
; channel steps toward it incrementally each frame.
;------------------------------------------------------------------------------

A_PORT:
    LDA (PC_A),Y
    STA port_A                                   ; Slide Speed in Semitones
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $8E - DUTY value
;
; Configures the upper bits of register $4000 which are combined with the
; volume bits (0-3) each frame.
;   bits 7-6:   Duty cycle waveform
;   bit 5:      Length counter halt flag
;   bit 4:      Constant volume flag
;------------------------------------------------------------------------------

A_DUTY:
    LDA (PC_A),Y
    STA duty_A                                   ; Duty
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $8F - VIBRATO delay, rate, limit, direction
;
; Variable length command format:
;   delay = 0   Disable vibrato. Consumes 2 bytes.
;   delay <> 0  Consumes 5 bytes to configure all parameters.
;
;   delay = Delays the start by N-1 frames
;   rate = Period units added or subtracted each frame
;   limit = Number of frames in the first swing and later swings doubled. A
;           value of 0 never reverses direction.
;   direction = Initial swing direction: $00 = decrement and $FF = increment
;------------------------------------------------------------------------------

A_VIBRATO:
    LDA (PC_A),Y
    STA vib_delay_A                              ; Delay timer (0 = Off) 
    BEQ @skip                                    ; Off: Skip Operands
    INY
    LDA (PC_A),Y
    STA vib_rate_A                               ; Period Per Frame
    INY
    LDA (PC_A),Y
    STA vib_limit2_A                             ; Swing Length
    INY
    LDA (PC_A),Y
    STA vib_dir_A                                ; Starting Direction
@skip:
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $90 - IGNORE
;
; Skips the transposition of the next note only.
;------------------------------------------------------------------------------

A_IGNORE:
    LDA #$FF
    STA ignore_A                                 ; Skip Transpose for Next Note
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

A_EFFECT:
    LDA (PC_A),Y
    STA eff_time_A                               ; Effect Length in Frames
    INY
    LDA (PC_A),Y
    STA eff_freq_A                               ; Effect Period Lo
    INY
    LDA (PC_A),Y
    STA eff_freq_A+1                             ; Effect Period Hi
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $92 - TABLE step_time, address
;
; Sets to Envelope Table Mode and the address for the volume table to be used.
;   step_time = Number of frames per table step
;   address = Pointer to the table data (low byte, high byte)
;------------------------------------------------------------------------------

A_TABLE:
    LDA (PC_A),Y
    STA time_A                                   ; Frames Per Table Entry
    INY
    LDA (PC_A),Y
    STA point_A                                  ; Table Address Lo
    INY
    LDA (PC_A),Y
    STA point_A+1                                ; Table Address Hi
    INY
    LDA #$FF
    STA ADSR_control_A                           ; Table Mode
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $93 - CUTOFF frames
; $94 - ENDIT frames
;
; These commands are only used in table envelope mode. They control when a note
; exits the table's hold state to advance to the entries that follow.
;   CUTOFF = Elapsed frames from note's start. Ignored if cutoff > duration
;   ENDIT = Remaining frames from note's end. Ignored if cutoff < duration
; Values of 0 disable.
;------------------------------------------------------------------------------

A_CUTOFF:
    LDA (PC_A),Y
    STA cutoff_A                                 ; Hold Exit: Frames After Note Start
    INY
    JMP ADVANCE_PC_A

A_ENDIT:
    LDA (PC_A),Y
    STA endit_A                                  ; Hold Exit: Frames Before Note End
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; $95 - SWEEP value
;
; Sets the value written to $4001 for each following note.
; Format: EPPPNSSS   E: Enable, P: Period, N: Negate, S: Shift
;------------------------------------------------------------------------------

A_SWEEP:
    LDA (PC_A),Y
    STA sweep_A                                  ; Sweep Register Value
    INY
    JMP ADVANCE_PC_A

;------------------------------------------------------------------------------
; Channel B Commands
;------------------------------------------------------------------------------

JUMP_LO_B:
    .LOBYTES B_FOR-1, B_NEXT-1, B_LEN-1, B_STOP-1, B_GOSUB-1, B_RETURN-1, B_TRANS-1, B_DISTORT-1
    .LOBYTES B_GOTO-1, B_SEND-1, B_ADSR-1, B_ENVON-1, B_WOBBLE-1, B_PORT-1, B_DUTY-1, B_VIBRATO-1
    .LOBYTES B_IGNORE-1, B_EFFECT-1, B_TABLE-1, B_CUTOFF-1, B_ENDIT-1, B_SWEEP-1

JUMP_HI_B:
    .HIBYTES B_FOR-1, B_NEXT-1, B_LEN-1, B_STOP-1, B_GOSUB-1, B_RETURN-1, B_TRANS-1, B_DISTORT-1
    .HIBYTES B_GOTO-1, B_SEND-1, B_ADSR-1, B_ENVON-1, B_WOBBLE-1, B_PORT-1, B_DUTY-1, B_VIBRATO-1
    .HIBYTES B_IGNORE-1, B_EFFECT-1, B_TABLE-1, B_CUTOFF-1, B_ENDIT-1, B_SWEEP-1

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

B_FOR:
    LDA (PC_B),Y                                 ; Repeat Count
    INY
    STA repeat_B
    LDA PC_B                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_B                                  ; Save Loop Start Address
    STA PC_B
    LDA PC_B+1
    ADC #0
    STA stack_B+1
    STA PC_B+1
    JMP DO_B

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

B_NEXT:
    DEC repeat_B                                 ; Repeat Count -= 1
    BEQ B_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_B                                  ; Back to Loop Start Address
    STA PC_B
    LDA stack_B+1
    STA PC_B+1
    JMP DO_B

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

B_LEN:
    LDA (PC_B),Y
    STA length_B                                 ; Fixed Note Duration
    INY
B_GOADDY:
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

B_STOP:
    INC stop_B                                   ; $FF -> $00: bit 7 Clear = Stopped
    LDA #%00110000                               ; Silence B Channel
    STA $4004
    JMP DO_CHANNEL_C

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

B_GOSUB:
    LDX sp_B                                     ; Get Stack Slot
    LDA PC_B                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_B,X
    LDA PC_B+1
    ADC #0
    STA stack_HI_B,X
    INX                                          ; Next Stack Slot
    STX sp_B
B_GOTO:
    LDA (PC_B),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_B),Y                                 ; Target Address Hi
    STA PC_B+1
    STX PC_B
    JMP DO_B

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

B_RETURN:
    DEC sp_B                                     ; Previous Stack Slot
    LDX sp_B
    LDA stack_LO_B,X                             ; Return Address
    STA PC_B
    LDA stack_HI_B,X
    STA PC_B+1
    JMP DO_B

;------------------------------------------------------------------------------
; $86 - TRANS semitones
;
; Applies a signed semitone offset to all following notes.
;------------------------------------------------------------------------------

B_TRANS:
    LDA (PC_B),Y
    STA transpose_B                              ; Transpose in Semitones (signed)
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $87 - DISTORT value
;
; Applies an unsigned detune offset. The value is added directly to all
; following note periods.
;------------------------------------------------------------------------------

B_DISTORT:
    LDA (PC_B),Y
    STA distort_B                                ; Period Offset (unsigned)
B_GOADDY1:
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

B_SEND:
    LDA (PC_B),Y                                 ; Register to Write
    BMI B_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_B),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE B_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8A - ADSR volumes, speeds, stage
;
; Configures the ADSR envelope parameters. Use ENVON to select the envelope
; mode.
;   byte 1:   iiiissss   i = Starting Volume (0-15), s = Sustain Volume (0-15)
;   byte 2:   aaaadddd   a = Attack Speed (0-15), d = Decay Speed (0-15)
;   byte 3:   starting stage: 0 = Attack, 1 = Decay, 2 = Sustain
; Both speed values act as frame timers: volume updates once every (speed + 1)
; frames. Attack always ramps to 15 before Decay drops to the Sustain Volume.
; WARNING: Avoid invoking ADSR when table mode is active.
;------------------------------------------------------------------------------

B_ADSR:
    LDA (PC_B),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_init_B                              ; Initial Volume
    LDA (PC_B),Y
    AND #$0F
    STA ADSR_sus_B                               ; Sustain Volume
    INY
    LDA (PC_B),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_att_B                               ; Attack Speed Timer
    LDA (PC_B),Y
    AND #$0F
    STA ADSR_dec_B                               ; Decay Speed Timer
    INY
    LDA (PC_B),Y
    STA ADSR_cyc_B                               ; Initial Stage
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $8B - ENVON mode
;
; Select which volume envelope mode will be used when each new note starts.
;   $00 = Legato mode: ADSR envelope persists across notes without resetting
;   $01-$7F = ADSR mode (configured with ADSR)
;   $80-$FF = Envelope Table Mode (configured with TABLE)
;------------------------------------------------------------------------------

B_ENVON:
    LDA (PC_B),Y
    STA ADSR_control_B                           ; Envelope Mode
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

B_WOBBLE:
    LDA (PC_B),Y
    STA wob_off_B                                ; Note Offset in Semitones
    INY
    LDA (PC_B),Y
    STA wob_delay1_B                             ; Up Timer
    INY
    LDA (PC_B),Y
    STA wob_delay2_B                             ; Down Timer
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $8D - PORT speed
;
; Sets the speed of the pitch slide in semitones per frame. A value of 0
; disables. When active, each following note acts as a target frequency and the
; channel steps toward it incrementally each frame.
;------------------------------------------------------------------------------

B_PORT:
    LDA (PC_B),Y
    STA port_B                                   ; Slide Speed in Semitones
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $8E - DUTY value
;
; Configures the upper bits of register $4004 which are combined with the
; volume bits (0-3) each frame.
;   bits 7-6:   Duty cycle waveform
;   bit 5:      Length counter halt flag
;   bit 4:      Constant volume flag
;------------------------------------------------------------------------------

B_DUTY:
    LDA (PC_B),Y
    STA duty_B                                   ; Duty
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $8F - VIBRATO delay, rate, limit, direction
;
; Variable length command format:
;   delay = 0   Disable vibrato. Consumes 2 bytes.
;   delay <> 0  Consumes 5 bytes to configure all parameters.
;
;   delay = Delays the start by N-1 frames
;   rate = Period units added or subtracted each frame
;   limit = Number of frames in the first swing and later swings doubled. A
;           value of 0 never reverses direction.
;   direction = Initial swing direction: $00 = decrement and $FF = increment
;------------------------------------------------------------------------------

B_VIBRATO:
    LDA (PC_B),Y
    STA vib_delay_B                              ; Delay timer (0 = Off)
    BEQ @skip                                    ; Off: Skip Operands
    INY
    LDA (PC_B),Y
    STA vib_rate_B                               ; Period Per Frame
    INY
    LDA (PC_B),Y
    STA vib_limit2_B                             ; Swing Length
    INY
    LDA (PC_B),Y
    STA vib_dir_B                                ; Starting direction
@skip:
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $90 - IGNORE
;
; Skips the transposition of the next note only.
;------------------------------------------------------------------------------

B_IGNORE:
    LDA #$FF
    STA ignore_B                                 ; Skip Transpose for Next Note
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

B_EFFECT:
    LDA (PC_B),Y
    STA eff_time_B                               ; Effect Length in Frames
    INY
    LDA (PC_B),Y
    STA eff_freq_B                               ; Effect Period Lo
    INY
    LDA (PC_B),Y
    STA eff_freq_B+1                             ; Effect Period Hi
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $92 - TABLE step_time, address
;
; Sets to Envelope Table Mode and the address for the volume table to be used.
;   step_time = Number of frames per table step
;   address = Pointer to the table data (low byte, high byte)
;------------------------------------------------------------------------------

B_TABLE:
    LDA (PC_B),Y
    STA time_B                                   ; Frame Per Table Entry
    INY
    LDA (PC_B),Y
    STA point_B                                  ; Table Address Lo
    INY
    LDA (PC_B),Y
    STA point_B+1                                ; Table Address Hi
    INY
    LDA #$FF
    STA ADSR_control_B                           ; Table Mode
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $93 - CUTOFF frames
; $94 - ENDIT frames
;
; These commands are only used in table envelope mode. They control when a note
; exits the table's hold state to advance to the entries that follow.
;   CUTOFF = Elapsed frames from note's start. Ignored if cutoff > duration
;   ENDIT = Remaining frames from note's end. Ignored if cutoff < duration
; Values of 0 disable.
;------------------------------------------------------------------------------

B_CUTOFF:
    LDA (PC_B),Y
    STA cutoff_B                                 ; Hold Exit: Frames After Note Start
    INY
    JMP ADVANCE_PC_B

B_ENDIT:
    LDA (PC_B),Y
    STA endit_B                                  ; Hold Exit: Frames Before Note End
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; $95 - SWEEP value
;
; Sets the value written to $4005 for each following note.
; Format: EPPPNSSS   E: Enable, P: Period, N: Negate, S: Shift
;------------------------------------------------------------------------------

B_SWEEP:
    LDA (PC_B),Y
    STA sweep_B                                  ; Sweep Register Value
    INY
    JMP ADVANCE_PC_B

;------------------------------------------------------------------------------
; Channel C Commands
;------------------------------------------------------------------------------

JUMP_LO_C:
    .LOBYTES C_FOR-1, C_NEXT-1, C_LEN-1, C_STOP-1, C_GOSUB-1, C_RETURN-1, C_TRANS-1, C_DISTORT-1
    .LOBYTES C_GOTO-1, C_SEND-1, NONE-1, NONE-1, C_WOBBLE-1, C_PORT-1, NONE-1, C_VIBRATO-1
    .LOBYTES C_IGNORE-1, C_EFFECT-1, NONE-1, NONE-1, NONE-1, NONE-1

JUMP_HI_C:
    .HIBYTES C_FOR-1, C_NEXT-1, C_LEN-1, C_STOP-1, C_GOSUB-1, C_RETURN-1, C_TRANS-1, C_DISTORT-1
    .HIBYTES C_GOTO-1, C_SEND-1, NONE-1, NONE-1, C_WOBBLE-1, C_PORT-1, NONE-1, C_VIBRATO-1
    .HIBYTES C_IGNORE-1, C_EFFECT-1, NONE-1, NONE-1, NONE-1, NONE-1

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

C_FOR:
    LDA (PC_C),Y                                 ; Repeat Count
    INY
    STA repeat_C
    LDA PC_C                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_C                                  ; Save Loop Start Address
    STA PC_C
    LDA PC_C+1
    ADC #0
    STA stack_C+1
    STA PC_C+1
    JMP DO_C

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

C_NEXT:
    DEC repeat_C                                 ; Repeact Count -= 1
    BEQ C_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_C                                  ; Back to Loop Start Address
    STA PC_C
    LDA stack_C+1
    STA PC_C+1
    JMP DO_C

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

C_LEN:
    LDA (PC_C),Y
    STA length_C                                 ; Fixed Note Duration
    INY
C_GOADDY:
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

C_STOP:
    INC stop_C                                   ; $FF -> $00: bit 7 Clear = Stopped
    LDA #%10000000                               ; Silence C Channel
    STA $4008
    JMP DO_CHANNEL_D

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

C_GOSUB:
    LDX sp_C                                     ; Get Stack Slot
    LDA PC_C                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_C,X
    LDA PC_C+1
    ADC #0
    STA stack_HI_C,X
    INX                                          ; Next Stack Slot
    STX sp_C
C_GOTO:
    LDA (PC_C),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_C),Y                                 ; Target Address Hi
    STA PC_C+1
    STX PC_C
    JMP DO_C

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

C_RETURN:
    DEC sp_C                                     ; Previous Stack Slot
    LDX sp_C
    LDA stack_LO_C,X                             ; Return Address
    STA PC_C
    LDA stack_HI_C,X
    STA PC_C+1
    JMP DO_C

;------------------------------------------------------------------------------
; $86 - TRANS semitones
;
; Applies a signed semitone offset to all following notes.
;------------------------------------------------------------------------------

C_TRANS:
    LDA (PC_C),Y
    STA transpose_C                              ; Transpose in Semitones (signed)
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $87 - DISTORT value
;
; Applies an unsigned detune offset. The value is added directly to all
; following note periods.
;------------------------------------------------------------------------------

C_DISTORT:
    LDA (PC_C),Y
    STA distort_C                                ; Period Offset (unsigned)
C_GOADDY1:
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

C_SEND:
    LDA (PC_C),Y                                 ; Register to Write
    BMI C_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_C),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE C_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

C_WOBBLE:
    LDA (PC_C),Y
    STA wob_off_C                                ; Note Offset in Semitones
    INY
    LDA (PC_C),Y
    STA wob_delay1_C                             ; Up Timer
    INY
    LDA (PC_C),Y
    STA wob_delay2_C                             ; Down Timer
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $8D - PORT speed
;
; Sets the speed of the pitch slide in semitones per frame. A value of 0
; disables. When active, each following note acts as a target frequency and the
; channel steps toward it incrementally each frame.
;------------------------------------------------------------------------------

C_PORT:
    LDA (PC_C),Y
    STA port_C                                   ; Slide Speed in Semitones
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $8F - VIBRATO delay, rate, limit, direction
;
; Variable length command format:
;   delay = 0   Disable vibrato. Consumes 2 bytes.
;   delay <> 0  Consumes 5 bytes to configure all parameters.
;
;   delay = Delays the start by N-1 frames
;   rate = Period units added or subtracted each frame
;   limit = Number of frames in the first swing and later swings doubled. A
;           value of 0 never reverses direction.
;   direction = Initial swing direction: $00 = decrement and $FF = increment
;------------------------------------------------------------------------------

C_VIBRATO:
    LDA (PC_C),Y
    STA vib_delay_C                              ; Delay timer (0 = Off)
    BEQ @skip                                    ; Off: Skip Operands
    INY
    LDA (PC_C),Y
    STA vib_rate_C                               ; Period Per Frame
    INY
    LDA (PC_C),Y
    STA vib_limit2_C                             ; Swing Length
    INY
    LDA (PC_C),Y                                 ; Starting direction
    STA vib_dir_C
@skip:
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $90 - IGNORE
;
; Skips the transposition of the next note only.
;------------------------------------------------------------------------------

C_IGNORE:
    LDA #$FF
    STA ignore_C                                 ; Skip Transpose for Next Note
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

C_EFFECT:
    LDA (PC_C),Y
    STA eff_time_C                               ; Effect Length in Frames
    INY
    LDA (PC_C),Y
    STA eff_freq_C                               ; Effect Period Lo
    INY
    LDA (PC_C),Y
    STA eff_freq_C+1                             ; Effect Period Hi
    INY
    JMP ADVANCE_PC_C

;------------------------------------------------------------------------------
; Channel D Commands
;------------------------------------------------------------------------------

JUMP_LO_D:
    .LOBYTES D_FOR-1, D_NEXT-1, D_LEN-1, D_STOP-1, D_GOSUB-1, D_RETURN-1, D_MINUS-1, D_PLUS-1
    .LOBYTES D_GOTO-1, D_SEND-1, D_ADSR-1, D_ENVON-1, D_WOBBLE-1, NONE-1, NONE-1, NONE-1
    .LOBYTES NONE-1, D_EFFECT-1, D_TABLE-1, D_CUTOFF-1, D_ENDIT-1, NONE-1

JUMP_HI_D:
    .HIBYTES D_FOR-1, D_NEXT-1, D_LEN-1, D_STOP-1, D_GOSUB-1, D_RETURN-1, D_MINUS-1, D_PLUS-1
    .HIBYTES D_GOTO-1, D_SEND-1, D_ADSR-1, D_ENVON-1, D_WOBBLE-1, NONE-1, NONE-1, NONE-1
    .HIBYTES NONE-1, D_EFFECT-1, D_TABLE-1, D_CUTOFF-1, D_ENDIT-1, NONE-1

;------------------------------------------------------------------------------
; $86 - MINUS
; $87 - PLUS
;
; Sets the Periodic Noise Mode in $400E
;   MINUS = Periodic Mode (93 steps)
;   PLUS = Normal Mode (32767 steps)
;------------------------------------------------------------------------------

D_MINUS:
    LDA #%10000000
    .BYTE $2C                                    ; OpCode Trick
D_PLUS:
    LDA #%00000000
    STA or_D                                     ; Periodic Noise Mode
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

D_FOR:
    LDA (PC_D),Y                                 ; Repeat Count
    INY
    STA repeat_D
    LDA PC_D                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_D                                  ; Save Loop Start Address
    STA PC_D
    LDA PC_D+1
    ADC #0
    STA stack_D+1
    STA PC_D+1
    JMP DO_D

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

D_NEXT:
    DEC repeat_D                                 ; Repeat Count -= 1
    BEQ D_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_D                                  ; Back to Loop Start Address
    STA PC_D
    LDA stack_D+1
    STA PC_D+1
    JMP DO_D

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

D_LEN:
    LDA (PC_D),Y
    STA length_D                                 ; Fixed Note Duration
    INY
D_GOADDY:
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

D_STOP:
    INC stop_D                                   ; $FF -> $00: bit 7 Clear = Stopped
    LDA #%00110000                               ; Silence D Channel
    STA $400C
    JMP DO_CHANNEL_E

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

D_GOSUB:
    LDX sp_D                                     ; Get Stack Slot
    LDA PC_D                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_D,X
    LDA PC_D+1
    ADC #0
    STA stack_HI_D,X
    INX                                          ; Next Stack Slot
    STX sp_D
D_GOTO:
    LDA (PC_D),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_D),Y                                 ; Target Address Hi
    STA PC_D+1
    STX PC_D
    JMP DO_D

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

D_RETURN:
    DEC sp_D                                     ; Previous Stack Slot
    LDX sp_D
    LDA stack_LO_D,X                             ; Return Address
    STA PC_D
    LDA stack_HI_D,X
    STA PC_D+1
    JMP DO_D

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

D_SEND:
    LDA (PC_D),Y                                 ; Register to Write
    BMI D_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_D),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE D_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8A - ADSR volumes, speeds, stage
;
; Configures the ADSR envelope parameters. Use ENVON to select the envelope
; mode.
;   byte 1:   iiiissss   i = Starting Volume (0-15), s = Sustain Volume (0-15)
;   byte 2:   aaaadddd   a = Attack Speed (0-15), d = Decay Speed (0-15)
;   byte 3:   starting stage: 0 = Attack, 1 = Decay, 2 = Sustain
; Both speed values act as frame timers: volume updates once every (speed + 1)
; frames. Attack always ramps to 15 before Decay drops to the Sustain Volume.
; WARNING: Avoid invoking ADSR when table mode is active.
;------------------------------------------------------------------------------

D_ADSR:
    LDA (PC_D),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_init_D                              ; Initial Volume
    LDA (PC_D),Y
    AND #$0F
    STA ADSR_sus_D                               ; Sustain Volume
    INY
    LDA (PC_D),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_att_D                               ; Attack Speed Timer
    LDA (PC_D),Y
    AND #$0F
    STA ADSR_dec_D                               ; Decay Speed Timer
    INY
    LDA (PC_D),Y
    STA ADSR_cyc_D                               ; Inital Stage
D_GOADDY1:
    INY
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $8B - ENVON mode
;
; Select which volume envelope mode will be used when each new note starts.
;   $00 = Legato mode: ADSR envelope persists across notes without resetting
;   $01-$7F = ADSR mode (configured with ADSR)
;   $80-$FF = Envelope Table Mode (configured with TABLE)
;------------------------------------------------------------------------------

D_ENVON:
    LDA (PC_D),Y
    STA ADSR_control_D                           ; Envelope Mode
    INY
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

D_WOBBLE:
    LDA (PC_D),Y
    STA wob_off_D                                ; Note Offset in Semitones
    INY
    LDA (PC_D),Y
    STA wob_delay1_D                             ; Up Timer
    INY
    LDA (PC_D),Y
    STA wob_delay2_D                             ; Down Timer
    INY
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

D_EFFECT:
    LDA (PC_D),Y
    STA eff_time_D                               ; Effect Length in Frames
    INY
    LDA (PC_D),Y
    STA eff_freq_D                               ; Effect Period
    INY
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $92 - TABLE step_time, address
;
; Sets to Envelope Table Mode and the address for the volume table to be used.
;   step_time = Number of frames per table step
;   address = Pointer to the table data (low byte, high byte)
;------------------------------------------------------------------------------

D_TABLE:
    LDA (PC_D),Y
    STA time_D                                   ; Frames Per Table Entry
    INY
    LDA (PC_D),Y
    STA point_D                                  ; Table Address Lo
    INY
    LDA (PC_D),Y
    STA point_D+1                                ; Table Address Hi
    INY
    LDA #$FF
    STA ADSR_control_D                           ; Table Mode
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; $93 - CUTOFF frames
; $94 - ENDIT frames
;
; These commands are only used in table envelope mode. They control when a note
; exits the table's hold state to advance to the entries that follow.
;   CUTOFF = Elapsed frames from note's start. Ignored if cutoff > duration
;   ENDIT = Remaining frames from note's end. Ignored if cutoff < duration
; Values of 0 disable.
;------------------------------------------------------------------------------

D_CUTOFF:
    LDA (PC_D),Y
    STA cutoff_D                                 ; Hold Exit: Frames After Note Start
    INY
    JMP ADVANCE_PC_D

D_ENDIT:
    LDA (PC_D),Y
    STA endit_D                                  ; Hold Exit: Frames Before Note End
    INY
    JMP ADVANCE_PC_D

;------------------------------------------------------------------------------
; Channel E Commands
;------------------------------------------------------------------------------

JUMP_LO_E:
    .LOBYTES E_FOR-1, E_NEXT-1, E_LEN-1, E_STOP-1, E_GOSUB-1, E_RETURN-1, E_MINUS-1, E_PLUS-1
    .LOBYTES E_GOTO-1, E_SEND-1, E_ADSR-1, E_ENVON-1, E_WOBBLE-1, NONE-1, NONE-1, NONE-1
    .LOBYTES NONE-1, E_EFFECT-1, E_TABLE-1, E_CUTOFF-1, E_ENDIT-1, NONE-1

JUMP_HI_E:
    .HIBYTES E_FOR-1, E_NEXT-1, E_LEN-1, E_STOP-1, E_GOSUB-1, E_RETURN-1, E_MINUS-1, E_PLUS-1
    .HIBYTES E_GOTO-1, E_SEND-1, E_ADSR-1, E_ENVON-1, E_WOBBLE-1, NONE-1, NONE-1, NONE-1
    .HIBYTES NONE-1, E_EFFECT-1, E_TABLE-1, E_CUTOFF-1, E_ENDIT-1, NONE-1

;------------------------------------------------------------------------------
; $86 - MINUS
; $87 - PLUS
;
; Sets the Periodic Noise Mode in $400E
;   MINUS = Periodic Mode (93 steps)
;   PLUS = Normal Mode (32767 steps)
;------------------------------------------------------------------------------

E_MINUS:
    LDA #%10000000
    .BYTE $2C                                    ; OpCode Trick
E_PLUS:
    LDA #%00000000
    STA or_E                                     ; Periodic Noise Mode
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

E_FOR:
    LDA (PC_E),Y                                 ; Repeat Count
    INY
    STA repeat_E
    LDA PC_E                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_E                                  ; Save Loop Start Address
    STA PC_E
    LDA PC_E+1
    ADC #0
    STA stack_E+1
    STA PC_E+1
    JMP DO_E

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

E_NEXT:
    DEC repeat_E                                 ; Repeat Count -= 1
    BEQ E_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_E                                  ; Back to Loop Start Address
    STA PC_E
    LDA stack_E+1
    STA PC_E+1
    JMP DO_E

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

E_LEN:
    LDA (PC_E),Y                                 ; Fixed Note Duration
    STA length_E
    INY
E_GOADDY:
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

E_STOP:
    INC stop_E                                   ; $FF -> $00: bit 7 Clear = Stopped

    LDA #%00110000                               ; Silence
    LDX stop_D                                   ; Channel D Active?
    BPL @E_STOP_VOL                              ; D stopped: Stay Silent
    LDA volume_D                                 ; Restore D Channel Volume
    ORA #%00110000
@E_STOP_VOL:
    STA $400C

    LDA old_note_D                               ; Restore Channel D Note Period
    STA $400E
    LDA #%00000011
    STA $400F
    JMP THE_END

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

E_GOSUB:
    LDX sp_E                                     ; Get Stack Slot
    LDA PC_E                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_E,X
    LDA PC_E+1
    ADC #0
    STA stack_HI_E,X
    INX                                          ; Next Stack Slot
    STX sp_E
E_GOTO:
    LDA (PC_E),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_E),Y                                 ; Target Address Hi
    STA PC_E+1
    STX PC_E
    JMP DO_E

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

E_RETURN:
    DEC sp_E                                     ; Previous Stack Slot
    LDX sp_E
    LDA stack_LO_E,X                             ; Return Address
    STA PC_E
    LDA stack_HI_E,X
    STA PC_E+1
    JMP DO_E

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

E_SEND:
    LDA (PC_E),Y                                 ; Register to Write
    BMI E_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_E),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE E_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8A - ADSR volumes, speeds, stage
;
; Configures the ADSR envelope parameters. Use ENVON to select the envelope
; mode.
;   byte 1:   iiiissss   i = Starting Volume (0-15), s = Sustain Volume (0-15)
;   byte 2:   aaaadddd   a = Attack Speed (0-15), d = Decay Speed (0-15)
;   byte 3:   starting stage: 0 = Attack, 1 = Decay, 2 = Sustain
; Both speed values act as frame timers: volume updates once every (speed + 1)
; frames. Attack always ramps to 15 before Decay drops to the Sustain Volume.
; WARNING: Avoid invoking ADSR when table mode is active.
;------------------------------------------------------------------------------

E_ADSR:
    LDA (PC_E),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_init_E                              ; Initial Volume
    LDA (PC_E),Y
    AND #$0F
    STA ADSR_sus_E                               ; Sustain Volume
    INY
    LDA (PC_E),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_att_E                               ; Attack Speed Timer
    LDA (PC_E),Y
    AND #$0F
    STA ADSR_dec_E                               ; Decay Speed Timer
    INY
    LDA (PC_E),Y
    STA ADSR_cyc_E                               ; Initial Stage
E_GOADDY1:
    INY
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $8B - ENVON mode
;
; Select which volume envelope mode will be used when each new note starts.
;   $00 = Legato mode: ADSR envelope persists across notes without resetting
;   $01-$7F = ADSR mode (configured with ADSR)
;   $80-$FF = Envelope Table Mode (configured with TABLE)
;------------------------------------------------------------------------------

E_ENVON:
    LDA (PC_E),Y
    STA ADSR_control_E                           ; Envelope Mode
    INY
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

E_WOBBLE:
    LDA (PC_E),Y
    STA wob_off_E                                ; Note Offset in Semitones
    INY
    LDA (PC_E),Y
    STA wob_delay1_E                             ; Up Timer
    INY
    LDA (PC_E),Y
    STA wob_delay2_E                             ; Down Timer
    INY
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

E_EFFECT:
    LDA (PC_E),Y
    STA eff_time_E                               ; Effect Length in Frames
    INY
    LDA (PC_E),Y                                 ; Effect Period
    STA eff_freq_E
    INY
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $92 - TABLE step_time, address
;
; Sets to Envelope Table Mode and the address for the volume table to be used.
;   step_time = Number of frames per table step
;   address = Pointer to the table data (low byte, high byte)
;------------------------------------------------------------------------------

E_TABLE:
    LDA (PC_E),Y
    STA time_E                                   ; Frames Per Table Entry
    INY
    LDA (PC_E),Y
    STA point_E                                  ; Table Address Lo
    INY
    LDA (PC_E),Y
    STA point_E+1                                ; Table Address Hi
    INY
    LDA #$FF
    STA ADSR_control_E                           ; Table Mode
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; $93 - CUTOFF frames
; $94 - ENDIT frames
;
; These commands are only used in table envelope mode. They control when a note
; exits the table's hold state to advance to the entries that follow.
;   CUTOFF = Elapsed frames from note's start. Ignored if cutoff > duration
;   ENDIT = Remaining frames from note's end. Ignored if cutoff < duration
; Values of 0 disable.
;------------------------------------------------------------------------------

E_CUTOFF:
    LDA (PC_E),Y
    STA cutoff_E                                 ; Hold Exit: Frames After Note Start
    INY
    JMP ADVANCE_PC_E

E_ENDIT:
    LDA (PC_E),Y
    STA endit_E                                  ; Hold Exit: Frames Before Note End
    INY
    JMP ADVANCE_PC_E

;------------------------------------------------------------------------------
; Channel F Commands
;------------------------------------------------------------------------------

JUMP_LO_F:
    .LOBYTES F_FOR-1, F_NEXT-1, F_LEN-1, F_STOP-1, F_GOSUB-1, F_RETURN-1, F_TRANS-1, F_DISTORT-1
    .LOBYTES F_GOTO-1, F_SEND-1, F_ADSR-1, F_ENVON-1, F_WOBBLE-1, F_PORT-1, F_DUTY-1, F_VIBRATO-1
    .LOBYTES F_IGNORE-1, F_EFFECT-1, F_TABLE-1, F_CUTOFF-1, F_ENDIT-1, F_SWEEP-1

JUMP_HI_F:
    .HIBYTES F_FOR-1, F_NEXT-1, F_LEN-1, F_STOP-1, F_GOSUB-1, F_RETURN-1, F_TRANS-1, F_DISTORT-1
    .HIBYTES F_GOTO-1, F_SEND-1, F_ADSR-1, F_ENVON-1, F_WOBBLE-1, F_PORT-1, F_DUTY-1, F_VIBRATO-1
    .HIBYTES F_IGNORE-1, F_EFFECT-1, F_TABLE-1, F_CUTOFF-1, F_ENDIT-1, F_SWEEP-1

;------------------------------------------------------------------------------
; $80 - FOR count
;
; Initializes a loop structure. Executes the subsequent block "count" times.
; The starting address is saved so NEXT can jump back to it.
; NOTE: Loops cannot be nested and subroutines invoked within a loop must not
; issue FOR commands.
;------------------------------------------------------------------------------

F_FOR:
    LDA (PC_F),Y                                 ; Repeat Count
    INY
    STA repeat_F
    LDA PC_F                                     ; Loop Start + 2
    CLC
    ADC #2
    STA stack_F                                  ; Save Loop Start Address
    STA PC_F
    LDA PC_F+1
    ADC #0
    STA stack_F+1
    STA PC_F+1
    JMP DO_F

;------------------------------------------------------------------------------
; $81 - NEXT
;
; Marks the end of a FOR loop. Each time NEXT is reached, the repeat counter is
; decremented. If more iterations remain, execution jumps back to the beginning
; of the FOR loop. Otherwise, the stream continues after NEXT.
;------------------------------------------------------------------------------

F_NEXT:
    DEC repeat_F                                 ; Repeat Count -= 1
    BEQ F_GOADDY                                 ; Last Pass: Continue after NEXT
    LDA stack_F                                  ; Back to Loop Start Address
    STA PC_F
    LDA stack_F+1
    STA PC_F+1
    JMP DO_F

;------------------------------------------------------------------------------
; $82 - LEN duration
;
; Sets a fixed note duration in frames for all following notes. A value of 0
; disables the fixed duration and tells the engine to read a separate duration
; byte after each note in the stream.
;------------------------------------------------------------------------------

F_LEN:
    LDA (PC_F),Y
    STA length_F                                 ; Fixed Note Duration
    INY
F_GOADDY:
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $83 - STOP
;
; Halts the channel and silences audio output.
;------------------------------------------------------------------------------

F_STOP:
    INC stop_F                                   ; $FF -> $00: bit 7 Clear = Stopped

    LDA #%00110000                               ; Silence
    LDX stop_A                                   ; Channel A active?
    BPL @F_STOP_VOL                              ; A stopped: Stay Silent
    LDA volume_A                                 ; Restore Channel A duty | volume
    ORA duty_A
@F_STOP_VOL:
    STA $4000

    LDA freq_A                                   ; Restore Channel A Note Period
    STA $4002
    LDA freq_A+1
    CMP oldfreq_F
    BEQ @F_NOHI
    STA oldfreq_A
    STA $4003
@F_NOHI:
    JMP DO_CHANNEL_B

;------------------------------------------------------------------------------
; $84 - GOSUB address
; $88 - GOTO address
;
; GOTO jumps directly to the stream address. GOSUB does the same but preserves
; the return address.
; NOTE: GOSUB can be nested up to stack_size (default 3).
;------------------------------------------------------------------------------

F_GOSUB:
    LDX sp_F                                     ; Get Stack Slot
    LDA PC_F                                     ; Return Address = PC + 3
    CLC
    ADC #3
    STA stack_LO_F,X
    LDA PC_F+1
    ADC #0
    STA stack_HI_F,X
    INX                                          ; Next Stack Slot
    STX sp_F
F_GOTO:
    LDA (PC_F),Y                                 ; Target Address Lo
    TAX
    INY
    LDA (PC_F),Y                                 ; Target Address Hi
    STA PC_F+1
    STX PC_F
    JMP DO_F

;------------------------------------------------------------------------------
; $85 - RETURN
;
; Returns from the most recent GOSUB and resumes execution immediately
; following the most recent GOSUB call.
;------------------------------------------------------------------------------

F_RETURN:
    DEC sp_F                                     ; Previous Stack Slot
    LDX sp_F
    LDA stack_LO_F,X                             ; Return Address
    STA PC_F
    LDA stack_HI_F,X
    STA PC_F+1
    JMP DO_F

;------------------------------------------------------------------------------
; $86 - TRANS semitones
;
; Applies a signed semitone offset to all following notes.
;------------------------------------------------------------------------------

F_TRANS:
    LDA (PC_F),Y
    STA transpose_F                              ; Transpose in Semitones (signed)
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $87 - DISTORT value
;
; Applies an unsigned detune offset. The value is added directly to all
; following note periods.
;------------------------------------------------------------------------------

F_DISTORT:
    LDA (PC_F),Y
    STA distort_F                                ; Period Offset (unsigned)
F_GOADDY1:
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $89 - SEND (register, value) ... terminator
;
; Writes values directly to APU registers. Accepts pairs of register offsets
; relative to $4000 ($00-$7F) followed by the data byte, terminated by any byte
; with bit 7 set. 
;------------------------------------------------------------------------------

F_SEND:
    LDA (PC_F),Y                                 ; Register to Write
    BMI F_GOADDY1                                ; bit 7: Set = End of List
    TAX
    INY
    LDA (PC_F),Y                                 ; Value to Write
    STA $4000,X
    INY
    BNE F_SEND                                   ; Next Register

;------------------------------------------------------------------------------
; $8A - ADSR volumes, speeds, stage
;
; Configures the ADSR envelope parameters. Use ENVON to select the envelope
; mode.
;   byte 1:   iiiissss   i = Starting Volume (0-15), s = Sustain Volume (0-15)
;   byte 2:   aaaadddd   a = Attack Speed (0-15), d = Decay Speed (0-15)
;   byte 3:   starting stage: 0 = Attack, 1 = Decay, 2 = Sustain
; Both speed values act as frame timers: volume updates once every (speed + 1)
; frames. Attack always ramps to 15 before Decay drops to the Sustain Volume.
; WARNING: Avoid invoking ADSR when table mode is active.
;------------------------------------------------------------------------------

F_ADSR:
    LDA (PC_F),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_init_F                              ; Initial Volume
    LDA (PC_F),Y
    AND #$0F
    STA ADSR_sus_F                               ; Sustain Volume
    INY
    LDA (PC_F),Y
    LSR
    LSR
    LSR
    LSR
    STA ADSR_att_F                               ; Attack Speed Timer
    LDA (PC_F),Y
    AND #$0F
    STA ADSR_dec_F                               ; Decay Speed Timer
    INY
    LDA (PC_F),Y
    STA ADSR_cyc_F                               ; Initial Stage
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $8B - ENVON mode
;
; Select which volume envelope mode will be used when each new note starts.
;   $00 = Legato mode: ADSR envelope persists across notes without resetting
;   $01-$7F = ADSR mode (configured with ADSR)
;   $80-$FF = Envelope Table Mode (configured with TABLE)
;------------------------------------------------------------------------------

F_ENVON:
    LDA (PC_F),Y
    STA ADSR_control_F                           ; Envelope Mode
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $8C - WOBBLE offset, up_time, down_time
;
; Adds a pitch change that alternates between the base pitch and secondary
; pitch.
;   offset = signed semitone offset applied during the change cycle
;   up_time = delay frames before transition to secondary pitch
;   down_time = delay frames before returning to base pitch
; A time value of 0 stops the wobble and an up_time of $FF disables.
; WARNING: Wobble and Vibrato share a direction flag and cannot execute
; concurrently.
;------------------------------------------------------------------------------

F_WOBBLE:
    LDA (PC_F),Y
    STA wob_off_F                                ; Note Offset in Semitones
    INY
    LDA (PC_F),Y
    STA wob_delay1_F                             ; Up Timer
    INY
    LDA (PC_F),Y
    STA wob_delay2_F                             ; Down Timer
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $8D - PORT speed
;
; Sets the speed of the pitch slide in semitones per frame. A value of 0
; disables. When active, each following note acts as a target frequency and the
; channel steps toward it incrementally each frame.
;------------------------------------------------------------------------------

F_PORT:
    LDA (PC_F),Y
    STA port_F                                   ; Slide Speed in Semitones
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $8E - DUTY value
;
; Configures the upper bits of register $4000 which are combined with the
; volume bits (0-3) each frame.
;   bits 7-6:   Duty cycle waveform
;   bit 5:      Length counter halt flag
;   bit 4:      Constant volume flag
;------------------------------------------------------------------------------

F_DUTY:
    LDA (PC_F),Y
    STA duty_F                                   ; Duty
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $8F - VIBRATO delay, rate, limit, direction
;
; Variable length command format:
;   delay = 0   Disable vibrato. Consumes 2 bytes.
;   delay <> 0  Consumes 5 bytes to configure all parameters.
;
;   delay = Delays the start by N-1 frames
;   rate = Period units added or subtracted each frame
;   limit = Number of frames in the first swing and later swings doubled. A
;           value of 0 never reverses direction.
;   direction = Initial swing direction: $00 = decrement and $FF = increment
;------------------------------------------------------------------------------

F_VIBRATO:
    LDA (PC_F),Y
    STA vib_delay_F                              ; Delay timer (0 = Off)
    BEQ @skip
    INY
    LDA (PC_F),Y
    STA vib_rate_F                               ; Period Per Frame
    INY
    LDA (PC_F),Y
    STA vib_limit2_F                             ; Swing Length
    INY
    LDA (PC_F),Y
    STA vib_dir_F                                ; Starting direction
@skip:
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $90 - IGNORE
;
; Skips the transposition of the next note only.
;------------------------------------------------------------------------------

F_IGNORE:
    LDA #$FF
    STA ignore_F                                 ; Skip Transpose for Next Note
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $91 - EFFECT time, period_lo, period_hi
;
; Makes each following note start with a fixed period instead of its own pitch
; producing a blip before transitioning to its standard pitch. The effect
; period sounds for (time - 1) frames. A time of 0 disables.
; NOTE: Vibrato, Wobble, and Slides are paused while the effect is playing.
; Transpose and Distort are not applied to the effect period.
;------------------------------------------------------------------------------

F_EFFECT:
    LDA (PC_F),Y
    STA eff_time_F                               ; Effect Length in Frames
    INY
    LDA (PC_F),Y
    STA eff_freq_F                               ; Effect Period Lo
    INY
    LDA (PC_F),Y
    STA eff_freq_F+1                             ; Effect Period Hi
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $92 - TABLE step_time, address
;
; Sets to Envelope Table Mode and the address for the volume table to be used.
;   step_time = Number of frames per table step
;   address = Pointer to the table data (low byte, high byte)
;------------------------------------------------------------------------------

F_TABLE:
    LDA (PC_F),Y
    STA time_F                                   ; Frames Per Table Entry
    INY
    LDA (PC_F),Y
    STA point_F                                  ; Table Address Lo
    INY
    LDA (PC_F),Y
    STA point_F+1                                ; Table Address Hi
    INY
    LDA #$FF
    STA ADSR_control_F                           ; Table Mode
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $93 - CUTOFF frames
; $94 - ENDIT frames
;
; These commands are only used in table envelope mode. They control when a note
; exits the table's hold state to advance to the entries that follow.
;   CUTOFF = Elapsed frames from note's start. Ignored if cutoff > duration
;   ENDIT = Remaining frames from note's end. Ignored if cutoff < duration
; Values of 0 disable.
;------------------------------------------------------------------------------

F_CUTOFF:
    LDA (PC_F),Y
    STA cutoff_F                                 ; Hold Exit: Frames After Note Start
    INY
    JMP ADVANCE_PC_F

F_ENDIT:
    LDA (PC_F),Y
    STA endit_F                                  ; Hold Exit: Frames Before Note End
    INY
    JMP ADVANCE_PC_F

;------------------------------------------------------------------------------
; $95 - SWEEP value
;
; Sets the value written to $4001 for each following note.
; Format: EPPPNSSS   E: Enable, P: Period, N: Negate, S: Shift
;------------------------------------------------------------------------------

F_SWEEP:
    LDA (PC_F),Y
    STA sweep_F                                  ; Sweep Register Value
    INY
    JMP ADVANCE_PC_F    
.endproc

; EQUAL TEMPERED CHROMATIC SCALE

; C2, C#2, D2, D#2, E2, F2, F#2, G2, G#2, A2, A#2, B2
; C3, C#3, D3, D#3, E3, F3, F#3, G3, G#3, A3, A#3, B3
; C4, C#4, D4, D#4, E4, F4, F#4, G4, G#4, A4, A#4, B4
; C5, C#5, D5, D#5, E5, F5, F#5, G5, G#5, A5, A#5, B5
; C6, C#6, D6, D#6, E6, F6, F#6, G6, G#6, A6, A#6, B6
; C7, C#7, D7, D#7, E7, F7, F#7, G7, G#7, A7, A#7, B7
; C8, C#8, D8, D#8, E8, F8, F#8, G8, G#8, A8, A#8, B8
; C9, C#9, D9, D#9, E9, F9, F#9, G9, G#9, A9, A#9, B9
; Rest

Notes_HI:
    .HIBYTES $06AE/1, $064E/1, $05F3/1, $059E/1, $054D/1, $0501/1, $04B9/1, $0475/1, $0435/1, $03F8/1, $03BF/1, $0389/1
    .HIBYTES $06AE/2, $064E/2, $05F3/2, $059E/2, $054D/2, $0501/2, $04B9/2, $0475/2, $0435/2, $03F8/2, $03BF/2, $0389/2
    .HIBYTES $06AE/4, $064E/4, $05F3/4, $059E/4, $054D/4, $0501/4, $04B9/4, $0475/4, $0435/4, $03F8/4, $03BF/4, $0389/4
    .HIBYTES $06AE/8, $064E/8, $05F3/8, $059E/8, $054D/8, $0501/8, $04B9/8, $0475/8, $0435/8, $03F8/8, $03BF/8, $0389/8
    .HIBYTES $06AE/16, $064E/16, $05F3/16, $059E/16, $054D/16, $0501/16, $04B9/16, $0475/16, $0435/16, $03F8/16, $03BF/16, $0389/16
    .HIBYTES $06AE/32, $064E/32, $05F3/32, $059E/32, $054D/32, $0501/32, $04B9/32, $0475/32, $0435/32, $03F8/32, $03BF/32, $0389/32
    .HIBYTES $06AE/64, $064E/64, $05F3/64, $059E/64, $054D/64, $0501/64, $04B9/64, $0475/64, $0435/64, $03F8/64, $03BF/64, $0389/64
    .HIBYTES $06AE/128, $064E/128, $05F3/128, $059E/128, $054D/128, $0501/128, $04B9/128, $0475/128, $0435/128, $03F8/128, $03BF/128, $0389/128
    .BYTE $00

Notes_LO:
    .LOBYTES $06AE/1, $064E/1, $05F3/1, $059E/1, $054D/1, $0501/1, $04B9/1, $0475/1, $0435/1, $03F8/1, $03BF/1, $0389/1
    .LOBYTES $06AE/2, $064E/2, $05F3/2, $059E/2, $054D/2, $0501/2, $04B9/2, $0475/2, $0435/2, $03F8/2, $03BF/2, $0389/2
    .LOBYTES $06AE/4, $064E/4, $05F3/4, $059E/4, $054D/4, $0501/4, $04B9/4, $0475/4, $0435/4, $03F8/4, $03BF/4, $0389/4
    .LOBYTES $06AE/8, $064E/8, $05F3/8, $059E/8, $054D/8, $0501/8, $04B9/8, $0475/8, $0435/8, $03F8/8, $03BF/8, $0389/8
    .LOBYTES $06AE/16, $064E/16, $05F3/16, $059E/16, $054D/16, $0501/16, $04B9/16, $0475/16, $0435/16, $03F8/16, $03BF/16, $0389/16
    .LOBYTES $06AE/32, $064E/32, $05F3/32, $059E/32, $054D/32, $0501/32, $04B9/32, $0475/32, $0435/32, $03F8/32, $03BF/32, $0389/32
    .LOBYTES $06AE/64, $064E/64, $05F3/64, $059E/64, $054D/64, $0501/64, $04B9/64, $0475/64, $0435/64, $03F8/64, $03BF/64, $0389/64
    .LOBYTES $06AE/128, $064E/128, $05F3/128, $059E/128, $054D/128, $0501/128, $04B9/128, $0475/128, $0435/128, $03F8/128, $03BF/128, $0389/128
    .BYTE $00

Driver_end:

.include "music_data.asm"
