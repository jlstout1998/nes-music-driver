;==============================================================================
; HEADER
;==============================================================================

.segment "HEADER"

    ; iNES magic number
    .byte "NES", $1A

    ; PRG-ROM size LSB: 2 x 16KB = 32KB
    .byte $02

    ; CHR-ROM size LSB: 1 x 8KB = 8KB
    .byte $01

    ; Flags 6
    ; bit 0 = vertical background table mirroring
    ; bits 4-7 = mapper
    .byte %00000001

    ; Flags 7
    ; bits 2-3 = NES 2.0 Identifier
    .byte %00001000

    ; Mapper MSB / Submapper
    .byte %00000000

    ; PRG_ROM / CHR-ROM MSB
    .byte %00000000

    ; PRG_RAM/EEPROM size
    .byte %00000000

    ; CHR-RAM size
    .byte %00000000

    ; CPU/PPU Timing
    .byte %00000000

    ; Vs. System Type / Extended Console Type
    .byte %00000000

    ; Misc. ROMs
    .byte %00000000

    ; Default Expansion Device
    .byte %00000000