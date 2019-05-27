;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 3: compressed data: title screen, overworld tiles, dungeon tiles
;

       COPY 'tilda.asm'


; Load title screen
; R2 = 0 title screen
;      1 load overworld tiles and menu
;      2 load dungeon tiles and border and menu
;      3 load dungeon dark pattern table, return to bank2
;      4 load dungeon light pattern table, return to bank2
;      5 load dungeon border (after exiting dungeon stairs)
;      6 main menu (save game select)

MAIN
       MOV R11,R13      ; Save return address for later
       LI R11,DONE2     ; LNKSPR needs this
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA MAIN2,OWTILE,DNTILE,DRKPAT,LITPAT,DNBORD,MMENU

       COPY 'tilda_common.asm'

VDPINI
       BYTE >00          ; VDP Register 0: 00
       BYTE >E2          ; VDP Register 1: 16x16 Sprites
       BYTE >00          ; VDP Register 2: 00
       BYTE >00+(CLRTAB/>40)  ; VDP Register 3: Color Table
       BYTE >00+(PATTAB/>800) ; VDP Register 4: Pattern Table
       BYTE >00+(SPRTAB/>80)  ; VDP Register 5: Sprite List Table
       BYTE >00+(SPRPAT/>800) ; VDP Register 6: Sprite Pattern Table
       BYTE >F1          ; VDP Register 7: White on Black

MAIN2
       LIMI 0                ; Disable interrupts, always
       LI   R14,VDPWA        ; Keep VDPWA address in R14
       LI   R15,VDPWD        ; Keep VDPWD address in R15

       LI R1,VDPINI         ; Load initial VDP registers
       CLR R0
!      MOVB *R1+,@R0LB
       BL @VDPREG
       AI R0,>0100
       CI R0,>0800+VDPRM
       JL -!

       SETO @RAND16          ; random seed must be nonzero



       ; turn off screen for faster VDP memory access
       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG

       LI R5,TITLE
       CLR R7       ; decompress to VDP addr 0
       BL @DAN2DC   ; Dan2 decompress

       ;B @DONE    ; skip title screen

       LI R0,SPRTAB    ; Copy VDP sprite table into SPRLST
       LI R1,SPRLST
       LI R2,32*4
       BL @VDPR

       ;TODO turn on screen
       LI R0,>01E2          ; VDP Register 1: 16x16 Sprites
       BL @VDPREG

       LI R0,BANK4
       LI R1,MAIN
       LI R2,0       ; title screen
       MOV R13,R11      ; restore return address
       B @BANKSW


MMENU
       LI R0,>07F1
       BL @VDPREG    ; Set border to black

       LI R0,CLRTAB+4  ; Color table text offset
       LI R1,>F100     ; white text, black background
       LI R2,8
       BL @VDPSET

       LI R0,SPRTAB
       LI R1,>D000     ; turn off sprites
       BL @VDPWB

       LI R0,SCR1TB    ; clear the screen
       LI R1,>2000
       LI R2,32*24
       BL @VDPSET

       BL @VSYNC

       LI R5,REGIST     ; 3 registration screens
       LI R7,LEVELA     ; screens
       BL @DAN2DC       ; Dan2 decompress

       LI R0,BANK4
       LI R1,MAIN
       LI R2,11         ; main menu
       MOV R13,R11      ; restore return address
       B @BANKSW

VSYNC
       CLR R12              ; CRU Address bit 0002 - VDP INT
       TB 2
       JEQ !
       MOVB @VDPSTA,R12     ; Clear interrupt flag manually since we polled CRU
       RT

DONE
       MOV  R4,@RAND16      ; Use counter for random seed


DONE2  LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW
DONE3
       MOV @HEROSP,R5         ; Get hero YYXX
       JMP DONE2


* Write R2 bytes from R1 to VDP address R0
VDPSET MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
!
       MOVB R1,*R15
       DEC R2
       JNE -!
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

       LI R5,DMNUMP        ; decompress menu map
       LI R7,MENUSC        ; put in menu screen
       BL @DAN2DC   ; Dan2 decompress

       LI   R0,CLRTAB       ; Color table
       LI   R1,DUNSET
       LI   R2,3*4
       BL   @VDPW

       LI   R0,MCLRTB       ; Menu Color table
       LI   R1,DUNSET
       LI   R2,12
       BL   @VDPW

       LI   R0,MCLRTB+30       ; Menu Color table
       LI   R1,DUNSET+30
       LI   R2,2
       BL   @VDPW

       LI   R0,BCLRTB         ; Bright Color table
       LI   R1,BCLRST
       LI   R2,32
       BL   @VDPW

       ; fall thru
DNBORD
       LI R5,DUNGMP              ; dungeon border
       LI R7,LEVELA              ; decompress screen
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
       BYTE >47,>47,>47,>47            ; Level-1
       BYTE >47,>4E,>14,>41            ; Level-1

       BYTE >1B,>14,>15,>45            ; Level-2 moon
       BYTE >4D,>15,>15,>15            ; Level-2 no water
       BYTE >15,>15,>15,>15            ; Level-2 blue on black
       BYTE >15,>15,>15,>15            ; Level-2
       BYTE >15,>48,>14,>41            ; Level-2

       BYTE >1B,>12,>12,>C3            ; Level-3 manji
       BYTE >CE,>12,>12,>12            ; Level-3 no water
       BYTE >12,>12,>12,>12            ; Level-3 green on black
       BYTE >12,>12,>13,>13            ; Level-3
       BYTE >13,>CB,>14,>41            ; Level-3

       BYTE >4B,>1A,>1A,>AB            ; Level-4 snake
       BYTE >4B,>1A,>1A,>1A            ; Level-4 blue water
       BYTE >1A,>1A,>1A,>1A            ; Level-4 yellow on black
       BYTE >1A,>1A,>1B,>1B            ; Level-4 yellow on blue
       BYTE >1B,>4A,>14,>41            ; Level-4

       BYTE >6B,>12,>12,>C3            ; Level-5 lizard
       BYTE >63,>12,>12,>12            ; Level-5 red water
       BYTE >12,>12,>12,>12            ; Level-5 green on dark green
       BYTE >12,>12,>13,>13            ; Level-5
       BYTE >13,>CB,>14,>41            ; Level-5

       BYTE >6B,>1A,>1A,>AB            ; Level-6 dragon
       BYTE >6B,>1A,>1A,>1A            ; Level-6 red water
       BYTE >1A,>1A,>1A,>1A            ; Level-6 yellow on black
       BYTE >1A,>1A,>1B,>1B            ; Level-6
       BYTE >1B,>6A,>14,>41            ; Level-6

       BYTE >4B,>12,>12,>C3            ; Level-7 demon
       BYTE >43,>12,>12,>12            ; Level-7 blue water
       BYTE >12,>12,>12,>12            ; Level-7 green on dark green
       BYTE >12,>12,>13,>13            ; Level-7
       BYTE >13,>CE,>14,>41            ; Level-7

       BYTE >4B,>1E,>1E,>EF            ; Level-8 lion
       BYTE >4F,>1E,>1E,>1E            ; Level-8 blue water
       BYTE >1E,>1E,>1E,>1E            ; Level-8 gray on black
       BYTE >1E,>1E,>1E,>1E            ; Level-8
       BYTE >1E,>4E,>14,>41            ; Level-8

       BYTE >6B,>1E,>1E,>EF            ; Level-9 death mountain
       BYTE >6F,>1E,>1E,>1E            ; Level-9 red water
       BYTE >1E,>1E,>1E,>1E            ; Level-9 gray on black
       BYTE >1E,>1E,>1E,>1E            ; Level-9
       BYTE >1E,>6E,>14,>41            ; Level-9





; Update Sprite List to VDP Sprite Table
; Modifies R0-R2
SPRUPD
       LI R0,SPRTAB  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU
       LI R2,128     ; Copy all 32 sprites
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
REGIST BCOPY "register.d2"  ; registration screens
       EVEN







