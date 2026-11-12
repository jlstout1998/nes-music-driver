; CTRL Register Shadows
.exportzp NES_CTRL0_shadow
.exportzp NES_CTRL1_shadow
; Frame Synchronization
.exportzp frame_state
.exportzp frame_counter
; Controllers
.exportzp controller_read
.exportzp controller1_state
.exportzp controller1_pressed
.exportzp controller1_held
; Tunes
.exportzp current_tune
.exportzp playing_tune
.exportzp current_effect
.exportzp pause_flag
.exportzp step_flag
.exportzp step_count
; Queue
.exportzp queue_ready
.exportzp queue_count
.exportzp once_flag
.exportzp screen_hi
.exportzp screen_lo
; Timer
.exportzp timer_divider
.exportzp timer
.exportzp seconds
.exportzp minutes
; Scan
.exportzp scan_ptr
.exportzp scan_vptr
.exportzp scan_val
.exportzp scan_left
.exportzp scan_idx
; Temporary
.exportzp tmp0
.exportzp tmp1
.exportzp tmp2

; OBJ BUFFER
.export OBJ

; Display
.export shadow
.export for_A
.export for_B
.export for_C
.export for_D
.export prev_rep_A
.export prev_rep_B
.export prev_rep_C
.export prev_rep_D

; Queue Buffer
.export queue_hi
.export queue_lo
.export queue_c0
.export queue_c1

;==============================================================================
; ZERO PAGE
;==============================================================================
;
; Frequently accessed state is kept in zero page so the raster code and game
; update code can use the shorter/faster addressing modes.
;==============================================================================

.segment "ZEROPAGE"

;------------------------------------------------------------------------------
; CTRL register shadows
;------------------------------------------------------------------------------

NES_CTRL0_shadow: .res 1
NES_CTRL1_shadow: .res 1

;------------------------------------------------------------------------------
; Frame synchronization
;------------------------------------------------------------------------------

frame_state:   .res 1
frame_counter: .res 1

;------------------------------------------------------------------------------
; Controllers
;------------------------------------------------------------------------------

controller_read:     .res 1
controller1_state:   .res 1
controller1_pressed: .res 1
controller1_held:    .res 1

;------------------------------------------------------------------------------
; Tunes
;------------------------------------------------------------------------------

current_tune:   .res 1
playing_tune:   .res 1
current_effect: .res 1
pause_flag:     .res 1
step_flag:      .res 1
step_count:     .res 1

;------------------------------------------------------------------------------
; Queue
;------------------------------------------------------------------------------

queue_ready: .res 1
queue_count: .res 1

once_flag:   .res 1

screen_hi:   .res 1
screen_lo:   .res 1

;------------------------------------------------------------------------------
; Timer
;------------------------------------------------------------------------------

timer_divider: .res 1
timer:         .res 4
seconds:       .res 1
minutes:       .res 1

;------------------------------------------------------------------------------
; Scan
;------------------------------------------------------------------------------

scan_ptr:  .res 2
scan_vptr: .res 2
scan_val:  .res 1
scan_left: .res 1
scan_idx:  .res 1

;------------------------------------------------------------------------------
; Temporary
;------------------------------------------------------------------------------

tmp0: .res 1
tmp1: .res 1
tmp2: .res 1

;==============================================================================
; OBJ BUFFER
;==============================================================================
;
; OBJ is copied to PPU OAM by DMA once per frame during NMI.
;==============================================================================

.segment "OBJ"

OBJ: .res 256

;==============================================================================
; DISPLAY
;==============================================================================

.segment "DISPLAY"

shadow:     .res 64

for_A:      .res 1
for_B:      .res 1
for_C:      .res 1
for_D:      .res 1
prev_rep_A: .res 1
prev_rep_B: .res 1
prev_rep_C: .res 1
prev_rep_D: .res 1

;==============================================================================
; QUEUE BUFFER
;==============================================================================

.segment "QUEUE"

queue_hi: .res 64
queue_lo: .res 64
queue_c0: .res 64
queue_c1: .res 64

;==============================================================================
; BSS / RESERVED WORK AREA
;==============================================================================

.segment "BSS"
