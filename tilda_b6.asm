;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 6: music and sounds



       COPY 'tilda.asm'

* pointer is 13 bits (8k range)
* duration is 3 bits

* variables
* music track 1 ptr & dur
* music track 2 ptr & dur
* music track 3 ptr & dur
* music track 4 ptr & dur
* sound effect track 1 ptr
* sound effect track 2 ptr
* sound effect track 3&4 ptr

* music pattern ptr in VDP
* pattern format
* 0ddd vvvv           duration and volume
* 1ddd vvvv nnnnnnnn  duration and note table
* 1ddd vvvv 00000000  end of pattern
* 1xxx xxxx 11111111 yyyyyyyy relative jump

* sound effect track 1,2,3 format
* 0ddd vvvv           duration and volume
* 1ddd vvvv nnnnnnnn  duration and note table
* 1ddd vvvv 00000000  end of sound effect

* sound effect track 4 format
* 0ddd vvvv           duration and volume
* 1ddd vvvv 11111nnn  duration and noise
* 1ddd vvvv 00000000  end of sound effect

* note table
*  0000 zzzz xxxx yyyy  frequency xyz
*  1aaa aaaa aaaa aaaa  pattern address



MAIN

       ;LI R1,>8000   ; Gen1
       LI R1,TRACK1
       LI R4,>2000   ; Adder for duration
       LI R13,>8400  ; sound chip address
CHANLP ; channel loop
       MOV *R1,R2   ; R2 = music ptr
       JEQ !        ; no music playing

       S R4,*R1+    ; decrement duration

       C R2,R4
       JHE !
       ; load next music note and play it (if no sound is playing)
       MOVB @6000(R2),R0
       ;JLT MUSNOT


       ; get volume
       MOV R0,R3
       ANDI R3,>7000
       SLA R3,1
       A R3,R2
       MOV R2,@-2(R1) ; save new duration and pointer
       ANDI R0,>0F00 ; get volume




       MOV *R1+,R3  ; R3 = sound ptr
       JNE SNDPLA

       ; no sound effect, play music note

       JMP SNDEND
!
       ; music is playing but nothing changed

       MOV *R1+,R3  ; R3 = sound ptr
       JEQ SNDEND




SNDPLA

       CI R1,>E000
       JEQ !
       ; channel 1-3 sound
       INCT @-2(R1)

       ; play 2 byte sound
       MOV *R3,R0
       ANDI R0,>0FFF ; get tone only
       CI R0,>0080   ; stop code
       JEQ SNDOFF
 
       ; play sound effect
       A R1,R0
       MOVB R0,*R13      ; write note part 1
       MOVB @R0LB,*R13   ; write note part 2
       JMP VOLPL1
!
       INC @-2(R1)

       ; channel 4 noise
       MOVB *R3,R0
       ANDI R0,>0F00
       A R1,R0
       MOVB R3,*R13     ; write noise

VOLPL1
       MOVB *R3,R0
       SRL R0,4
VOLPL2
       A R1,R0
       AI R0,>1000
       MOVB R0,*R13  ; write  volume

SNDEND


       AI R1,>2000   ; Next channel >A000,>C000,>E000
       JNE CHANLP

       CLR R0      ; return to bank 0
       MOV R11,R1
       B @BANKSW

SNDOFF
       CLR @-2(R1)   ; disable sound effect
       JMP SNDEND



       COPY 'music.asm'