.import __DRIVERZP_RUN__, __DRIVERABS_RUN__
.import __DRIVERZP_SIZE__, __DRIVERABS_SIZE__

.segment "DRIVERZP":zp

PC_A: .res 2 ; $D0-$D1
PC_B: .res 2 ; $D2-$D3
PC_C: .res 2 ; $D4-$D5
PC_D: .res 2 ; $D6-$D7
PC_E: .res 2 ; $D8-$D9
PC_F: .res 2 ; $DA-$DB

point_A: .res 2 ; $DC-$DD
point_B: .res 2 ; $DE-$DF
point_D: .res 2 ; $E0-$E1
point_E: .res 2 ; $E2-$E3
point_F: .res 2 ; $E4-$E5

sp_A: .res 1 ; $E6
sp_B: .res 1 ; $E7
sp_C: .res 1 ; $E8
sp_D: .res 1 ; $E9
sp_E: .res 1 ; $EA
sp_F: .res 1 ; $EB

freq_A: .res 2 ; $EC-$ED
freq_B: .res 2 ; $EE-$EF
freq_C: .res 2 ; $F0-$F1
freq_F: .res 2 ; $F2-$F3

old_note_A: .res 1 ; $F4
old_note_B: .res 1 ; $F5
old_note_C: .res 1 ; $F6
old_note_D: .res 1 ; $F7
old_note_E: .res 1 ; $F8
old_note_F: .res 1 ; $F9

EFF_zp: .res 2 ; $FA-$FB

CLEAR1 = <__DRIVERZP_SIZE__

.segment "DRIVERABS"

stack_size = 3 ; Size of stack for nested GOSUB's.

stack_LO_A: .res stack_size ; $700-$702
stack_LO_B: .res stack_size ; $703-$705
stack_LO_C: .res stack_size ; $706-$708
stack_LO_D: .res stack_size ; $709-$70B
stack_LO_E: .res stack_size ; $70C-$70E
stack_LO_F: .res stack_size ; $70F-$711

stack_HI_A: .res stack_size ; $712-$714
stack_HI_B: .res stack_size ; $715-$717
stack_HI_C: .res stack_size ; $718-$71A
stack_HI_D: .res stack_size ; $71B-$71D
stack_HI_E: .res stack_size ; $71E-$720
stack_HI_F: .res stack_size ; $721-$723

ADSR_init_A: .res 1 ; $724
ADSR_init_B: .res 1 ; $725
ADSR_init_D: .res 1 ; $726
ADSR_init_E: .res 1 ; $727
ADSR_init_F: .res 1 ; $728

ADSR_att_A: .res 1 ; $729
ADSR_dec_A: .res 1 ; $72A
ADSR_att_B: .res 1 ; $72B
ADSR_dec_B: .res 1 ; $72C
ADSR_att_D: .res 1 ; $72D
ADSR_dec_D: .res 1 ; $72E
ADSR_att_E: .res 1 ; $72F
ADSR_dec_E: .res 1 ; $730
ADSR_att_F: .res 1 ; $731
ADSR_dec_F: .res 1 ; $732

ADSR_sus_A: .res 1 ; $733
ADSR_sus_B: .res 1 ; $734
ADSR_sus_D: .res 1 ; $735
ADSR_sus_E: .res 1 ; $736
ADSR_sus_F: .res 1 ; $737

ADSR_cyc_A: .res 1 ; $738
ADSR_cyc_B: .res 1 ; $739
ADSR_cyc_D: .res 1 ; $73A
ADSR_cyc_E: .res 1 ; $73B
ADSR_cyc_F: .res 1 ; $73C

ADSR_stage_A: .res 1 ; $73D
ADSR_stage_B: .res 1 ; $73E
ADSR_stage_D: .res 1 ; $73F
ADSR_stage_E: .res 1 ; $740
ADSR_stage_F: .res 1 ; $741

ADSR_time_A: .res 1 ; $742
ADSR_time_B: .res 1 ; $743
ADSR_time_D: .res 1 ; $744
ADSR_time_E: .res 1 ; $745
ADSR_time_F: .res 1 ; $746

wob_wait_A: .res 1 ; $747
wob_wait_B: .res 1 ; $748
wob_wait_C: .res 1 ; $749
wob_wait_D: .res 1 ; $74A
wob_wait_E: .res 1 ; $74B
wob_wait_F: .res 1 ; $74C

wob_delay1_A: .res 1 ; $74D
wob_delay1_B: .res 1 ; $74E
wob_delay1_C: .res 1 ; $74F
wob_delay1_D: .res 1 ; $750
wob_delay1_E: .res 1 ; $751
wob_delay1_F: .res 1 ; $752

wob_delay2_A: .res 1 ; $753
wob_delay2_B: .res 1 ; $754
wob_delay2_C: .res 1 ; $755
wob_delay2_D: .res 1 ; $756
wob_delay2_E: .res 1 ; $757
wob_delay2_F: .res 1 ; $758

wob_off_A: .res 1 ; $759
wob_off_B: .res 1 ; $75A
wob_off_C: .res 1 ; $75B
wob_off_D: .res 1 ; $75C
wob_off_E: .res 1 ; $75D
wob_off_F: .res 1 ; $75E

port_A: .res 1 ; $75F
port_B: .res 1 ; $760
port_C: .res 1 ; $761
port_F: .res 1 ; $762

target_A: .res 1 ; $763
target_B: .res 1 ; $764
target_C: .res 1 ; $765
target_F: .res 1 ; $766

duty_A: .res 1 ; $767
duty_B: .res 1 ; $768
duty_F: .res 1 ; $769

vib_delay_A: .res 1 ; $76A
vib_delay_B: .res 1 ; $76B
vib_delay_C: .res 1 ; $76C
vib_delay_F: .res 1 ; $76D

vib_delay1_A: .res 1 ; $76E
vib_delay1_B: .res 1 ; $76F
vib_delay1_C: .res 1 ; $770
vib_delay1_F: .res 1 ; $771

vib_rate_A: .res 1 ; $772
vib_rate_B: .res 1 ; $773
vib_rate_C: .res 1 ; $774
vib_rate_F: .res 1 ; $775

vib_limit1_A: .res 1 ; $776
vib_limit1_B: .res 1 ; $777
vib_limit1_C: .res 1 ; $778
vib_limit1_F: .res 1 ; $779

vib_limit2_A: .res 1 ; $77A
vib_limit2_B: .res 1 ; $77B
vib_limit2_C: .res 1 ; $77C
vib_limit2_F: .res 1 ; $77D

vib_dir_A: .res 1 ; $77E
vib_dir_B: .res 1 ; $77F
vib_dir_C: .res 1 ; $780
vib_dir_F: .res 1 ; $781

eff_time_A: .res 1 ; $782
eff_time_B: .res 1 ; $783
eff_time_C: .res 1 ; $784
eff_time_D: .res 1 ; $785
eff_time_E: .res 1 ; $786
eff_time_F: .res 1 ; $787

eff_freq_A: .res 2 ; $788-$789
eff_freq_B: .res 2 ; $78A-$78B
eff_freq_C: .res 2 ; $78C-$78D
eff_freq_D: .res 1 ; $78E
eff_freq_E: .res 1 ; $78F
eff_freq_F: .res 2 ; $790-$791

eff_wait_A: .res 1 ; $792
eff_wait_B: .res 1 ; $793
eff_wait_C: .res 1 ; $794
eff_wait_D: .res 1 ; $795
eff_wait_E: .res 1 ; $796
eff_wait_F: .res 1 ; $797

stack_A: .res 2 ; $798-$799
stack_B: .res 2 ; $79A-$79B
stack_C: .res 2 ; $79C-$79D
stack_D: .res 2 ; $79E-$79F
stack_E: .res 2 ; $7A0-$7A1
stack_F: .res 2 ; $7A2-$7A3

time_A: .res 1 ; $7A4
time_B: .res 1 ; $7A5
time_D: .res 1 ; $7A6
time_E: .res 1 ; $7A7
time_F: .res 1 ; $7A8

stop_A: .res 1 ; $7A9
stop_B: .res 1 ; $7AA
stop_C: .res 1 ; $7AB
stop_D: .res 1 ; $7AC
stop_E: .res 1 ; $7AD
stop_F: .res 1 ; $7AE

transpose_A: .res 1 ; $7AF
transpose_B: .res 1 ; $7B0
transpose_C: .res 1 ; $7B1
transpose_F: .res 1 ; $7B2

repeat_A: .res 1 ; $7B3
repeat_B: .res 1 ; $7B4
repeat_C: .res 1 ; $7B5
repeat_D: .res 1 ; $7B6
repeat_E: .res 1 ; $7B7
repeat_F: .res 1 ; $7B8

distort_A: .res 1 ; $7B9
distort_B: .res 1 ; $7BA
distort_C: .res 1 ; $7BB
distort_F: .res 1 ; $7BC

length_A: .res 1 ; $7BD
length_B: .res 1 ; $7BE
length_C: .res 1 ; $7BF
length_D: .res 1 ; $7C0
length_E: .res 1 ; $7C1
length_F: .res 1 ; $7C2

oldfreq_A: .res 1 ; $7C3
oldfreq_B: .res 1 ; $7C4
oldfreq_C: .res 1 ; $7C5
oldfreq_F: .res 1 ; $7C6

ADSR_control_A: .res 1 ; $7C7
ADSR_control_B: .res 1 ; $7C8
ADSR_control_D: .res 1 ; $7C9
ADSR_control_E: .res 1 ; $7CA
ADSR_control_F: .res 1 ; $7CB

volume_A: .res 1 ; $7CC
volume_B: .res 1 ; $7CD
volume_D: .res 1 ; $7CE
volume_E: .res 1 ; $7CF
volume_F: .res 1 ; $7D0

flip1_A: .res 1 ; $7D1
flip1_B: .res 1 ; $7D2
flip1_C: .res 1 ; $7D3
flip1_D: .res 1 ; $7D4
flip1_E: .res 1 ; $7D5
flip1_F: .res 1 ; $7D6

or_D: .res 1 ; $7D7
or_E: .res 1 ; $7D8

ignore_A: .res 1 ; $7D9
ignore_B: .res 1 ; $7DA
ignore_C: .res 1 ; $7DB
ignore_F: .res 1 ; $7DC

cutoff_A: .res 1 ; $7DD
cutoff_B: .res 1 ; $7DE
cutoff_D: .res 1 ; $7DF
cutoff_E: .res 1 ; $7E0
cutoff_F: .res 1 ; $7E1

endit_A: .res 1 ; $7E2
endit_B: .res 1 ; $7E3
endit_D: .res 1 ; $7E4
endit_E: .res 1 ; $7E5
endit_F: .res 1 ; $7E6

maul_A: .res 1 ; $7E7
maul_B: .res 1 ; $7E8
maul_D: .res 1 ; $7E9
maul_E: .res 1 ; $7EA
maul_F: .res 1 ; $7EB

count_A: .res 1 ; $7EC
count_B: .res 1 ; $7ED
count_C: .res 1 ; $7EE
count_D: .res 1 ; $7EF
count_E: .res 1 ; $7F0
count_F: .res 1 ; $7F1

sweep_A: .res 1 ; $7F2
sweep_B: .res 1 ; $7F3
sweep_F: .res 1 ; $7F4

CLEAR2 = <__DRIVERABS_SIZE__

Music_ZP = __DRIVERZP_RUN__ ; DEFAULT DRIVERZP = $D0
Music_MEM = __DRIVERABS_RUN__ ; DEFAULT DRIVERABS = $700