* This is in bank 2

* Useful functions in this file
* LOADSC - load a map into VRAM, called from bank 0
* LOADDC - load dungeon cave
* LOADOC - load overworld cave
* LITEUP - light up after moving into a not-dark room, called from bank 0
* LITCDL - light up a room by candle, called from bank 5
* DNBOMB - bomb exploded at R5, Called from bank 5
* SHUTR2 - get shutter mask R2 = NSWE bits, called from bank0
* SHUTTR - Draw shuttered doors, called from from bank 0
* UNLOKD - unlock door at facing R3, call from bank 0
* CLRSCN - clear screen before drawing tiles, called from bank 0
* DRWLAD - draw ladder at R8, called from bank 0


* Load a map into VRAM
* Load map screen from MAPLOC, taking into account DUNLVL and INCAVE flags
* Modifies R?    TODO
LOADSC
       MOV R11,@TEMPRT     ; Save return address

       LI R0,SWRDST
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       LI R0,OBJECT+12      ; Clear objects[6..31]
       LI R1,32-6
!      CLR *R0+
       DEC R1
       JNE -!

       ; TODO will this work in dark rooms
       LI R0,>0300+(CLRTAB/>40) ; VDP Register 3: Color Table
       BL @VDPREG
       LI R0,>07F1          ; VDP Register 7: White on Black
       BL @VDPREG



       ; Copy the top 3 rows from the current screen to the flipped screen
       LI   R6,VDPRD        ; Keep VDPRD address in R6
       LI   R10,SCRFLG+VDPWM
       MOV  @FLAGS,R0
       ANDI R0,SCRFLG
       LI   R9,3            ; Process 3 lines
!      BL   @!READ32         ; Read a line from current
       XOR  R10,R0
       BL   @!PUTSCR         ; Write a line to flipped
       XOR  R10,R0
       AI   R0,32
       DEC  R9
       JNE -!


       CLR  R3
       MOVB @MAPLOC,R3      ; Get MAPLOC as >YX00

       MOV @FLAGS,R0
       ANDI R0,DUNLVL+INCAVE
       JEQ OVERW     ; not dungeon or cave

       ; in a cave or dungeon

       CLR  @DOOR            ; Clear door location inside cave

       ANDI R0,INCAVE
       JNE !
       B @DODUNG          ; Dungeon
!

       LI   R0,CLRTAB+15
       LI   R1,>1E00        ; Use gray on black palette for warp stairs
       BL   @VDPWB

       LI   R3,CAVE          ; Use cave layout
       MOV @FLAGS,R0
       ANDI R0,DUNLVL     ; Test for dungeon
       JEQ !

       ;LI   R3,DTUNNL  ;CAVE      ; TODO (or DTUNNL)
       ; get dungeon cave type R3=DCAVE or DTUNNL
       ; and position hero at left or right side
       BL   @GETDNC

       LI   R0,CLRTAB+12
       LI   R1,>EF00        ; Use gray on white palette for dungeon steps
       BL   @VDPWB
       LI   R0,CLRTAB+16
       LI   R1,>1E00        ; Use gray on black palette for dungeon brick
       BL   @VDPWB

!
       LI   R0,LEVELA+VDPWM  ; R0 is screen table address in VRAM (with write bits)
       JMP  STINIT

OVERW  ; overworld (not a dungeon or a cave)


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

       INC R1               ; Scan until start bit (>80) is found
!      MOVB *R9+,R8         ; Get code
       A   R8,R8            ; Get upper bit in carry status
       JNC -!               ; No start bit
       DEC R1               ; Found start bit
       JNE -!               ; Count down until we hit the right one

       LI   R6,11           ; Metatile counter (11 per strip)
       DEC  R9              ; Back up strip pointer
       CLR  R0             ; Clear double bit
MTLOOP
       MOV R0,R8
       ANDI R0,>4000       ; Mask only double bit
       SLA  R0,2
       JOC !

       MOVB *R9+,R8         ; R8 is metatile index
       MOV  R8,R0           ; Save bits for later
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


       LI R0,>000A-(9*256)
       MOVB @MAPLOC,R1      ; Mapdot Y = MAPDOT[(MAPLOC & 0x7000) >> 12]
       ANDI R1,>7000
       SRL R1,4
       A R1,R0
       A R1,R0
       A R1,R0
       AI R0,->0100

       MOVB @MAPLOC,R1      ; Mapdot X = ((MAPLOC & 0x0F00) >> 6) + 16
       ANDI R1,>0F00
       SLA  R1,2
       AI   R1,>0A00

MPDONE
       LI R2,MPDTST+VDPWM   ; Set VDP address to map dot in sprite list
       MOVB @R2LB,*R14
       MOVB R2,*R14
       MOVB R0,*R15     ; Store Y
       MOVB R1,*R15     ; Store X

       ;LI R13,LENEMY  ; Load enemies in bank 1 (return address is in TEMPRT)
       ;B @BANK1
       MOV  @TEMPRT,R13
       B    @BANK0            ; Return to saved address


* Open secret cave if bit set
* Modifies R0-R3
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
       CLR R0          ; delay slot
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
TESTS2 RT


* Copy scratchpad to the screen at R0
* Modifies R0,R1,R2
!PUTSCR
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


* Restore 32B scratchpad from VDP
!SCHRST
       LI R0,SCHSAV
       ; fall thru

; Copy screen at R0 into scratchpad 32 bytes
* Modifies R1,R2,R12
!READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH        ; Dest pointer to scratchpad ram
       LI R2,8             ; Read 32 bytes to scratchpad
       LI R12,VDPRD        ; Keep VDPRD address in R6
!      MOVB *R12,*R1+
!READ3 MOVB *R12,*R1+
       MOVB *R12,*R1+
       MOVB *R12,*R1+
       DEC R2
       JNE -!
       RT

*       ; Copy screen at R0 into R1 31 bytes
*       ; Modifies R1,R2
*!READ31
*       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
*       MOVB R0,*R14         ; Send high byte of VDP RAM read address
*       LI R2,8             ; Read 31 bytes to scratchpad
*       JMP -!READ3           ; Use loop in READ32 minus 1




* Overworld map consists of 16x8 screens, each screen is 16 bytes
* Each byte is into an index into an array of strips 11 metatiles tall
* Each screen is 16x11 metatiles
* Each screen should have a palette to switch between green/white brick, or brown/green trees/faces

WORLD  BCOPY "data/overworld.bin" ; World strip indexes 16*8*16 bytes
WORLDE
CAVE   EQU WORLD+>800       ; Cave strips 16 bytes
DCAVE  EQU WORLD+>810       ; Dungeon cave strips 16 bytes
DTUNNL EQU WORLD+>820       ; Dungeon tunnel strips 16 bytes
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
       DATA >D8D9,>DADB  ; Waterfall bottom
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
       DATA >8383,>8383  ; Gray Brick
       DATA >6363,>6363  ; Ladder (must be same num as overworld stairs)
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


       ; Dark rooms must be darkened before transition and floor should be hidden
       ; Going from dark to light room must lighten after transition and floor should be shown
       ; Using candle must lighten, and re-render floor

       ; if dark flag is set and map bit is dark, render the floor dark, MASK=>8080
       ; if dark flag is not set or map bit not dark, render the room light MASK=>FFFF

* Modifies R0..R10,R13
LITEUP
       MOV R11,R13    ; save return address for later

       ; we already know dark flag is set
       ; light up the room if it's not a darkened room
       MOVB @MAPLOC,R3
       SRL R3,8             ; Map location
       MOVB @DUNMAP(R3),R1  ; Screen type
       SLA R1,1      ;ANDI R1,>8000
       JOC !               ; stay dark

;LITCAV ; light up cave called from bank0
       ;MOV R11,R12     ; Save return address from bank0
       LI R4,DARKRM
       SZC R4,@FLAGS       ; Clear DARKRM flag

       ; TODO this is slow - turn off playing sounds
       ;BL @BANK3X          ; tiles.asm
       ;DATA x#LITPAT       ; Load light tileset and palette (Modifies R0..R10,R13)
       ;MOV R12,R13     ; Restore return address
       LI R13,x#LIGHTN     ; Lighten
!
       B @BANK0




* Modifies R0..R10,R12,R13
LITCDL
       MOV R11,R6        ; save return address from bank5

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
       BL @STDUNG         ; draw dungeon strips

       ; copy from LEVELA to the active screen

       LI R0,SCHSAV
       BL @-!PUTSCR

       MOV @FLAGS,R5
       ANDI R5,SCRFLG
       AI R5,(7*32)
       LI R10,LEVELA+(4*32)  ; First metatile location
       LI R4,14       ; number of rows to copy
!      MOV R10,R0
       BL @-!READ32
       MOV R5,R0
       BL @-!PUTSCR
       AI R10,32
       AI R5,32
       DEC R4
       JNE -!

       ; Redraw ladder if position is nonzero
       LI R0,LADPOS
       BL @VDPRB
       JEQ !      ; ladder here?
       MOVB @VDPRD,@R1LB
       MOV R1,R8    ; R8 = ladder pos
       BL @DRWLA0
!

       BL @-!SCHRST   ; Restore 32B scratchpad from VDP

       ; go through bank0, and returns to bank5
       LI R13,x#LITUP5  ; don't forget to return to R6
       B @BANK0



; Note: must preserve R13
; R3 = MAPLOC
* Modifies R0..R10,R12,R13, OBJPTR
DODUNG
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
       ;MOV R13,R12       ; and return address

       BL @BANK0X       ; hero.asm
       DATA x#DARKN2    ; Get darker

       ; TODO this is slow - turn off playing sounds
       ;BL @BANK3X
       ;DATA x#DRKPAT     ; Load dark tileset (Modifies R0..R10,R13)

       MOV @OBJPTR,R1     ; Restore screen type
       ;MOV R12,R13    ; and return address
ALLDRK ; already dark

       LI R4,>7F7F        ; dark tile mask (tile will be either >00 or >80)

NOTDRK
       BL @STDUNG
       JMP STDOOR

* Modifies R0..R5,R7..R10
STDUNG  ; draw dungeon strips
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
       MOVB @WALMAP(R1),R7   ; Lookup in DOORS table


;       MOVB @DUNMAP(R1),R3
;       ANDI R3,>4000     ; Test stair bit
;       JEQ !
;       BL @DSTAIR      ; Draw stairs if stair bit is set
;!
       BL @SPWNST       ; Spawn stairs if one exists here

       LI R3,>4000     ; Check V door bit
       LI R5,4
       LI R10,LEVELA+(18*32)+14+VDPWM
       LI R9,LEVELA+(18*32)+15+VDPWM
       LI R8,SWALL
       BL @DVDOOR      ; Draw south door or wall

       SRL R3,2        ; Check H door bit
       CLR R5
       LI R10,LEVELA+(9*32)+28+VDPWM
       LI R9,LEVELA+(10*32)+28+VDPWM
       LI R8,EWALL
       BL @DHDOOR      ; Draw east door or wall

       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOVB @WALMAP-1(R1),R7   ; Lookup in DOORS table

       LI R5,2
       LI R10,LEVELA+(9*32)+1+VDPWM
       LI R9,LEVELA+(10*32)+2+VDPWM
       LI R8,WWALL
       BL @DHDOOR      ; Draw west door or wall

       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOV R1,R7
       ANDI R7,>0070    ; R7=0 when Y=0 or 8
       JEQ !
       MOVB @WALMAP-16(R1),R7   ; Lookup in DOORS table
!
       SLA R3,2        ; Check V door bit
       LI R5,6
       LI R10,LEVELA+(1*32)+14+VDPWM
       LI R9,LEVELA+(2*32)+15+VDPWM
       LI R8,NWALL
       BL @DVDOOR      ; Draw north door or wall
       BL @MMDRAW      ; Draw mini map
       ; note R0=mapdot Y R1=mapdot X
       B @MPDONE   ; Jump to draw mapdot

* Modifies R0-R8
MM_GET ; called from bank 5 when map item is acquired
       MOV R11,R13      ; save return address in bank 5
       BL @MMDRAW
       B @BANK5     ; return to saved address

* Modifies R0-R8
MMDRAW ; Draw dungeon mini-map on status bar
       MOV  @FLAGS,R7
       ANDI R7,DUNLVL    ; Get dungeon level
       SRL  R7,12        ; R7 = level
       MOVB @MAPLOC,R0   ; R0 = YX__
       MOV R0,R1
       ANDI R0,>7000     ; R0 = Y___
       ANDI R1,>0F00     ; R1 = _X__
       SRL R0,2          ; Y multiple of 4
       SLA R1,3          ; X multiple of 8

       AB  @MMXADJ(R7),R1 ; Adjust X based on table
       SLA  R7,3         ; R7 = level * 8

       CI   R7,1*8    ; level 1 doesn't scroll minimap
       JEQ !
       CI   R7,3*8    ; level 3 doesn't scroll minimap
       JEQ !
       CI   R0,>0C00  ; need to scroll minimap up?
       JLE !!
!      INCT R7        ; Map is always adjusted down
       AI R0,->800    ; Move map dot Y up
!
       ; if minimap hasn't been collected, use blank map
       MOV @HFLAG2,R3
       SLA R3,1
       JOC !         ; minimap collected?
       CLR R7        ; clear level number
!
       AI   R7,MINIMP
       LI   R3,SCR1TB+2+VDPWM
       LI   R4,3   ; Draw 3 rows into screen table
MMYLP
       LI   R2,8   ; Draw 8 characters per row
       MOV *R7+,R5  ; Get bitmap for this row
       MOV  R5,R6
       SWPB R6
       MOVB @R3LB,*R14
       MOVB R3,*R14
MMXLP   ; X-loop
       LI   R8,>F000  ; both on
       SLA R5,1       ; get bit in carry
       JOC !
       AI  R8,>0100
!      SLA R6,1
       JOC !
       AI  R8,>0200
!      CI R8,>F300
       JNE !
       LI R8,>2000      ; space char
!      MOVB R8,*R15     ; store char

       DEC  R2
       JNE MMXLP
       AI   R3,32         ; next row
       DEC  R4
       JNE MMYLP

       ; Set R0=mapdot Y R1=mapdot X
       AI R0,->0A00   ; adjust Y as needed
       RT

       ; levels layout
       ; 6 6 6 6   5 5     4 4 4 4 2 2
       ; 6 6 6 6 5 5 5 5 4 4 4 4 4 4 2 2
       ; 6 6 1 1 5 5 5 5 4 4 3 3 4 4 2 2
       ; 6 6 6 1 5 1 1 5 4 4 4 3 4 3 2 2
       ; 6 1 1 1 1 1 5 5 4 3 3 3 3 3 2 2
       ; 6 6 1 1 1 5 5 5 4 3 3 3 3 3 2 2
       ;   6 6 1 5 5 5 5 4 3 4 3 2 2 2 2
       ; 6 6 1 1 1   5 5 4 4 4 3 3 2 2

       ; 7 7 7 7 7 7 8     9 9 9 9 9 9
       ; 7 7 7 7 7 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7 7 7 8 8 8   9 9 9 9 9 9 9 9
       ; 7 7 7 8 8 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7   8 8 8 8   9 9 9 9 9 9 9 9
       ; 7 7 7 7 8 8 8 8 9 9 9 9 9 9 9 9
       ; 7 7 7 7 7 7 8     9 9 9 9 9 9
       ; 7 7 7   8 8 8 8   9   9 9   9

MINIMP ; minimap bitmaps
       DATA >0000,>0000,>0000,>0000  ; no map
       DATA >0000,>3016,>7C38,>1038  ; LEVEL-1 eagle
       DATA >180C,>0C0C,>0C0C,>3C18  ; LEVEL-2 moon
       DATA >0000,>3014,>7C7C,>5018  ; LEVEL-3 manji
       DATA >3C2C,>3030,>2030,>1830  ; LEVEL-4 snake
       DATA >1828,>3C24,>0C1C,>3C0C  ; LEVEL-5 lizard
       DATA >3C7E,>6674,>4040,>5070  ; LEVEL-6 dragon
       DATA >3E6C,>7870,>6078,>7E70  ; LEVEL-7 demon
       DATA >081C,>087C,>783C,>083C  ; LEVEL-8 lion
       DATA >7EFF,>FFDB,>FFFF,>7E5A  ; LEVEL-9 death mountain
MMXADJ ; minimap X-adjust per dungeon
       BYTE >00,>0C,->44,->34,>1C,->04,->2C,>14,->04,->34
       EVEN

DVDOOR  ; Draw vertical door
       LI R4,3
       CZC R3,R7
       JEQ !       ; draw wall
       AI R8,16    ; draw door instead

!      MOVB @R10LB,*R14
       MOVB R10,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       AI R10,32
       DEC R4
       JNE -!
       JMP LOKBOM

DHDOOR  ; Draw horizontal door
       LI R4,4
       CZC R3,R7
       JEQ !       ; draw wall
       AI R8,16    ; draw door instead

!      MOVB @R10LB,*R14
       MOVB R10,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       AI R10,32
       DEC R4
       JNE -!

LOKBOM ; Draw locked door or bomb hole
       SLA R3,1
       CZC R3,R7
       JNE !      ; Locked or bombable bit set?
       SRL R3,1
       RT
!
       SRL R3,1

       ; get opened bit
       MOV R11,R10     ; Save return address
       MOV @LOKOFS(R5),R0
       AB @MAPLOC,R0
       SRL R0,7
       LI R1,SDOPEN
       BL @GETBIT
       JOC !!           ; opened
       ; not open
       MOV R10,R11     ; Restore return address

       CZC R3,R7
       JNE DRAWCH      ; Draw locked door
!      RT

!      ; opened
       MOV R10,R11     ; Restore return address

       CZC R3,R7
       JNE -!!      ; don't draw locked door

DRAWCH ; draw 2x2 block characters pointed by R8 to VDP at R9 (with VDPWM)
       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       AI R9,32
       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       RT

* Modifies R0-R3
SHUTR2 ; get shutter mask R2 = EWSN bits
       MOV R11,R13      ; save return address from bank 0
       BL @SHTMSK ; get shutter mask
       B @BANK0    ; return to bank0

* Modifies R0-R3, R8-R9
SHUTTR ; Draw shuttered doors
       MOV R11,R13      ; save return address from bank 0
       BL @SHTMSK ; get shutter mask
       JEQ !!!!
       ; R2 = NSWE bits
       ; R3 = door offsets pointer
       ; R0 = screen offset
       LI R1,SHUTCH
       JMP !!!
!
       ; draw shutters
       MOV R0,R9
       A *R3,R9   ; doorway offset
       MOV R1,R8  ; block pointer
       BL @DRAWCH

!      INCT R3
       AI R1,4

!      SLA R2,1
       JOC -!!!
       JNE -!!

       LI R0,x#TSF282    ; Door open sound
       MOV R0,@SOUND3
       LI R0,x#TSF283    ; Door open sound
       MOV R0,@SOUND4
!
       B @BANK0    ; return to bank0

OPENSH
       MOV R11,R4     ; save return address
       BL @SHTMSK ; get shutter mask
       ; R2 = EWSN bits
       ; R3 = door offsets pointer (offsets include VDPWM)
       ; R0 = screen offset
       LI R1,EDORWY
       JMP !!!
!
       ; draw doorways
       MOV R0,R9
       A *R3,R9   ; doorway offset
       MOV R1,R8  ; block pointer
       BL @DRAWCH

!      INCT R3
       AI R1,4

!      SLA R2,1
       JOC -!!!
       JNE -!!
       B *R4   ; return to saved address

* Modifies R0-R3, R8-R9
OPENER ; Open shuttered doors (called from bank0 AUTOM2)
       MOV R11,R13     ; save return address

       ; don't open yet if push block
       BL @DUNITM     ; R4=item,location,0,0
       CI R4,>E000    ; push block item
       JEQ !

       BL @OPENSH ; open shutters
!
       B @BANK0



       ; stairs locations, by screen type:
       ;  center: A
       ;  top-right: default
       ;  right: 14
       ;  NE-from-center: 19

;DSTAIR ; Draw stairs (need to preserve R0)
;       MOVB @MAPLOC,R1   ; Get dungeon map location
;       SRL R1,8
;       MOVB @DUNMAP(R1),R1   ; Lookup in dungeon map table
;       ANDI R1,>3F00
;       LI R9,(7*32)+4+(11*2)   ; Top right corner
;       CI R1,>0A00
;       JNE !
;       LI R9,(13*32)+4+(6*2)   ; Center
;       JMP !!!!
;!      CI R1,>1400
;       JNE !
;       LI R9,(13*32)+4+(11*2)   ; Right
;!      CI R1,>1900
;       JNE !
;       LI R9,(11*32)+4+(7*2)   ; NE-from-center
;!
;       ; TODO non-center stairs will only appear after block push
;!
;       ; convert character coordinate to pixel coordinate YYY YYYXXXXX -> YYYYY000 XXXXX000
;       MOV R9,R1
;       SLA R1,3
;       MOVB @R9LB,@R1LB
;       SLA R1,3
;       ANDI R1,>F8F8
;       MOV R1,@DOOR
;
;       LI R8,DSTACH
;       AI R9,LEVELA-(3*32)+VDPWM
;       JMP DRAWCH     ; tail call


* Called from bank 5
* R5=bomb position
* Modifies R0-3,R8,R9
DNBOMB
       MOV R11,R13     ; save return address for bank 5

       ; TODO check for bombable walls
       MOVB @MAPLOC,R3
       SRL R3,8
       MOVB @WALMAP(R3),R2
       LI R1,4  ; south door
       BL @DORBOM

       MOVB @WALMAP(R3),R2
       SLA R2,2 ; east door
       CLR R1  ; east door
       BL @DORBOM

       MOV R3,R0
       ANDI R0,>0070
       JEQ !      ; skip top rows
       MOVB @WALMAP-16(R3),R2
       LI R1,6  ; north door
       BL @DORBOM
!
       MOVB @WALMAP-1(R3),R2
       SLA R2,2
       LI R1,2  ; west door
       BL @DORBOM

       B @BANK5

DORBOM ; check door in facing R1 against R5
       ANDI R2,>C000  ; mask room type bit
       CI R2,>8000   ; bomb bit pattern is 10
       JEQ !!    ; door is not bombable
!      RT
!
       MOV @BOMPOS(R1),R0
       S R5,R0
       ABS R0
       CI R0,>1800
       JH -!!
       SWPB R0
       ABS R0
       CI R0,>1800
       JH -!!

       MOV R1,R8
       SLA R8,4  ; multiply by 16
       AI R8,EBOMB

       MOV @DORPOS(R1),R9
       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15
       AI R9,32
       MOVB @R9LB,*R14
       MOVB R9,*R14
       MOVB *R8+,*R15
       MOVB *R8+,*R15

       ; set unlocked/bombed bit
       MOV @LOKOFS(R1),R0
       AB @MAPLOC,R0
       SRL R0,7
       LI R1,SDOPEN
       JMP SETBIT ; return thru SETBIT


UNLOKD ; unlock door at facing R3
       MOV R11,R13      ; save return address from bank 0
       ; unlock door at facing R3
       MOV R3,R8
       SRL R8,7
       MOV @DORPOS(R8),R9
       SLA R8,1
       AI R8,EDORWY
       BL @DRAWCH

       ; set unlocked/bombed bit
       MOV R3,R1
       SRL R1,7
       MOV @LOKOFS(R1),R0
       AB @MAPLOC,R0
       SRL R0,7
       LI R1,SDOPEN
       BL @SETBIT

       B @BANK0

LOKOFS ; Locked door / bombable wall bit offsets, same order as DIR_XX, 2 bits per room
       DATA >0080,>FF80,>0000,>F000   ; E, W, S, N

BOMPOS ; sprite positions of bombable walls
       DATA >68E0,>6810,>A878,>2878  ; E, W, S, N


* Get bit R0 in VDP at address R1, returns bit in C
* modifies R0-R2
GETBIT
       MOV R0,R2
       ANDI R0,7  ; R0 = lower 3 bits
       SRL R2,3
       A R2,R1    ; R1 = adjusted VDP address
       MOVB @R1LB,*R14
       MOVB R1,*R14
       INC R0       ; delaying instruction before read
       MOVB @VDPRD,R1
       SLA R1,R0   ; shift the bit into carry
       RT

* Set bit R0 in VDP at address R1
* modifies R0-R2
SETBIT
       MOV R0,R2
       SRL R2,3
       A R2,R1    ; R1 = adjusted VDP address
       LI R2,>8000
       ANDI R0,7  ; R0 = lower 3 bits
       JEQ !       ; can't shift by zero
       SRL R2,R0   ; shift the bit
!      MOVB @R1LB,*R14
       MOVB R1,*R14
       ORI R1,VDPWM    ; delaying instruction before read
       SOCB @VDPRD,R2  ; R2 = OR'd bits
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15   ; write it back
       RT

* Get shutter bit mask
* Returns R2=EWSN flags   R3=DORPOS  R0=screen offset
* Modifies R0-R3
SHTMSK
       MOVB @MAPLOC,R1   ; Get dungeon map location
       SRL R1,8
       MOVB @WALMAP(R1),R0   ; Lookup in DOORS table
       MOV R0,R2
       ANDI R0,>0F00  ; R0 = xxxx EWSN
       SLA R2,2       ; C = S wall
       JNC !
       ORI R0,>2000   ; R0 = xxSx EWSN
!      SLA R2,2       ; C = E wall
       JNC !
       ORI R0,>8000   ; R0 = ExSx EWSN
!

       MOVB @WALMAP-1(R1),R2   ; get west wall
       ANDI R2,>1000
       SLA R2,2
       SOC R2,R0      ; R0 = EWSx EWSN

       MOVB @WALMAP-16(R1),R2   ; get north wall
       ANDI R2,>4000
       SRL R2,2
       SOC R0,R2     ; R2 = EWSN EWSN (doors, shutters)
       SLA R0,4      ; R0 = EWSN (shutters)

       SZC R0,R2     ; R2 = EWSN EWSN (door AND shutters, shutters)

       MOV @FLAGS,R0
       ANDI R0,SCRFLG  ; get screen offset
       LI R3,DORPOS
       ANDI R2,>F000
       RT


DSTACH DATA >7475,>7677 ; dungeon stair chars
SHUTCH DATA >E4E5,>E6E7 ; horizontal shutters
       DATA >E4E5,>E6E7 ; horizontal shutters
       DATA >E0E1,>E2E3 ; vertical shutters
       DATA >E0E1,>E2E3 ; vertical shutters

       ; same order as DIR_XX
EDORWY DATA >7E20,>7A20 ; east doorway
WDORWY DATA >207F,>207B ; west doorway
SDORWY DATA >7978,>2020 ; south doorway
NDORWY DATA >2020,>7B7A ; north doorway

       ; same order as DIR_XX
DORPOS DATA (13*32)+28+VDPWM ; east doorway location (on visible screen)
       DATA (13*32)+2+VDPWM  ; west
       DATA (21*32)+15+VDPWM ; south
       DATA (5*32)+15+VDPWM  ; north


EWALL  BYTE >9E,>9E,>8F,>9E,>9E,>8F,>9E,>9E,>8F,>9E,>9E,>8F
EBOMB  BYTE >F7,>6E,>20,>6F
EDOOR  BYTE >C3,>CB,>A7,>7E,>20,>A7,>7A,>20,>A7,>C5,>CD,>A7
ELOCK  BYTE >DC,>DD,>DE,>DF

WWALL  BYTE >8F,>9D,>9D,>8F,>9D,>9D,>8F,>9D,>9D,>8F,>9D,>9D
WBOMB  BYTE >6C,>F7,>6D,>20
WDOOR  BYTE >A6,>CA,>C2,>A6,>20,>7F,>A6,>20,>7B,>A6,>CC,>C4
WLOCK  BYTE >D8,>D9,>DA,>DB

SWALL  BYTE >B1,>B1,>B1,>B1,>B1,>B1,>B1,>B1,>89,>89,>89,>89
SBOMB  BYTE >20,>20,>6A,>6B
SDOOR  BYTE >C6,>79,>78,>C7,>CE,>20,>20,>CF,>BC,>BC,>BC,>BC
SLOCK  BYTE >D4,>D5,>D6,>D7

NWALL  BYTE >89,>89,>89,>89,>96,>96,>96,>96,>96,>96,>96,>96
NBOMB  BYTE >68,>69,>20,>20
NDOOR  BYTE >94,>94,>94,>94,>C8,>20,>20,>C9,>C0,>7B,>7A,>C1
NLOCK  BYTE >D0,>D1,>D2,>D3



       ; W=wall D=door L=locked B=bomb  pair:(south,east) or (north,west)
WW     EQU >0F
WD     EQU >1F
WB     EQU >2F
WL     EQU >3F
DW     EQU >4F
DD     EQU >5F
DB     EQU >6F
DL     EQU >7F
BW     EQU >8F
BD     EQU >9F
BB     EQU >AF
BL     EQU >BF
LW     EQU >CF
LD     EQU >DF
LB     EQU >EF
LL     EQU >FF

N_BIT  EQU >01
S_BIT  EQU >02
W_BIT  EQU >04
E_BIT  EQU >08

WW5    EQU WW-N_BIT-W_BIT  ; NW shutters
WW7    EQU WW-N_BIT  ; N shutter
WWD    EQU WW-W_BIT  ; W shutter
WD6    EQU WD-N_BIT-E_BIT  ; NE shutters
WD7    EQU WD-N_BIT  ; N shutter
WDE    EQU WD-E_BIT  ; E shutter
WDD    EQU WD-W_BIT  ; W shutter
WB7    EQU WB-N_BIT

DW3    EQU DW-N_BIT-S_BIT  ; NS shutters
DW5    EQU DW-N_BIT-W_BIT  ; NW shutters
DW7    EQU DW-N_BIT  ; N shutter
DWB    EQU DW-S_BIT  ; S shutter
DWD    EQU DW-W_BIT  ; W shutter
DD7    EQU DD-N_BIT
DDA    EQU DD-S_BIT-E_BIT
DDB    EQU DD-S_BIT
DDD    EQU DD-W_BIT  ; S shutter
DDE    EQU DD-E_BIT  ; E shutter
DB3    EQU DB-N_BIT-S_BIT  ; NS shutters
DBB    EQU DB-S_BIT  ; S shutter
DL7    EQU DL-N_BIT
DLB    EQU DL-S_BIT

BW7    EQU BW-N_BIT
BDE    EQU BD-E_BIT
BL5    EQU BL-N_BIT-W_BIT
LW7    EQU LW-N_BIT
LD6    EQU LD-N_BIT-E_BIT  ; NE shutter
LDD    EQU LD-W_BIT  ; W shutter
LDE    EQU LD-E_BIT  ; E shutter
LL7    EQU LL-N_BIT



       ; Each byte is the south and east wall/doors for that room (north,west are taken from byte above and left)
       ; and lower nibble is shutter indicators: N S W E
       BYTE WW ; dummy byte to prevent west-door on next room
WALMAP BYTE DL, BD, DW, DW, WW, WL, LW, WW, WW, LB, DBB,DW, DW, WD, DWD,WW
       BYTE DB3,BB, WDE,WW5,DW, BW, WB, WW, DDA,LD, WD, WW7,DW7,DW, DB3,DW
       BYTE LD, LW, WL, LW, DL7,WD, WL, DW, DBB,DW, WDE,DW, DD, WW, DL7,BW
       BYTE DL, WDE,WW, DW, WW7,LDE,WW, DW, DW3,WD6,WW, LW7,WW7,DW, DD, BW
       BYTE DW, WD, LDD,BL, BD, WW, LD, DW, DW, DD, DL, DL, DB, DW3,DDB,BW
       BYTE WD, DW, WDE,DD, WW, DDE,DDD,WW, DW7,DLB,WD, DB, WDE,WW5,DL, BW
       BYTE WW, DL, WW, LW, WB, WB7,DD7,BW, DW, WW, LW, DW, WD, DDD,DL, WW
       BYTE WD, DW, WD, DD, WW, WW, DD, WW, WL, DD, WW, WD, DW, DD, WW, WW

       BYTE BB, DDA,WWD,LW, DB, WW, DWB,WW, WW, DLB,DW, WB, WW, WB, LW, BW
       BYTE DL, WB7,WB, WL, WW, DB, LD6,WW, BW, DWB,LL7,LW, DL, BD, DW, BW
       BYTE LW, WB, WDE,WW, DW, WB, BW, WW, WW, DBB,WL, LB, DW, BL, LB, BW
       BYTE WDE,DB, WW, DB, BW7,DW, LDE,WWD,LB, DWB,DWB,WB, WW, WW, WB, DW
       BYTE LW, DW7,WW, WDE,WWD,DL7,DW, WW, LW, DWB,DW3,BW, DD, BD, DW, DW
       BYTE DD, BDE,BW, DW, WD, WD, BL5,WW, WDE,DWD,WW7,LW, DB, BB, DW, WW
       BYTE DB, DD, DD, WD7,WD, WW, DW, WW, WW, DD, WL, LW, WD, WD, DW5,WW
       BYTE WW, DD, WW, WW, WD, WDD,DD, WW, WW, WW, WW, WL, WW, WW, DW, WW

       EVEN

       ; possible stairs/cave items  (4 bits)
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

       ; item types  (4 bits)


DNINIT ; load initial dungeon item (called from bank 0)
       MOV R11,R13     ; save return address for bank 5 (FIXME ?)

       BL @DUNITM
       JEQ !!

       LI R0,ECOUNT
       BL @VDPRB
       JEQ !    ; Zero enemies - spawn item no matter what

       CI R4,>8000
       JHE !!       ; only items that are less than this can spawn early
!
       BL @SPWNIT
!
       BL @DUNITM
       SRL R4,12   ; R4=item type
       MOVB @ITMSPR(R4),R2
       JEQ !
       SRL R2,8
       MOV R13,R11 ; restore saved return address from bank 0
       LI R13,x#LDITEM
       B @BANK1    ; will return to bank 0
!
       B @BANK0    ; return to saved address in bank 0


DNITEM ; load dungeon item when enemies become zero (called from bank 5)
       MOV R11,R13     ; save return address for bank 5

       ; TODO loading item when entering room?
       ; TODO loading item when enemies gone?
       ; TODO check flag to see if item already collected
       ; TODO enable pushable block

       BL @DUNITM  ; R4=item,location,x,x

       CI R4,>7000
       JL !         ; item already spawned in DNINIT


       BL @SPWNIT
       ; TODO open shutters
       ; TODO spawn dungeon item
!
DNITRT
       B @BANK5   ; return to saved address in bank 5

* Modifies R0-R4,R10
SPWNIT ; spawn item   R4 = item type from ITEMAP
       MOV R11,R10    ; save return address

       CI R4,>E000  ; pushable block
       JEQ SPWNBL

       MOV R3,R0      ; map location
       LI R1,SDDUNG   ; save data dungeon items collected
       BL @GETBIT
       JOC !          ; already collected

       MOV R4,R3
       ANDI R3,>0F00
       SZC R3,R4
       SRL R4,10    ; R4 = type * 4
       SRL R3,7     ; R3 = location * 2

       ; FIXME this needs to use a free item slot instead of LASTSP
       MOV @ITEMXY(R3),@LASTSP      ; YYXX
       MOV @ITMTBL-4(R4),@LASTSP+2  ; SS.C
       MOV @ITMTBL-2(R4),@MOVEOB    ; moveable object word
!
       B *R10   ; return to saved address

* modifies R0-R2,R10
SPWNBL ; spawn pushable block (always leftmost in middle row)
       LI R0,SCR1TB+(13*32)+4     ; middle row
       BL @VDPRB
       LI R2,>6820    ; starting yyxx coordinate
!      CI R1,>8400    ; Upleft corner of tile block is >84
       JEQ !
       MOVB @VDPRD,R1 ; skip
       MOVB @VDPRD,R1 ; get next tile corner
       AI R2,>0010    ; next tile coordinate
       CI R2,>68E0    ; end of middle row
       JNE -!
       CLR R2         ; no block found
!
       MOV R2,@PSHBLK ; store block location
       B *R10   ; return to saved address

DUNITM   ; get dungeon item in R4=item,location,_,_
       MOVB @MAPLOC,R3
       SRL R3,8
       CLR R4
       MOVB @ITEMAP(R3),R4  ; R4=item,location,_,_
       RT

ITMSPR ; custom item sprites (loaded when sprite index is >68)
       BYTE >00 ; 0
       BYTE >22 ; 1 compass
       BYTE >32 ; 2 map
       BYTE >00 ; 3 tiforce
       BYTE >31 ; 4 key
       BYTE >31 ; 5 key
       BYTE >00 ; 6
       BYTE >31 ; 7 key
       BYTE >00,>00,>00,>00 ; 8 9 A B
       BYTE >30 ; C heart container
       BYTE >00,>00,>00 ; D E F
       EVEN

ITMTBL ; Dungeon item table SPRIDX+COLOR,MOBDATA
       DATA COMPSC,CITMID+(>100)   ;  1 compass     ; load into shared sprite
       DATA MAP_SC,CITMID+(>200)   ;  2 map         ; load into shared sprite
       DATA TIFOSC,CITMID+(>300)   ;  3 tiforce     ; load into shared sprite (location shifted 8 pix left)
       DATA KEY_SC,CITMID+(>400)   ;  4 key         ; load into shared sprite
       DATA KEY_SC,CITMID+(>400)   ;  5 key carried by enemy (also has location for when all enemies are killed)
       DATA BOMBSC,CITMID+(>500)   ;  6 bomb carried by enemy (also has location for when all enemies are killed)
       DATA >0000, STRSID          ;  7 unused
       ; all of the above are available after DNINIT
       DATA KEY_SC,CITMID+(>400)   ;  8 key   (this and following items appear after killing all enemies)
       DATA MBOMSC,CITMID   ;  9 magic boomerang
       DATA RUPEEB,CITMID   ;  A rupeesX5
       DATA BOMBSC,CITMID+(>500)   ;  B bombs
       DATA HRTCSC,CITMID+(>600)   ;  C heart container   ; load into shared sprite
       DATA >0000,>0000     ;  D TODO unused
       DATA >0000,>0000     ;  E activate push block to open shutters or stairs (always middle leftmost)
       DATA BOOMSC,CITMID   ;  F TODO wood boomerang
       ; TODO old man / grumble grumble / princess Tilda
       ; TODO 10 rupees diamond shape
       ; TODO item underground
       ; TODO connecting tunnel (use tunnel pairs lookup table)


ITEMAP  ; bits 7-4: item type  3-0: item location
       BYTE >00,>8B,>00,>3D,>00,>E0,>E0,>00,>00,>E0,>00,>00,>3D,>3D,>C4,>00   ; 0x
       BYTE >00,>00,>E0,>CA,>3D,>00,>87,>00,>00,>24,>84,>00,>C4,>E0,>B1,>00   ; 1x
       BYTE >00,>2A,>E0,>8C,>CC,>00,>87,>87,>00,>84,>84,>00,>00,>84,>00,>A4   ; 2x
       BYTE >00,>00,>E0,>54,>00,>C6,>3D,>17,>E0,>00,>E0,>E0,>00,>3D,>84,>B4   ; 3x
       BYTE >8B,>00,>E0,>26,>FC,>49,>27,>87,>00,>84,>B4,>84,>24,>C4,>84,>94   ; 4x
       BYTE >00,>85,>00,>8C,>16,>87,>BC,>A7,>84,>00,>14,>B4,>00,>00,>00,>24   ; 5x
       BYTE >00,>00,>1B,>00,>E0,>64,>84,>00,>14,>00,>00,>84,>84,>00,>00,>11   ; 6x
       BYTE >85,>00,>89,>00,>56,>00,>00,>87,>00,>00,>84,>84,>00,>00,>84,>00   ; 7x

       BYTE >00,>A4,>84,>B4,>B4,>E0,>B4,>00,>00,>00,>00,>E0,>E0,>E0,>00,>E0   ; 8x
       BYTE >24,>00,>E0,>B4,>00,>B4,>00,>E0,>E0,>B4,>A4,>00,>00,>A4,>B4,>00   ; 9x
       BYTE >00,>E0,>C6,>3D,>3D,>00,>24,>00,>E0,>00,>00,>00,>00,>B4,>A4,>24   ; Ax
       BYTE >A1,>00,>84,>00,>C8,>00,>00,>B4,>E0,>00,>00,>00,>A4,>14,>00,>B4   ; Bx
       BYTE >00,>00,>00,>84,>E0,>81,>A4,>00,>A4,>00,>00,>00,>A4,>00,>00,>81   ; Cx
       BYTE >A4,>00,>16,>00,>84,>84,>84,>14,>00,>00,>00,>00,>00,>E0,>84,>84   ; Dx
       BYTE >B4,>B4,>00,>00,>B4,>56,>A4,>00,>00,>E0,>A4,>00,>00,>00,>00,>00   ; Ex
       BYTE >84,>00,>B4,>00,>E0,>A4,>00,>44,>00,>00,>00,>00,>E0,>00,>00,>00   ; Fx
       ;     00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F

ITEMXY  ; possible item and stairs locations  (4 bits)
       DATA >0000+>3820 ; 0 top left corner           _ _ _ _ _ _ _ _ _ _ _ _
       DATA >00B0+>3820 ; 1 top right corner         |0|_|_|_|_|_|_|_|_|_|_|1|
       DATA >30B0+>3820 ; 2 right center (st only)   |_|_|_|_|_|_|C|_|_|_|_|_|
       DATA >2070+>3820 ; 3 upright from center (st) |_|_|_|_|_|_|B|3|_|_|_|_|
       DATA >3060+>3820 ; 4 center                   |_|_|_|_|_|_|4|5|_|_|6|2|
       DATA >3070+>3820 ; 5 slight right of center   |_|_|_|_|_|_|7|_|_|_|_|_|
       DATA >30A0+>3820 ; 6 middle right             |_|_|_|_|_|_|_|_|_|_|_|_|
       DATA >4060+>3820 ; 7 slight down from center  |8|_|_|_|_|_|_|_|9|_|_|A|
       DATA >6000+>3820 ; 8 bottom left
       DATA >6080+>3820 ; 9 bottom mid-right
       DATA >60B0+>3820 ; A bottom right
       DATA >2060+>3820 ; B slight up from center
       DATA >1060+>3820 ; C top center
       DATA >3058+>3820 ; D exact center (TIFORCE only)
       ; TODO 5 and 6 are the same as a and c below, could reuse
EXITXY ; stairs exits
       DATA >3070+>3820 ; 0) a slight right of center
       DATA >2050+>3820 ; 1) b slight upleft of center  _ _ _ _ _ _ _ _ _ _ _ _
       DATA >30A0+>3820 ; 2) c slight lt of ctr rt     |_|_|_|_|_|_|_|_|_|_|_|_|
       DATA >5040+>3820 ; 3) d mid left bottom         |_|_|_|_|_|_|_|_|_|_|i|_|
       DATA >4040+>3820 ; 4) e mid left mid            |_|_|_|_|_|b|_|_|_|_|_|_|
       DATA >3040+>3820 ; 5) f mid left top            |_|_|_|_|f|_|_|a|_|_|c|_|
       DATA >60A0+>3820 ; 6) g slight lt of bot rt     |_|_|_|_|e|_|_|_|h|_|_|_|
       DATA >4080+>3820 ; 7) h slight down right of ctr|_|_|_|_|d|_|_|_|_|_|_|_|
       DATA >10A0+>3820 ; 8) i slight lt of top rt     |_|_|_|_|_|_|_|_|_|_|g|_|

TUNNLS ; cellars and tunnels table   loc y:4 x:4, rightside:1, stair idx:3, exit idx:4
       DATA >6444,>06C4   ; tunnel D5 A  (mid 4e - mid 4e)
       DATA >3A14,>1DA4   ; tunnel D6 A  (upright 1e push to open - right 2e)
       DATA >A144,>8594   ; tunnel D7 A  (mid 4e - upright 1e push to open)
       DATA >C431,>B7A1   ; tunnel D8 A  (mid upright 3b - right 2b)
       DATA >9C34,>DDC4   ; tunnel D9 A  (mid upright 3e  - mid 4e)
       DATA >EB27,>8D97   ; tunnel D9 B  (right 2h - upright 1h push to open)
       DATA >A844,>E9C4   ; tunnel D9 C  (mid 4e - mid 4e)
       DATA >F924,>FCC4   ; tunnel D9 D  (right 2e - mid 4e)
       DATA >B818,>8CC8   ; tunnel D9 E  (upright 1i push to open - mid 4i)
       DATA >DA24,>8BC4   ; tunnel D9 F  (right 2e - mid 4e)
CELLRS
       DATA >2243   ; stairs to D1 bow       (mid 4d)
       DATA >6925   ; stairs to D3 raft       (right 2f)
       DATA >3216   ; stairs to D4 ladder     (upright 1g push to open)
       DATA >0510   ; stairs to D5 flute     (upright 1a push to open)
       DATA >0912   ; stairs to D6 magic rod (blue)   (upright 1c push to open)
       DATA >9244   ; stairs to D7 red candle  (mid 4e)
       DATA >9744   ; stairs to D8 magic key   (mid 4e)
       DATA >F444   ; stairs to D8 magic book  (mid 4e)
       DATA >9814   ; stairs to D9 silver arrow  (upright 1e push to open)
       DATA >8F44   ; stairs to D9 red ring    (mid 4e)
CELLRX

SPWNST  ; spawn stairs from dungeon room load
       LI R1,TUNNLS
!      MOV *R1+,R0
       CB R0,@MAPLOC
       JEQ !!
       CI R1,CELLRX
       JNE -!
       ; no match
!      RT
!      ; found a match
       ; only stairs that are open from the start
       ; R0 contains maploc y:4 x:4, rightside:1, stair idx:3, exit idx:4

       MOV R0,R1
       ANDI R1,>0070
       ; don't draw upper right stairs at start
       CI R1,>0010  ; upper right corner
       JEQ -!!
       LI R9,LEVELA-(3*32)+VDPWM
DSTAIR ; draw stairs  R1=00n0  where n=ITEMXY index  R9=screen
       SRL R1,3
       MOV @ITEMXY(R1),R1    ; get stair pixel coordinates
       MOV R1,@DOOR

       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
       MOV R1,R3
       SRL R3,3
       MOVB R3,R1
       SRL R1,3
       A R1,R9

       LI R8,DSTACH
       B @DRAWCH     ; tail call


DUNBLK  ; draw stairs after block is pushed
       MOV R11,R13    ; save return address from bank 5
        ; spawn stairs
       LI R1,TUNNLS
!      MOV *R1+,R0
       CB R0,@MAPLOC
       JEQ !
       CI R1,CELLRX
       JNE -!
       ; no match?  open shutters then
       BL @OPENSH
       JMP !!     ; return to bank 5

!      ; found a match
       MOV R0,R1
       ANDI R1,>0070
       MOV @FLAGS,R9
       ANDI R9,SCRFLG
       AI R9,VDPWM
       BL @DSTAIR
!      B @BANK5   ; return to saved address in bank 5




; get dungeon cave type R3=DCAVE or DTUNNL
; and position hero at left or right side
; modifies R0,R1
GETDNC
       LI R3,DCAVE  ; default
       LI R1,TUNNLS
!      MOV *R1+,R0
       CB R0,@MAPLOC
       JNE -!
       ; R0 contains >YXij where i=stairs index j=exit index
       CI R1,CELLRS
       JH !
       ; tunnel
       LI R3,DTUNNL
       SRC R0,8      ; get rightside bit in carry
       JOC !!
!      LI  R5,>1830        ; Put hero at cellar left entrance
       MOV R5,@HEROSP
       RT
!      LI  R5,>18C0        ; Put hero at cellar right entrance
       MOV R5,@HEROSP
       RT

; Get dungeon cellar exit and new MAPLOC (called from bank 0)
GETDCX
       MOV R11,R13     ; Save return address
       LI R1,TUNNLS
!      MOV *R1+,R2
       CB R2,@MAPLOC
       JNE -!
       MOV @HEROSP,R5
       SB  R5,R5      ; Clear Y pos
       LI R0,>0080    ; Rightside bit
       CZC R0,R2      ; Test Rightside bit set
       JNE RTSIDE
       ; Rightside bit not set
       C R5,R0
       JL NOCHG        ; hero on left ladder, no need to change
       ; Hero on right side
       MOV *R1,R2       ; Get rightside location
       JMP CHSIDE
RTSIDE
       ; Rightside bit set
       C R5,R0
       JHE NOCHG        ; hero on right ladder, no need to change
       MOV @-4(R1),R2   ; Get rightside location
CHSIDE ; changed sides, update maploc
       MOVB R2,@MAPLOC  ; Update maploc
NOCHG
       ; R0 contains >YXij where i=stairs index j=exit index
       ANDI R2,>000F
       SLA R2,1
       MOV @EXITXY(R2),@HEROSP
       MOV @EXITXY(R2),@HEROSP+4
       B @BANK0        ; Return to saved address in bank 0




       ; bits 5:0 - room type
       ; bit 6 - stairs  (dungeon boss roar sound effect?)
       ; bit 7 - dark room
DUNMAP BYTE >28,>A5,>90,>0C,>00,>09,>0A,>00,>00,>0F,>0F,>28,>0C,>0C,>02,>00
       BYTE >0E,>28,>0F,>11,>0C,>28,>21,>28,>11,>24,>A1,>05,>0E,>14,>08,>28
       BYTE >20,>A2,>0A,>20,>12,>13,>23,>A0,>08,>A3,>07,>28,>00,>A4,>07,>00
       BYTE >A1,>1F,>4F,>1F,>04,>0B,>0C,>9F,>0F,>A4,>09,>0F,>9F,>0C,>2A,>00
       BYTE >A0,>28,>09,>06,>04,>08,>A2,>20,>10,>00,>15,>16,>00,>2A,>04,>12
       BYTE >8D,>05,>03,>04,>05,>24,>00,>9F,>12,>07,>00,>00,>06,>03,>06,>05
       BYTE >00,>04,>9B,>03,>0A,>04,>A1,>28,>07,>14,>28,>0D,>00,>05,>08,>03
       BYTE >00,>01,>00,>01,>07,>00,>01,>07,>06,>01,>85,>05,>01,>01,>00,>00

       BYTE >28,>0F,>12,>2A,>18,>16,>00,>00,>00,>A4,>2A,>0A,>0A,>0F,>28,>0A
       BYTE >A5,>06,>0A,>00,>00,>0D,>00,>0A,>16,>02,>2A,>80,>19,>A3,>0F,>06
       BYTE >28,>0A,>0B,>0C,>0C,>28,>00,>00,>0A,>02,>07,>22,>9F,>1C,>05,>0F
       BYTE >08,>12,>02,>28,>11,>28,>18,>14,>0F,>02,>1A,>80,>23,>2A,>00,>18
       BYTE >28,>21,>00,>98,>19,>02,>00,>00,>25,>80,>A9,>2A,>00,>00,>02,>03
       BYTE >00,>04,>A7,>28,>12,>8D,>12,>A1,>A3,>0D,>14,>18,>1B,>0A,>27,>A3
       BYTE >00,>18,>97,>03,>12,>24,>02,>00,>00,>0A,>2A,>14,>06,>A1,>28,>00
       BYTE >18,>01,>07,>00,>0A,>18,>01,>A5,>00,>14,>00,>06,>0A,>00,>01,>00

       ; Screen type strips of metatiles (12 or more bytes)
       ; column of bits indicating 0=floor or 1=other (block/water/lava/sand)
       ; (1xxx xxxx indicates next byte contains statue bit mask)
ST0    BYTE >FF,>7C,>7C,>7C,>7C  ; dark sand
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00,>00   ; 0 Completely empty
       BYTE >00,>80,>2A,>00,>03,>81,>2A,>07,>07,>81,>2A,>03,>00,>80,>2A,>00  ; 1 Starting room (sand)
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 2 Room full of dark sand

       BYTE >FF,>84,>86,>85,>87  ; block
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
       BYTE >7F,>40,>D8,>01,>58,>E0,>04,>40,>40,>E0,>04,>58,>D8,>01,>40,>7F  ; 1A Princess room
       BYTE >00,>7C,>05,>6C,>20,>3E,>00,>23,>20,>3E,>10,>13    ; 1B Block maze
       BYTE >00,>00,>00,>00,>7F,>00,>00,>7F,>00,>00,>00,>00    ; 1C Two long strips vertical
       BYTE >00,>3E,>00,>3E,>00,>3E,>3E,>00,>3E,>00,>3E,>00    ; 1D Five strips vertical
       BYTE >77,>77,>77,>77,>77,>36,>08,>77,>77,>77,>77,>77    ; 1E Crossroads

       BYTE >FF,>81,>81,>81,>81  ; water
       BYTE >77,>41,>5F,>41,>7D,>04,>10,>5F,>41,>7D,>41,>77   ; 1F Water maze
       BYTE >00,>3E,>22,>2A,>08,>08,>08,>08,>2A,>22,>3E,>00   ; 20 Water shape [-]
       BYTE >10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10,>10   ; 21 Water horizontal strip
       BYTE >00,>3F,>3F,>33,>33,>30,>30,>33,>33,>3F,>3F,>00   ; 22 Water shape T
       BYTE >00,>3E,>22,>22,>22,>22,>22,>22,>22,>22,>3E,>00   ; 23 Water rect
       BYTE >00,>00,>00,>00,>00,>00,>00,>00,>7F,>00,>00,>00   ; 24 Water strip vertical
       BYTE >77,>41,>5D,>55,>77,>22,>22,>77,>55,>5D,>41,>77   ; 25 Water shape spider
       BYTE >00,>7F,>37,>30,>30,>30,>30,>30,>30,>3F,>3F,>00   ; 26 Water shape h
       BYTE >12,>12,>12,>12,>12,>12,>12,>12,>12,>12,>12,>12   ; 27 Water 2 horizontal strips

       BYTE >FF,>20,>20,>20,>20  ; black
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 28 Black floor
       BYTE >BE,>41,>7F,>43,>1B,>38,>04,>04,>38,>1B,>43,>7F,>BE,>41  ; 29 Final boss room

       BYTE >FF,>05,>05,>05,>05  ; light sand
       BYTE >7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F,>7F   ; 2A light sand

       EVEN

* item       condition
* 1 K-key      O-open
* 2 B-bomb     K-kill all enemies
* 3 C-compass  P-push block after killing enemies
* 4 R-rupees   C-carried by enemy
* 5 M-map
* 6 P-push block
* 7 S-stairs
* 8 D-doors
* 9 I-item
* A H-heart container
* B T-tiforce

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

* Clear screen, call from hero.asm bank0
* Modifies R0-1,R8,R13
CLRSCN
       MOV  R11,R13     ; save return address from bank0
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
       B @BANK0       ; return to saved address in bank0



* Modifies R0-R3,R8-R10
DRWLAD
       MOV R11,R13   ; Save return address
       LI R11,BANK0  ; return to bank 0
       ; fall thru
* Draw ladder at R8 in name table
* Saves ladder pos and backup chars to VDP LADPOS
* Modifies R0-R3,R9-R10
DRWLA0
       ANDI R8,>F8F8
       MOV R8,R0
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
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
       MOVB @VDPRD,R9
       MOVB @VDPRD,@R9LB

       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       AI R0,-32+VDPWM
       MOVB @VDPRD,R10
       MOVB @VDPRD,@R10LB

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
       LI R1,R8LB-1     ; copy R8-R10
       LI R2,6
       B @VDPW     ; write and return

