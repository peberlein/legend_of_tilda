;
; Legend of Tilda
;
; Bank 3: title screen, game over animation, hero sprites
; todo: compressed sprites
;

       COPY 'tilda.asm'

       
; Load title screen
; R2 = 0 title screen
;      1 game over screen
;      2 load hero sprites (R3 = direction)
MAIN
       MOV R11,R13      ; Save return address for later
       CI R2,1
       JNE !
       B @GAMOVR
!      CI R2,2
       JNE !
       LI R11,DONE2
       B @LNKSPR
!
MAIN2
       LI R0,CLRTAB     ; Load color table
       LI R1,CLRSET
       LI R2,32
       BL @VDPW

       LI R0,>0700
       BL @BGCOL

       LI R0,PATTAB+(32*8)     ; Load pattern table
       LI R1,PAT32
       LI R2,SPR0-PAT32
       BL @VDPW

       LI R0,SPRPAT     ; Load sprite patterns
       LI R1,SPR0
       LI R2,MCOUNT-SPR0
       BL @VDPW

       LI R0,SCR1TB     ; Load screen table
       LI R1,MD0
       LI R2,32*24
       BL @VDPW

       LI R0,SPRLST     ; Load sprite table
       LI R1,SL0
       LI R2,(28*4)/2
!      MOV *R1+,*R0+
       DEC R2
       JNE -!

       CLR  R4          ; waterfall counter

       LI R9, 1         ; Reset tiforce counter
       LI R8,TIPAT      ; Tiforce pattern pointer

MLOOP
       BL @WATERF

       BL @VSYNC

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
; Modifies R0-
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
       LI R0,CLRTAB+31+VDPWM
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
       LI R1,MD0+(32*17)+10
       LI R2,4
!      MOVB *R1+,R0
       A R5,R0
       MOVB R0,*R15
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
       LI R1,CLRSET
       LI R2,31
BGCOL2 MOVB *R1+,R3
       MOV R3,R0
       ANDI R0,>0700
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
       BL @VSYNC
       LI R3,FACEDN
       BL @LNKSPR

       LI R4,32      ; Hurt Blink 32 frames
!      MOV R4,R1
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2
       BL @VSYNC
       BL @SPRUPD
       DEC R4
       JNE -!

       LI R4,26
!      BL @VSYNC
       DEC R4
       JNE -!

       LI R5,DEDCLR
       BL @FGCSET
       BL @VSYNC
       BL @VSYNC

       LI R0,>D000
       MOVB R0,@SPRLST+(4*6)+0 ; Turn off sprites 6+
       MOVB R0,@SPRLST+(4*31)+0 ; Turn off sprites 6+

       LI R0,CLRTAB
       LI R1,DEDCLR
       LI R2,32
       BL @VDPW
       BL @VSYNC
       BL @VSYNC

       LI R4,16
!
       BL @VSYNC
       BL @VSYNC
       BL @VSYNC
       BL @VSYNC
       BL @VSYNC
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
!      BL @VSYNC
       DEC R2
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL3
       LI R2,32
       BL @VDPW
       LI R2,10
!      BL @VSYNC
       DEC R2
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL4
       LI R2,32
       BL @VDPW
       LI R2,10
!      BL @VSYNC
       DEC R2
       JNE -!

       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       ORI R0,VDPWM+(3*32)
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,>2000  ; Space
       LI R2,21*32
!      MOVB R1,*R15
       DEC R2
       JNE -!

       LI R0,>0E00
       MOVB R0,@HEROSP+3   ; Set hero color to gray
       BL @SPRUPD
       LI R2,24
!      BL @VSYNC
       DEC R2
       JNE -!

       LI R0,>E800
       MOVB R0,@HEROSP+2   ; Set hero sprite index to little star
       BL @SPRUPD
       LI R2,10
!      BL @VSYNC
       DEC R2
       JNE -!

       LI R0,>EC00
       MOVB R0,@HEROSP+2   ; Set hero sprite index to big star
       BL @SPRUPD
       LI R2,4
!      BL @VSYNC
       DEC R2
       JNE -!

       LI R0,>0000
       MOVB R0,@HEROSP+3   ; Set hero color to transparent
       BL @SPRUPD
       LI R2,46
!      BL @VSYNC
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
!      BL @VSYNC
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

LNKSPN DATA FACERT,FACEDN,FACELT,FACEUP

; 939 2 brown on dark red palette
DEDCLR BYTE >16,>1B,>16,>96            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>14,>96            ;
       BYTE >96,>96,>16,>16            ;

; 1018 10 brown on lightred palette
DEDCL2 BYTE >18,>1B,>68,>98            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >18,>16,>16,>16            ;
       BYTE >16,>18,>98,>98            ;
       BYTE >19,>19,>19,>19            ;
       BYTE >19,>19,>14,>98            ;
       BYTE >98,>98,>18,>18            ;

; 1028 10 dark brown on darkred palette
DEDCL3 BYTE >16,>1B,>16,>96            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>14,>96            ;
       BYTE >96,>96,>16,>16            ;

; 1038 10 black on darkred palette
DEDCL4 BYTE >16,>1B,>16,>16            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>14,>16            ;
       BYTE >16,>16,>16,>16            ;





LNKSPR
       MOV R11,R12    ; Save return address
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       A R3,R1
       A R3,R1
       SRA R1,1
       AI R1,LSPR0

       CI R3,FACEUP
       JEQ !          ; No shield sprite for facing up
       LI R0,MAGSHD
       CZC @HFLAGS,R0  ; Got magic shield?
       JNE LNKSHD

!      LI R0,SPRPAT   ; Copy walking+attack sprites to sprites pattern table
       LI R2,32*6
       BL @VDPW
       B *R12        ; Return to saved address
LNKSHD
       LI R0,SPRPAT
       AI R1,32*8     ; Copy magic shield walking sprites to sprites pattern table
       LI R2,32*4
       BL @VDPW
       LI R0,SPRPAT+(32*4)
       AI R1,-32*8    ; Copy attack sprites to sprites pattern table
       LI R2,32*3
       BL @VDPW
       B *R12         ; Return to saved address

LSPR0  DATA >072F,>2830,>351F,>3603    ; Color 3
       DATA >2071,>2021,>0003,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
LSPR1  DATA >0000,>070F,>0A00,>49FC    ; Color 1
       DATA >DF8E,>DFDE,>FFFC,>7E0E    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CC12,>92FA,>8C00,>7000    ;
LSPR2  DATA >072F,>2830,>351F,>1603    ; Color 3
       DATA >1038,>1010,>0000,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
LSPR3  DATA >0000,>070F,>0A00,>297C    ; Color 1
       DATA >6F47,>6F6F,>7F7F,>3E00    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
LSPR4  DATA >0317,>1C38,>3597,>4E26    ; Color 3
       DATA >1807,>0A0C,>0602,>0100    ;
       DATA >E0F0,>180A,>AEEC,>7860    ;
       DATA >00C0,>0484,>6CE8,>E000    ;
LSPR5  DATA >1828,>63C7,>CA68,>3119    ; Color 1
       DATA >0708,>0503,>1939,>0000    ;
       DATA >0000,>E0F0,>5010,>8098    ;
       DATA >FC3C,>F878,>9217,>0F00    ;
LSPR6  DATA >6374,>0815,>1F0E,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >C62E,>10A8,>F870,>60C0    ;
       DATA >30F0,>3880,>38F8,>0000    ;
LSPR7  DATA >0003,>676A,>6031,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >00C0,>E656,>068C,>9C3C    ;
       DATA >C808,>C078,>C000,>7070    ;
LSPR8  DATA >072F,>2830,>351F,>0018    ; Color 7
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
LSPR9  DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CE12,>92FA,>8C00,>7000    ;
LSPR10 DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
LSPR11 DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
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
LSPR18 DATA >6374,>0815,>1F0D,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >E0F0,>1404,>ACEC,>78C0    ;
       DATA >3CFC,>3088,>38E0,>0000    ;
LSPR19 DATA >0003,>676A,>6032,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >0000,>E0F0,>5010,>843C    ;
       DATA >C000,>C870,>C010,>7070    ;
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
LSPR24 DATA >0F37,>6AEC,>AE26,>030C    ; Color 3
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FC,>F0F0    ;
       DATA >C464,>E0C0,>00E0,>0000    ;
LSPR25 DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F0,>2002,>0202    ;
       DATA >3A9A,>1A22,>E200,>0080    ;
LSPR26 DATA >0007,>1B35,>7657,>1301    ; Color 3
       DATA >0C11,>0020,>301F,>0F00    ;
       DATA >00C0,>8000,>0068,>7EF8    ;
       DATA >78E4,>D430,>E008,>F000    ;
LSPR27 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ;
       DATA >0000,>78FC,>F890,>8002    ;
       DATA >821A,>2ACA,>12F2,>0C38    ;
LSPR28 DATA >0003,>0B15,>1637,>7341    ; Color 3
       DATA >0F18,>1030,>783F,>1F00    ;
       DATA >00C0,>8000,>0068,>7EF0    ;
       DATA >EE1E,>1A10,>E000,>F000    ;
LSPR29 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0007,>0F0F,>07C0,>E070    ;
       DATA >0000,>78FC,>F890,>8008    ;
       DATA >10F0,>F0E0,>18F8,>0C1E    ;
LSPR30 DATA >0003,>0B15,>3677,>4301    ; Color 3
       DATA >070C,>0810,>381F,>0F00    ;
       DATA >00C0,>8000,>0068,>7EF8    ;
       DATA >E61E,>1A10,>E008,>F000    ;
LSPR31 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0107,>0F0F,>0760,>7038    ;
       DATA >0000,>78FC,>F890,>8000    ;
       DATA >18E0,>E4E0,>18F8,>0C1E    ;
LSPR32 DATA >0F37,>6AEC,>AE26,>030C    ; Color 8
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FD,>F1F1    ;
       DATA >C565,>E1C1,>01E0,>0000    ;
LSPR33 DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F3,>2302,>0202    ;
       DATA >3A9A,>1A22,>E203,>0380    ;
LSPR34 DATA >0007,>1B35,>7657,>1301    ; Color 8
       DATA >0C11,>0020,>301F,>0F00    ;
       DATA >00C0,>8000,>0068,>7DF9    ;
       DATA >79E5,>D531,>E109,>F000    ;
LSPR35 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ;
       DATA >0000,>78FC,>FB93,>8202    ;
       DATA >821A,>2ACA,>12F2,>0F3B    ;
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






       ; source in R3, dest VDP address in R4 (already loaded)
HFLIP
       LI R2,16      ; Copy 16 bytes
       A R2,R3       ; Start reading from right column
!      MOVB *R3+,R0  ; read a byte from the right column
       BL @REVB8      ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       LI R2,16      ; Copy 16 bytes
       AI R3,-32     ; Start reading from left column
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8      ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       AI R3,16
       JMP NEXTSP


UPCPY8 LI R2,8
       JMP !
UPCP16 LI R2,16
!      A R2,R3
; Copy R2 bytes from *R3 to *R15, moving upward
UPCOPY
!      DEC R3
       MOVB *R3,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

; source in R3, dest VDP address in R4 (already loaded)
VFLIP
       BL @UPCP16    ; Start reading from the bottom
       AI R3,16      ; Start reading from bottom of next column
       BL @UPCP16
       AI R3,16
       JMP NEXTSP
       
CLKWIS
       LI R2,32      ; Copy 32 bytes
       AI R3,8       ; Start from lower left
CLKWI2
       CI R2,24
       JNE CLKWI3
       CI R2,8
       JNE CLKWI3
       AI R3,16      ; Get next offset
       JMP !
CLKWI3 CI R2,16
       JNE !
       AI R3,-24     ; Get next offset
!      MOV R2,R0
       NEG R0
       LI R5,>7F7F
       SRC R5,R0     ; Get bitmask
       
       LI R4,8       ; Copy 8 bits
       CLR R0
CLKWI4 SRL R1,1
       MOVB *R3+,R0
       SZC R5,R0     ; AND bitmask
       JEQ !
       ORI R1,>8000
!      DEC R4
       JNE CLKWI4
       
       DEC R2
       JNE CLKWI2
       AI R3,16      ; Get next offset

       JMP NEXTSP

; Copy R2 zeros to *R15
CPZERO CLR R0
!      MOVB R0,*R15  ; Copy zero to VDP
       DEC R2
       JNE -!

; Copy R2 bytes from *R3 to *R15, shifting right by 4
CPSR4
!      MOVB *R3+,R1
       SRL R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
CPSL4
!      MOVB *R3+,R1
       SLA R1,4      ; Shift it
       MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

HVCENT
       LI R2,4       ; Copy 4 zero bytes
       BL @CPZERO
       LI R2,8       ; Copy 8 shifted bytes
       BL @CPSR4
       LI R2,8       ; Copy 8 zero bytes
       BL @CPZERO
       LI R2,8       ; Copy 8 bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       LI R2,8       ; Copy 4 zero bytes
       BL @CPZERO
       JMP NEXTSP

HCENT
       LI R2,16      ; Copy 16 shifted bytes
       BL @CPSR4
       LI R2,16      ; Copy 16 shifted bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       JMP NEXTSP

NEXTSP

COPY16 LI R2,16
       JMP !
COPY8
       LI R2,8
; Copy R2 bytes from *R3 to *R15
COPY
!      MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
       
VCENT
       LI R2,4       ; Copy 4 zero bytes
       BL @CPZERO
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 zero bytes
       BL @CPZERO
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 4 zero bytes
       BL @CPZERO
       JMP NEXTSP

HVSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes upward
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       LI R2,8       ; Copy 8 bytes
!      DEC R3
       MOVB *R3,R0   ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       AI R3,8
       JMP NEXTSP

; source in R3, dest VDP address in R4 (already loaded)
HSYMM
       BL @COPY16    ; Copy 16 bytes
       LI R2,16      ; Copy 16 bytes
       S R2,R3       ; Start reading from left column
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       JMP NEXTSP

VSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes reverse
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
       A R2,R3
       BL @COPY
       LI R2,8       ; Copy 8 bytes
       BL @UPCOPY
       AI R3,8
       JMP NEXTSP


; Reverse the 16-bit word in R0
; Modifies R1
REVB16
       SWPB R0      ; Reverse groups of 8 bits
REVB8
       MOV R0,R1    ; Reverse even and odd bits
       SRL R1,1
       ANDI R1,>5555
       ANDI R0,>5555
       SLA R0,1
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 2 bits
       SRL R1,2
       ANDI R1,>3333
       ANDI R0,>3333
       SLA R0,2
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 4 bits
       SRL R1,4
       ANDI R1,>0F0F
       ANDI R0,>0F0F
       SLA R0,4
       SOC R1,R0

       RT



TILDA  COPY "title.asm"
