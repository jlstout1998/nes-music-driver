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

rest    = $60

DATA_start:

;------------------------------------------------------------------------------
; TUNE DATA
;------------------------------------------------------------------------------

; Tune Data Here

;------------------------------------------------------------------------------
; SOUND EFFECTS DATA
;------------------------------------------------------------------------------

; FX Data Here

DATA_end:
