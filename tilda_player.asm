*
* Legend of Tilda
* Copyright (c) 2019 Pete Eberlein
*
* Music and sound player (with ultra-low memory usage)
* (2 bytes per music, 2 bytes per sound) * 4 channels = 16 bytes CPU RAM
* (2 bytes VDP per music) = 8 bytes VDP RAM


* duration is 3 bits
* pointer is 13 bits (8k range, in current bank)

* variables
* music track 1 ptr & dur
* music track 2 ptr & dur
* music track 3 ptr & dur
* music track 4 ptr & dur
* sound effect track 1 ptr
* sound effect track 2 ptr
* sound effect track 3 ptr
* sound effect track 4 ptr
* return music pattern ptr in VDP for each music track

* pattern format
* 0ddd vvvv           duration and volume
* 1ddd vvvv nnnnnnnn  duration, volume and note table index

* note table
*  0000 zzzz 00xx yyyy  frequency divider xyz 0-1023 or noise 0-7
*  aaaa aaaa aaaa aaaa  subpattern address (current address stored in VDP)
*  1111 1111 1111 1111  subpattern return (return address loaded from VDP)
*    subpattern return could also be fixed table entry 255
*    sound effects must terminate with subpattern return
* number of note table entries cannot exceed 256

* sound effects which utilize GEN3 should always have a track3


       ; Music and Sound player 
       ; Modifies R0-R3,R12
       LI R1,MUSIC1  ; Track or sound pointer
       LI R12,>8000  ; Sound channel 1
       
CHANLP ; channel loop
       MOV *R1,R2   ; R2 = music ptr (points to next note to be played)
       JEQ SNDST     ; no music playing

       LI R0,>2000   ; Adder for duration in bit 13
       C R2,R0
       JL !
       S R0,*R1     ; decrement duration
       JMP SNDST    ; duration not expired yet

!      ; decode next music note or volume and play it (if no sound is playing)
MUSDEC
       MOVB @CARTAD(R2),R0  ; R0=0dddvvvv or 1dddvvvv
       INC R2         ; inc pointer

       MOV R0,R3
       ANDI R3,>7000  ; get duration
       SLA R3,1       ; shift left
       A R2,R3        ; add to pointer
       MOV R3,*R1+    ; save new duration and pointer

       MOVB R0,R0
       JLT MUSNOT   ; music note (sign bit)

       ; update volume only

       MOV *R1,R3  ; R3 = sound ptr
       JNE SNDPLA  ; sound playing
       ; no sound effect, change volume

       JMP DOVOL
       
MUSNOT
       ; R0 = volume >0X00
       ; R2 = encoded music pointer
       INC @-2(R1)    ; inc music pointer

       MOVB @CARTAD(R2),R2 ; get note index
       JNE !
       ;CLR @-2(R1)    ; stop music
       ;JMP SNDEND
       ; return from subpattern music pointer
       MOV R1,R0
       AI R0,-2+MUS1RT-MUSIC1
       MOVB @R0LB,*R14
       MOVB R0,*R14
       DECT R1       ; delaying before read
       MOVB @VDPRD,R2
       MOVB @VDPRD,@R2LB
       JMP MUSDEC

!
       SRL R2,8
       A R2,R2
       MOV @NOTETAB(R2),R2
       CI R2,>1000   ; sound notes are less than >1000
       JL !
       
       ; subpattern - save current pointer and jump to new
       DECT R1
       MOV R1,R0
       AI R0,MUS1RT-MUSIC1+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB *R1,*R15
       MOVB @1(R1),*R15

       ANDI R2,>1FFF
       JMP MUSDEC
       
!
       MOV *R1,R3  ; R3 = sound ptr
       JEQ DONOTE  ; no sound playing

       CI R3,NOTETAB & >1FFF  ; sound done?
       JNE SNDPLA
       CLR *R1     ; turn off sound
       
DONOTE
       A R12,R2
       MOVB R2,@SNDREG   ; write first byte
       CI R12,>E000
       JEQ !
       MOVB @R2LB,@SNDREG   ; write second byte
!
DOVOL  ; R0 = volume >0X00
       ANDI R0,>0F00 ; get volume
       A R12,R0      ; add channel in upper nibble
       ORI R0,>1000  ; set volume address
       MOVB R0,@SNDREG  ; write byte to sound reg

       JMP SNDEND


       ; music is playing but nothing changed
SNDST

       INCT R1     ; get sound track ptr
       MOV *R1,R3  ; R3 = sound ptr
       JEQ SNDEND  ; no sound playing

SNDPLA ; R3 = sound pointer
       LI R0,>2000   ; Adder for duration in bit 13
       C R3,R0
       JL !
       S R0,*R1     ; decrement duration
       JMP SNDEND    ; duration not expired yet

!      ; decode next sound note or volume and play it
       MOVB @CARTAD(R3),R0  ; R0=0dddvvvv or 1dddvvvv
       INC R3         ; inc pointer

       MOV R0,R2
       ANDI R2,>7000  ; get duration
       SLA R2,1       ; shift left
       A R3,R2        ; add to pointer
       MOV R2,*R1     ; save new duration and pointer

       MOVB R0,R0
       JGT DOVOL      ; sound vol (no sign bit)
       JEQ DOVOL

SNDNOT ; sound note (sign bit) 
       ; R0 = volume >0X00
       ; R3 = encoded sound pointer
       INC *R1    ; inc sound pointer

       MOVB @CARTAD(R3),R2 ; get note index
       JNE !
       ; zero index, end of sound
       LI R0,NOTETAB & >1FFF
       MOV R0,*R1   ; store ending note
       
       JMP SNDEND
!
       SRL R2,8
       A R2,R2
       MOV @NOTETAB(R2),R2
       JMP DONOTE

SNDEND
       INCT R1    ; get next music ptr

       AI R12,>2000 ; increment sound channel

       CI R1,SOUND4+2  ; end of tracks?
       JNE CHANLP
