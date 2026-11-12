.ifndef CONSTANTS_ASM
CONSTANTS_ASM = 1

; NES REGISTERS
.global NES_CTRL0
.global NES_CTRL1
.global NES_SR
.global NES_OAM_AR
.global NES_OAM
.global NES_SCC_H
.global NES_SCC_V
.global NES_VRAM_AR
.global NES_VRAM
.global NES_OBJDMA
.global NES_A0
.global NES_A1
.global NES_A2
.global NES_A3
.global NES_B0
.global NES_B1
.global NES_B2
.global NES_B3
.global NES_C0
.global NES_C2
.global NES_C3
.global NES_D0
.global NES_D2
.global NES_D3
.global NES_E0
.global NES_E1
.global NES_E2
.global NES_E3
.global NES_ST
.global NES_SOFTCLK
.global NES_P0
.global NES_P1

; MMC3 REGISTERS
.global MMC3_POINTER
.global MMC3_ROMBANK
.global MMC3_SW
.global MMC3_PROTECT
.global MMC3_ITIRQ
.global MMC3_PSIT
.global MMC3_DITIRQ
.global MMC3_EITIRQ

; CTRL0 BITS
.global CTRL0_MSBH
.global CTRL0_MSBV
.global CTRL0_INCM
.global CTRL0_OBJSEG
.global CTRL0_BGSEG
.global CTRL0_8X16
.global CTRL0_SLAVE
.global CTRL0_INT

.global CTRL0_BG_2000
.global CTRL0_BG_2400
.global CTRL0_BG_2800
.global CTRL0_BG_2C00

; CTRL1 BITS
.global CTRL1_MC
.global CTRL1_BGLBLK
.global CTRL1_OBJLBLK
.global CTRL1_BGBLK
.global CTRL1_OBJBLK
.global CTRL1_RED
.global CTRL1_BLUE
.global CTRL1_GREEN

; ST BITS
.global ST_A
.global ST_B
.global ST_C
.global ST_D
.global ST_E

; SOFTCLK BITS
.global SOFTCLK_INT
.global SOFTCLK_EXTM

; CONTROLLER BITS
.global P_RIGHT
.global P_LEFT
.global P_DOWN
.global P_UP
.global P_START
.global P_SELECT
.global P_B
.global P_A

; VRAM MEMORY
.global BG_RAM0
.global BG_COLOR0
.global BG_RAM1
.global BG_COLOR1
.global BG_RAM2
.global BG_COLOR2
.global BG_RAM3
.global BG_COLOR3
.global COLOR_TABLE

; FRAMES
.global FRAME_WAIT
.global FRAME_READY

; STEPS
.global NO_STEP
.global STEP

; TUNE/EFFECT INDEXES
.global SONG_MAX
.global EFFECT_MAX

; QUEUE
.global QUEUE_MAX

; FAST FORWARD AMOUNT
.global FF_COUNT

; PAUSE OPTION
.global PAUSE_TOGGLE

;==============================================================================
; NES REGISTERS
;==============================================================================

NES_CTRL0      := $2000 ; PPU Control 0
NES_CTRL1      := $2001 ; PPU Control 1
NES_SR         := $2002 ; Status Register
NES_OAM_AR     := $2003 ; OAM Address Register
NES_OAM        := $2004 ; OBJ Attribute Memory Data
NES_SCC_H      := $2005 ; Horizontal Scroll Register (w=0)
NES_SCC_V      := $2005 ; Vertical Scroll Register (w=1)
NES_VRAM_AR    := $2006 ; VRAM Address Register
NES_VRAM       := $2007 ; VRAM Data
NES_OBJDMA     := $4014 ; OBJ DMA

; SOUND A - SQUARE WAVE
NES_A0         := $4000
NES_A1         := $4001
NES_A2         := $4002
NES_A3         := $4003
; SOUND B - SQUARE WAVE
NES_B0         := $4004
NES_B1         := $4005
NES_B2         := $4006
NES_B3         := $4007
; SOUND C - TRIANGLE WAVE
NES_C0         := $4008
NES_C2         := $400A
NES_C3         := $400B
; SOUND D - NOISE GENERATOR
NES_D0         := $400C
NES_D2         := $400E
NES_D3         := $400F
; SOUND E - DELTA MODULATION
NES_E0         := $4010
NES_E1         := $4011
NES_E2         := $4012
NES_E3         := $4013

; STATUS
NES_ST         := $4015

; FRAME COUNTER
NES_SOFTCLK    := $4017

; CONTROLLERS
NES_P0         := $4016 ; Controller 0
NES_P1         := $4017 ; Controller 1

;==============================================================================
; MMC3 REGISTERS
;==============================================================================

MMC3_POINTER   := $8000 ; ROM Bank Pointer
MMC3_ROMBANK   := $8001 ; ROM Bank

MMC3_SW        := $A000 ; Scroll Switch
MMC3_PROTECT   := $A001 ; Protect: Backup-RAM

MMC3_ITIRQ     := $C000 ; JAM: Interval Timer IRQ
MMC3_PSIT      := $C001 ; Preset & Start Interval Timer

MMC3_DITIRQ    := $E000 ; DISABLE Interval Timer IRQ
MMC3_EITIRQ    := $E001 ; ENABLE Interval Timer IRQ

;==============================================================================
; CTRL0 BITS
;==============================================================================

CTRL0_MSBH     := %00000001 ; H Scroll Offset
CTRL0_MSBV     := %00000010 ; V Scroll Offset
CTRL0_INCM     := %00000100 ; Increment Mode +32
CTRL0_OBJSEG   := %00001000 ; OBJ CHR Area $1000
CTRL0_BGSEG    := %00010000 ; BG CHR Area $1000
CTRL0_8X16     := %00100000 ; 8x16 OBJ CHR Size
CTRL0_SLAVE    := %01000000 ; Slave Mode
CTRL0_INT      := %10000000 ; Interrupt Occurance On

CTRL0_BG_2000  := %00000000
CTRL0_BG_2400  := CTRL0_MSBH
CTRL0_BG_2800  := CTRL0_MSBV
CTRL0_BG_2C00  := CTRL0_MSBV | CTRL0_MSBH

;==============================================================================
; CTRL1 BITS
;==============================================================================

CTRL1_MC       := %00000001 ; Monotone
CTRL1_BGLBLK   := %00000010 ; BG Left Blank Off
CTRL1_OBJLBLK  := %00000100 ; OBJ Left Blank Off
CTRL1_BGBLK    := %00001000 ; BG Blank Off
CTRL1_OBJBLK   := %00010000 ; OBJ Blank Off
CTRL1_RED      := %00100000 ; Red
CTRL1_BLUE     := %01000000 ; Blue
CTRL1_GREEN    := %10000000 ; Green

;==============================================================================
; ST BITS
;==============================================================================

ST_A := %00000001 ; ENABLE Sound A
ST_B := %00000010 ; ENABLE Sound B
ST_C := %00000100 ; ENABLE Sound C
ST_D := %00001000 ; ENABLE Sound D
ST_E := %00010000 ; ENABLE Sound E

;==============================================================================
; SOFTCLK BITS
;==============================================================================

SOFTCLK_INT    := %01000000 ; Interrupt Occurance Off
SOFTCLK_EXTM   := %10000000 ; Extended Mode

;==============================================================================
; CONTROLLER BITS
;==============================================================================

P_RIGHT  := %00000001
P_LEFT   := %00000010
P_DOWN   := %00000100
P_UP     := %00001000
P_START  := %00010000
P_SELECT := %00100000
P_B      := %01000000
P_A      := %10000000

;==============================================================================
; VRAM MEMORY
;==============================================================================

BG_RAM0        := $2000
BG_COLOR0      := $23C0
BG_RAM1        := $2400
BG_COLOR1      := $27C0
BG_RAM2        := $2800
BG_COLOR2      := $2BC0
BG_RAM3        := $2C00
BG_COLOR3      := $2FC0

COLOR_TABLE := $3F00

;==============================================================================
; FRONTEND
;==============================================================================

FRAME_WAIT  := 0
FRAME_READY := 1

NO_STEP := 0
STEP := 1

SONG_MAX    = 0         ; <<< SET THIS: index of the LAST tune
EFFECT_MAX  = 0         ; <<< SET THIS: index of the LAST effect

QUEUE_MAX   = 48

FF_COUNT    = 4         ; REFRESH calls per frame while Select is held

PAUSE_TOGGLE = 1        ; 1 = B toggles pause, 0 = hold B to freeze (original behaviour)

.endif