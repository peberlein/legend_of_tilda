* Do the item selection menu
* Modifies R0-R12
DOMENU
       LI R0,SCHSAV
       BL @PUTSCR      ; Save a backup of scratchpad

* Scroll menu screen down
MENUDN
       LI R0,SWRDST
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       LI R0,HEROST
       LI R1,>D100
       BL @VDPWB       ; Hide hero sprites
       LI R0,HEROST+4
       BL @VDPWB       ; Hide hero sprites

       ;Copy current screen to LevelA
       MOV @FLAGS,R4
       ANDI R4,SCRFLG
       AI R4,3*32
       LI R9,21       ; Move 21 lines
       LI R10,LEVELA  ; Dest into LEVELA
!      MOV R4,R0
       BL @READ32
       MOV R10,R0
       BL @PUTSCR
       AI R4,32
       AI R10,32
       DEC R9
       JNE -!

       MOV @FLAGS,R4
       MOV R4,R0
       ANDI R0,DUNLVL
       JNE NOFORC   ; don't draw tiforce in dungeon

       ANDI R4,INCAVE
       JEQ !
       BL @CLRCAV      ; Clear cave
!

       ;       LI R5,TIFORC    ; Draw TIFORCE collected
       ;       LI R0,MENUSC+(32*11)+10     ; TiForce offset at 10,11
       ;       LI R8,8        ; 8 rows
       ;
       ;!      MOV *R5+,R3     ; Draw TIFORCE pieces
       ;       BL @TIFROW
       ;       MOV *R5+,R3
       ;       BL @TIFROW
       ;       AI R0,32-8
       ;       DEC R8
       ;       JNE -!

       LI R5,TIFORC-1    ; Draw TIFORCE collected
       LI R3,MENUSC+(32*11)+10     ; TiForce offset at 10,11
       LI R0,SDTIFO    ; Get TiForce bits
       BL @VDPRB
       MOV R1,R8       ; R8 = TiForce bits
!      JEQ NOFOR2
       INC R5
       SLA R8,1
       JNC -!
       BL @TIFROW
       AI R3,32
       BL @TIFROW
       AI R3,-32
       JMP -!

NOFORC
NOFOR2
       LI R4,MENUSC+(32*20)    ; Menu screen VDP address
       LI R8,21        ; Scroll through 21 rows
!
       LI R5,-32       ; Direction down
       LI R9,23        ; Move 23 lines
       LI R10,32*23    ; Dest start at at bottom
       BL @SCROLL      ; Scroll down

       LI R0,>0800
       BL @STMOVE      ; Move status sprites down

       DEC R8
       JNE -!

       LI R0,MCLRTB+15     ; Menu color set, partial
       LI R1,MCLRST
       LI R2,11
       BL @VDPW

       LI R0,>0300+(MCLRTB/>40)  ; VDP Register 3: Menu Color Table
       BL @VDPREG
       LI R0,>400+(MENTAB/>800)   ; VDP register 4
       BL @VDPREG

       LI R5,ITEMS
       MOV @HFLAGS,R6
       SRL R6,7      ; start at bow
       ;LI R7,PATTAB+(>78*8)
       LI R8,22       ; Draw 22 items
       LI R9,>787A    ; Use characters starting at 7C

!      MOV *R5+,R4   ; R4=sprite index R4LB=screen offset

       ;MOV R7,R0     ; Save original char pattern in PATSAV
       ;BL @READ32
       ;AI R0,PATSAV-PATTAB-(>78*8)
       ;BL @PUTSCR

       CI R8,13
       JNE !
       MOV @HFLAG2,R6  ; get 2nd half of flags
!
       SRL R6,1       ; have item flag in carry
       JNC NOITEM

       ;BL @CPYITM

       MOV @FLAGS,R0   ; Set dest to flipped screen
       ANDI R0,SCRFLG
       SB R4,R4   ;ANDI R4,>00FF
       A R4,R0         ; Add screen pos

       MOV R9,R1       ; Get character number
       BL @VDPW2B       ; Draw characters from sprite pattern
       AI R0,>20
       AI R1,>0101
       BL @VDPW2B
NOITEM
       AI R9,>0404
       ;AI R7,32

       DEC R8
       JNE -!!

       ; FIXME this needs to point to the correct sprite
       LI R0,SPRPAT+(91*32)  ; Selector sprite
       BL @READ32
       LI R0,SPRPAT+(>6C*8)
       BL @PUTSCR
* End scroll menu down


       LI R0,ITEMST
       LI R1,>1F40          ; Position B item in box
       BL @VDPW2B

       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ NOTDNG
       ; show map icon, compass icon, and automap instead
       MOV @HFLAG2,R3
       SLA R3,1
       JNC !

       LI R0,HEROST
       LI R1,MAP_ST
       LI R2,4
       BL @VDPW         ; set map sprite

!      SLA R3,1
       JNC !

       LI R0,HEROST+4
       LI R1,CMP_ST
       LI R2,4
       BL @VDPW       ; set compass sprite
!
       BL @BANK1X
       DATA x#LDMPCM   ; load map and compass sprite patterns

NOTDNG
       MOV @HFLAGS,R4       ; Current selection
       ANDI R4,SELITM
       SZC R4,@HFLAGS       ; Set zeros
       LI R6,>6C04          ; Selector sprite and color

       LI R8,1
       CLR R3
       JMP MENUMV

MENULP ; menu loop
       BL @VSYNCM

       DEC R8
       JNE !
       LI R8,8
       LI R0,>0002
       XOR R0,R6
MENUSP
       LI R0,ASWDST         ; Update selector sprite
       LI R1,WRKSP+(5*2)    ; Copy bytes from R5 and R6
       LI R2,4
       BL @VDPW
!
       BL @BANK4X
       DATA x#DOKEY0        ; Read joystick/keys (return to bank 0)

       MOV @KEY_FL, R0
       MOV R0,R1

       SLA R1,4             ; Shift EDG_RT into carry
       JNC !
       LI R3,1
       JMP MENUM0
!
       MOV R0,R1
       SLA R1,5             ; Shift EDG_LT into carry
       JNC !
       LI R3,-1
       JMP MENUM0
!
       SLA R0,1             ; Shift EDG_C bit into carry status
       JNC MENULP

       JMP MENUUP           ; Scroll menu screen up and exit

MENUM0
       LI R0,x#TSF181  ; Cursor
       MOV R0,@SOUND2

MENUMV
       MOV R4,R7
!
       A R3,R4        ; Change selected item by R3
       ANDI R4,>0007  ; Wrap around

       MOV R4,R0
       ANDI R0,>0003  ; Get X coordinate
       MOV R0,R5
       A R0,R5
       A R0,R5        ; Multiply by 3
       SLA R5,3       ; Multiply by 8
       MOV R4,R0
       ANDI R0,>0004  ; Get Y coordinate
       SLA R0,10
       A R0,R5
       AI R5,>1F80    ; New selector sprite location

       MOV R5,R0
       AI R0,>0100
       LI R2,MENUM2
       BL @TESTCH

       C R4,R7
       JNE -!
       ; no items can be selected
       CLR R4
       ; clear the selected sprite
       LI R1,SCRTCH
       LI R2,16
!      CLR *R1+
       DEC R2
       JNE -!
       JMP MENUM3

MENUM2

       ; R1 contains character under selector
       MOV R1,R2

       ; get color for item sprite
       CI R1,>9800
       JHE !
       LI R1,>0A00   ; brown
       JMP !!!
!
       CI R1,>B800
       JL !
       LI R1,>0600   ; red
       JMP !!
!
       LI R1,>0400   ; blue
!
       LI R0,ITEMST+3 ; Set color in VDP sprite table
       BL @VDPWB

       LI R0,SPRPAT+(>AC*8) ; Special case for arrows, use Arrow Up sprite
       CI R4,2
       JEQ !

       ; copy pattern from character index to sprite 62
       MOV R2,R0
       SRL R0,5
       AI R0,MENTAB
!
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR
MENUM3
       LI R0,SPRPAT+(62*32)
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW

       JMP MENUSP


MENUUP
       SOC R4,@HFLAGS       ; Save selected item

       LI R0,HEROST
       LI R1,>D000
       BL @VDPWB       ; Hide map and compass sprites

       LI R0,ITEMST
       LI R1,BBOXYX+(21*>800)  ; Reposition item B-box sprite
       BL @VDPW2B
       LI R0,ASWDST
       LI R1,ABOXYX+(21*>800)  ; Reposition sword A-box sprite
       BL @VDPW2B
       BL @GETSWD           ; Get selected sword


       LI R5,ITEMS
       LI R8,22       ; Erase 22 items
       MOV @FLAGS,R9   ; Set dest to flipped screen
       ANDI R9,SCRFLG

!      MOV *R5+,R0
       SB R0,R0   ;ANDI R0,>00FF
       A R9,R0         ; Add screen pos

       LI R1,>2020     ; Erase 2 characters
       BL @VDPW2B

       AI R0,>20       ; Next row
       BL @VDPW2B


       DEC R8
       JNE -!

       ; restore color table
       BL @VSYNCM
       LI R0,>0300+(CLRTAB/>40)  ; VDP Register 3: Color Table
       BL @VDPREG

       ; restore pattern table
       LI R0,>400+(PATTAB/>800)   ; VDP register 4
       MOV @FLAGS,R1
       ANDI R1,DARKRM
       JEQ !
       LI R0,>400+(DRKTAB/>800)   ; VDP register 4
!
       BL @VDPREG


;       LI R6,VDPRD     ; Keep VDPRD address in R6
;       LI R7,PATSAV
;       LI R8,22       ; Erase 22 meta-patterns

;!      MOV R7,R0        ; Restore saved pattern tables
;       BL @READ32
;       AI R0,PATTAB+(>78*8)-PATSAV
;       BL @PUTSCR

;       AI R7,32
;       DEC R8
;       JNE -!

       LI R8,21        ; Scroll through 21 rows
       LI R4,LEVELA
!
       LI R5,32        ; Direction up
       LI R9,23        ; Move 23 lines
       CLR R10         ; Dest start at at top
       BL @SCROLL      ; Scroll up

       LI R0,->0800
       BL @STMOVE      ; Move status sprites up

       DEC R8
       JNE -!

       LI R9,3        ; Copy 3 lines from current to flipped
       MOV @FLAGS,R10  ; Set dest to flipped screen
       INV R10
       ANDI R10,SCRFLG

!      LI R0,SCRFLG
       XOR R10,R0      ; Source from current screen
       BL @READ32      ; Read 32 bytes into scratchpad

       MOV R10,R0      ; Dest to screen
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       AI R10,32

       DEC R9
       JNE -!

       BL @SCHRST

       B @MENUX

MAP_ST DATA >5F2C,>6000+(MAP_SC&15)   ; map yyxx, sprite idx and color
CMP_ST DATA >872C,>6400+(COMPSC&15)   ; compass yyxx, sprite idx and color

TIFORC ; bit [7]=3wide [6-4]=y offset [2-0]=x offset
       BYTE 2+(0*16)  ; Tiforce 1 piece 10,11   2,0
       BYTE 2+(2*16)  ; Tiforce 2 piece 10,13   2,2
       BYTE 4+(2*16)  ; Tiforce 3 piece 12,13   4,2
       BYTE 6+(2*16)  ; Tiforce 4 piece 14,13   6,2
       BYTE 0+(3*16)  ; Tiforce 5 piece  8,14   0,3
       BYTE 2+(4*16)+128  ; Tiforce 6 piece 10,15   2,4
       BYTE 5+(4*16)+128  ; Tiforce 7 piece 13,15   5,4
       BYTE 3+(6*16)+128  ; Tiforce 8 piece 11,17   3,6

* R5 = TIFORC pointer (preserved)
* R3 = screen offset (preserved)
* modifies R0-R2,R10
TIFROW
       MOV R11,R10    ; Save return address

       LI R2,2
       MOVB *R5,R1
       JGT !
       INC R2   ; 3 wide
!      MOV R1,R0
       ANDI R0,>7000
       ANDI R1,>0700
       SRL R1,1
       SOC R1,R0
       SRL R0,7    ; R0 = Y*32 + X
       A R3,R0

TIFRO1
       ANDI R0,>3FFF  ; Clear VDPWD bit
       BL @VDPRB      ; Read 1 byte
       CI R1,>3A00    ; /
       JNE !
       AI R1,>0200    ; Change to |/
       LI R2,1        ; finish
       JMP TIFRO2
!
       CI R1,>3B00    ; \
       JNE !
       AI R1,>0200    ; Change to \|
       JMP TIFRO2
!
       CI R1,>3C00
       JEQ TIFRO4     ; Don't change |/
       CI R1,>3D00
       JEQ TIFRO3     ; Don't change \|
       CI R1,>2F00    ; | ]
       JNE !
       CI R2,1
       JEQ TIFRO4     ; Don't change last | ]
!
       LI R1,>5B00    ; Change to Solid []
TIFRO2
       BL @VDPWB
TIFRO3
       INC R0
       DEC R2
       JNE TIFRO1
TIFRO4
       B *R10         ; Return to saved address



       ;TIFORC
       ;DATA >0011,>0000  ; 0 0 1 1 0 0 0 0
       ;DATA >0011,>0000  ; 0 0 1 1 0 0 0 0
       ;DATA >0022,>3344  ; 0 0 2 2 3 3 4 4
       ;DATA >5522,>3344  ; 5 5 2 2 3 3 4 4
       ;DATA >5566,>6777  ; 5 5 6 6 6 7 7 7
       ;DATA >0066,>6770  ; 0 0 6 6 6 7 7 0
       ;DATA >0008,>8800  ; 0 0 0 8 8 7 0 0
       ;DATA >0008,>8000  ; 0 0 0 8 8 0 0 0

       ;* Translate 4 TIFORCE characters
       ;* R0 = screen offset
       ;* R3 = 4 nibbles
       ;* R6 = TIFORCE flags
       ;* Modifies R0-R3,R10
       ;TIFROW
       ;       MOV R11,R10    ; Save return address
       ;
       ;       LI R2,4       ; Go through each nibble
       ;TIFRO1
       ;       MOV R3,R1
       ;       SLA R3,4
       ;       SRL R1,12  ; Todo Test this bit in collected tiforces
       ;       JEQ TIFRO3
       ;
       ;       ANDI R0,>3FFF  ; Clear VDPWD bit
       ;       BL @VDPRB      ; Read 1 byte
       ;       CI R1,>3A00    ; /
       ;       JNE !
       ;       AI R1,>0200    ; Change to |/
       ;       JMP TIFRO2
       ;!
       ;       CI R1,>3B00    ; \
       ;       JNE !
       ;       AI R1,>0200    ; Change to \|
       ;       JMP TIFRO2
       ;!
       ;       CI R1,>3C00
       ;       JEQ TIFRO3     ; Don't change |/
       ;       CI R1,>3D00
       ;       JEQ TIFRO3     ; Don't change \|
       ;
       ;       LI R1,>5B00    ; Solid []
       ;TIFRO2
       ;       BL @VDPWB
       ;TIFRO3
       ;       INC R0
       ;       DEC R2
       ;       JNE TIFRO1
       ;
       ;       B *R10         ; Return to saved address

* items that get copied to pattern table
* 78  bow    arrows  brown  (can't be selected alone)
* 80  ladder  raft   brown
* 88  magkey boomer  brown
* 90  flute  bow+arr brown
* 98  silver bombs  blue
* A0  boomer candle  blue
* A8  letter potion  blue
* B0  magrod ring    blue
* B8  ring   book    red
* C0  powerb candle  red
* C8  meat   potion  red

* Raft (brown) Book (red) Ring (blue/red) Ladder (brown) Dungeon Key (brown) Power Bracelet (red)
* 30 32 34 36 38 3A
* 90  93   96   99   Boomerang (brown/blue) Bomb (blue) Bow/Arrow (brown/?) Candle (red/blue)
* D0  D3   D6   D9   Flute (brown) Meat (red) Scroll(brown)/Potion(red/blue) Magic Rod (blue)

ITEMS  ; [15-8]=sprite index [7-0]=screen offset
       DATA >4A96  ; Bow
       DATA >2B96  ; Arrows
       DATA >4736  ; Ladder
       DATA >4430  ; Raft
       DATA >4838  ; Magic Key
       DATA >2590  ; Boomerang
       DATA >4BD0  ; Flute
       DATA >4A96  ; Bow + Arrows
       DATA >4A96  ; Bow + Silver arrows?
       DATA >3193  ; Bombs (HFLAGS2 from here on)
       DATA >2590  ; Magic Boomerang
       DATA >5299  ; Blue Candle
       DATA >4ED6  ; Letter
       DATA >4FD6  ; Potion
       DATA >46D9  ; Magic Rod
       DATA >5034  ; Blue Ring
       DATA >5034  ; Red Ring
       DATA >4532  ; Magic Book
       DATA >493A  ; Power Bracelet
       DATA >5299  ; Red Candle
       DATA >51D3  ; Meat
       DATA >4FD6  ; Red Potion

****************************************
* Menu Colorset Definitions starting at char >78
****************************************
MCLRST BYTE >A1,>A1,>A1,>A1
       BYTE >41,>41,>41,>41
       BYTE >61,>61,>61



SELPOS BYTE >90,>93,>96,>99,>D0,>D3,>D6,>D9
       EVEN
* Get selected item sprite and color into sprite 62
* Modifies R0-R2,R4-5,R7-R10,R13   (R3,R6,R12 must be preserved)
GETSEL
       MOV R11,R13        ; Save return address
       MOV @HFLAGS,R9
       ANDI R9,7
       MOVB @SELPOS(R9),R9   ; Get selected item pos

       LI R7,SPRPAT+(62*32)

       LI R5,ITEMS
       MOV @HFLAGS,R6
       SRL R6,7      ; start at bow
       LI R8,22       ; Draw 22 items

!
       MOV *R5+,R4   ; R4 = [15:8] Sprite index [7:0] screen offset

       CI R8,13
       JNE !
       MOV @HFLAG2,R6  ; get 2nd half of flags
!
       SRL R6,1       ; have item in carry flag
       JNC NOTITM     ; item not collected

       CB R9,@R4LB
       JNE NOTITM     ; not selected item

       ; Copy sprite
       BL @CPYITM

       ; Get color from menu colorset
       AI R5,-ITEMS-2
       SRL R5,2
       MOVB @MCLRST(R5),R5
       SRL R5,12
       ORI R5,>F800          ; item sprite index

       LI R0,ITEMST+2+VDPWM
       MOV R5,R1
       BL @VDPW2B           ; Put in VDP sprite table
       BL @GETSWD
       B *R13         ; Return to saved address

NOTITM
       DEC R8
       JNE -!!

       B *R13         ; Return to saved address

* Get active sword and set sprite and color
* Modifies R0,R1
GETSWD
       MOV @HFLAGS,R0         ; Get hero flags for sword bits
       LI R1,NSWORC           ; no sword sprite and color
       ANDI R0,ASWORD+WSWORD+MSWORD
       JEQ !
       LI R1,ASWORC           ; wooden sword sprite and color
       ANDI R0,WSWORD+MSWORD
       JEQ !
       LI R1,WSWORC           ; white sword sprite and color
       ANDI R0,MSWORD
       JEQ !
       LI R1,MSWORC           ; master sword sprite and color
!
       LI R0,ASWDST+2+VDPWM   ; Set active sword sprite and color
VDPW2B ; Write 2 bytes in R1 to VDP Address R0
       ORI R0,VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R1,*R15
       MOVB @R1LB,*R15
       RT

* Copy item from sprite pattern to character pattern (or selected item sprite)
* R4=IIPP  II=sprite index PP=screen pos
* R7=destination VDP address
* Modifies R0-R2,R12
CPYITM
       MOV R11,R12      ; Save return address

       ; Copy sprite
       MOV R4,R0
       ANDI R0,>FF00
       SRL R0,3
       AI R0,SPRPAT
       BL @READ32      ; Get the sprite pattern
       MOV R7,R0
       BL @PUTSCR      ; Save it

       B *R12          ; Return to saved address

* Clear screen with spaces
* Modifies R0-R1,R8-R9
CLRCAV
       LI R1,>2020  ; ASCII space
       LI R8,14     ; clear 14 lines
       MOV @FLAGS,R0  ; Set dest to flipped screen
       ANDI R0,SCRFLG
       AI  R0,(32*7)+4+VDPWM  ; Calculate right column dest pointer with write flag
!      MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R9,24     ; clear 24 chars per line
!      MOVB R1,*R15
       DEC R9
       JNE -!
       AI R0,32
       DEC R8
       JNE -!!
       RT

* Status sprites move by R0 (read/write in VDP)
* Modifies R0-R2
STMOVE
       LI R1,SPRTAB             ; sprite list address
!      MOVB @R1LB,*R14          ; set vdp read address
       MOVB R1,*R14
       ORI R1,VDPWM             ; delay slot, set write mask
       MOVB @VDPRD,R2           ; read sprite YY
       AB R0,R2                 ; adjust YY by R0
       MOVB @R1LB,*R14          ; set vdp write address
       MOVB R1,*R14
       ANDI R1,~VDPWM           ; delay slot, clear write mask
       MOVB R2,*R15             ; write new sprite YY
       AI R1,4                  ; next sprite
       CI R1,SPRTAB+16          ; loop over 4 sprites
       JNE -!
       RT
