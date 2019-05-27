;
; Legend of Tilda
; Copyright (c) 2019 Pete Eberlein
;
; Bank 7: title+finale music and sounds

       COPY 'tilda.asm'

MAIN   ; R11 = return address

       ; modifies R0-R3,R12
       COPY 'tilda_player.asm'

       LI R0,BANK4      ; return to bank 4
       MOV R11,R1
       B @BANKSW

       ; overworld and dungeon music, and sound effects
       COPY "tilda_music1.asm"


* title screen music pointers
TSMUS1 EQU TSF00 & >1FFF    ; tilda_equ
TSMUS2 EQU TSF01 & >1FFF    ; tilda_equ
TSMUS3 EQU TSF02 & >1FFF    ; tilda_equ
TSMUS4 EQU TSF03 & >1FFF    ; tilda_equ

* ending credits pointers
ECMUS1 EQU TSF10 & >1FFF    ; tilda_equ
ECMUS2 EQU TSF11 & >1FFF    ; tilda_equ
ECMUS3 EQU TSF12 & >1FFF    ; tilda_equ
ECMUS4 EQU TSF13 & >1FFF    ; tilda_equ

* Rupee / Menu cursor
SNDCR1 EQU TSF21 & >1FFF    ; tilda_equ

* Clunk
SNDCL0 EQU TSF30 & >1FFF    ; tilda_equ

* Link hurt
SNDLH2 EQU TSF42 & >1FFF    ; tilda_equ
SNDLH3 EQU TSF43 & >1FFF    ; tilda_equ

