;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 4: game over animation, hero sprites, load enemies
;

       COPY 'tilda.asm'

;
; R2 = 0
;      1 game over screen
;      2 load hero sprites (R3 = direction)
;      3 load hero sprite attack stance (R3 = direction) TODO
;      4
;      5 load hero sprites masked LEFT (R3 = direction, R4=count)
;      6 load hero sprites masked RIGHT (R3 = direction, R4=count)
;      7 load hero sprites masked BOTTOM (R3 = direction, R4=count)
;      8 load hero sprites masked TOP (R3 = direction, R4=count)
;      9 load hero sprites holding item
;     10 load enemies
;

MAIN
       MOV R11,R13      ; Save return address for later
       LI R11,DONE2     ; LNKSPR needs this
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA DONE2,GAMOVR,LNKSPR,LNKATK,DONE2,MSKLFT,MSKRGT,MSKBOT,MSKTOP,LNKITM,LENEMY


DONE2  LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW

; Update Sprite List to VDP Sprite Table
; Modifies R0-R2
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

GAMOVR       ; GAME OVER
       LI R0,>D000
       MOVB R0,@SPRLST+(4*6)+0 ; Turn off sprites 6+
       MOVB R0,@SPRLST+(4*31)+0 ; Turn off sprites 6+
       BL @SPRUPD
       BL @VSYNCM
       LI R3,DIR_DN
       BL @LNKSPR

       LI R4,32      ; Hurt Blink 32 frames
!      MOV R4,R1
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2
       BL @VSYNCM
       BL @SPRUPD
       DEC R4
       JNE -!

       LI R4,26
!      BL @VSYNCM
       DEC R4
       JNE -!

       LI R5,DEDCLR
       BL @FGCSET
       BL @VSYNCM
       BL @VSYNCM

       LI R0,>D000
       MOVB R0,@SPRLST+(4*6)+0 ; Turn off sprites 6+
       MOVB R0,@SPRLST+(4*31)+0 ; Turn off sprites 6+

       LI R0,CLRTAB
       LI R1,DEDCLR
       LI R2,32
       BL @VDPW
       BL @VSYNCM
       BL @VSYNCM

       LI R4,16
!
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
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
       LI R2,10
!      BL @VSYNCM
       DEC R2
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL3
       LI R2,32
       BL @VDPW
       LI R2,10
!      BL @VSYNCM
       DEC R2
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL4
       LI R2,32
       BL @VDPW
       LI R2,10
!      BL @VSYNCM
       DEC R2
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
       LI R2,24
!      BL @VSYNCM
       DEC R2
       JNE -!

       LI R0,>E800
       MOVB R0,@HEROSP+2   ; Set hero sprite index to little star
       BL @SPRUPD
       LI R2,10
!      BL @VSYNCM
       DEC R2
       JNE -!

       LI R0,>EC00
       MOVB R0,@HEROSP+2   ; Set hero sprite index to big star
       BL @SPRUPD
       LI R2,4
!      BL @VSYNCM
       DEC R2
       JNE -!

       CLR @HEROSP+2   ; Set hero color to transparent
       CLR @HEROSP+6   ; Set hero color to transparent
       BL @SPRUPD
       LI R2,46
!      BL @VSYNCM
       DEC R2
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

       LI R2,96
!      BL @VSYNCM
       DEC R2
       JNE -!

       B @DONE2

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


       ; Copy scratchpad to the screen at R0
       ; Modifies R0,R1,R2
PUTSCR
       ORI R0,VDPWM
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       LI R1,SCRTCH        ; Source pointer to scratchpad ram
       LI R2,8             ; Write 32 bytes from scratchpad
!      MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       DEC R2
       JNE -!
       RT

       ; Copy screen at R0 into scratchpad 32 bytes
       ; Note: R6 must be VDPRD address
       ; Modifies R1,R2
READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH        ; Dest pointer to scratchpad ram
       LI R2,8             ; Read 32 bytes to scratchpad
       LI R6,VDPRD        ; Keep VDPRD address in R6
!      MOVB *R6,*R1+
READ3  MOVB *R6,*R1+
       MOVB *R6,*R1+
       MOVB *R6,*R1+
       DEC R2
       JNE -!
       RT

       ; Add R1 to hero sprite YYXX, and update VDP sprite list
DOSPRT
       A R1,@HEROSP
       A R1,@HEROSP+4
       LI R0,SPRTAB+(HEROSP-SPRLST)
       LI R1,HEROSP
       LI R2,8
       B @VDPW


DONE3
       LI R0,SCHSAV
       BL @READ32            ; Restore saved scratchpad

       MOV @HEROSP,R5        ; Get hero YYXX
       AI R5,>0100           ; Move Y down one

       LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW

       ; Load dungeon enemies
LDUNGE
       LI R0,SPRLST+(6*4)      ; Clear sprite list [6..31]
       LI R2,(32-6)*2          ; (including scratchpad)
!      CLR *R0+
       DEC R2
       JNE -!

       JMP DONE3

       ; Load overwold enemies
LENEMY
       MOVB @MAPLOC,R1         ; Get map location
       SRL R1,8

       LI R9,LASTOB        ; Start filling the object list at last index

       MOV @FLAGS,R0
       MOV R0,R7
       ANDI R7,DUNGON
       JNE LDUNGE           ; Load dungeon enemies
       ANDI R0,INCAVE
       JNE LCAVE            ; Load cave items instead

       MOVB @ENEMYS(R1),R0     ; Get enemy group index at map location
       SRL R0,8

       LI R7,ENEMYG           ; Pointer to enemy groups

       MOV  R0,R5
       LI R4,4              ; 4 Armos sprites
       LI R8, ENESPR+(>2C*32)   ; Armos sprite source address index >2C
       LI R10,SPRPAT+(>18*32)   ; Destination sprite address index >60
       ANDI R0,>0080        ; Test zora bit
       JEQ LENEM2
       LI R0,>0010          ; Zora enemy type
       MOV R0,*R9+          ; Store it
       INC R4 	     	    ; 5 Zora sprites
       LI R8,ENESPR+(>20*32)    ; Zora sprite source address index >20
       AI R10,32            ; Destination sprite address index >61

LENEM2 MOV R8,R0            ; Copy Zora or Armos sprite
       AI R8,32
       BL @READ32           ; Read sprite into scratchpad

       MOV R10,R0
       AI R10,32
       BL @PUTSCR           ; Copy it back to the sprite pattern table

       CI R8,ENESPR+(>23*32)   ; After zora (pulsing ground)
       JNE !
       LI R10,SPRPAT+(>0A*32)   ; Pulsing ground dest address index >28

!      DEC R4
       JNE LENEM2


       MOV R5,R1               ; R5 = enemy group index
       MOV R5,R0
       ANDI R0,>0040           ; Test edge loading bit
       ; TODO

       ANDI R1,>003F          ; Mask off zora and loading behavior bits to get group index
       JNE LENEM3
       JMP LENEM6                ; No enemies on this screen

!      CLR R3
       MOVB *R7+,R3
       CI R3,>8000             ; Keep reading until the end of the group (upper bit not set)
       JHE -!
LENEM3 DEC R1                  ; Decrement counter until we locate the enemy group
       JNE -!


LENEM4 MOVB *R7+,R3            ; Load the number and type of enemies

       MOV R3,R4
       SRL R4,12
       ANDI R4,>0007           ; Get the count of enemies
       JEQ LENEM5

       MOV R3,R8
       ANDI R8,>0F00           ; Get only the enemy type
       SWPB R8
       JNE !
       LI R8,>0012            ; Fairy pond special case
!      MOV R8,*R9+            ; Store enemy type in objects array
       DEC R4
       JNE -!

       A R8,R8                 ; Load the sprites for this enemy
       MOV @ENEMYP(R8),R4      ; Get Enemy pattern (XXYZ -> XX = source pattern offset, Y = dest index + 20, Z = sprite count)
       JEQ LENEM5

       MOV R4,R8
       ANDI R8,>FF00
       SRL  R8,3
       AI   R8,ENESPR          ; Get source offset in R8 = XX * 32 + ENESPR

       MOV R4,R10
       ANDI R10,>00F0
       SLA  R10,2
       AI  R10,SPRPAT+>0100     ; Calculate dest offset into sprite pattern table (Y * 64 + >20 * 8)

       ANDI R4,>000F       ; The number of sprites to copy
!      MOV R8,R0
       BL @READ32          ; Read sprite into scratchpad
       AI R8,32

       MOV R10,R0
       BL @PUTSCR          ; Copy it back to the sprite pattern table
       AI R10,32

       DEC R4
       JNE -!

LENEM5 A R3,R3             ; Keep reading until the end of the group (upper bit not set)
       JOC LENEM4

       LI R0,ENEMHP+12+VDPWM      ; Fill enemy HP
       MOVB @R0LB,*R14
       MOVB R0,*R14

       LI R9,LASTOB      ; Read objects
       LI R4,(SPRLST-LASTOB)/2 ; 32-12
!      MOV *R9+,R1
       ANDI R1,>003F
       MOVB @INITHP(R1),*R15 ; Copy initial HP
       DEC R4
       JNE -!

LENEM6
       LI R0,SPRLST+(6*4)      ; Clear sprite list [6..31]
       LI R2,(32-6)*2          ; (including scratchpad)
!      CLR *R0+
       DEC R2
       JNE -!

       JMP CAVERT

LCAVE

       LI R8,LASTSP
!      CLR *R8+
       CI R8,WRKSP+256        ; Clear sprite table
       JNE -!

       ;LI R0,BANK4
       ;LI R1,MAIN
       ;LI R2,4                ; Link face direction up
       ;BL @BANKSW

       LI R3,DIR_UP
       BL @LNKSPR


       LI R9,5                ; Link walks upward for 5 frames
!      BL @VSYNCM
       LI R1,->100
       BL @DOSPRT

       DEC R9
       JNE -!

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM


       LI R5,SPRPAT+(76*32)   ; copy cave item sprites
       LI R9,SPRPAT+(8*32)    ; into enemies spots
       LI R4,14               ; copy 14 sprite patterns
!      MOV R5,R0
       BL @READ32
       MOV R9,R0
       BL @PUTSCR
       AI R5,32
       AI R9,32
       DEC R4
       JNE -!

       LI R0,ENESPR+(20*32)   ; Copy Moblin sprite
       BL @READ32
       MOV R9,R0
       BL @PUTSCR


       LI R2,3            ; 2 fires and 1 npc

       ;DEC R2   TODO check if item already collected

       LI R4,LASTOB       ; object list
       LI R5,LASTSP       ; sprite list
       LI R7,CAVDAT
!
       MOV *R7+,*R4+      ; Object ID
       MOV *R7+,*R5+      ; Object pos
       MOV *R7+,*R5+      ; Object sprite
       DEC R2
       JNE -!

       ; Clear remaining sprite table
!      CLR *R5+
       CI R5,WRKSP+256
       JNE -!
CAVERT
       B @DONE3

CAVDAT DATA >D05F,>5748,>0000 ; Flame object id, location, sprite
       DATA >D05F,>57A8,>0000 ; Flame object id, location, sprite
       DATA >C0DF,>5778,>D00F ; Old man object id, location, sprite







****************************************
* Enemy pattern indexes (XXYZ -> XX = source pattern offset, Y = dest index*4+20, Z = count)
* Y table 0:20 1:28 2:30 3:38 4:40 5:48 6:50 7:58 8:60 9:68
****************************************
ENEMYP DATA >0000  ; 0 Fairy
       DATA >0002  ; 1 Peahat              (both vertical symmetry)
       DATA >0222  ; 2 Red Tektite         (both vertical symmetry)
       DATA >0222  ; 3 Blue Tektite        (both vertical symmetry)
       DATA >0449  ; 4 Red Octorok         (both vertical symmetry, both horizontal symmetry, flips + bullet)
       DATA >0449  ; 5 Blue Octorok        (both vertical symmetry, both horizontal symmetry, flips + rotations + bullet)
       DATA >0449  ; 6 Fast Red Octorok
       DATA >0449  ; 7 Fast Blue Octorok
       DATA >1008  ; 8 Red Moblin          (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1008  ; 9 Blue Moblin         (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1848  ; A Red Lynel           (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1848  ; B Blue Lynel          (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >2804  ; C Ghini               (1 sprite flipped, 1 sprite flipped)
       DATA >0E22  ; D Rock                (2 sprites)
       DATA >2315  ; E Red Leever          (5 sprites, all vertical symmetry)
       DATA >2315  ; F Blue Leever         (5 sprites, all vertical symmetry)

       ; initial HP for enemies
INITHP BYTE 0,2,1,1     ; Armos Peahat RedTektite BlueTektite
       BYTE 1,2,1,2     ; RedOctorok BlueOctorok FastRedOctorok FastBlueOctorok
       BYTE 2,3,4,6     ; RedMoblin BlueMoblin RedLynel BlueLynel
       BYTE 9,0,2,4     ; Ghini Rock RedLeever BlueLeever
       BYTE 2           ; Zora


****************************************
* Enemy groups  (XY -> Y = Enemy pattern index  X = Count or Count + 8 if more enemies in group)
****************************************
ENEMYG BYTE >4A     ; 01  4 red lynel
       BYTE >4D     ; 02  4 rocks
       BYTE >6B     ; 03  6 blue lynel
       BYTE >AB,>AA,>9E,>1F    ; 04  2 blue lynel 2 red lynel 1 red leveer 1 blue leveer
       BYTE >AB,>AA,>21 ; 05  2 blue lynel 2 red lynel 2 peahat
       BYTE >1A     ; 06  1 red lynel
       BYTE >1B     ; 07  1 blue lynel
       BYTE >1E     ; 08  1 red leever
       BYTE >62     ; 09  6 red tektite
       BYTE >4B     ; 0A  4 blue lynel
       BYTE >AB,>2A ; 0B  2 blue lynel 2 red lynel
       BYTE >61     ; 0C  6 peahat
       BYTE >41     ; 0D  4 peahat
       BYTE >4E     ; 0E  4 red leever
       BYTE >6F     ; 0F  6 blue leever
       BYTE >AF,>9E,>31 ; 10  2 blue leever 1 red leveer 3 peahat
       BYTE >42     ; 11  4 red tektite
       BYTE >B6,>25 ; 12  3 fast red octorok 2 blue octorok
       BYTE >45     ; 13  4 blue octorok
       BYTE >4F     ; 14  4 blue leever
       BYTE >14     ; 15  1 red octorok
       BYTE >C6,>15 ; 16  5 fast red octorok 1 blue octorok
       BYTE >10     ; 17  fairy
       BYTE >15     ; 18  1 blue octorok
       BYTE >49     ; 19  4 blue moblin
       BYTE >48     ; 1A  4 red moblin
       BYTE >B9,>18 ; 1B  3 blue moblin 1 red moblin
       BYTE >42     ; 1C  4 red tektite
       BYTE >53     ; 1D  5 blue tektite
       BYTE >43     ; 1E  4 blue tektite
       BYTE >6E     ; 1F  6 red leever
       BYTE >18     ; 20  1 red moblin
       BYTE >44     ; 21  4 red octorok
       BYTE >11     ; 22  1 peahat
       BYTE >63     ; 23  6 blue tektite
       BYTE >78     ; 24  7 red moblin
       BYTE >5A     ; 25  5 red lynel
       BYTE >59     ; 26  5 blue moblin
       BYTE >A9,>28 ; 27  2 blue moblin 2 red moblin
       BYTE >B9,>28 ; 28  3 blue moblin 2 red moblin
       BYTE >99,>B8,>27 ; 29  1 blue moblin 3 red moblin 2 fast blue octorok
       BYTE >1C     ; 2a  1 ghini
       BYTE >A4,>26 ; 2b  2 red octorok, 2 fast red octorok
       BYTE >B4,>27 ; 2c  3 red octorok 2 fast blue octorok
       BYTE >12     ; 2d  1 red tektite

       ; +40 enemies enter from sides of screen (otherwise appear in puffs of smoke)
       ; +80 zora (otherwise armos sprites are loaded)

ENEMYS BYTE >00,>01,>01,>02,>03,>04,>05,>06,>02,>00,>87,>08,>09,>09,>00,>00
       BYTE >0A,>05,>03,>0B,>01,>05,>02,>82,>82,>82,>89,>00,>00,>0C,>89,>0C
       BYTE >2a,>2a,>06,>01,>00,>0D,>8C,>8C,>8C,>0E,>0F,>10,>11,>92,>93,>00
       BYTE >2a,>2a,>05,>00,>14,>80,>80,>15,>96,>17,>10,>14,>18,>19,>92,>98
       BYTE >2a,>2a,>20,>17,>A1,>22,>80,>80,>8E,>16,>23,>24,>12,>19,>19,>AC
       BYTE >25,>26,>27,>28,>A1,>95,>A1,>2B,>2B,>8D,>A1,>27,>19,>19,>26,>92
       BYTE >05,>26,>26,>29,>12,>AB,>2B,>21,>21,>A1,>A1,>29,>1A,>1A,>29,>96
       BYTE >0D,>26,>1B,>19,>2D,>90,>11,>00,>21,>1D,>1E,>9F,>9F,>93,>A1,>98




