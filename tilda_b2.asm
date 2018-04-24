;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 2: overworld map, cave, dungeon map
;

       COPY 'tilda.asm'

       
; Load a map into VRAM
; Load map screen from MAPLOC
; Use transition in R2
; (transition is actually performed in bank 5)
;      0=none
;      1=scroll up
;      2=down
;      3=left
;      4=right
;      5=wipe from center
;      6=cave in
;      7=cave out
; Modifies R0-R12,R15
MAIN
       MOV R11,R12          ; Save return address for later

       LI R0,SPRTAB+(6*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       LI R0,OBJECT+12      ; Clear objects[6..31]
       LI R1,32-6
!      CLR *R0+
       DEC R1
       JNE -!

       MOV R2,R3
       CI R3,5              ; Load initial color table on WIPE
       JNE !

INWIPE   ;  Initial wipe
       BL @CLRSCN

       MOV R12,@DOOR
       LI R0,BANK3
       LI R1,MAIN
       LI R2,3             ; Load overworld tileset
       BL @BANKSW
       LI R3,5           ; wipe from center
       MOV @DOOR,R12

       LI   R0,CLRTAB+VDPWM         ; Color table
       LI   R1,CLRSET
       LI   R2,32
       BL   @VDPW

       LI   R0,MCLRTB+VDPWM         ; Menu Color table
       LI   R1,CLRSET
       LI   R2,32
       BL   @VDPW

       LI   R0,MCLRTB+16+VDPWM      ; Menu Color table
       LI   R1,MCLRST
       LI   R2,10
       BL   @VDPW

       LI   R0,BCLRTB+VDPWM         ; Bright Color table
       LI   R1,BCLRST
       LI   R2,32
       BL   @VDPW

!
       ; Copy the top 3 rows from the current screen to the flipped screen
       LI   R6,VDPRD        ; Keep VDPRD address in R6
       LI   R10,SCRFLG+VDPWM
       MOV  @FLAGS,R0
       ANDI R0,SCRFLG
       LI   R9,3            ; Process 3 lines
!      BL   @READ32         ; Read a line from current
       XOR  R10,R0
       BL   @PUTSCR         ; Write a line to flipped
       XOR  R10,R0
       AI   R0,32
       DEC  R9
       JNE -!

       MOV R3,R2
       CI R2, 6      ; Cave in
       JNE !

       LI R9,16             ; Step down 16 lines

       CLR R1
       MOVB R1,@SCRTCH      ; Clear top line

STEPDN LI R4, 4             ; Step downward first four sprites
       LI R0,SPRPAT         ; Read 1st sprite pattern
STEPD2 LI R1,SCRTCH+1       ; Write to scratchpad
       BL @READ31
       CLR R1
       MOVB R1,@SCRTCH+16  ; Clear top right edge
       BL @PUTSCR

       AI R0,-VDPWM+32   ; Clear write bit and add 32
       DEC R4
       JNE STEPD2

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM

       DEC R9
       JNE STEPDN

       MOV R3,R2            ; Restore R2 since PUTSCR modified it

       BL @CLRSCN           ; Clear the screen so palette changes won't be visible
       BL @VSYNCM


       MOV @FLAGS,R0
       MOV R0,R1
       ANDI R0,DUNGON     ; Test for dungeon
       JEQ CAVEX

       ANDI R1,DUNLVL
       SRL R1,8
       MOV R1,R0
       SRL R1,2
       A R0,R1      ; R1 = dungeon level * 5 * 4

       LI   R0,CLRTAB+(3*4)       ; Color table
       AI   R1,DUNSET+(3*4)
       LI   R2,5*4
       BL   @VDPW

       LI   R0,CLRTAB       ; Color table
       LI   R1,DUNSET
       LI   R2,3*4
       BL   @VDPW

       LI   R0,>9978        ; Put hero at cave entrance
       MOV  R0,@HEROSP      ; Update color sprite
       MOV  R0,@HEROSP+4    ; Update outline sprite


       MOV R12,@DOOR
       LI R0,BANK3
       LI R1,MAIN
       LI R2,5             ; Load dungeon tileset
       BL @BANKSW
       MOV @DOOR,R12

       LI  R2,5             ; Use Wipe from center
       JMP !!
CAVEX

       CLR  @DOOR            ; Clear door location inside cave

       LI   R0,CLRTAB+15
       LI   R1,>1E00        ; Use gray on black palette for warp stairs
       BL   @VDPWB
       LI   R0,>B178        ; Put hero at cave entrance
       MOV  R0,@HEROSP      ; Update color sprite
       MOV  R0,@HEROSP+4    ; Update outline sprite
       LI   R0,LEVELA+VDPWM  ; R0 is screen table address in VRAM (with write bits)
       LI   R3,CAVE          ; Use cave layout
       JMP  STINIT
!
       CI R2, 7       ; Cave out
       JNE !
       BL @CLRCAV     ; Clear cave background
!

       CLR  R3
       MOVB @MAPLOC,R3      ; Get MAPLOC as >YX00

       MOV @FLAGS,R0
       ANDI R0,DUNGON     ; Test for dungeon
       JEQ !
       B @GODUNG          ; Dungeon strips
!

       MOV R3,R1            ; Get door/secret location from MAPLOC
       SWPB R1
       MOVB @DOORS(R1),R0   ; Lookup in DOORS table
       MOV  R0,R1           ; Convert >YX00 to >Y0X0
       ANDI R0,>F000
       ANDI R1,>0F00
       SRL  R1,4
       SOC  R1,R0           ; (SOC is OR)
       AI   R0,>1800
       MOV  R0,@DOOR        ; Store it

       MOV  R3,R1           ; Get palette offset
       SRL  R1,9            ; Get 16-bit offset
       MOVB @PALETT(R1),R5  ; Get palette entry
       MOV  R3,R0
       SLA  R0,8            ; Get lowest bit in carry
       JOC  !
       SRL  R5,4
!      ANDI R5,>0F00       ; R15 is palette

       MOV  R5,R11
       LI R1,>1C1B          ; black on dark green, black on yellow
       SLA  R11,6           ; put palette white bit in carry
       JNC !
       LI R1,>1F1E          ; black on white, black on grey
!      LI R0,VDPWM+CLRTAB+15      ; color table entry of green bricks
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R1,*R15
       MOVB R1,*R15
       MOVB R1,*R15
       SWPB R1
       LI R0,VDPWM+CLRTAB+26      ; color table entry of dungeon edges
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R1,*R15
       AI R1,>3000
       LI R0,VDPWM+CLRTAB+27      ; color table entry of armos
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R1,*R15

       SWPB R1              ; go back to black on green/white
       MOV  R5,R11
       LI R0,VDPWM+CLRTAB+22      ; trees
       SLA  R11,5           ; put trees or dungeon bit in carry
       JOC !
       INCT R0              ; dungeon
!      SLA  R11,3           ; put inner bit in carry
       JOC !
       LI R1,>1600          ; black on dark red
!      MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R1,*R15
       MOVB R1,*R15


       SRL  R3,4            ; Calculate offset into WORLD map
       AI   R3,WORLD        ; R3 is map screen address in ROM
STINIT
       LI   R10,LEVELA+VDPWM ; R10 is screen table address in VRAM (with write bits)
       LI   R4, 16          ; R4 is 16 strips

STLOOP
       MOVB *R3+,R8         ; Load strip index -> R8
       SRL R8,8
       MOV R8,R1
       ANDI R1,>000F        ; Load strip number past offset
       XOR R1,R8
       SRL R8,3
       MOV @STRIPO(R8),R9   ; Load strip offset
       AI R9,STRIPB
       
       INC R1 	     	    ; Scan until start bit (>80) is found
!      MOVB *R9+,R8  	    ; Get code
       A   R8,R8      	    ; Get upper bit in carry status
       JNC -! 	     	    ; No start bit
       DEC R1 	     	    ; Found start bit
       JNE -! 	     	    ; Count down until we hit the right one

       LI   R6,11           ; Metatile counter (11 per strip)
       DEC  R9	     	; Back up strip pointer
       CLR  R0             ; Clear double bit
MTLOOP
       MOV R0,R8
       ANDI R0,>4000	; Mask only double bit
       SLA  R0,2
       JOC !

       MOVB *R9+,R8         ; R8 is metatile index
       MOV  R8,R0    	; Save bits for later
!      ANDI R8,>3F00        ; Mask off upper two bits
       
       MOV  R5,R11         ; Move palette to temp register
       AI   R6,-3
       AI   R4,-3
       CI   R6,7            ; R6 between 2 and 9?
       JHE OUTER
       CI   R4,12           ; R4 between 2 and 14?
       JHE OUTER
       SLA  R11,8
       JNC ENDPAL           ; inner bit set
       JMP PALCHG
OUTER
       SLA  R11,7           ; outer bit set
       JNC ENDPAL           ; do palette change
PALCHG
       LI R1,PALMTG         ; use green metatile convert table
       MOV R5,R11
       SLA R11,6            ; put palette white bit in carry
       JNC !
       LI R1,PALMTW         ; use white metatile convert table 
!      CI R1,PALMTE
       JEQ ENDPAL
       CB *R1+,R8
       JNE -!
       AI R1,-PALMTW-1
       MOV R1,R8
       SLA R8,2
       AI R8,MTGREY-MT00
       SLA R8,6

ENDPAL AI   R6,3
       AI   R4,3

       SRL  R8,6
       AI   R8,MT00         ; R8 is metatile address

       MOV  *R8+,R1         ; R1 is first two metatile characters
       MOV  *R8,R8          ; R8 is second two metatile characters

       MOVB @R10LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R10,*R14          ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       MOVB @R1LB,*R15
       AI   R10,32           ; Next row

       MOVB @R10LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R10,*R14          ; Send high byte of VDP RAM write address
       MOVB R8,*R15
       MOVB @R8LB,*R15
       AI   R10,32           ; Next row

       DEC  R6              ; Decrement metatile counter
       JNE  MTLOOP
!
       AI   R10,2-(22*32)    ; Back to top and 1 metatile right

       DEC  R4              ; Decrement strip counter
       JNE  STLOOP
       

; TODO Show secret if persistent bit is set
       BL @TESTSC
JMPMOD
       LI   R6,VDPRD        ; Keep VDPRD address in R6
       
       LI R0,BANK5       ; Use R2=transition in bank 5
       LI R1,MAIN
       MOV R12,R11       ; Restore saved return address
       B @BANKSW

DONE
       LI R0,>000A-(10*256)
       MOVB @MAPLOC,R1      ; Mapdot Y = MAPDOT[(MAPLOC & 0x7000) >> 12]
       ANDI R1,>7000
       SRL R1,4
       A R1,R0
       A R1,R0
       A R1,R0

       MOVB @MAPLOC,R1      ; Mapdot X = ((MAPLOC & 0x0F00) >> 6) + 16
       ANDI R1,>0F00
       SRL  R1,6
       A    R1,R0         ; Set XX
       MOV  R0,@MPDTSP    ; Set Map Dot YYXX  (YY=16,20...76 XX=-13,-10,-7,-4,-1,2,5,8)

       LI R0,BANK4
       LI R1,MAIN
       LI R2,10               ; Load enemies
       MOV R12,R11            ; Restore our return address
       B    @BANKSW

DONE3
       LI R0,SCHSAV
       BL @READ32            ; Restore saved scratchpad

       MOV @HEROSP,R5        ; Get hero YYXX
       AI R5,>0100           ; Move Y down one

       LI   R0,BANK0         ; Load bank 0
       MOV  R12,R1           ; Jump to our return address
       B    @BANKSW




; Test for vsync and play music if set
VMUSIC
       MOV R12,R0           ; Save R12
       CLR R12              ; CRU Address bit 0002 - VDP INT
       TB 2
       JEQ !
       MOVB @VDPSTA,R12     ; Clear interrupt flag manually since we polled CRU
       MOV R0,R12           ; Restore R12
       B @MUSIC       
!      MOV R0,R12           ; Restore R12
       RT


; Add R1 to hero sprite YYXX, and update VDP sprite list
DOSPRT
       A R1,@HEROSP
       A R1,@HEROSP+4
       LI R0,SPRTAB+(HEROSP-SPRLST)
       LI R1,HEROSP
       LI R2,8
       B @VDPW

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

; Copy screen at R0 into R1 31 bytes
; Modifies R1,R2
READ31
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R2,8             ; Read 31 bytes to scratchpad
       JMP READ3           ; Use loop in READ32 minus 1


; Flip the current page, the visible page is stored in VDP2 and SCRPTR
; Modifies R0
FLIP   LI   R0,SCRFLG      ; Screen flag mask
       XOR  @FLAGS,R0      ; Get flags into R0 with screen flag toggled
       MOV  R0,@FLAGS      ; Save the updated flags word
       ANDI R0,SCRFLG      ; Mask only the screen flag
       SRL  R0,10          ; Lower 10 bits of screen table are not used
       ORI  R0,>8200       ; VDP Register 2: Screen Table 1
       MOVB @R0LB,*R14      ; Send low byte of VDP register
       MOVB R0,*R14         ; Send high byte of VDP register
       RT


CLRCAV
       LI R1,>2020  ; ASCII space
       LI R8,14     ; clear 14 lines
       MOV @FLAGS,R0  ; Set dest to flipped screen
       ANDI R0,SCRFLG
       AI  R0,(32*7)+4+VDPWM  ; Calculate right column dest pointer with write flag
!      MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R9,24
!      MOVB R1,*R15
       DEC R9
       JNE -!
       AI R0,32
       DEC R8
       JNE -!!
       RT


CLRSCN
       LI R1,>2020  ; ASCII space
       LI R8,21*32
       MOV @FLAGS,R0  ; Set dest to flipped screen
       ANDI R0,SCRFLG
       AI  R0,(32*3)+VDPWM  ; Calculate right column dest pointer with write flag
       MOVB @R0LB,*R14
       MOVB R0,*R14
!      MOVB R1,*R15
       DEC R8
       JNE -!
       RT





; Open secret cave if bit set
TESTSC
       MOVB @MAPLOC,R0
       SRL R0,8
       MOV R0,R1
       SRL R1,3
       AI R1,SDCAVE  ; Save data - opened secret caves
       MOVB @R1LB,*R14
       MOVB R1,*R14
       ANDI R0,7
       MOVB @VDPRD,R3
       INC R0
       SLA R3,R0
       JNC TESTS2

; Open secret cave
;OPENSC
       MOV R2,R13
       MOV @DOOR,R3
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX R3
       ; to character coordinate        YY YYYXXXXX R0
       MOV R3,R0
       SRL R0,3
       MOVB R0,R3
       SRL R3,3
       AI R3,LEVELA-(32*3)
       MOVB @R3LB,*R14
       MOVB R3,*R14
       CLR R0
       MOVB @VDPRD,R0

       LI R1,>7879  ; Green stairs
       LI R2,>7A7B

       CI R0,>9800  ; Brown bush
       JNE !
       LI R1,>7071  ; Brown stairs
       LI R2,>7273
!      CI R0,>8000  ; Green brick
       JEQ !
       CI R0,>A000  ; Red brick
       JNE !!
!      LI R1,>7F7F  ; Doorway
       LI R2,>2020
!      ORI R3,VDPWM
       MOVB @R3LB,*R14
       MOVB R3,*R14
       MOVB R1,*R15
       MOVB @R1LB,*R15
       AI R3,32
       MOVB @R3LB,*R14
       MOVB R3,*R14
       MOVB R2,*R15
       MOVB @R2LB,*R15
       MOV R13,R2
TESTS2 RT



; Overworld map consists of 16x8 screens, each screen is 16 bytes
; Each byte is into an index into an array of strips 11 metatiles tall
; Each screen is 16x11 metatiles
; Each screen should have a palette to switch between green/white brick, or brown/green trees/faces

WORLD  BCOPY "overworld.bin" ; World strip indexes 16*8*16 bytes
WORLDE
CAVE   EQU WORLD+>800       ; Cave strips 16 bytes
STRIPO EQU WORLD+>810       ; Strip offsets 16 words
STRIPB EQU WORLD+>830       ; Strip base (variable size)
 
;   outer inner Palette options
; 0 brown brown 000 
; 1 brown green 001  ; bit 0 - inner 0=brown 1=green/white
; 2 green brown 010  ; bit 1 - outer 0=brown 1=green/white
; 3 green green 011  ; bit 2 - 0=green 1=white (set brick/trees/dungeon to this color)
; 4 brown brown 100  ; bit 3 - set 0=dungeon 1=trees to inner color
; 5 brown white 101
; 7 white white 111
PALETT DATA >0000,>0000,>0000,>0000
       DATA >8888,>0000,>0000,>0009
       DATA >7754,>0000,>1000,>0007
       DATA >77C5,>0008,>0100,>330C
       DATA >7701,>1133,>3333,>3330
       DATA >7001,>3333,>3333,>3330
       DATA >4000,>3223,>3333,>3330
       DATA >8000,>2333,>3000,>0000

; YX coordinates of secrets/door on overworld screens
DOORS  BYTE >00,>19,>00,>47,>1C,>65,>00,>4A,>00,>00,>12,>47,>18,>19,>45,>48
       BYTE >19,>00,>18,>12,>1C,>00,>16,>00,>00,>00,>46,>00,>4B,>35,>1C,>46
       BYTE >00,>59,>47,>54,>00,>1A,>13,>1E,>6D,>00,>00,>00,>69,>15,>00,>46
       BYTE >00,>00,>00,>1A,>44,>00,>00,>47,>00,>00,>00,>00,>47,>49,>00,>46
       BYTE >00,>00,>56,>00,>14,>48,>79,>7B,>2D,>35,>1B,>2B,>00,>6D,>4A,>00
       BYTE >00,>69,>00,>00,>00,>48,>6A,>00,>00,>00,>00,>62,>00,>00,>17,>00
       BYTE >00,>00,>28,>66,>17,>00,>17,>17,>62,>00,>6C,>68,>00,>2A,>00,>13
       BYTE >1B,>15,>00,>00,>48,>12,>16,>14,>64,>59,>00,>19,>16,>16,>00,>00


       
MT00   DATA >A0A1,>A2A3  ; Brown Brick
       DATA >0000,>0000  ; Ground
       DATA >1415,>1415  ; Ladder
       DATA >A4A5,>ABAC  ; Brown top
       DATA >A7AE,>AF07  ; Brown corner SE
       DATA >A506,>ACAD  ; Brown corner NE
       DATA >A8A9,>05A6  ; Brown corner SW
       DATA >7F7F,>2020  ; Black doorway
       DATA >04A4,>AAAB  ; Brown corner NW
       DATA >9C9D,>9E9F  ; Brown rock
       DATA >E6E7,>E5E1  ; Water corner NW
       DATA >E5E0,>E4E1  ; Water edge W
       DATA >E4E0,>E3E2  ; Water corner SW
       DATA >E7E7,>E1E1  ; Water edge N
       DATA >E0E0,>E1E1  ; Water
       DATA >E0E0,>E2E2  ; Water edge S

MT10   DATA >00ED,>0011  ; Water inner corner NE
       DATA >EC00,>1000  ; Water inner corner NW
       DATA >E7E8,>E1E9  ; Water corner NE
       DATA >E0E9,>E1EA  ; Water edge E
       DATA >E0EA,>E2EB  ; Water corner SE
       DATA >00D0,>D2C8  ; Brown Dungeon NW
       DATA >D3C9,>CBCA  ; Brown Dungeon SW
       DATA >C0C1,>C2C3  ; Brown Dungeon two eyes
       DATA >D100,>CCD2  ; Brown Dungeon NE
       DATA >CDD3,>CECB  ; Brown Dungeon SE
       DATA >7071,>7273  ; Red Steps
       DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >D4B0,>D5B0  ; Brown Tree NW
       DATA >00B2,>00B3  ; Brown Tree SW
       DATA >B400,>B500  ; Brown Tree NE
       DATA >B6D6,>B7D7  ; Brown Tree SE

MT20   DATA >D8D9,>DADB  ; Waterfall
       DATA >D8D9,>1717  ; Waterfall bottom
       DATA >B8B9,>BABB  ; Tree face
       DATA >F4F5,>F6F7  ; Gravestone
       DATA >9899,>9A9B  ; Bush
       DATA >1200,>EE00  ; Water inner corner SW
       DATA >6061,>6263  ; Sand
       DATA >1C1C,>1D1D  ; Red Bridge
       DATA >878E,>8F08  ; Grey corner SE
       DATA >0808,>0808  ; Grey Ground
       DATA >F4F5,>F6F7  ; Gravestone
       DATA >8485,>8B8C  ; Grey top
       DATA >7879,>7A7B  ; Grey stairs
       DATA >F0F1,>F2F3  ; Grey bush
       DATA >0062,>D2C8  ; Green Dungeon NW
       DATA >D3C9,>CBCA  ; Green Dungeon SW

MT30   DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >6300,>CCD2  ; Green Dungeon NE
       DATA >2020,>2020  ; Black square
       DATA >DCDD,>DEDF  ; Armos
       DATA >0013,>00EF  ; Water inner corner SE
       DATA >7475,>7677  ; Brown brick Hidden path
       DATA >E0E9,>E1EA  ; Water edge E

MTGREY ; white metatiles
       DATA >0808,>0808  ; Grey Ground
       DATA >0A0B,>0A0B  ; Grey Ladder
       DATA >878E,>8F0F  ; Grey corner SE
       DATA >850E,>8C8D  ; Grey corner NE
       DATA >8889,>0D86  ; Grey corner SW
       DATA >0C84,>8A8B  ; Grey corner NW
       DATA >F0F1,>F2F3  ; Grey bush
       DATA >7879,>7A7B  ; Grey stairs
       DATA >08D0,>D2C8  ; White Dungeon NW
       DATA >D108,>CCD2  ; White Dungeon NE

MTGREN ; green metatiles
       DATA >8081,>8283  ; Green brick
       DATA >8485,>8B8C  ; Green top
       DATA >878E,>8F07  ; Green corner SE
       DATA >8506,>8C8D  ; Green corner NE
       DATA >8889,>0586  ; Green corner SW
       DATA >0484,>8A8B  ; Green corner NW
       DATA >9495,>9697  ; Green rock
       DATA >7879,>7A7B  ; Green Steps
       DATA >9091,>9293  ; Green bush
       DATA >7C7C,>7D7D  ; Green Bridge

; palette metatile conversions white/green, same order as MTGREY or MTGREN, above
PALMTW BYTE >01,>02,>04,>05,>06,>08,>24,>1A,>15,>18  ; grey conversions
PALMTG BYTE >00,>03,>04,>05,>06,>08,>09,>1A,>24,>27  ; green conversions
PALMTE


; Master is sprites.mag

****************************************
* Overworld Colorset Definitions
****************************************
CLRSET BYTE >1B,>1E,>4B,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >6B,>1B,>16,>1C            ;
       BYTE >1C,>1C,>CB,>6B            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>1B,>4B            ;
       BYTE >4B,>4B,>1F,>41            ;

****************************************
* Menu Colorset Definitions starting at char >80
****************************************
MCLRST BYTE >A1,>A1,>A1,>41            ;
       BYTE >41,>41,>41,>61            ;
       BYTE >61,>61

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

****************************************
* Dungeon Colorset Definitions
****************************************
DUNSET BYTE >1B,>1B,>1B,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;

       BYTE >47,>17,>17,>75            ; Level-1
       BYTE >47,>47,>47,>47            ; Level-1
       BYTE >47,>47,>47,>47            ; Level-1
       BYTE >47,>17,>17,>17            ; Level-1
       BYTE >17,>4E,>41,>41            ; Level-1

       BYTE >14,>14,>15,>54            ; Level-2
       BYTE >15,>14,>14,>14            ; Level-2
       BYTE >14,>14,>14,>14            ; Level-2
       BYTE >14,>14,>14,>14            ; Level-2
       BYTE >14,>48,>41,>41            ; Level-2

       BYTE >12,>12,>12,>2C            ; Level-3
       BYTE >13,>12,>12,>12            ; Level-3
       BYTE >12,>12,>12,>12            ; Level-3
       BYTE >12,>12,>12,>12            ; Level-3
       BYTE >12,>C6,>41,>41            ; Level-3

       BYTE >1A,>1A,>1A,>BA            ; Level-4
       BYTE >4B,>1A,>1A,>1A            ; Level-4
       BYTE >1A,>1A,>1A,>1A            ; Level-4
       BYTE >1A,>1A,>1A,>1A            ; Level-4
       BYTE >1A,>A4,>41,>41            ; Level-4

       BYTE >C3,>12,>12,>32            ; Level-5
       BYTE >13,>C3,>C3,>C3            ; Level-5
       BYTE >C3,>C3,>C3,>C3            ; Level-5
       BYTE >C3,>13,>13,>13            ; Level-5
       BYTE >13,>16,>41,>41            ; Level-5

       BYTE >1A,>1A,>1A,>BA            ; Level-6
       BYTE >6B,>1A,>1A,>1A            ; Level-6
       BYTE >1A,>1A,>1A,>1A            ; Level-6
       BYTE >1A,>1A,>1A,>1A            ; Level-6
       BYTE >1A,>A6,>41,>41            ; Level-6

       BYTE >C3,>12,>12,>32            ; Level-7
       BYTE >13,>C3,>C3,>C3            ; Level-7
       BYTE >C3,>C3,>C3,>C3            ; Level-7
       BYTE >C3,>13,>13,>13            ; Level-7
       BYTE >13,>15,>41,>41            ; Level-7

       BYTE >1E,>1E,>1E,>FE            ; Level-8
       BYTE >1F,>1E,>1E,>1E            ; Level-8
       BYTE >1E,>1E,>1E,>1E            ; Level-8
       BYTE >1E,>1E,>1E,>1E            ; Level-8
       BYTE >1E,>E4,>41,>41            ; Level-8

       BYTE >1E,>1E,>1E,>FE            ; Level-9
       BYTE >1F,>1E,>1E,>1E            ; Level-9
       BYTE >1E,>1E,>1E,>1E            ; Level-9
       BYTE >1E,>1E,>1E,>1E            ; Level-9
       BYTE >1E,>1E,>41,>41            ; Level-9


; Note: must preserve R2,R12
; R3 = MAPLOC
GODUNG
       CI R2,2        ; Down?
       JNE !
       MOV R3,R0
       ANDI R0,>7000  ; at bottom of dungeon?
       JNE !

       ; exiting dungeon
       LI R0,MAPSAV
       BL @VDPRB
       MOVB R1,@MAPLOC   ; Restore saved overworld map location

       SRL R1,8
       MOVB @DOORS(R1),R0   ; Lookup in DOORS table
       MOV  R0,R1           ; Convert >YX00 to >Y0X0
       ANDI R0,>F000
       ANDI R1,>0F00
       SRL  R1,4
       SOC  R1,R0           ; (SOC is OR)
       AI   R0,>1800
       MOV  R0,@DOOR        ; Store it

       MOV  @DOOR,R5        ; Move link to door location
       AI R5,->0100         ; Move Y up one
       MOV R5,@HEROSP	    ; Update color sprite
       MOV R5,@HEROSP+4     ; Update outline sprite
       LI R0,SPRTAB+(HEROSP-SPRLST)
       LI R1,>D000
       BL @VDPWB            ; Turn off hero sprite

       LI R0,DUNGON+DUNLVL
       SZC R0,@FLAGS     ; Clear dungeon flag
       LI R2,5           ; Wipe
       B @INWIPE

!


       LI R10,LEVELA+(4*32)+4+VDPWM  ; First metatile location + write mask
       SRL R3,8             ; Map location
       MOVB @DUNMAP(R3),R1  ; Screen type
       SRL R1,8

       INC R1
       LI R5,ST0
!      DEC R1
       JEQ STDUN1
       LI R0,12
       CLR R3
STDUN0 CI R3,>FF00       ; FF byte indicates load tile type
       JNE !
       MOVB *R5+,R7      ; load word into R7
       MOVB *R5+,@R7LB
       MOVB *R5+,R8      ; load word into R8
       MOVB *R5+,@R8LB
!      MOVB *R5+,R3
       JLT STDUN0
       DEC R0
       JNE STDUN0
       JMP -!!
STDUN1
       CLR R3
       MOVB *R5+,R3    ; Get floor bits
       SLA R3,1
       JNC STDUN2
       CI R3,>FE00     ; FF byte indicates load tile type
       JNE !
       MOVB *R5+,R7    ; load word into R7
       MOVB *R5+,@R7LB
       MOVB *R5+,R8    ; load word into R8
       MOVB *R5+,@R8LB
       JMP STDUN1
!      MOVB *R5+,@R3LB  ; Get statue bits
STDUN2
       SLA R3,1
       JNC !
       MOV R7,R0
       MOV R8,R1
       JMP STDUN3
!
       LI R0,>0080
       COC R0,R3
       JEQ !
       LI R0,>7879     ; floor
       LI R1,>7A7B
       JMP STDUN3
!
       MOV R10,R0
       ANDI R0,>001F
       CI R0,16   ; At middle?
       JHE !
       LI R0,>E8E9    ; right facing statue
       LI R1,>EAEB
       JMP STDUN3
!
       LI R0,>ECED    ; left facing statue
       LI R1,>EEEF
STDUN3
       MOVB @R10LB,*R14     ; Draw upper-half metatile
       MOVB R10,*R14
       AI R10,32
       MOVB R0,*R15
       MOVB @R0LB,*R15

       MOVB @R10LB,*R14     ; Draw lower-half metatile
       MOVB R10,*R14
       AI R10,32
       MOVB R1,*R15
       MOVB @R1LB,*R15

       CI R10,LEVELA+(18*32)+VDPWM   ; At bottom?
       JL STDUN2

       AI R10,-(14*32)+2  ; Move up and right 2
       CI R10,LEVELA+(4*32)+28+VDPWM  ; At rightmost?
       JL STDUN1

       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOVB @WALMAP(R1),R0   ; Lookup in DOORS table

       LI R3,>0400     ; Check V door bit
       LI R10,LEVELA+(18*32)+14+VDPWM
       LI R9,LEVELA+(18*32)+15+VDPWM
       LI R1,SWALL
       BL @DVDOOR      ; Draw south door or wall

       SRL R3,2        ; Check H door bit
       LI R10,LEVELA+(9*32)+28+VDPWM
       LI R9,LEVELA+(10*32)+28+VDPWM
       LI R1,EWALL
       BL @DHDOOR      ; Draw east door or wall

       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOVB @WALMAP-1(R1),R0   ; Lookup in DOORS table

       LI R10,LEVELA+(9*32)+1+VDPWM
       LI R9,LEVELA+(10*32)+2+VDPWM
       LI R1,WWALL
       BL @DHDOOR      ; Draw west door or wall

       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOV R1,R0
       ANDI R0,>0070    ; R0=0 when Y=0 or 8
       JEQ !
       MOVB @WALMAP-16(R1),R0   ; Lookup in DOORS table
!
       SLA R3,2        ; Check V door bit
       LI R10,LEVELA+(1*32)+14+VDPWM
       LI R9,LEVELA+(2*32)+15+VDPWM
       LI R1,NWALL
       BL @DVDOOR      ; Draw north door or wall



       B @JMPMOD   ; Jump to mode

DVDOOR  ; Draw vertical door
       LI R4,3
       CZC R3,R0
       JEQ !
       AI R1,16    ; draw door instead

!      MOVB @R10LB,*R14
       MOVB R10,*R14
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       AI R10,32
       DEC R4
       JNE -!
       JMP LOKBOM

DHDOOR  ; Draw horizontal door
       LI R4,4
       CZC R3,R0
       JEQ !
       AI R1,16    ; draw door instead

!      MOVB @R10LB,*R14
       MOVB R10,*R14
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       AI R10,32
       DEC R4
       JNE -!

LOKBOM ; Draw locked door or bomb hole
       SLA R3,1
       CZC R3,R0
       JNE !      ; Locked or bombable bit set?
       SRL R3,1
       RT
!      SRL R3,1
       CZC R3,R0
       JNE !      ; Draw locked door
       RT
!

       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       AI R9,32
       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       RT



NWALL  BYTE >89,>64,>64,>89,>96,>96,>96,>96,>96,>96,>96,>96
NBOMB  BYTE >68,>69,>20,>20
NDOOR  BYTE >94,>60,>60,>94,>C8,>20,>20,>C9,>C0,>7B,>7A,>C1
NLOCK  BYTE >D8,>D9,>DA,>DB

WWALL  BYTE >8F,>9D,>9D,>8F,>9D,>9D,>65,>9D,>9D,>8F,>9D,>9D
WBOMB  BYTE >6C,>20,>6D,>20
WDOOR  BYTE >A6,>CA,>C2,>A6,>F7,>7F,>62,>20,>7B,>A6,>CC,>C4
WLOCK  BYTE >E0,>E1,>E2,>E3

EWALL  BYTE >9E,>9E,>8F,>9E,>9E,>8F,>9E,>9E,>65,>9E,>9E,>8F
EBOMB  BYTE >20,>6E,>20,>6F
EDOOR  BYTE >C3,>CB,>A7,>7E,>F7,>A7,>7A,>20,>63,>C5,>CD,>A7
ELOCK  BYTE >E4,>E5,>E6,>E7

SWALL  BYTE >B1,>B1,>B1,>B1,>B1,>B1,>B1,>B1,>89,>64,>64,>89
SBOMB  BYTE >20,>20,>6A,>6B
SDOOR  BYTE >C6,>79,>78,>C7,>CE,>20,>20,>CF,>BC,>61,>61,>BC
SLOCK  BYTE >DC,>DD,>DE,>DF

; W=wall D=door L=locked B=bomb
WW     EQU >00
WD     EQU >01
WB     EQU >02
WL     EQU >03
DW     EQU >04
DD     EQU >05
DB     EQU >06
DL     EQU >07
BW     EQU >08
BD     EQU >09
BB     EQU >0A
BL     EQU >0B
LW     EQU >0C
LD     EQU >0D
LB     EQU >0E
LL     EQU >0F

; Each byte is the south and east wall/doors for that room (north,west are taken from byte above and left)
WALMAP BYTE DL,BD,DW,DW,WW,WL,LW,WW,WW,LB,DB,DW,DW,WD,DW,WW
       BYTE DB,BB,WD,WW,DW,BW,WB,WW,DD,LD,WD,WW,DW,DW,DB,DW
       BYTE LD,LW,WL,LW,DL,WD,WL,DW,DB,DW,WD,DW,WW,WW,DL,BW
       BYTE DL,WD,WW,DW,WW,LD,WW,DW,DW,WD,WW,LW,DW,DW,DD,BW
       BYTE DW,WD,LD,BL,BD,WW,LD,DW,DW,DD,DL,DL,DB,DW,DD,BW
       BYTE WD,DW,WD,DD,WW,DD,DD,WW,DW,DL,WD,DB,WD,WW,DL,BW
       BYTE WW,DL,WW,LW,WB,WB,DD,BW,DW,WW,WL,DW,WD,DD,DL,WW
       BYTE WD,DW,WD,DD,WW,WW,DD,WW,WL,DD,WW,WD,DW,DD,WW,WW

       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW
       BYTE WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW,WW


       ; 6 bits map
       ; 2 bits door type (0=wall 1=open 2=bomb 3=lock)
       ;
DUNMAP BYTE >28,>26,>10,>0C,>00,>09,>0A,>00,>00,>0F,>0F,>28,>0C,>0C,>02,>00
       BYTE >0E,>28,>0F,>11,>0C,>28,>22,>28,>11,>25,>22,>05,>0E,>14,>08,>28
       BYTE >21,>23,>0A,>21,>12,>13,>24,>21,>08,>24,>07,>28,>00,>25,>07,>00
       BYTE >22,>20,>0F,>20,>04,>0B,>0C,>20,>0F,>25,>09,>0F,>20,>0C,>29,>00
       BYTE >21,>28,>09,>06,>04,>08,>23,>21,>10,>00,>15,>16,>00,>29,>04,>12
       BYTE >0D,>05,>03,>04,>05,>25,>00,>20,>12,>07,>00,>00,>06,>03,>06,>05
       BYTE >00,>04,>1C,>03,>0A,>04,>22,>28,>07,>14,>28,>0D,>00,>05,>08,>03
       BYTE >00,>01,>00,>01,>07,>00,>01,>07,>06,>01,>05,>05,>01,>01,>00,>00

       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00

       ; Screen type strips of metatiles (12 or more bytes)
       ; column of bits indicating 0=floor or 1=other (block/water/lava/sand)
       ; (1xxx xxxx indicates next byte contains statue bit mask)
ST0    BYTE >FF,>7C,>7C,>7C,>7C  ; dark sand
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00   ; 0 Completely empty
       BYTE >00,>80,>2A,>00,>03,>81,>2A,>07,>07,>81,>2A,>03,>00,>80,>2A,>00  ; 1 Starting room (sand)
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 2 Room full of dark sand

       BYTE >FF,>84,>85,>86,>87  ; brick
       BYTE >00,>00,>00,>00,>00,>1C,>1C,>00,>00,>00,>00,>00   ; 3 Six bricks in center
       BYTE >00,>00,>14,>00,>00,>00,>00,>00,>00,>14,>00,>00   ; 4 Four bricks squat rect
       BYTE >00,>00,>22,>00,>00,>00,>00,>00,>00,>22,>00,>00   ; 5 Four bricks rect
       BYTE >00,>22,>22,>00,>00,>08,>08,>00,>00,>22,>22,>00   ; 6 Five sets of two bricks
       BYTE >00,>00,>1C,>1C,>00,>00,>00,>00,>1C,>1C,>00,>00   ; 7 Two sets of six bricks
       BYTE >00,>2A,>00,>2A,>00,>2A,>2A,>00,>2A,>00,>2A,>00   ; 8 Two sets of separated nine bricks
       BYTE >00,>00,>00,>00,>00,>08,>00,>00,>00,>00,>00,>00   ; 9 Single brick
       BYTE >00,>00,>00,>00,>08,>14,>22,>14,>08,>00,>00,>00   ; A Diamond bricks
       BYTE >00,>00,>00,>00,>00,>00,>00,>41,>41,>63,>77,>77   ; B Right boss room
       BYTE >00,>3E,>22,>A2,>08,>A2,>10,>20,>20,>A2,>10,>A2,>08,>22,>3E,>00  ; C Tiforce room
       BYTE >01,>22,>44,>08,>10,>20,>02,>04,>08,>11,>22,>40   ; D Angled walls
       BYTE >80,>01,>08,>00,>02,>00,>00,>00,>00,>02,>00,>08,>80,>01  ; E Four bricks, two statues
       BYTE >00,>00,>00,>00,>08,>00,>00,>08,>00,>00,>00,>00   ; F Two bricks near center
       BYTE >00,>08,>14,>00,>00,>00,>00,>00,>00,>14,>08,>00   ; 10 Small <  >
       BYTE >70,>70,>62,>60,>40,>00,>00,>40,>60,>62,>70,>70   ; 11 Top boss room
       BYTE >80,>41,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>80,>41  ; 12 Four statues in corners
       BYTE >00,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>00   ; 13 Three brick strips horizontal
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>63,>77,>77,>77   ; 14 Right stair room
       BYTE >14,>14,>14,>14,>14,>14,>14,>14,>14,>14,>14,>14   ; 15 Two long strips horizontal
       BYTE >00,>22,>22,>22,>22,>22,>22,>22,>22,>22,>3E,>00   ; 16 Big backward C
       BYTE >00,>00,>3E,>22,>22,>22,>22,>22,>22,>3E,>00,>00   ; 17 Brick rect
       BYTE >00,>00,>00,>00,>80,>08,>00,>00,>80,>08,>00,>00,>00,>00 ; 18 Two statues near center
       BYTE >00,>3E,>22,>22,>22,>2A,>2A,>2A,>3A,>02,>7E,>00   ; 19 Spiral with stairs
       BYTE >BE,>41,>7F,>43,>1B,>38,>04,>04,>38,>1B,>43,>7F,>BE,>41  ; 1A Final boss room
       BYTE >7F,>40,>D8,>01,>58,>E0,>04,>40,>40,>E0,>04,>58,>D8,>01,>40,>7F  ; 1B Princess room
       BYTE >00,>7C,>05,>6C,>20,>3E,>00,>23,>20,>3E,>10,>13    ; 1C Brick maze
       BYTE >00,>00,>00,>00,>7F,>00,>00,>7F,>00,>00,>00,>00    ; 1D Two long strips vertical
       BYTE >00,>3E,>00,>3E,>00,>3E,>3E,>00,>3E,>00,>3E,>00    ; 1E Five strips vertical
       BYTE >77,>77,>77,>77,>77,>36,>08,>77,>77,>77,>77,>77    ; 1F Crossroads

       BYTE >FF,>80,>80,>80,>80  ; water
       BYTE >77,>41,>5F,>41,>7D,>04,>10,>5F,>41,>7D,>41,>77   ; 20 Water maze
       BYTE >00,>3E,>22,>2A,>08,>08,>08,>08,>2A,>22,>3E,>00   ; 21 Water shape [-]
       BYTE >10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10   ; 22 Water horizontal strip
       BYTE >00,>3F,>3F,>33,>33,>30,>30,>33,>33,>3F,>3F,>00   ; 23 Water shape T
       BYTE >00,>3E,>22,>22,>22,>22,>22,>22,>22,>22,>3E,>00   ; 24 Water rect
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>7F,>00,>00,>00   ; 25 Water strip vertical
       BYTE >77,>41,>5D,>55,>77,>22,>22,>77,>55,>5D,>41,>77   ; 26 Water shape spider
       BYTE >00,>7F,>37,>30,>30,>30,>30,>30,>30,>3F,>3F,>00   ; 27 Water shape h

       BYTE >FF,>20,>20,>20,>20  ; black
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 28 Black Room

       BYTE >FF,>05,>05,>05,>05  ; light sand
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 29 light sand

       ;

;DUNMAP DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
;
