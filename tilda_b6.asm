;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 6: music and sounds



       COPY 'tilda.asm'

* pointer is 13 bits (8k range, in current bank)
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
* 1ddd 1111 00000000  end of pattern
* 1xxx xxxx 11111111 yyyyyyyy relative jump

* sound effect track 1,2,3 format
* 0ddd vvvv           duration and volume
* 1ddd vvvv nnnnnnnn  duration and note table
* 1ddd 1111 00000000  end of sound effect

* sound effect track 4 format
* 0ddd vvvv           duration and volume
* 1ddd vvvv 11111nnn  duration and noise
* 1ddd 1111 00000000  end of sound effect

* note table
*  0000 zzzz xxxx yyyy  frequency xyz



MAIN


; Music and Sound player 
; Modifies R0-R4,R13
       LI R1,TRACK1  ; Track or sound pointer
       LI R4,>2000   ; Adder for duration in bit 13
       LI R13,SNDREG  ; Sound chip address
       
CHANLP ; channel loop
       MOV *R1,R2   ; R2 = music ptr (points to next note to be played)
       JEQ SNDST     ; no music playing

       S R4,*R1     ; decrement duration

       C R2,R4
       JHE SNDST    ; no change
       
       ; load next music note and play it (if no sound is playing)
       
       
       MOVB @6000(R2),R0  ; R0=0dddvvvv or 1dddvvvv
       JLT MUSNOT   ; music note (sign bit)

       ; update volume only
       
       MOV R0,R3
       ANDI R3,>7000  ; get duration
       SLA R3,1       ; shift left
       A R3,R2        ; add to pointer
       INC R2         ; inc pointer
       MOV R2,*R1+    ; save new duration and pointer
       

       MOV *R1,R2  ; R2 = sound ptr
       JNE SNDPLA  ; sound playing
       ; no sound effect, change volume

DOVOL  ; R0 = volume >0X00
       ANDI R0,>0F00 ; get volume
       MOV R1,R2
       AI R2,-TRACK1 ; get track or sound offset  
       ANDI R2,>000C ; get gen number
       SRC R2,5      ; shift into other byte
       A R2,R0
       ORI R0,>9000  ; set volume address
       MOVB R0,@SNDREG
       JMP SNDEND
       
MUSNOT
       MOVB @6001(R2),R2 ; get note type
       JEQ MUSOFF    ; zero means turn off
       SRL R2,7
       
       
       
       
       ; volume in R0,
       ; note in R3
       
       

       JMP SNDEND

       ; music is playing but nothing changed
SNDST

       INCT R1     ; get sound track ptr
       MOV *R1,R2  ; R2 = sound ptr
       JEQ SNDEND  ; no sound playing

SNDPLA
       
       S R4,*R1    ; decrement duration
       C R2,R4
       JHE SNDEND  ; no change

       


SNDEND
       INCT R1    ; get music ptr


       CI R1,SOUND4+2  ; end of tracks?
       JNE CHANLP

       CLR R0      ; return to bank 0
       MOV R11,R1
       B @BANKSW
MUSOFF
       CLR *R1   ; disable music track
       JMP SNDST
       
SNDOFF
       CLR *R1   ; disable sound track
       JMP SNDEND



DONOTE


       COPY 'music.asm'
       COPY 'sound.asm'
