;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 4: title screen animation, game over animation, hero sprites, load enemies
;

       COPY 'tilda.asm'
       COPY 'tilda_b6_equ.asm'
       COPY 'tilda_b7_equ.asm'

CLRSAV EQU WRKSP+>30

;
; R2 = 0 title screen (only from bank3)
;      1 game over screen
;      2 load hero sprites, walk and attack (R3 = direction)
;      3 load hero sprite attack stance (R3 = direction)
;      4 read keys/joystick
;      5 load hero sprites masked LEFT (R3 = direction, R4=count)
;      6 load hero sprites masked RIGHT (R3 = direction, R4=count)
;      7 load hero sprites masked BOTTOM (R3 = direction, R4=count)
;      8 load hero sprites masked TOP (R3 = direction, R4=count)
;      9 load hero sprites holding item
;     10 load enemies TODO move to bank1
;     11 main menu  (only from bank3)

MAIN
       MOV R11,R13      ; Save return address for later
       LI R11,DONE2     ; LNKSPR needs this
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA TITLE,GAMOVR,LNKSPR,LNKATK,DOKEYS,MSKLFT,MSKRGT,MSKBOT,MSKTOP,LNKITM,0,MMENU

       COPY 'tilda_common.asm'

DONE2  LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW

* Modifies R0-R3,R12
VSYNCM
       CLR R12               ; CRU Address bit 0002 - VDP INT
!      TB 2                  ; CRU bit 2 - VDP INT
       JEQ -!                ; Loop until set
       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU

       LI R0,BANK7             ; play music in bank 7
       LI R1,MAIN
       B @BANKSW               ; return after bankswitch
       RT

* Update Sprite List to VDP Sprite Table
* Modifies R0-R2
SPRUPD
       LI R0,SPRTAB  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU
       LI R2,128     ; Copy all 32 sprites
       B @VDPW

LNKHRC ; Hero hurt colors, 2 frames each
       DATA >0301      ; green, black  (normal colors)  TODO blue/red based on rings
       DATA >040F      ; dark blue, white
       DATA >060F      ; red, white
       DATA >0106      ; black, red

LNKCLR ; set link color based on rings
       MOV @HFLAG2,R0
       ANDI R0,REDRNG+BLURNG
       JEQ !!  ; if no rings, then green
       LI R1,BLUCLR ; Light Blue
       ANDI R0,REDRNG
       JEQ !
       LI R1,REDCLR ; Medium Red
!      MOVB R1,@HEROSP+3  ; hero sprite color
       MOVB R1,@MPDTSP+3  ; map dot sprite color
!
       RT



TITLE
       LI R0,CLRTAB        ; Load color table
       LI R1,CLRSAV
       LI R2,32
       BL @VDPR

       LI R0,>0700
       BL @BGCOL

       B @INITSD    ; skip title screen


       ; load title screen music, and clear sound effects
       LI R1,MUSIC1
       LI R0,TSMUS1
       MOV R0,*R1+
       CLR *R1+
       LI R0,TSMUS2
       MOV R0,*R1+
       CLR *R1+
       LI R0,TSMUS3
       MOV R0,*R1+
       CLR *R1+
       LI R0,TSMUS4
       MOV R0,*R1+
       CLR *R1+

       ;B @MMENU    ; skip title screen

       CLR  R4          ; waterfall counter

       LI R9, 1         ; Reset tiforce counter
       LI R8,TIPAT      ; Tiforce pattern pointer

MLOOP
       BL @WATERF

       BL @VSYNCM

       DEC R9            ; Decrement tiforce counter
       JNE !             ; until zero
       BL @TIFORC
!
       ; update sprites after tiforce so palette and sprites stay in sync
       BL @SPRUPD
       ; BL @MUSIC

       INC R4

       BL @DOKEYS
       MOV @KEY_FL,R0
       ANDI R0,EDG_A
       JEQ !

       BL @QUIET
       LI R0,BANK3
       LI R1,MAIN
       LI R2,6  ; main menu
       MOV R13,R11
       B @BANKSW

!


       CI R4,553
       JNE !
       LI R0,>0300     ; Light green
       BL @BGCOL
       JMP MLOOP
!
       CI R4,561
       JNE !
       LI R0,>0500     ; Light blue
       BL @BGCOL
       JMP MLOOP
!
       CI R4,567
       JNE !
       LI R0,>0700     ; Cyan
       BL @BGCOL
       JMP MLOOP
!
       CI R4,572
       JNE !
       LI R0,>0300     ; Light green
       BL @BGCOL
       LI R1,SWDGRY     ; Sword gray
       BL @SWDCOL
       LI R0,>0400      ; Sword hilt dark blue
       MOVB R0,@SPRLST+(19*4)+3
       JMP MLOOP
!
       CI R4,585
       JNE !
       LI R0,>0100     ; Black
       BL @BGCOL
       LI R0,>0E00     ; Gray
       BL @WFCOL
       LI R0,CLRTAB     ; Load color table
       LI R1,CLRST2
       LI R2,32
       BL @VDPW

       LI R9,1
       LI R8,TIPURP
       JMP MLOOP

!      CI R4,777
       JNE !
       ; Waterfall darker
       LI R0,>0400     ; Dark blue
       BL @WFCOL
       JMP MLOOP

!      CI R4,783
       JNE !
       LI R0,CLRTAB     ; Load color table
       LI R1,CLRST3
       LI R2,32
       BL @VDPW
       LI R9,500
       LI R0,>0100      ; Sword hilt black
       MOVB R0,@SPRLST+(19*4)+3
MLOOP2 JMP MLOOP

!      CI R4,787
       JNE !!
       LI R0,CLRTAB+VDPWM   ; Load color table
       LI R1,>1100      ; Black
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R2,32
!      CLR *R15
       DEC R2
       JNE -!
       LI R0,>0100     ; Black
       BL @WFCOL
       LI R9,1
       LI R8,TIBLCK
       JMP MLOOP2

!      CI R4,6000     ; 1030 starts scrolling text
       JNE MLOOP2

       LI R0,BANK3
       LI R1,MAIN
       CLR R2           ; title
       MOV R13,R11      ; restore return address
       B @BANKSW

       ; Tiforce colors and durations
TIPAT  DATA >0906,>0B0C,>0906,>0806,>060C,>0810,>0000

       ; Draw Tiforce with tiforce pointer in R8, counter in R9
TIFORC
       MOV *R8+,R9       ; load next tiforce counter
       JNE !
       LI R8,TIPAT
       JMP TIFORC
!
       LI R1,SPRLST+3
       LI R2,19

       ; update sprites
!      MOVB R9,*R1
       C *R1+,*R1+     ; R1 += 4
       DEC R2
       JNE -!

       ; update palette entry for characters
       AI R9,>1000 ; add black for palette entry
       LI R0,CLRTAB+0+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R9,*R15

       ANDI R9,>00FF
       RT

       ; Draw waterfall with counter in R4
WATERF
       ; calculate offset for character change
       MOV R4,R5
       DEC R5
       MOV R5,R0
       ANDI R0,>0007
       JNE WAVES

       ANDI R5,>0008
       SLA R5,7

       ; animate top off waterfall (row 17 col 10)
       LI R0,SCR1TB+(32*17)+10+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,>E800
       A R5,R1
       LI R2,4
!      MOVB R1,*R15
       AI R1,>100
       DEC R2
       JNE -!

       A R5,R5

       ; animate spray on waterfall
       AI R5,>7000
       MOVB R5,@SPRLST+(4*20)+2
       AI R5,>0400
       MOVB R5,@SPRLST+(4*21)+2

WAVES
       MOV R4,R0
       ANDI R0,>0003
       JNE !

       MOV R4,R5
       ANDI R5,>0004
       SLA R5,9

       ; animate top wave
       AI R5,>5000
       MOVB R5,@SPRLST+(4*22)+2
       AI R5,>0400
       MOVB R5,@SPRLST+(4*23)+2
!
       ; calculate waterfall wave y offset
       MOV R4,R5
       ANDI R5,>0007
       SLA R5,9
       AI R5,>8900

       ; set y offset for each pair of wave sprites
       LI R1,SPRLST+(4*22)
       LI R2,3
!      MOVB R5,*R1
       C *R1+,*R1+
       MOVB R5,*R1
       C *R1+,*R1+
       AI R5,>1000
       DEC R2
       JNE -!

       RT

       ; Set waterfall to color in R0
WFCOL
       MOV R0,R1
       LI R0,SPRLST+(4*20)+3
       LI R2,8
!      MOVB R1,*R0
       C *R0+,*R0+
       DEC R2
       JNE -!
       RT

       ; Set background colors to R0
BGCOL
       MOV R0,R5
       SWPB R0
       ORI R0,>87F0      ; VDP Register 7: White on Cyan
       MOVB @R0LB,*R14      ; Send low byte of VDP Register Data
       MOVB R0,*R14         ; Send high byte of VDP Register Number


       LI R0,CLRTAB+VDPWM     ; Load color table
       MOVB @R0LB,*R14      ; Send low byte of VDP Write Address
       MOVB R0,*R14         ; Send high byte of VDP Write Address
       LI R1,CLRSAV
       LI R2,31
BGCOL2 MOVB *R1+,R3
       MOV R3,R0
       ANDI R0,>0F00
       CI R0,>0700
       JNE !
       ANDI R3,>F000
       A R5,R3
!      MOVB R3,*R15
       DEC R2
       JNE BGCOL2

       RT

       ; Set sword colors to R1 pointer
SWDCOL
       LI R0,CLRTAB+25     ; Load color table
       LI R2,2
       B @VDPW

SWDGRY DATA >E3E3,>E1E1    ; Sword gray on green
TIPURP DATA >05FF
TIBLCK DATA >01FF

CLRST2 BYTE >E0,>10,>40,>E0            ;
       BYTE >E1,>E1,>E1,>E1            ;
       BYTE >E1,>E1,>E1,>E1            ;
       BYTE >F0,>41,>41,>11            ;
       BYTE >41,>41,>41,>41            ;
       BYTE >41,>41,>41,>11            ;
       BYTE >11,>E1,>E1,>E1            ;
       BYTE >11,>41,>40,>15            ;

CLRST3 BYTE >E0,>10,>40,>E0            ;
       BYTE >E1,>E1,>E1,>E1            ;
       BYTE >E1,>E1,>E1,>E1            ;
       BYTE >F0,>41,>41,>11            ;
       BYTE >11,>11,>11,>11            ;
       BYTE >11,>11,>11,>11            ;
       BYTE >11,>41,>41,>11            ;
       BYTE >11,>11,>10,>11            ;


VSYNC0 ; Do vsync and music from bank0
       LI R0,BANK0
       MOV R12,R1
       B @BANKSW

* R12=VSYNC0 bank0 address
GAMOVR       ; GAME OVER

       ; HP is zero, game over and restart

       LI R0,>D000
       MOVB R0,@SPRLST+(4*6)+0 ; Turn off sprites 6+
       MOVB R0,@SPRLST+(4*31)+0 ; Turn off sprites 6+
       BL @SPRUPD
       BL @VSYNC0
       LI R3,DIR_DN

       BL @LNKSPR

       LI R4,32      ; Hurt Blink 32 frames
!      MOV R4,R1
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2
       BL @VSYNC0
       BL @SPRUPD
       DEC R4
       JNE -!

       BL @LNKCLR
       BL @SPRUPD

       BL @QUIET
       LI R0,SND151      ; Game over sound
       MOV R0,@SOUND2

       LI R4,26
!      BL @VSYNC0
       DEC R4
       JNE -!

       LI R5,DEDCLR
       BL @FGCSET
       BL @VSYNC0
       BL @VSYNC0


       LI R0,CLRTAB
       LI R1,DEDCLR
       LI R2,32
       BL @VDPW
       BL @VSYNC0
       BL @VSYNC0

       
       LI R4,16    ; spin 16 times, 5 frames each
!
       BL @VSYNC0
       BL @VSYNC0
       BL @VSYNC0
       BL @VSYNC0
       BL @VSYNC0
       MOV R4,R3
       ANDI R3,>0003
       A R3,R3
       MOV @LNKSPN(R3),R3
       BL @LNKSPR
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL2
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @VSYNC0
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL3
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @VSYNC0
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL4
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @VSYNC0
       DEC R4
       JNE -!

       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       ORI R0,VDPWM+(3*32)
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,>2000  ; Fill screen with Space
       LI R2,21*32
!      MOVB R1,*R15
       DEC R2
       JNE -!

       LI R0,>0E00
       MOVB R0,@HEROSP+3   ; Set hero color to gray
       BL @SPRUPD
       LI R4,24
!      BL @VSYNC0
       DEC R4
       JNE -!


       LI R0,>E800
       MOVB R0,@HEROSP+2   ; Set hero sprite index to little star
       BL @SPRUPD
       LI R4,10
!      BL @VSYNC0
       DEC R4
       JNE -!

       ; play text writing sound
       LI R0,SND100
       MOV R0,@SOUND1

       LI R0,>EC00
       MOVB R0,@HEROSP+2   ; Set hero sprite index to big star
       BL @SPRUPD
       LI R4,4
!      BL @VSYNC0
       DEC R4
       JNE -!

       CLR @HEROSP+2   ; Set hero color to transparent
       CLR @HEROSP+6   ; Set hero color to transparent
       BL @SPRUPD
       LI R4,46
!      BL @VSYNC0
       DEC R4
       JNE -!

       ;1133 96 GAME OVER (G below X's) centered vertically
       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       ORI R0,VDPWM+(14*32)+12
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,GAMEOV
       LI R2,9
!      MOVB *R1+,*R15
       DEC R2
       JNE -!

       LI R4,96
!      BL @VSYNC0
       DEC R4
       JNE -!

!      BL @VSYNC0
       JMP -!
       ;B @CONSAV ; Continue save mainmenu

GAMEOV TEXT 'GAME OVER'

       ; Set foreground colors from colorset at R5
FGCSET MOV R11,R10  ; Save return address
       LI R0,CLRTAB
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       LI R0,CLRTAB+VDPWM
       LI R1,SCRTCH
       LI R2,32
       MOVB @R0LB,*R14
       MOVB R0,*R14

!      MOVB *R1+,R0
       ANDI R0,>0F00
       MOVB *R5+,R3
       ANDI R3,>F000
       A R3,R0
       MOVB R0,*R15
       DEC R2
       JNE -!
       B *R10   ; Return to saved address

LNKSPN DATA DIR_RT,DIR_DN,DIR_LT,DIR_UP

* 939 2 brown on dark red palette
DEDCLR BYTE >16,>96,>96,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>16,>96            ;
       BYTE >96,>96,>16,>41            ;

* 1018 10 brown on lightred palette
DEDCL2 BYTE >18,>98,>98,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >18,>16,>16,>16            ;
       BYTE >16,>18,>98,>98            ;
       BYTE >19,>19,>19,>19            ;
       BYTE >19,>19,>18,>98            ;
       BYTE >98,>98,>18,>41            ;

* 1028 10 dark brown on darkred palette
DEDCL3 BYTE >16,>96,>96,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>16,>96            ;
       BYTE >96,>96,>16,>41            ;

* 1038 10 black on darkred palette
DEDCL4 BYTE >16,>16,>16,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>41            ;

SDINIT ; Initial save data
       BYTE 3           ; Save Data hearts
       BYTE 250         ; Initial Rupees
       BYTE 2           ; Initial Keys
       BYTE >23         ; Initial Max bombs / Bombs
       DATA RAFT+LADDER+BMRANG  ; HFLAGS
       DATA 0                  ; HFLAG2
       DATA 0           ; Dungeon Compasses collected
       DATA 0           ; Dungeon Maps collected
       BYTE 0           ; Dungeon TiForces collected
       DATA 0,0,0,0,0,0,0,0  ; Overworld caves opened
       DATA 0,0,0,0,0,0,0,0  ; Overworld items collected
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; Dungeon rooms visited
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; Dungeon items collected
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; Dungeon doors unlocked
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;   or walls bombed
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; Overworld enemy counts
       DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;
SDINIE



REGSPR ; 6 sprites for player, 1 for heart, 2 for cursors
       DATA >3F30,>8003,>3F30,>840C;>8404
       DATA >5730,>8007,>5730,>8405
       DATA >6F30,>8009,>6F30,>8406;>8404
       DATA >3F20,>880D
       DATA >0000,>9000,>0000,>9400
       BYTE >D0 ; sprite list terminator
CURSRY ; cursor Y locations
       BYTE >3F,>57,>6F,>8B,>9B
REGIMY ; cursor Y locations
       BYTE >17,>2F,>47,>5B
       EVEN

RUPSND
       LI R0,SNDCR1     ; rupee sound
       MOV R0,@SOUND2
       RT

* Main menu - file select, registration mode, elimination mode
* Prerequisite: screens loaded from bank3 at LEVELA
MMENU

       LI R5,LEVELA
       BL @CPYSCR    ; Copy screen

       BL @VSYNCM

       LI R0,SPRTAB     ; load sprites
       LI R1,REGSPR
       LI R2,9*4+1
       BL @VDPW

       ; TODO scan for files

       CLR R13

MMENU1 ; move heart to right row
       LI R0,SPRTAB+(6*4)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB @CURSRY(R13),*R15

MMENU2
       BL @VSYNCM
       BL @DOKEYS

       MOV @KEY_FL,R1

       LI R0,EDG_UP
       CZC R0,R1
       JEQ !
       CI R13,0
       JEQ !

       BL @RUPSND
       DEC R13
       JMP MMENU1
!
       LI R0,EDG_DN
       CZC R0,R1
       JEQ !
       CI R13,4
       JEQ !

       BL @RUPSND
       INC R13
       JMP MMENU1
!
       LI R0,EDG_A
       CZC R0,R1
       JEQ MMENU2

       CI R13,3
       JEQ REGIMD

       CI R13,4
       JNE !
       B @ELIMMD
!
       BL @QUIET
       ; TODO load save game indicated by R13
INITSD
       LI R0,SDHART
       LI R1,SDINIT          ; Inital save data
       LI R2,SDINIE-SDINIT   ; count
       BL @VDPW

       LI R0,BANK0
       LI R1,MAIN
       B @BANKSW     ; start game in bank0



REGEND ; registration end
       ; copy filenames
       LI R5,SCR1TB+(3*32)+14
       LI R6,LEVELA+(8*32)+9
       BL @CPYNAM
       JMP MMENU



REGIMD ; registration mode

       ; copy filenames
       LI R5,SCR1TB+(8*32)+9
       LI R6,LEVELA+>300+(3*32)+14
       BL @CPYNAM

       LI R5,LEVELA+>300
       BL @CPYSCR    ; Copy screen

       ; set sprite list address
       LI R0,SPRTAB+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14

       ; update 6 hero sprites
       LI R1,REGSPR
       LI R2,6
!
       MOV *R1+,R0
       AI R0,>D820
       MOVB R0,*R15
       MOVB @R0LB,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       DEC R2
       JNE -!
       ; update heart sprite
       LI R0,>3C00
       MOVB R0,*R15
       MOVB R0,*R15


REGIM1 ; move heart to right row
       LI R0,SPRTAB+(6*4)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB @REGIMY(R13),*R15

REGIM2
       BL @VSYNCM
       BL @DOKEYS

       MOV @KEY_FL,R1

       LI R0,EDG_A
       CZC R0,R1
       JEQ !
       CI R13,3
       JEQ REGEND
       JMP REGNAM
!
       LI R0,EDG_UP
       CZC R0,R1
       JEQ !
       CI R13,0
       JEQ !
       BL @RUPSND
       DEC R13
       JMP REGIM1
!
       LI R0,EDG_DN
       CZC R0,R1
       JEQ !
       CI R13,3
       JEQ !
       BL @RUPSND
       INC R13
       JMP REGIM1
!
       JMP REGIM2

REGIM3 ; turn off cursor sprites
       CLR R1        ; transparent sprite
       LI R0,SPRTAB+(7*4)+3
       BL @VDPWB
       LI R0,SPRTAB+(8*4)+3
       BL @VDPWB
       LI R13,3
       BL @DOKEYS    ; reset key states

       JMP REGIM1

KEYBUF EQU SCRTCH+8

REGNAM ; registration entering name

!      BL @VSYNCM
       BL @DOKEYS
       MOV @KEY_FL,R0
       JNE -!    ; wait until no keys are pressed


       MOV R13,R6 ; name cursor
       A R13,R6
       A R13,R6   ; times 3
       SLA R6,5  ; times 32
       AI R6,>006E

       LI R2,KEYBUF      ; key pressed flags 64 bits
       CLR *R2+          ; 07..00,0F..08
       CLR *R2+          ; 17..10,1F..18
       CLR *R2+          ; 27..20,2F..28
       CLR *R2+          ; 37..30,3F..38

       CLR R7           ; repeat counter
REGNM0
       ; keyboard cursor
       LI R5,>01C6

REGNM1 ; draw the cursors

       CI R5,>1C4
       JL REGIM3
       JNE !
       LI R5,>29A
!
       CI R5,>29C
       JEQ REGNM0
       JLE !
       AI R5,-32*8
!


       MOV R5,R0
       ANDI R0,>001F
       CI R0,4
       JNE !
       AI R5,-10-32
!      CI R0,28
       JNE !
       AI R5,10+32
!

       BL @NEGSPR
       BL @NEGSP2
       CLR R4  ; blink counter

REGNM2
       BL @VSYNCM
       JMP ALLKEY

REGNM3

       ; blink
       INC R4
       CI  R4,10
       JNE !!
       CLR R1        ; transparent sprite
!      LI R0,SPRTAB+(7*4)+3
       BL @VDPWB
       LI R0,SPRTAB+(8*4)+3
       BL @VDPWB
       JMP REGNM2

!      CI R4,20
       JNE REGNM2
       CLR R4
       LI R1,>0D00    ; purple sprite
       JMP -!!

ALLKEY
       LI R2,KEYBUF
       CLR R1          ; key index

ALLKE1 LI R12,>0024    ; Select address lines starting at line >18
       SLA R1,5
       LDCR R1,3       ; Send 3 bits to set one 8 of output lines enabled
       SRL R1,5
       LI R12,>0006    ; Select address lines to read starting at line 3
       LI R3,>0100     ; Bit to test in R0 byte from R2 KEYBUF
       MOVB *R2,R0
ALLKE2 TB 0
       JNE !     ; key pressed?
       ; not pressed
       SZCB R3,*R2   ; set key state to 0
       JMP ALLKE3
!
       ; key was pressed
       CZC R3,R0
       JNE ALLKE3         ; key already pressed
       SOCB R3,*R2   ; set key state to 1
       CLR R7        ; clear repeat counter
       ;JMP ACTION

ACTION ; R1=key pressed 0..3F
       ; preserve R0-R3,R12

       CI R1,>30    ; Joystick
       JHE JOYSTK

       CI R1,2      ; Enter
       JEQ REGIM3

       LI R0,>1000   ; Test function key
       CZC @KEYBUF,R0
       JNE FCTN

       SLA R0,1     ; Test shift key
       CZC @KEYBUF,R0
       JNE SHIFT

       SLA R0,1     ; Test ctrl key
       CZC @KEYBUF,R0
       JNE REGNM3   ; no ctrl combinations allowed

       MOVB @KEYCOD(R1),R1
       JEQ REGNM3

ADDCHR ; add R1 character to the current name
       MOV R6,R0
       BL @VDPWB
ADDCH1 INC R6

ADDCH2 MOV R6,R0
       ANDI R0,>001F
       CI R0,22
       JNE !
       AI R6,-8
!
       CI R0,13
       JNE !
       AI R6,8
!
       LI R0,SNDCL0   ; Clunk
       MOV R0,@SOUND1
       B @REGNM1

JOYMOV
       AI R7,16
       JMP REGNM1

ALLKE3
       INCT R12
       INC R1
       SLA R3,1

       JNE ALLKE2
       INC R2
       CI R1,64
       JNE ALLKE1

       MOV R7,R7     ; repeat enabled?
       JEQ REGNM3
       DEC R7        ; repeat count reached?
       JNE REGNM3

       JMP REPEAT



JOYSTK
       CI R1,>0030  ; J1 Fire
       JNE !
       MOV R5,R0
       BL @VDPRB    ; get the current char under cursor
       JMP ADDCHR   ; and add it
!
       CI R1,>0031  ; J1 Left
       JNE !
MLEFT
       BL @RUPSND
       DECT R5      ; two cols left
       JMP JOYMOV
!
       CI R1,>0032  ; J1 Right
       JNE !
MRIGHT
       BL @RUPSND
       INCT R5      ; two cols right
       JMP JOYMOV
!
       CI R1,>0033  ; J1 Down
       JNE !
MDOWN
       BL @RUPSND
       AI R5,64     ; two rows down
       JMP JOYMOV
!
       CI R1,>0034  ; J1 Up
       JNE !
MUP
       BL @RUPSND
       AI R5,-64    ; two rows up
       JMP JOYMOV
!
       CI R1,>0038  ; J2 fire
       JEQ BACKSP
       CI R1,>003B  ; J2 Down
       JEQ BACKSP

       JMP ALLKE3


FCTN
       CI R1,>0A    ; Fctn-O
       JNE !
       LI R1,''''*>100
       JMP ADDCHR
!
       CI R1,>0D    ; Fctn-S
       JNE !
BACKSP DEC R6
       JMP ADDCH2
!
       CI R1,>15    ; Fctn-D
       JEQ ADDCH1   ; move right only

       B @REGNM3
SHIFT
       CI R1,>2C   ; Shift-1 = !
       JNE !
       LI R1,'!'*>100
       JMP ADDCHR
!
       CI R1,>1B   ; Shift-7 = &
       JNE !
       LI R1,'&'*>100
       JMP ADDCHR
!
       CI R1,>28   ; Shift-/ = -
       JNE !
       LI R1,'-'*>100
       JMP ADDCHR
!

       B @REGNM3

REPEAT ; repeat joystick moves
       LI R7,-10         ; next repeat will be shorter
       MOVB @KEYBUF+6,R0
       SLA R0,4
       JOC MUP
       SLA R0,1
       JOC MDOWN
       SLA R0,1
       JOC MRIGHT
       SLA R0,1
       JOC MLEFT

       CLR R7
       B @REGNM3

KEYCOD
       BYTE 0,' ',0,0,0,0,0,0
       TEXT '.LO92SWX'
       TEXT ',KI83DEC'
       TEXT 'MJU74FRV'
       TEXT 'NHY65GTB'
       BYTE 0,0
       TEXT 'P01AQZ'

*R1     TB 0  TB 1  TB 2  TB 3  TB 4  TB 5  TB 6  TB 7
*0000   =+    space enter       fctn  shift ctrl
*0100   .>    L     O'    9(    2@    Slt   W~    Xdn
*0200   ,<    K     I?    8*    3#    Drt   Eup   C`
*0300   M     J     U_    7&    4$    F{    R[    V
*0400   N     H     Y     6^    5%    G}    T]    B
*0500   /-    ;:    P"    0)    1!    A|    Q     Z\
*0600   Fire  Left  Right Down  Up  (Joystick 1)
*0700   Fire  Left  Right Down  Up  (Joystick 2)



ELIMMD ; elimination mode
       ; copy filenames
       LI R5,SCR1TB+(8*32)+9
       LI R6,LEVELA+>600+(3*32)+14
       BL @CPYNAM

       LI R5,LEVELA+>600
       BL @CPYSCR    ; Copy screen

       ; set sprite list address
       LI R0,SPRTAB+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14

       ; update 6 hero sprites
       LI R1,REGSPR
       LI R2,6
!
       MOV *R1+,R0
       AI R0,>D820
       MOVB R0,*R15
       MOVB @R0LB,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       DEC R2
       JNE -!
       ; update heart sprite
       LI R0,>3C00
       MOVB R0,*R15
       MOVB R0,*R15

       LI R13,3

ELIMM1 ; move heart to right row
       LI R0,SPRTAB+(6*4)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB @REGIMY(R13),*R15

ELIMM2
       BL @VSYNCM
       BL @DOKEYS

       MOV @KEY_FL,R1

       LI R0,EDG_A
       CZC R0,R1
       JEQ !
       CI R13,3
       JNE !
       B @REGEND

!
       LI R0,EDG_UP
       CZC R0,R1
       JEQ !
       CI R13,0
       JEQ !
       BL @RUPSND
       DEC R13
       JMP ELIMM1
!
       LI R0,EDG_DN
       CZC R0,R1
       JEQ !
       CI R13,3
       JEQ !
       BL @RUPSND
       INC R13
       JMP ELIMM1
!

       JMP ELIMM2


NEGSPR ; negate the sprite at R5
       MOV R11,R10

       ; Get character under screen cursor
       MOV R5,R0
       BL @VDPRB

       ; calculate sprite position from char position
       MOV R0,R2       ; 0000 00YY YYYX XXXX
       ANDI R2,>03E0   ; 0000 00YY YYY0 0000
       XOR R2,R0       ; 0000 0000 000X XXXX
       SLA R2,3        ; 000Y YYYY 0000 0000
       SOC R0,R2       ; 000Y YYYY 000X XXXX
       SLA R2,3        ; YYYY Y000 XXXX X000
       AI R2,->100

       LI R0,SPRTAB+(8*4)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R2,*R15
       MOVB @R2LB,*R15
       LI R2,>900D
       MOVB R2,*R15
       MOVB @R2LB,*R15

       MOV R1,R0
       SRL R0,5
       AI R0,PATTAB
       LI R1,SCRTCH
       LI R2,8
       BL @VDPR

       LI R0,SPRPAT+(>90*8)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,SCRTCH
       LI R2,8
!      MOVB *R1+,R0
       NEG R0
       MOVB R0,*R15
       DEC R2
       JNE -!

       B *R10

NEGSP2 ; negate the sprite at R6
       MOV R11,R10

       MOV R6,R0
       ; Get character under screen cursor
       BL @VDPRB

       ; calculate sprite position from char position
       MOV R0,R2       ; 0000 00YY YYYX XXXX
       ANDI R2,>03E0   ; 0000 00YY YYY0 0000
       XOR R2,R0       ; 0000 0000 000X XXXX
       SLA R2,3        ; 000Y YYYY 0000 0000
       SOC R0,R2       ; 000Y YYYY 000X XXXX
       SLA R2,3        ; YYYY Y000 XXXX X000
       AI R2,->100

       LI R0,SPRTAB+(7*4)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R2,*R15
       MOVB @R2LB,*R15
       LI R2,>940D
       MOVB R2,*R15
       MOVB @R2LB,*R15

       MOV R1,R0
       SRL R0,5
       AI R0,PATTAB
       LI R1,SCRTCH
       LI R2,8
       BL @VDPR

       LI R0,SPRPAT+(>94*8)+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,SCRTCH
       LI R2,8
!      MOVB *R1+,R0
       NEG R0
       MOVB R0,*R15
       DEC R2
       JNE -!

       B *R10




* Copy screen at R5 to visible screen
CPYSCR
       MOV R11,R10
       LI R6,SCR1TB
       LI R4,24  ; Copy 24 lines
!
       MOV R5,R0
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       MOV R6,R0
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW

       AI R5,32
       AI R6,32
       DEC R4
       JNE -!

       B *R10

* Copy 3 names from screen at R5 to screen at R6
CPYNAM
       MOV R11,R10
       LI R4,3 ; Copy 3 lines
!
       MOV R5,R0
       LI R1,SCRTCH
       LI R2,8
       BL @VDPR

       MOV R6,R0
       LI R1,SCRTCH
       LI R2,8
       BL @VDPW

       AI R5,32*3
       AI R6,32*3
       DEC R4
       JNE -!

       B *R10





       .IFDEF GENEVE
       COPY "tilda_genkey.asm"
       .ENDIF

* Set keyboard lines in R1 to CRU
SETCRU
       MOV *R11+,R1    ; Get ouput line from callers DATA
       LI R12,>0024    ; Select address lines starting at line 18
       LDCR R1,3       ; Send 3 bits to set one 8 of output lines enabled
       LI R12,>0006    ; Select address lines to read starting at line 3
       RT

* Read keys and joystick into KEY_FL
* Modifies R0-2,R10,R12
DOKEYS
       MOV R11,R10     ; Save return address
       .IFDEF GENEVE

       BLWP @GENKEY    ; Geneve key scan

       .ELSE
       CLR R0
       BL @SETCRU
       DATA >0000
       TB 2            ; Test Enter
       JEQ !
       ORI R0, KEY_A
!      BL @SETCRU
       DATA >0100
       TB 5            ; Test S
       JEQ !
       ORI R0, KEY_DN
!      TB 6            ; Test W
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0200
       TB 5            ; Test D
       JEQ !
       ORI R0, KEY_RT
!      TB 6            ; Test E
       JEQ !
       ORI R0, KEY_B
!      BL @SETCRU
       DATA >0500
       TB 0            ; Test Slash
       JEQ !
       ORI R0, KEY_C
!      TB 1            ; Test Semicolon
       JEQ !
       ORI R0, KEY_B
!      TB 5            ; Test A
       JEQ !
       ORI R0, KEY_LT
!      TB 6            ; Test Q
       JEQ !
       ORI R0, KEY_C
!      BL @SETCRU
       DATA >0600
       TB 0            ; Test J1 Fire
       JEQ !
       ORI R0, KEY_A
!      TB 1            ; Test J1 Left
       JEQ !
       ORI R0, KEY_LT
!      TB 2            ; Test J1 Right
       JEQ !
       ORI R0, KEY_RT
!      TB 3            ; Test J1 Down
       JEQ !
       ORI R0, KEY_DN
!      TB 4            ; Test J1 Up
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0700
       TB 0            ; Test J2 Fire
       JEQ !
       ORI R0, KEY_B
!      TB 1            ; Test J2 Left
       JEQ !
       ORI R0, KEY_A
!      TB 2            ; Test J2 Right
       JEQ !
       ORI R0, KEY_C
!      TB 3            ; Test J2 Down
       JEQ !
       ORI R0, KEY_B
!      TB 4            ; Test J2 Up
       JEQ !
       ORI R0, KEY_C
!

       .ENDIF

       ; Calculate edges
       MOV R0,R1
       XOR @KEY_FL,R1
       INV R0
       SZC R0,R1
       INV R0
       SLA R1,8
       SOC R1,R0
       MOV R0,@KEY_FL

       B *R10  ; Return to saved address


*R1     TB 0  TB 1  TB 2  TB 3  TB 4  TB 5  TB 6  TB 7
*0000   =     space enter fctn  shift ctrl
*0100   .     L     O     9     2     S     W     X
*0200   ,     K     I     8     3     D     E     C
*0300   M     J     U     7     4     F     R     V
*0400   N     H     Y     6     5     G     T     B
*0500   /     ;     P     0     1     A     Q     Z
*0600   Fire  Left  Right Down  Up  (Joystick 1)
*0700   Fire  Left  Right Down  Up  (Joystick 2)




* palette is in sprites.mag, also tilda_b2.asm:CLRSET
* Overworld Colorset Definitions
*CLRSET BYTE >1B,>1E,>4B,>61            ; black/yellow black/gray blue/yellow red/black
*       BYTE >F1,>F1,>F1,>F1            ; white/black
*       BYTE >F1,>F1,>F1,>F1            ; white/black
*       BYTE >6B,>1B,>16,>1C            ; red/yellow black/yellow black/red black/green
*       BYTE >1C,>1C,>CB,>6B            ; black/green black/green green/yellow red/yellow
*       BYTE >16,>16,>16,>16            ; black/red
*       BYTE >16,>16,>1B,>4B            ; black/red black/red black/yellow blue/yellow
*       BYTE >4B,>4B,>1F,>41            ; blue/yellow blue/yellow black/white blue/black



LNKADR ; Calculate sprites source address
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       A R3,R1
       A R3,R1
       SRA R1,1
       AI R1,LSPR0

       CI R3,DIR_UP
       JEQ !          ; No shield sprite for facing up
       LI R0,MAGSHD
       CZC @HFLAGS,R0  ; Got magic shield?
       JEQ !
       AI R1,32*8     ; Copy magic shield walking sprites to sprites pattern table

!      LI R0,SPRPAT+VDPWM   ; Copy walking+attack+rod sprites to sprites pattern table
       MOVB @R0LB,*R14
       MOVB R0,*R14
       RT

LNKSPR
       MOV R11,R10    ; Save return address
       BL @LNKADR     ; Get sprites address in R1
       LI R2,32*4
!      MOVB *R1+,*R15
       DEC R2
       JNE -!
       B *R10         ; Return to saved address

LNKATK
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       A R3,R1
       A R3,R1
       SRA R1,1
       AI R1,LSPR0+(32*4)
       LI R0,SPRPAT+(32*4)
       LI R2,32*3
       BL @VDPW
       B @DONE2



MSKALL   ; All clear mask
       LI R2,32*4
!      MOVB R2,*R15   ; Copy zeroes
       DEC R2
       JNE -!
       B @DONE2


; Masked copy bottom R4 lines of R3 sprites to VDP
; R4 lines zerod, rest copied
MSKTOP
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2       ; Copy 4 sprites
MSKTO2
       MOV R4,R2
       A R2,R1
!      MOVB R2,*R15    ; Copy R2 zeroes
       DEC R2
       JNE -!

       LI R2,16
       S R4,R2
!      MOVB *R1+,*R15      ; Copy 16-R2 bytes
       DEC R2
       JNE -!

       DEC R8
       JNE MSKTO2
       B @DONE2

; Copy sprite at R1 to VDP (address already programmed)
; R2 lines copied, rest zeros
; R2 must be preserved
MSKBOT
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2       ; Copy 4 sprites
MSKBO2
       LI R2,16
       S R4,R2
!      MOVB *R1+,*R15     ; Copy 16-R2 bytes
       DEC R2
       JNE -!

       MOV R4,R2
       A R2,R1
!      MOVB R2,*R15    ; Copy R2 zeroes
       DEC R2
       JNE -!

       DEC R8
       JNE MSKBO2
       B @DONE2


MSKLFT
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2

       LI R0,16
       S R4,R0
       JLE MSKALL
       SETO R7
       SLA R7,R0
MSKLF2
       LI R2,16       ; Copy left half or right half of sprite, alternating
!      MOVB *R1+,R0
       SZCB R7,R0
       MOVB R0,*R15
       DEC R2
       JNE -!

       SWPB R7        ; Alternate pixel mask

       DEC R8
       JNE MSKLF2
       B @DONE2

MSKRGT
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2

       LI R0,16
       S R4,R0
       JLE MSKALL
       SETO R7
       SRL R7,R0
       JMP MSKLF2  ; Same copy loop, different R7 mask

LNKITM ; Load sprites link holding item
       LI R0,SPRPAT   ; Copy link holding item sprites to sprites pattern table
       LI R1,LSPR7
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+32
       LI R1,LSPR19
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+64
       LI R1,LSPR31
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+96
       LI R1,LSPR43
       LI R2,32
       BL @VDPW

       B @DONE2

LSPR0  DATA >0F37,>6AEC,>AE26,>030C    ; Color 3
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FC,>F0F0    ;
       DATA >C464,>E0C0,>00E0,>0000    ;
LSPR1  DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F0,>2002,>0202    ;
       DATA >3A9A,>1A22,>E200,>0080    ;
LSPR2  DATA >0007,>1B35,>7657,>1301    ; Color 3
       DATA >0C11,>0020,>301F,>0F00    ;
       DATA >00C0,>8000,>0068,>7EF8    ;
       DATA >78E4,>D430,>E008,>F000    ;
LSPR3  DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ;
       DATA >0000,>78FC,>F890,>8002    ;
       DATA >821A,>2ACA,>12F2,>0C38    ;
LSPR4  DATA >0003,>0B15,>1637,>7341    ; Color 3
       DATA >0F18,>1030,>783F,>1F00    ;
       DATA >00C0,>8000,>0068,>7EF0    ;
       DATA >EE1E,>1A10,>E000,>F000    ;
LSPR5  DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0007,>0F0F,>07C0,>E070    ;
       DATA >0000,>78FC,>F890,>8008    ;
       DATA >10F0,>F0E0,>18F8,>0C1E    ;
LSPR6  DATA >0000,>0000,>0000,>00FF    ; Color 4
       DATA >FF00,>0000,>0000,>0000    ;
       DATA >0000,>0000,>0000,>56AB    ;
       DATA >AF56,>0000,>0000,>0000    ;
LSPR7  DATA >6374,>0815,>1F0E,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >C62E,>10A8,>F870,>60C0    ;
       DATA >30F0,>3880,>38F8,>0000    ;
LSPR8  DATA >0F37,>6AEC,>AE26,>030C    ; Color 8
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FD,>F1F1    ;
       DATA >C565,>E1C1,>01E0,>0000    ;
LSPR9  DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F3,>2302,>0202    ;
       DATA >3A9A,>1A22,>E203,>0380    ;
LSPR10 DATA >0007,>1B35,>7657,>1301    ; Color 8
       DATA >0C11,>0020,>301F,>0F00    ;
       DATA >00C0,>8000,>0068,>7DF9    ;
       DATA >79E5,>D531,>E109,>F000    ;
LSPR11 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ;
       DATA >0000,>78FC,>FB93,>8202    ;
       DATA >821A,>2ACA,>12F2,>0F3B    ;
LSPR12 DATA >0100,>0000,>0B3F,>0F0F    ; Color 3
       DATA >2326,>0703,>0007,>0000    ;
       DATA >F0EC,>5637,>7564,>C030    ;
       DATA >18E0,>6080,>64FE,>0000    ;
LSPR13 DATA >000F,>1F0F,>0440,>4040    ; Color 1
       DATA >5C59,>5844,>4700,>0001    ;
       DATA >0010,>A8C8,>8898,>38C0    ;
       DATA >E41E,>9E7E,>9800,>E0E0    ;
LSPR14 DATA >0003,>0100,>0016,>7E1F    ; Color 3
       DATA >1E27,>2B0C,>0710,>0F00    ;
       DATA >00E0,>D8AC,>6EEA,>C880    ;
       DATA >3088,>0004,>0CF8,>F000    ;
LSPR15 DATA >0000,>1E3F,>1F09,>0140    ; Color 1
       DATA >4158,>5453,>484F,>301C    ;
       DATA >0000,>2050,>9010,>3070    ;
       DATA >C070,>F8F8,>F006,>0E1C    ;
LSPR16 DATA >0003,>0100,>0016,>7E0F    ; Color 3
       DATA >7778,>5808,>0700,>0F00    ;
       DATA >00C0,>D0A8,>68EC,>CE82    ;
       DATA >F018,>080C,>1EFC,>F800    ;
LSPR17 DATA >0000,>1E3F,>1F09,>0110    ; Color 1
       DATA >080F,>0F07,>181F,>3078    ;
       DATA >0000,>2050,>9010,>3070    ;
       DATA >00E0,>F0F0,>E003,>070E    ;
LSPR18 DATA >0000,>0000,>0000,>6AB5    ; Color 4
       DATA >F56A,>0000,>0000,>0000    ;
       DATA >0000,>0000,>0000,>00FF    ;
       DATA >FF00,>0000,>0000,>0000    ;
LSPR19 DATA >0003,>676A,>6031,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >00C0,>E656,>068C,>9C3C    ;
       DATA >C808,>C078,>C000,>7070    ;
LSPR20 DATA >0100,>0000,>0BBF,>8F8F    ; Color 8
       DATA >A3A6,>8783,>8007,>0000    ;
       DATA >F0EC,>5637,>7564,>C030    ;
       DATA >18E0,>6080,>64FE,>0000    ;
LSPR21 DATA >000F,>1FCF,>C440,>4040    ; Color 1
       DATA >5C59,>5844,>47C0,>C001    ;
       DATA >0010,>A8C8,>8898,>38C0    ;
       DATA >E41E,>9E7E,>9800,>E0E0    ;
LSPR22 DATA >0003,>0100,>0016,>BE9F    ; Color 8
       DATA >9EA7,>AB8C,>8790,>0F00    ;
       DATA >00E0,>D8AC,>6EEA,>C880    ;
       DATA >3088,>0004,>0CF8,>F000    ;
LSPR23 DATA >0000,>1E3F,>DFC9,>4140    ; Color 1
       DATA >4158,>5453,>484F,>F0DC    ;
       DATA >0000,>2050,>9010,>3070    ;
       DATA >C070,>F8F8,>F006,>0E1C    ;
LSPR24 DATA >072F,>2830,>351F,>3603    ; Color 3
       DATA >2071,>2021,>0003,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
LSPR25 DATA >0000,>070F,>0A00,>49FC    ; Color 1
       DATA >DF8E,>DFDE,>FFFC,>7E0E    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CC12,>92FA,>8C00,>7000    ;
LSPR26 DATA >072F,>2830,>351F,>1603    ; Color 3
       DATA >1038,>1010,>0000,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
LSPR27 DATA >0000,>070F,>0A00,>297C    ; Color 1
       DATA >6F47,>6F6F,>7F7F,>3E00    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
LSPR28 DATA >0317,>1C38,>3597,>4E26    ; Color 3
       DATA >1807,>0A0C,>0602,>0100    ;
       DATA >E0F0,>180A,>AEEC,>7860    ;
       DATA >00C0,>0484,>6CE8,>E000    ;
LSPR29 DATA >1828,>63C7,>CA68,>3119    ; Color 1
       DATA >0708,>0503,>1939,>0000    ;
       DATA >0000,>E0F0,>5010,>8098    ;
       DATA >FC3C,>F878,>9217,>0F00    ;
LSPR30 DATA >0101,>0101,>0101,>0101    ; Color 4
       DATA >0102,>0102,>0102,>0301    ;
       DATA >8080,>8080,>8080,>8080    ;
       DATA >8040,>8040,>80C0,>C080    ;
LSPR31 DATA >6374,>0815,>1F0D,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >E0F0,>1404,>ACEC,>78C0    ;
       DATA >3CFC,>3088,>38E0,>0000    ;
LSPR32 DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
LSPR33 DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CE12,>92FA,>8C00,>7000    ;
LSPR34 DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
LSPR35 DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
LSPR36 DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0727,>2718,>1F07,>0000    ;
       DATA >C0E0,>F4F4,>E4CC,>8810    ;
       DATA >F0F0,>E018,>F8C0,>0000    ;
LSPR37 DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3858,>5827,>0008,>0600    ;
       DATA >0000,>0008,>1830,>70E8    ;
       DATA >0C0C,>1CE0,>0038,>7830    ;
LSPR38 DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0F0F,>0718,>1F03,>0000    ;
       DATA >C0E0,>F4F4,>E4CC,>8810    ;
       DATA >E0E4,>E418,>F8E0,>0000    ;
LSPR39 DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3030,>3807,>001C,>1E0C    ;
       DATA >0000,>0008,>1830,>70E8    ;
       DATA >1C1A,>1AE4,>0010,>6000    ;
LSPR40 DATA >0F5F,>5F7F,>2F27,>1218    ; Color 3
       DATA >1F1F,>2F30,>3F01,>0000    ;
       DATA >80C0,>E0E8,>D811,>3244    ;
       DATA >C8D0,>A010,>F8E0,>0000    ;
LSPR41 DATA >1000,>2000,>5058,>6D67    ; Color 1
       DATA >2020,>104F,>C0E0,>0000    ;
       DATA >0000,>0000,>20E0,>C1BB    ;
       DATA >372F,>5EEC,>0018,>3C3C    ;
LSPR42 DATA >0102,>0301,>0201,>0201    ; Color 4
       DATA >0101,>0101,>0101,>0101    ;
       DATA >80C0,>C080,>4080,>4080    ;
       DATA >8080,>8080,>8080,>8080    ;
LSPR43 DATA >0003,>676A,>6032,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >0000,>E0F0,>5010,>843C    ;
       DATA >C000,>C870,>C010,>7070    ;




* Mute all the sound channels and clear the music pointers
* Modifies R0
QUIET
       LI R0,MUTESB
       MOVB *R0+,@SNDREG
       MOVB *R0+,@SNDREG
       MOVB *R0+,@SNDREG
       MOVB *R0+,@SNDREG
       CLR @MUSIC1
       CLR @MUSIC2
       CLR @MUSIC3
       CLR @MUSIC4
       RT
MUTESB BYTE >9F,>BF,>DF,>FF  ; mute sound bytes
