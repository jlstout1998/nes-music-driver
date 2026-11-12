VERSION:
    .BYTE "MUSIC DRIVER V1   - BY S.RUDDY"
SIZE:
    .BYTE "DRIVER 0000-DATA 0000-ALL 0000"
SELECTION:
    .BYTE "SELECT 00 - TUNE 00 TIME 00:00"
CHANNEL:
    .BYTE         "CH.A  CH.B  CH.C  CH.D"
NOTE:
    .BYTE "NOTE    00    00    00    00"
LENGTH:
    .BYTE "LENGTH  00    00    00    00"
COUNT:
    .BYTE "COUNT   00    00    00    00"
TRANS:
    .BYTE "TRANS   00    00    00"
FOR:
    .BYTE "FOR     00    00    00    00"
NEXT:
    .BYTE "NEXT    00    00    00    00"
FREQ:
    .BYTE "FREQ    0000  0000  0000"
DIST:
    .BYTE "DIST    00    00    00"
WOB_SET:
    .BYTE "WOB-SET 00    00    00    00"
WOB_VAR:
    .BYTE "WOB-VAR 00    00    00    00"
VIB_DEL:
    .BYTE "VIB-DEL 00    00    00"
VIB_RAT:
    .BYTE "VIB-RAT 00    00    00"
VIB_LIM:
    .BYTE "VIB-LIM 00    00    00"
VIB_DIR:
    .BYTE "VIB-DIR 00    00    00"
VOLUME:
    .BYTE "VOLUME  00    00          00"

TUNE_NAME_LO:
    .LOBYTES TUNE0
TUNE_NAME_HI:
    .HIBYTES TUNE0

TUNE0: .BYTE "6-CHANNEL TESTER",$FF