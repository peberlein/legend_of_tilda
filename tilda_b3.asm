;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 3: title screen, load overworld tiles, load dungeon tiles
;

       COPY 'tilda.asm'


CLRSAV EQU WRKSP+>20

; Load title screen
; R2 = 0 title screen
;      1 load overworld tiles and menu
;      2 load dungeon tiles and border and menu
;      3 load dungeon dark pattern table, return to bank2
;      4 load dungeon light pattern table, return to bank2
MAIN
       MOV R11,R13      ; Save return address for later
       LI R11,DONE2     ; LNKSPR needs this
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA MAIN2,OWTILE,DNTILE,DRKPAT,LITPAT

MAIN2

       ; turn off screen for faster VDP memory access
       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG

       LI R5,TITLE
       CLR R7       ; decompress to VDP addr 0
       BL @DAN2DC   ; Dan2 decompress


       B @DONE    ; skip title screen

       ;LI R0,SPRLST     ; Load sprite table
       ;LI R1,SL0
       ;LI R2,(28*4)/2
;!      MOV *R1+,*R0+
;       DEC R2
;       JNE -!

       LI R0,CLRTAB        ; Load color table
       LI R1,CLRSAV
       LI R2,32
       BL @VDPR

       LI R0,>0700
       BL @BGCOL

       LI R0,SPRTAB    ; Copy VDP sprite table into SPRLST
       LI R1,SPRLST
       LI R2,32*4
       BL @VDPR

       ;TODO turn on screen
       LI R0,>01E2          ; VDP Register 1: 16x16 Sprites
       BL @VDPREG

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

       BL @KEYTST

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
       LI R0,CLRTAB     ; Load color table
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

!      CI R4,1000     ; 1030 starts scrolling text
       JNE MLOOP2

       B @MAIN2


DONE
       MOV  R4,@RAND16      ; Use counter for random seed


DONE2  LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW
DONE3
       MOV @HEROSP,R5         ; Get hero YYXX
       JMP DONE2

KEYTST
       CLR R1
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 0
       LI R12, >0006
       TB 2                 ; Key Enter
       JNE DONE           ; Sword key down

       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            ; Turn on Joystick Col 0
       LI R12, >0006
       TB 0                 ; Joystick 1 Fire
       JNE DONE           ; Sword key down
       RT


; Master is sprites.mag

****************************************
* Overworld Colorset Definitions
****************************************
CLRSET BYTE >1B,>1E,>6B,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >4B,>1B,>16,>1C            ;
       BYTE >1C,>1C,>CB,>6B            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>1B,>4B            ;
       BYTE >4B,>4B,>1F,>41            ;

****************************************
* Menu Colorset Definitions starting at char >80
****************************************
;MCLRST BYTE >A1,>A1,>A1,>41            ;
;       BYTE >41,>41,>41,>61            ;
;       BYTE >61,>61

****************************************
* Bright Colorset Definitions
****************************************
BCLRST BYTE >EF,>EF,>EF,>FE            ;
       BYTE >FE,>FE,>FE,>FE            ;
       BYTE >FE,>FE,>FE,>FE            ;
       BYTE >EF,>EF,>EF,>EF            ;
       BYTE >EF,>EF,>EF,>EF            ;
       BYTE >EF,>EF,>EF,>EF            ;
       BYTE >EF,>EF,>EF,>EF            ;
       BYTE >EF,>EF,>EF,>FE            ;

OWTILE
       ; turn off screen for faster VDP memory access
       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG

       LI R5,OVERW1
       LI R7,PATTAB+(8*4)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress
       LI R5,OVERW2
       LI R7,PATTAB+(8*96)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress

       LI R5,MENUMP        ; decompress menu map
       LI R7,MENUSC        ; put in menu screen
       BL @DAN2DC   ; Dan2 decompress

       LI R5,CAVED2
       LI R7,CAVTXT       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress

       LI   R0,CLRTAB         ; Color table
       LI   R1,CLRSET
       LI   R2,32
       BL   @VDPW

       LI   R0,MCLRTB         ; Menu Color table
       LI   R1,CLRSET
       LI   R2,32
       BL   @VDPW

       LI   R0,BCLRTB         ; Bright Color table
       LI   R1,BCLRST
       LI   R2,32
       BL   @VDPW

MENUCP

       CLR R4           ; Copy bottom of menu screen to top of main screen
!      MOV R4,R0
       AI R0,MENUSC+(32*21)
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       MOV R4,R0
       AI R0,SCR1TB
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW
       AI R4,32
       CI R4,32*3
       JNE -!


       LI R4,21*32  ; Clear the rest of the screen
       LI R0,>2000  ; With spaces
!      MOVB R0,*R15
       DEC R4
       JNE -!

       ; turn on screen
       LI R0,>01E2          ; VDP Register 1: 16x16 Sprites
       BL @VDPREG

       B @DONE2


* Load dungeon tiles and colorsets
DNTILE
       ; turn off screen for faster VDP memory access
       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG

       LI R5,DUNGN1
       LI R7,PATTAB+(8*4)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress
       LI R5,DUNGN2
       LI R7,PATTAB+(8*96)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress

       LI R5,DUNGMP              ; dungeon border
       LI R7,LEVELA              ; decompress screen
       BL @DAN2DC   ; Dan2 decompress

       LI R5,DMNUMP        ; decompress menu map
       LI R7,MENUSC        ; put in menu screen
       BL @DAN2DC   ; Dan2 decompress

       MOV @FLAGS,R1
       ANDI R1,DUNLVL
       SRL R1,8
       MOV R1,R0
       SRL R1,2
       A R0,R1      ; R1 = dungeon level * 5 * 4

       LI   R0,CLRTAB+(3*4)       ; Color table
       AI   R1,DUNSET+(3*4)-(5*4)
       LI   R2,5*4
       BL   @VDPW

       LI   R0,CLRTAB       ; Color table
       LI   R1,DUNSET
       LI   R2,3*4
       BL   @VDPW

       LI   R0,MCLRTB       ; Menu Color table
       LI   R1,DUNSET
       LI   R2,3
       BL   @VDPW

       LI   R0,MCLRTB+30       ; Menu Color table
       LI   R1,DUNSET+30
       LI   R2,2
       BL   @VDPW

       JMP  MENUCP

DRKPAT                           ; load dark dungeon patterns
       LI R5,DNDARK
       LI R7,PATTAB+(8*96)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress
       ; NOTE dark colorset is loaded in bank2:GODUNG
       JMP !
LITPAT                           ; load light dungeon patterns
       LI R5,DUNGN2
       LI R7,PATTAB+(8*96)       ; decompress tiles
       BL @DAN2DC   ; Dan2 decompress

       MOV @FLAGS,R1
       ANDI R1,DUNLVL
       SRL R1,8
       MOV R1,R0
       SRL R1,2
       A R0,R1      ; R1 = dungeon level * 5 * 4

       LI   R0,CLRTAB+(3*4)       ; Color table
       AI   R1,DUNSET+(3*4)-(5*4)
       LI   R2,5*4
       BL   @VDPW

       LI   R0,CLRTAB       ; Color table
       LI   R1,DUNSET
       LI   R2,3*4
       BL   @VDPW

!      LI   R0,BANK2         ; Load bank 2
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW


****************************************
* Dungeon Colorset Definitions
****************************************
DUNSET BYTE >1B,>1B,>1B,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;

       BYTE >4B,>17,>17,>57            ; Level-1 eagle
       BYTE >47,>47,>47,>47            ; Level-1 blue water
       BYTE >47,>47,>47,>47            ; Level-1 cyan on dark blue
       BYTE >47,>17,>17,>17            ; Level-1
       BYTE >17,>4E,>41,>41            ; Level-1

       BYTE >1B,>14,>15,>45            ; Level-2 moon
       BYTE >4D,>14,>14,>14            ; Level-2 no water
       BYTE >14,>14,>14,>14            ; Level-2 blue on black
       BYTE >14,>14,>14,>14            ; Level-2
       BYTE >14,>48,>41,>41            ; Level-2

       BYTE >1B,>12,>12,>C2            ; Level-3 manji
       BYTE >C3,>12,>12,>12            ; Level-3 no water
       BYTE >12,>12,>12,>12            ; Level-3 green on black
       BYTE >12,>12,>12,>12            ; Level-3
       BYTE >12,>16,>41,>41            ; Level-3

       BYTE >4B,>1A,>1A,>AB            ; Level-4 snake
       BYTE >4B,>1A,>1A,>1A            ; Level-4 blue water
       BYTE >1A,>1A,>1A,>1A            ; Level-4 yellow on black
       BYTE >4B,>4B,>4B,>4B            ; Level-4 yellow on blue
       BYTE >4B,>A4,>41,>41            ; Level-4

       BYTE >6B,>12,>12,>23            ; Level-5 lizard
       BYTE >63,>C3,>C3,>C3            ; Level-5 red water
       BYTE >C3,>C3,>C3,>C3            ; Level-5 green on dark green
       BYTE >C3,>13,>13,>13            ; Level-5
       BYTE >13,>16,>41,>41            ; Level-5

       BYTE >6B,>1A,>1A,>AB            ; Level-6 dragon
       BYTE >6B,>1A,>1A,>1A            ; Level-6 red water
       BYTE >1A,>1A,>1A,>1A            ; Level-6 yellow on black
       BYTE >6A,>6A,>6A,>6A            ; Level-6
       BYTE >6A,>A6,>41,>41            ; Level-6

       BYTE >4B,>12,>12,>23            ; Level-7 demon
       BYTE >43,>C3,>C3,>C3            ; Level-7 blue water
       BYTE >C3,>C3,>C3,>C3            ; Level-7 green on dark green
       BYTE >C3,>13,>13,>13            ; Level-7
       BYTE >13,>15,>41,>41            ; Level-7

       BYTE >4B,>1E,>1E,>EF            ; Level-8 lion
       BYTE >4F,>1E,>1E,>1E            ; Level-8 blue water
       BYTE >1E,>1E,>1E,>1E            ; Level-8 gray on black
       BYTE >1E,>1E,>1E,>1E            ; Level-8
       BYTE >1E,>E4,>41,>41            ; Level-8

       BYTE >6B,>1E,>1E,>EF            ; Level-9 death mountain
       BYTE >6F,>1E,>1E,>1E            ; Level-9 red water
       BYTE >1E,>1E,>1E,>1E            ; Level-9 gray on black
       BYTE >1E,>1E,>1E,>1E            ; Level-9
       BYTE >1E,>1E,>41,>41            ; Level-9




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

; Update Sprite List to VDP Sprite Table
; Modifies R0-R2
SPRUPD
       LI R0,SPRTAB  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU
       LI R2,128     ; Copy all 32 sprites
       B @VDPW

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



* Dan2 decompression subroutine
       COPY 'dan2.asm'

* Compressed data
TITLE  BCOPY "title.d2"
OVERW1 BCOPY "overworld1.d2"
OVERW2 BCOPY "overworld2.d2"
CAVED2 BCOPY "cavetext.d2"
DUNGN1 BCOPY "dungeon1.d2"
DUNGN2 BCOPY "dungeon2.d2"
DUNGMP BCOPY "dungeonm.d2"  ; dungeon outline map
MENUMP BCOPY "menu.d2"      ; overworld menu
DMNUMP BCOPY "dmenu.d2"     ; dungeon menu
DNDARK BCOPY "dungdark.d2"  ; dark room patterns
       EVEN







