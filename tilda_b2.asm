;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 2: overworld map, cave, dungeon map
;

       COPY 'tilda.asm'

       
; Load a map into VRAM
; Load map screen from MAPLOC
; R2=0  load screen
; R2=1  Light up darkened room (only call if DARKRM flag is set)
; R2=2  Light up darkened room by candle (only call if DARKRM flag is set), returning to bank 5
; R2=3  Draw ladder and backup chars underneath  R8=ladder pos
; Modifies R0-R12,R15
MAIN
       MOV R11,R12          ; Save return address for later

       DEC R2
       JNE !
       B @LITEUP         ; Light up after moving into new room
!
       DEC R2
       JNE !
       B @LITCDL         ; Light up after using candle
!
       DEC R2
       JNE !
       BL @DRWLAD         ; Draw ladder

       LI R0,BANK0
       MOV R12,R1         ; Restore return address
       B @BANKSW          ; return to bank0
!



       LI R0,SPRTAB+(6*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       LI R0,OBJECT+12      ; Clear objects[6..31]
       LI R1,32-6
!      CLR *R0+
       DEC R1
       JNE -!


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


       CLR  R3
       MOVB @MAPLOC,R3      ; Get MAPLOC as >YX00

       MOV @FLAGS,R0
       ANDI R0,INCAVE
       JEQ !

       CLR  @DOOR            ; Clear door location inside cave

       LI   R0,CLRTAB+15
       LI   R1,>1E00        ; Use gray on black palette for warp stairs
       BL   @VDPWB

       LI   R0,LEVELA+VDPWM  ; R0 is screen table address in VRAM (with write bits)
       LI   R3,CAVE          ; Use cave layout
       JMP  STINIT

!
       MOV @FLAGS,R0
       ANDI R0,DUNLVL     ; Test for dungeon
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

DONE
       LI R0,>000A-(9*256)
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

       LI R1,>7071  ; Red stairs
       LI R2,>7273

       CI R0,>9000  ; Green bush
       JNE !
       LI R1,>7879  ; Green stairs
       LI R2,>7A7B
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
CAVE   EQU WORLD+>800       ; Cave strips 48 bytes
STRIPO EQU WORLD+>830       ; Strip offsets 16 words
STRIPB EQU WORLD+>850       ; Strip base (variable size)
 
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
       BYTE >00,>59,>47,>54,>4E,>1A,>13,>1E,>6D,>00,>00,>00,>69,>15,>00,>46
       BYTE >00,>00,>00,>1A,>44,>00,>00,>47,>00,>00,>00,>00,>47,>49,>00,>46
       BYTE >00,>00,>56,>00,>14,>48,>79,>7B,>2D,>35,>1B,>2B,>00,>6D,>4A,>00
       BYTE >00,>69,>00,>00,>00,>48,>6A,>00,>00,>00,>00,>62,>00,>00,>17,>00
       BYTE >00,>00,>28,>66,>17,>00,>17,>17,>62,>00,>6C,>68,>00,>2A,>00,>13
       BYTE >1B,>15,>00,>00,>48,>12,>16,>14,>64,>59,>00,>19,>16,>16,>00,>00


       
MT00   DATA >A0A1,>A2A3  ; Brown Brick
       DATA >1414,>1414  ; Ground
       DATA >6263,>6263  ; Ladder
       DATA >A4A5,>ABAC  ; Brown top
       DATA >A7AE,>AF07  ; Brown corner SE
       DATA >A506,>ACAD  ; Brown corner NE
       DATA >A8A9,>05A6  ; Brown corner SW
       DATA >7F7F,>2020  ; Black doorway
       DATA >04A4,>AAAB  ; Brown corner NW
       DATA >9C9E,>9D9F  ; Brown rock
       DATA >E6E7,>E5E1  ; Water corner NW
       DATA >E5E0,>E4E1  ; Water edge W
       DATA >E4E0,>E3E2  ; Water corner SW
       DATA >E7E7,>E1E1  ; Water edge N
       DATA >E0E0,>E1E1  ; Water
       DATA >E0E0,>E2E2  ; Water edge S

MT10   DATA >14ED,>1465  ; Water inner corner NE
       DATA >EC14,>6414  ; Water inner corner NW
       DATA >E7E8,>E1E9  ; Water corner NE
       DATA >E0E9,>E1EA  ; Water edge E
       DATA >E0EA,>E2EB  ; Water corner SE
       DATA >14D0,>D2C8  ; Brown Dungeon NW
       DATA >D3C9,>CBCA  ; Brown Dungeon SW
       DATA >C0C1,>C2C3  ; Brown Dungeon two eyes
       DATA >D114,>CCD2  ; Brown Dungeon NE
       DATA >CDD3,>CECB  ; Brown Dungeon SE
       DATA >7071,>7273  ; Red Steps
       DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >D4B0,>D5B0  ; Brown Tree NW
       DATA >14B2,>14B3  ; Brown Tree SW
       DATA >B414,>B514  ; Brown Tree NE
       DATA >B6D6,>B7D7  ; Brown Tree SE

MT20   DATA >D8D9,>DADB  ; Waterfall
       DATA >D8D9,>1717  ; Waterfall bottom
       DATA >B8B9,>BABB  ; Tree face
       DATA >F4F6,>F5F7  ; Gravestone
       DATA >9899,>9A9B  ; Bush
       DATA >6614,>EE14  ; Water inner corner SW
       DATA >1011,>1213  ; Sand
       DATA >1C1C,>1D1D  ; Red Bridge
       DATA >878E,>8F08  ; Grey corner SE
       DATA >0808,>0808  ; Grey Ground
       DATA >F4F6,>F5F7  ; Gravestone  FIXME duplicated?
       DATA >8485,>8B8C  ; Grey top
       DATA >7879,>7A7B  ; Grey stairs
       DATA >F0F1,>F2F3  ; Grey bush
       DATA >1462,>D2C8  ; Green Dungeon NW
       DATA >D3C9,>CBCA  ; Green Dungeon SW

MT30   DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >6314,>CCD2  ; Green Dungeon NE
       DATA >2020,>2020  ; Black square
       DATA >DCDD,>DEDF  ; Armos
       DATA >1467,>14EF  ; Water inner corner SE
       DATA >7475,>7677  ; Brown brick Hidden path
       DATA >E0E9,>E1EA  ; Water edge E

       ; These are for dungeon underground (item room or passage)
       DATA >F7F7,>F7F7  ; Solid black square
       DATA >7272,>7272  ; Gray Brick
       DATA >6767,>6767  ; Ladder
       DATA >F7F7,>2020  ; Passable black square


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
       DATA >9496,>9597  ; Green rock
       DATA >7879,>7A7B  ; Green Steps
       DATA >9091,>9293  ; Green bush
       DATA >7C7C,>7D7D  ; Green Bridge

; palette metatile conversions white/green, same order as MTGREY or MTGREN, above
PALMTW BYTE >01,>02,>04,>05,>06,>08,>24,>1A,>15,>18  ; grey conversions
PALMTG BYTE >00,>03,>04,>05,>06,>08,>09,>1A,>24,>27  ; green conversions
PALMTE


* Flip the current page, the visible page is stored in VDP2 and SCRPTR
* Modifies R0
FLIP   LI   R0,SCRFLG      ; Screen flag mask
       XOR  @FLAGS,R0      ; Get flags into R0 with screen flag toggled
       MOV  R0,@FLAGS      ; Save the updated flags word
       ANDI R0,SCRFLG      ; Mask only the screen flag
       SRL  R0,10          ; Lower 10 bits of screen table are not used
       ORI  R0,>8200       ; VDP Register 2: Screen Table 1
       MOVB @R0LB,*R14      ; Send low byte of VDP register
       MOVB R0,*R14         ; Send high byte of VDP register
       RT

* Draw ladder at R5 in name table
* Saves ladder pos and backup chars to VDP LADPOS
* Modifies R0-R3,R6-R7
DRWLAD
       MOV R5,R0
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
       ANDI R0,>F8F8
       MOV R0,R3
       SRL R3,3
       MOVB R3,R0
       SRL R0,3
       MOV @FLAGS,R3
       ANDI R3,SCRFLG
       A R3,R0

       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       AI R0,32
       MOVB @VDPRD,R6
       MOVB @VDPRD,@R6LB

       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       AI R0,-32+VDPWM
       MOVB @VDPRD,R7
       MOVB @VDPRD,@R7LB

       LI R3,2
       LI R1,>6061      ; Ladder chars
!
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address

       MOVB R1,*R15
       MOVB @R1LB,*R15

       AI R0,32

       DEC R3
       JNE -!

       LI R0,LADPOS     ; save ladder pos and backup chars
       LI R1,R5LB-1     ; copy R5-R7
       LI R2,6
       B @VDPW     ; write and return


; Dark rooms should be darkened before transition and floor should be hidden
; Going from dark to light room should lighten after transition and floor should be shown
; Using candle should lighten, and re-render floor

; if dark flag is set and map bit is dark, render the floor dark, MASK=>8080
; if dark flag is not set or map bit not dark, render the room light MASK=>FFFF

LITEUP
       MOV R11,@OBJPTR     ; Save return address

       ; we already know dark flag is set
       ; light up the room if it's not a darkened room
       MOV @MAPLOC,R3
       SRL R3,8             ; Map location
       MOVB @DUNMAP(R3),R1  ; Screen type
       ANDI R1,>8000
       JNE !               ; stay dark

       LI R4,DARKRM
       SZC R4,@FLAGS       ; Clear DARKRM flag

       ; TODO this is slow - turn off playing sounds
       LI R0,BANK3
       LI R1,MAIN
       LI R2,4            ; Load light tileset and palette
       BL @BANKSW
!
       LI R0,BANK0
       MOV @OBJPTR,R1     ; Restore return address
       B @BANKSW

LITCDL
       ; we already know dark flag is set
       ; light up the room when candle is used

       LI R4,DARKRM
       SZC R4,@FLAGS       ; Clear DARKRM flag

       ; reload floor tiles into LEVELA

       MOVB @MAPLOC,R3      ; Get MAPLOC as >YX00
       SRL R3,8             ; Map location
       MOVB @DUNMAP(R3),R1  ; Screen type
       SRL R1,8
       ANDI R1,>3F

       CLR R4             ; light tile mask (inverted for SZC)
       BL @STDUNG

       ; copy from LEVELA to the active screen

       LI R0,SCHSAV
       BL @PUTSCR

       MOV @FLAGS,R5
       ANDI R5,SCRFLG
       AI R5,(7*32)
       LI R10,LEVELA+(4*32)  ; First metatile location
       LI R4,14       ; number of rows to copy
!      MOV R10,R0
       BL @READ32
       MOV R5,R0
       BL @PUTSCR
       AI R10,32
       AI R5,32
       DEC R4
       JNE -!

       ; Redraw ladder if position is nonzero
       LI R0,LADPOS
       BL @VDPRB
       JEQ !      ; ladder here?
       MOVB @VDPRD,@R1LB
       MOV R1,R5    ; R5 = ladder pos
       BL @DRWLAD
!

       LI R0,SCHSAV
       BL @READ32

       MOV R12,@MOVE12   ; Temporary save return address

       ; TODO this is slow - turn off playing sounds
       LI R0,BANK3
       LI R1,MAIN
       LI R2,4            ; Load light tileset and palette
       BL @BANKSW

       MOV @MOVE12,R1   ; Restore return address
       CLR @MOVE12

       LI R0,BANK5      ; Return to flame function in bank 5
       B @BANKSW





DRKPAL BYTE >14,>14,>1C,>1A,>1C,>1A,>1C,>1E,>1E  ; Levels 1-9


; Note: must preserve R12
; R3 = MAPLOC
GODUNG
       CLR @DOOR          ; TODO should load stair or item location
       CLR R4             ; light tile mask (inverted for SZC)

       LI R0,LADPOS       ; Clear ladder position
       CLR R1
       BL @VDPWB
       MOVB R1,*R15

       SRL R3,8             ; Map location
       MOVB @DUNMAP(R3),R1  ; Screen type
       SRL R1,8

       MOV R1,R0
       ANDI R1,>3F
       ANDI R0,>80         ; Test dark room flag
       JEQ NOTDRK

       LI R4,DARKRM
       CZC @FLAGS,R4
       JNE ALLDRK         ; already dark?

       SOC R4,@FLAGS      ; Set DARKRM flag

       MOV R1,@OBJPTR     ; Save screen type
       MOV R12,@SCRTCH    ; and return address

       LI R0,CLRTAB+11    ; Color table offset char >60
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOV @FLAGS,R1
       SRL R1,12          ; Get dungeon number
       LI R0,>1A00        ; dark ladder
       MOVB R0,*R15
       LI R2,17
!
       MOVB @DRKPAL-1(R1),*R15
       DEC R2
       JNE -!

       ; TODO this is slow - turn off playing sounds
       LI R0,BANK3
       LI R1,MAIN
       LI R2,3            ; Load dark tileset
       BL @BANKSW

       MOV @OBJPTR,R1     ; Restore screen type
       MOV @SCRTCH,R12    ; and return address
ALLDRK

       LI R4,>7F7F        ; dark tile mask (tile will be either >00 or >80)

NOTDRK
       BL @STDUNG
       JMP STDOOR

STDUNG
       LI R10,LEVELA+(4*32)+4+VDPWM  ; First metatile location + write mask

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
       ANDI R0,>0010  ; At middle?
       JNE !
       LI R0,>E8E9    ; right facing statue
       LI R1,>EAEB
       JMP STDUN3
!
       LI R0,>ECED    ; left facing statue
       LI R1,>EEEF
STDUN3
       CI R0,>8181    ; water?
       JEQ !
       SZC R4,R0      ; apply light mask
       SZC R4,R1      ; apply light mask
!
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
       RT

       ; draw doorways or locked doors, bombholes or walls
STDOOR
       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOVB @WALMAP(R1),R0   ; Lookup in DOORS table

       LI R3,>4000     ; Check V door bit
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

       B @DONE   ; Jump to mode

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
       ;JNE !      ; Locked or bombable bit set?   FIXME dungeons unlocked for demo
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
NLOCK  BYTE >D0,>D1,>D2,>D3

WWALL  BYTE >8F,>9D,>9D,>8F,>9D,>9D,>65,>9D,>9D,>8F,>9D,>9D
WBOMB  BYTE >6C,>20,>6D,>20
WDOOR  BYTE >A6,>CA,>C2,>A6,>F7,>7F,>62,>20,>7B,>A6,>CC,>C4
WLOCK  BYTE >D8,>D9,>DA,>DB

EWALL  BYTE >9E,>9E,>8F,>9E,>9E,>8F,>9E,>9E,>65,>9E,>9E,>8F
EBOMB  BYTE >20,>6E,>20,>6F
EDOOR  BYTE >C3,>CB,>A7,>7E,>F7,>A7,>7A,>20,>63,>C5,>CD,>A7
ELOCK  BYTE >DC,>DD,>DE,>DF

SWALL  BYTE >B1,>B1,>B1,>B1,>B1,>B1,>B1,>B1,>89,>64,>64,>89
SBOMB  BYTE >20,>20,>6A,>6B
SDOOR  BYTE >C6,>79,>78,>C7,>CE,>20,>20,>CF,>BC,>61,>61,>BC
SLOCK  BYTE >D4,>D5,>D6,>D7

; W=wall D=door L=locked B=bomb
WW     EQU >00
WD     EQU >10
WB     EQU >20
WL     EQU >30
DW     EQU >40
DD     EQU >50
DB     EQU >60
DL     EQU >70
BW     EQU >80
BD     EQU >90
BB     EQU >A0
BL     EQU >B0
LW     EQU >C0
LD     EQU >D0
LB     EQU >E0
LL     EQU >F0

; Each byte is the south and east wall/doors for that room (north,west are taken from byte above and left)
       BYTE WW ; dummy byte to prevent west-door on next room
WALMAP BYTE DL,BD,DW,DW,WW,WL,LW,WW,WW,LB,DB,DW,DW,WD,DW,WW
       BYTE DB,BB,WD,WW,DW,BW,WB,WW,DD,LD,WD,WW,DW,DW,DB,DW
       BYTE LD,LW,WL,LW,DL,WD,WL,DW,DB,DW,WD,DW,WW,WW,DL,BW
       BYTE DL,WD,WW,DW,WW,LD,WW,DW,DW,WD,WW,LW,DW,DW,DD,BW
       BYTE DW,WD,LD,BL,BD,WW,LD,DW,DW,DD,DL,DL,DB,DW,DD,BW
       BYTE WD,DW,WD,DD,WW,DD,DD,WW,DW,DL,WD,DB,WD,WW,DL,BW
       BYTE WW,DL,WW,LW,WB,WB,DD,BW,DW,WW,WL,DW,WD,DD,DL,WW
       BYTE WD,DW,WD,DD,WW,WW,DD,WW,WL,DD,WW,WD,DW,DD,WW,WW

       BYTE BB,DD,WW,LW,DB,WW,DW,WW,WW,DL,DW,WB,WW,WB,LW,BW
       BYTE DL,WB,WB,WL,WW,DB,LD,WW,BW,DW,LL,LW,DL,BD,DW,BW
       BYTE LW,WB,WD,WW,DW,WB,BW,WW,WW,DB,WL,LB,DW,BL,LB,BW
       BYTE WD,DB,WW,DB,BW,DW,LD,WW,LB,DW,DW,WB,WW,WW,WB,DW
       BYTE LW,DW,WW,WD,WW,DL,DW,WW,LW,DW,DW,BW,DD,BD,DW,DW
       BYTE DD,BD,BW,DW,WD,WD,BL,WW,WD,DW,WW,LW,DB,BB,DW,WW
       BYTE DB,DD,DD,WD,WD,WW,DW,WW,WW,DD,WL,LW,WD,WD,DW,WW
       BYTE WW,DD,WW,WW,WD,WD,DD,WW,WW,WW,WW,WL,WW,WW,DW,WW

       ; items  (4 bits)
       ;  0 nothing
       ;  1 compass
       ;  2 map
       ;  3 tiforce
       ;  4 key
       ;  5 key carried by enemy (also has location for when all enemies are killed)
       ;  6 key (this and following items appear after killing all enemies)
       ;  7 wood boomerang
       ;  8 magic boomerang
       ;  9 rupeesX5
       ;  A bombs
       ;  B heart container
       ;  C push block to open shutters  (always middle leftmost)
       ;  D push block to open stairs  (always middle leftmost)
       ;  E one way shutter (doesn't open)

       ; possible item locations  (4 bits)
       BYTE >00 ; top left corner
       BYTE >0B ; top right corner
       BYTE >16 ; top center
       BYTE >26 ; slight up from center
       BYTE >36 ; center
       BYTE >37 ; slight right of center
       BYTE >3A ; middle right
       BYTE >46 ; slight down from center
       BYTE >68 ; bottom mid-right
       BYTE >6B ; bottom right

       ; possible cave items (descend stairs)  (
       ;  0 no stairs
       ;  1 bow
       ;  2 tunnel (use tunnel pairs lookup table)
       ;  3 raft
       ;  4 ladder
       ;  5 flute
       ;  6 magic rod
       ;  7 red candle
       ;  8 book of magic
       ;  9 magical key
       ;  A red ring
       ;  B silver arrow
       ;

       ; stairs locations, by screen type:
       ;  center: A
       ;  top-right: default
       ;  right: 14
       ;  NE-from-center: 19

       ; 8 bits
       ;  stairs destination (6 bits) doors are to same quadrant
       ;  cave item type
       ;  room item type + room item pos (7 bits)
       ;  condition
LOCMAP
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00

       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00

       ; levels layout
       ; 6 6 6 6   5 5     4 4 4 4 2 2
       ; 6 6 6_6 5 5 5 5 4 4 4 4 4 4 2 2
       ; 6 6 1 1 5 5 5 5 4 4 3 3 4 4 2 2
       ; 6 6 6 1 5 1 1 5 4 4 4 3 4 3 2 2
       ; 6 1 1 1 1 1 5 5 4 3 3 3 3 3 2 2
       ; 6 6 1 1 1 5 5 5 4 3 3 3 3 3 2 2
       ;   6 6 1 5 5 5 5 4 3 4 3 2 2 2 2
       ; 6 6 1 1 1   5 5 4 4 4 3 3 2 2
       
       ; 7 7 7 7 7 7 8     9 9 9 9 9 9 9
       ; 7 7 7 7 7 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7 7 7 8 8 8   9 9 9 9 9 9 9 9
       ; 7 7 7 8 8 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7   8 8 8 8   9 9 9 9 9 9 9 9
       ; 7 7 7 7 8 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7 7 7 7 7 8     9 9 9 9 9 9
       ; 7 7 7   8 8 8 8   9   9 9   9

LVLMAP ; dungeon  map bitmaps
       BYTE >00,>00,>30,>16,>7C,>38,>10,>38  ; level-1
       BYTE >00,>00,>30,>16,>7C,>38,>10,>38  ; level-2


       ; bits 5:0 - room type
       ; bit 6 - dungeon boss roar sound effect?
       ; bit 7 - dark room
DUNMAP BYTE >29,>A6,>90,>0C,>00,>09,>0A,>00,>00,>0F,>0F,>29,>0C,>0C,>02,>00
       BYTE >0E,>29,>0F,>11,>0C,>29,>22,>29,>11,>25,>A2,>05,>0E,>14,>08,>29
       BYTE >21,>A3,>0A,>21,>12,>13,>24,>A1,>08,>A4,>07,>29,>00,>A5,>07,>00
       BYTE >A2,>20,>0F,>20,>04,>0B,>0C,>A0,>0F,>A5,>09,>0F,>A0,>0C,>2A,>00
       BYTE >A1,>29,>09,>06,>04,>08,>A3,>21,>10,>00,>15,>16,>00,>2A,>04,>12
       BYTE >8D,>05,>03,>04,>05,>25,>00,>A0,>12,>07,>00,>00,>06,>03,>06,>05
       BYTE >00,>04,>9C,>03,>0A,>04,>A2,>29,>07,>14,>29,>0D,>00,>05,>08,>03
       BYTE >00,>01,>00,>01,>07,>00,>01,>07,>06,>01,>85,>05,>01,>01,>00,>00

       BYTE >29,>0F,>12,>2A,>18,>16,>00,>00,>00,>A5,>2A,>0A,>0A,>0F,>2A,>0A
       BYTE >A6,>06,>0A,>00,>00,>0D,>00,>0A,>16,>02,>2A,>80,>19,>A4,>0F,>06
       BYTE >29,>0A,>0B,>0C,>0C,>29,>00,>00,>0A,>02,>07,>23,>A0,>1D,>05,>0F
       BYTE >08,>12,>02,>29,>11,>29,>18,>14,>0F,>02,>1B,>80,>24,>2A,>00,>18
       BYTE >29,>22,>00,>98,>19,>02,>00,>00,>26,>80,>9A,>2A,>00,>00,>02,>03
       BYTE >00,>04,>A8,>29,>12,>8D,>12,>A2,>A4,>0D,>14,>18,>1C,>0A,>28,>A4
       BYTE >00,>18,>97,>03,>12,>25,>02,>00,>00,>0A,>2A,>14,>06,>A2,>29,>00
       BYTE >18,>01,>07,>00,>0A,>18,>01,>A6,>00,>14,>00,>06,>0A,>00,>01,>00

       ; Screen type strips of metatiles (12 or more bytes)
       ; column of bits indicating 0=floor or 1=other (block/water/lava/sand)
       ; (1xxx xxxx indicates next byte contains statue bit mask)
ST0    BYTE >FF,>7C,>7C,>7C,>7C  ; dark sand
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00   ; 0 Completely empty
       BYTE >00,>80,>2A,>00,>03,>81,>2A,>07,>07,>81,>2A,>03,>00,>80,>2A,>00  ; 1 Starting room (sand)
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 2 Room full of dark sand

       BYTE >FF,>84,>85,>86,>87  ; block
       BYTE >00,>00,>00,>00,>00,>1C,>1C,>00,>00,>00,>00,>00   ; 3 Six blocks in center
       BYTE >00,>00,>14,>00,>00,>00,>00,>00,>00,>14,>00,>00   ; 4 Four blocks squat rect
       BYTE >00,>00,>22,>00,>00,>00,>00,>00,>00,>22,>00,>00   ; 5 Four blocks rect
       BYTE >00,>22,>22,>00,>00,>08,>08,>00,>00,>22,>22,>00   ; 6 Five sets of two blocks
       BYTE >00,>00,>1C,>1C,>00,>00,>00,>00,>1C,>1C,>00,>00   ; 7 Two sets of six blocks
       BYTE >00,>2A,>00,>2A,>00,>2A,>2A,>00,>2A,>00,>2A,>00   ; 8 Two sets of separated nine blocks
       BYTE >00,>00,>00,>00,>00,>08,>00,>00,>00,>00,>00,>00   ; 9 Single block
       BYTE >00,>00,>00,>00,>08,>14,>22,>14,>08,>00,>00,>00   ; A Diamond blocks
       BYTE >00,>00,>00,>00,>00,>00,>00,>41,>41,>63,>77,>77   ; B Right boss room
       BYTE >00,>3E,>22,>A2,>08,>A2,>10,>20,>20,>A2,>10,>A2,>08,>22,>3E,>00  ; C Tiforce room
       BYTE >01,>22,>44,>08,>10,>20,>02,>04,>08,>11,>22,>40   ; D Angled walls
       BYTE >80,>01,>08,>00,>02,>00,>00,>00,>00,>02,>00,>08,>80,>01  ; E Four blocks, two statues
       BYTE >00,>00,>00,>00,>08,>00,>00,>08,>00,>00,>00,>00   ; F Two blocks near center
       BYTE >00,>08,>14,>00,>00,>00,>00,>00,>00,>14,>08,>00   ; 10 Small <  >
       BYTE >70,>70,>62,>60,>40,>00,>00,>40,>60,>62,>70,>70   ; 11 Top boss room
       BYTE >80,>41,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>80,>41  ; 12 Four statues in corners
       BYTE >00,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>2A,>00   ; 13 Three block strips horizontal
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>63,>77,>77,>77   ; 14 Right stair room
       BYTE >14,>14,>14,>14,>14,>14,>14,>14,>14,>14,>14,>14   ; 15 Two long strips horizontal
       BYTE >00,>22,>22,>22,>22,>22,>22,>22,>22,>22,>3E,>00   ; 16 Wide backward C
       BYTE >00,>00,>3E,>22,>22,>22,>22,>22,>22,>3E,>00,>00   ; 17 Block rect
       BYTE >00,>00,>00,>00,>80,>08,>00,>00,>80,>08,>00,>00,>00,>00 ; 18 Two statues near center
       BYTE >00,>3E,>22,>22,>22,>2A,>2A,>2A,>3A,>02,>7E,>00   ; 19 Spiral with stairs
       BYTE >BE,>41,>7F,>43,>1B,>38,>04,>04,>38,>1B,>43,>7F,>BE,>41  ; 1A Final boss room
       BYTE >7F,>40,>D8,>01,>58,>E0,>04,>40,>40,>E0,>04,>58,>D8,>01,>40,>7F  ; 1B Princess room
       BYTE >00,>7C,>05,>6C,>20,>3E,>00,>23,>20,>3E,>10,>13    ; 1C Block maze
       BYTE >00,>00,>00,>00,>7F,>00,>00,>7F,>00,>00,>00,>00    ; 1D Two long strips vertical
       BYTE >00,>3E,>00,>3E,>00,>3E,>3E,>00,>3E,>00,>3E,>00    ; 1E Five strips vertical
       BYTE >77,>77,>77,>77,>77,>36,>08,>77,>77,>77,>77,>77    ; 1F Crossroads

       BYTE >FF,>81,>81,>81,>81  ; water
       BYTE >77,>41,>5F,>41,>7D,>04,>10,>5F,>41,>7D,>41,>77   ; 20 Water maze
       BYTE >00,>3E,>22,>2A,>08,>08,>08,>08,>2A,>22,>3E,>00   ; 21 Water shape [-]
       BYTE >10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10   ; 22 Water horizontal strip
       BYTE >00,>3F,>3F,>33,>33,>30,>30,>33,>33,>3F,>3F,>00   ; 23 Water shape T
       BYTE >00,>3E,>22,>22,>22,>22,>22,>22,>22,>22,>3E,>00   ; 24 Water rect
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>7F,>00,>00,>00   ; 25 Water strip vertical
       BYTE >77,>41,>5D,>55,>77,>22,>22,>77,>55,>5D,>41,>77   ; 26 Water shape spider
       BYTE >00,>7F,>37,>30,>30,>30,>30,>30,>30,>3F,>3F,>00   ; 27 Water shape h
       BYTE >12,>12,>12,>12,>12,>12,>12,>12,>12,>12,>12,>12   ; 28 Water 2 horizontal strips

       BYTE >FF,>20,>20,>20,>20  ; black
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 29 Black floor

       BYTE >FF,>05,>05,>05,>05  ; light sand
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 2A light sand


* item       condition
* K-key      O-open
* B-bomb     K-kill all enemies
* C-compass  P-push block after killing enemies
* R-rupees   C-carried by enemy
* M-map
* P-push block
* S-stairs
* D-doors
* I-item
* H-heart container
* T-tiforce

* LEVEL-1
*    SP KK    TO
*       KC    HK
* -- DP MO IK KO
*    DK KK CO
*       --
*    KK -- KC

* LEVEL-2
*    TO HK
*      DBK --
*       DK RK
*       KK BO
*      DKK IK
*       -- MO
* KO DK -- CO
*    -- KK

* LEVEL-3
*
*
* DK/KO --
*       DP    TO
* KO BK KK MO HK
* DK CO BK DK DIK
* SO    KK
*       KO --

* LEVEL-4
*
*
* -- MO
* -- DK SP
* KO
* -- KO
*    -- CO
* KK --
