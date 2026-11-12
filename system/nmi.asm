.export UPDATE_OAM
.export UPDATE_VRAM
.export UPDATE_COLOR
.export UPDATE_SCROLL

;==============================================================================
; Update OAM
;==============================================================================

.proc UPDATE_OAM

    ; DMA OBJ buffer
    LDA #$00
    STA NES_OAM_AR
    LDA #>OBJ
    STA NES_OBJDMA

    RTS

.endproc

;==============================================================================
; Update VRAM
;==============================================================================

.proc UPDATE_VRAM

    ; Check queue ready
    LDA queue_ready
    BEQ @finish

    ; Write queue
    BIT NES_SR
    LDX queue_count
    DEX
@next:
    LDA queue_hi,X
    STA NES_VRAM_AR
    LDA queue_lo,X
    STA NES_VRAM_AR
    LDA queue_c0,X
    STA NES_VRAM
    LDA queue_c1,X
    STA NES_VRAM
    DEX
    BPL @next

    ; Queue done
    LDA #0
    STA queue_count
    STA queue_ready
@finish:
    RTS

.endproc

;==============================================================================
; Update Color
;==============================================================================

.proc UPDATE_COLOR

    RTS

.endproc

;==============================================================================
; Update Scroll
;==============================================================================

.proc UPDATE_SCROLL

    ; Reset the PPU write latch
    BIT NES_SR

    ; Select background table from camera_x.
    LDA NES_CTRL0_shadow
    AND #%11111100
    ORA #$00 ; camera_x + 1
    STA NES_CTRL0_shadow
    STA NES_CTRL0

    ; Fine/Coarse X
    LDA #$00 ; camera_x + 0
    STA NES_SCC_H

    ; Fine/Coarse Y, wrapping at the top of the physical background table.
    LDA #$00 ; scroll_y
    STA NES_SCC_V

    RTS

.endproc