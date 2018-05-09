;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 5: transition functions, item select, cave items, draw status
;

       COPY 'tilda.asm'

       
; Use transition in R2
;      0=none
;      1=scroll up
;      2=down
;      3=left
;      4=right
;      5=wipe from center
;      6=cave in
;      7=cave out
;      8=item select in (menu)
;      9=item select out (menu)
;      10=get selected item
;      11=cave items
;      12=draw status
;      13=go into door, returning thru bank 2
;      14=Armos spawning something
; Modifies R0-R13,R15
MAIN
       MOV R11,R12          ; Save return address for later
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA DONE2,SCRLUP,SCRLDN,SCRLLT,SCRLRT,WIPE,CAVEIN,CAVOUT
       DATA MENUDN,MENUUP,GETSEL,CAVEIT,STATUS,GODOOR,ARMOSS

; save for menudn


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

       MOV @HEROSP,R5        ; Get hero YYXX
       AI R5,>0100           ; Move Y down one
DONE4
       LI R0,SCHSAV
       BL @READ32            ; Restore saved scratchpad
DONE2
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

; Scroll all or a portion of the screen up or down
; R4 = source address of row to scroll in
; R5 = direction to scroll (-32 or 32)
; R9 = number of rows to scroll
; R10 = starting offset off screen
; modifies R0-R3
SCROLL
       MOV R11,R3      ; Save return address

       MOV @FLAGS,R0   ; Set dest to flipped screen
       INV R0
       ANDI R0,SCRFLG
       A  R0,R10       ; Add screen offset to dest

!      LI R0,SCRFLG
       XOR R10,R0      ; Set source to current screen
       A  R5,R0

       BL @READ32      ; Read 32 bytes into scratchpad

       MOV R10,R0      ; Dest to screen
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       A  R5,R10

       BL @VMUSIC

       DEC R9
       JNE -!

       MOV R4,R0       ; Source from new screen pointer
       BL @READ32      ; Read 32 bytes into scratchpad

       MOV R10,R0      ; Dest to top of screen
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       A  R5,R4

       BL @VSYNCM
       BL @FLIP
       B *R3           ; Return to saved address


SCRLDN
       LI R8,22        ; Scroll through 22 rows
       LI R4,LEVELA
SCRLD2
       LI R5,32        ; Direction down
       LI R9,21        ; Move 21 lines
       LI R10,32*3     ; Dest start at top
       BL @SCROLL      ; Scroll down

       LI R1,>F900
       BL @DOSPRT

       DEC R8
       JNE SCRLD2

       B @DONE

SCRLUP
       LI R8,22        ; Scroll through 22 rows
       LI R4,LEVELA+(32*21)
SCRLU2
       LI R5,-32       ; Direction down
       LI R9,21        ; Move 21 lines
       LI R10,32*24    ; Dest start at at bottom
       BL @SCROLL      ; Scroll down

       LI R1,>0700
       BL @DOSPRT

       DEC R8
       JNE SCRLU2

       B @DONE

; Scroll screen left
; R4 - pointer to new screen in VRAM
SCRLLT
       LI   R8,32           ; Scroll through 32 columns
       LI R4,LEVELA+31

; Shift 31 columns to the right, fill in leftmost column from new
SCRLL2 
       LI  R9,22
       LI R10,SCRFLG
       XOR @FLAGS,R10  ; Set dest to flipped screen
       ANDI R10,SCRFLG
       AI  R10,(3*32)

!      MOV R4,R0
       LI  R1,SCRTCH
       MOVB @R0LB,*R14       ; Send low byte of VDP RAM read address
       MOVB R0,*R14          ; Send high byte of VDP RAM read address
       LI R0,SCRFLG
       MOVB *R6,*R1+        ; Copy byte from new screen

       XOR R10,R0      ; Set source to current screen
       BL @READ31      ; Read 31 bytes into scratchpad
       
       MOV R10,R0
       BL @PUTSCR      ; Write 32 bytes from scratchpad       
       
       AI R4,32
       AI R10,32

       BL @VMUSIC
       
       DEC R9
       JNE -!
       
       AI R4,(-32*22)-1

       BL @VSYNCM
       BL @FLIP

       MOV R8,R1
       ANDI R1,1
       NEG R1
       AI R1,8
       BL @DOSPRT
       
       DEC R8
       JNE SCRLL2
       B @DONE
       
       
; Scroll screen right
; R4 - pointer to new screen in VRAM
SCRLRT
       LI   R8,32           ; Scroll through 31 columns
       LI R4,LEVELA
       
; Shift 31 columns to the left, fill in rightmost column from new
SCRLR2
       LI  R9,22
       LI R10,SCRFLG
       XOR @FLAGS,R10  ; Set dest to flipped screen
       ANDI R10,SCRFLG
       AI R10,(3*32)

!      LI R0,SCRFLG
       XOR R10,R0  ; Set source to current screen
       INC R0
       LI R1,SCRTCH        ; Dest pointer to scratchpad ram
       BL @READ31        ; Read 31 bytes into scratchpad
       
       MOV R4,R0
       MOVB @R0LB,*R14       ; Send low byte of VDP RAM read address
       MOVB R0,*R14          ; Send high byte of VDP RAM read address
       MOV R10,R0
       MOVB *R6,*R1         ; Copy byte from new screen
       
       BL @PUTSCR      ; Write 32 bytes from scratchpad
       
       AI R4,32
       AI R10,32
       
       BL @VMUSIC
       
       DEC R9
       JNE -!
       
       AI R4,(-32*22)+1
       
       BL @VSYNCM
       BL @FLIP

       MOV R8,R1
       ANDI R1,1
       AI R1,-8
       BL @DOSPRT

       DEC R8
       JNE SCRLR2
       B @DONE






CAVOUT

       ;MOV  @DOOR,R5        ; Move link to door location
       ;AI R5,->0100         ; Move Y up one
       ;MOV R5,@HEROSP	    ; Update color sprite
       ;MOV R5,@HEROSP+4     ; Update outline sprite
       ;LI R0,>0100
       ;MOVB R0,@HEROSP+7    ; Set outline color to black

       ; fall thru
CAVEIN
       LI R0,SCRFLG
       XOR @FLAGS,R0  ; Set dest to flipped screen
       ANDI R0,SCRFLG
       AI R0,(3*32)+VDPWM
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address

       LI R0,>2000
       LI R9,(21*32)
!      MOVB R0,*R15         ; Clear the flipped screen with space
       DEC R9
       JNE -!
       
       BL @VSYNCM
       BL @FLIP
       LI R9,10            ; Delay 10 frames
!      BL @VSYNCM
       DEC R9
       JNE -!
       ; fall thru
CUT    
       LI R4,LEVELA     ; Set source to new screen
       LI  R9,22        ; Copy 22 lines
       LI R10,SCRFLG
       XOR @FLAGS,R10  ; Set dest to flipped screen
       ANDI R10,SCRFLG
       AI R10,(3*32)
!
       MOV R4,R0
       BL @READ32

       MOV R10,R0
       BL @PUTSCR      ; Write 32 bytes from scratchpad
       
       AI R4,32
       AI R10,32
       
       DEC R9
       JNE -!
       
       BL @VSYNCM
       BL @FLIP

       CLR R1
       BL @DOSPRT

       B @DONE



; Wipe screen from center
; R4 - pointer to new screen in VRAM
WIPE
       ;TODO turn on screen
       LI R0,>01E2          ; VDP Register 1: 16x16 Sprites
       BL @VDPREG

       LI   R8,16           ; Scroll through 16 columns

WIPE2

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM

; Copy two vertical strips from new screen to screen table

       LI  R4,LEVELA-1    ; Calculate left column source pointer
       A   R8,R4
       
       MOV @FLAGS,R3  ; Set dest to flipped screen
       ANDI R3,SCRFLG
       AI  R3,(32*3)-1+VDPWM  ; Calculate left column dest pointer with write flag
       A   R8,R3
       
       LI R9,22           ; Copy 22 characters
!      MOV R4,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       NOP
       MOVB *R6,R1
       AI R4,32

       MOV R3,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       AI R3,32
       
       DEC R9
       JNE -!

       LI  R4,LEVELA+32    ; Calculate right column source pointer
       S   R8,R4
       
       MOV @FLAGS,R3  ; Set dest to flipped screen
       ANDI R3,SCRFLG
       AI  R3,(32*3)+32+VDPWM  ; Calculate right column dest pointer with write flag
       S   R8,R3
       
       LI R9,22           ; Copy 22 characters
!      MOV R4,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       NOP
       MOVB *R6,R1
       AI R4,32

       MOV R3,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       AI R3,32
       
       DEC R9
       JNE -!

       DEC R8
       JNE WIPE2

       B @DONE



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


; Status sprites move by R0
STMOVE
       A R0,@MPDTSP
       A R0,@ITEMSP
       A R0,@ASWDSP
       A R0,@HARTSP
       LI R0,SPRTAB
       LI R1,SPRLST
       LI R2,4*4
       B @VDPW


; items that get copied to pattern table
; 80  ladder  raft   brown
; 88  magkey boomer  brown
; 90  arrows flute   brown
; 98  silver boomer  blue
; A0  bombs  candle  blue
; A8  letter potion  blue
; B0  magrod ring    blue
; B8  ring   book    red
; C0  powerb candle  red
; C8  meat   potion  red

; Raft (brown) Book (red) Ring (blue/red) Ladder (brown) Dungeon Key (brown) Power Bracelet (red)
; 30 32 34 36 38 3A
; 90  93   96   99   Boomerang (brown/blue) Bomb (blue) Bow/Arrow (brown/?) Candle (red/blue)
; D0  D3   D6   D9   Flute (brown) Meat (red) Scroll(brown)/Potion(red/blue) Magic Rod (blue)

ITEMS  ; [15-8]=sprite index [7-0]=screen offset
       DATA >4736  ; Ladder
       DATA >4430  ; Raft
       DATA >4838  ; Magic Key
       DATA >2590  ; Boomerang
       DATA >4A96  ; Arrows
       DATA >4BD0  ; Flute
       DATA >4A96  ; Silver arrows?
       DATA >2590  ; Magic Boomerang
       DATA >3193  ; Bombs
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
* Menu Colorset Definitions starting at char >80
****************************************
MCLRST BYTE >A1,>A1,>A1,>41            ;
       BYTE >41,>41,>41,>61            ;
       BYTE >61,>61

SELPOS BYTE >90,>93,>96,>99,>D0,>D3,>D6,>D9
       EVEN
; Get selected item sprite and color into sprite 62
; Modifies R0-R2,R4-5,R7-R10,R13   (R3,R6,R12 must be preserved)
GETSEL
       MOV @HFLAGS,R9
       ANDI R9,7
       MOVB @SELPOS(R9),R9   ; Get selected item pos

       LI R7,SPRPAT+(62*32)

       LI R5,ITEMS
       LI R8,20       ; Draw 20 items

!      MOV *R5+,R4

       ; TODO is item collected?

       CB R9,@R4LB
       JNE !

       ; Copy sprite
       BL @CPYITM

       ; Get color from menu colorset
       MOV R5,R1
       AI R1,-ITEMS-2
       SRL R1,2
       MOVB @MCLRST(R1),R1
       SRL R1,4
       MOVB R1,@ITEMSP+3   ; Put in sprite list
       LI R0,SPRTAB+ITEMSP-SPRLST+3
       BL @VDPWB           ; Put in VDP sprite table

!      DEC R8
       JNE -!!

       B @DONE4

; Copy item from sprite pattern to character pattern (or selected item sprite)
; R4=IIPP  II=sprite index PP=screen pos
; R7=destination VDP address
CPYITM
       MOV R11,R13      ; Save return address

       ; Copy sprite
       MOV R4,R0
       ANDI R0,>FF00

       CI R0,>4A00     ; is it bow and arrows?
       JNE !!!

       MOV @HFLAGS,R1
       ANDI R1,BOW+ARROWS
       JNE !
       ; TODO neither bow nor arrow
!      CI R1,BOW
       JNE !
       LI R0,>5200     ; Only Bow
!      CI R1,ARROWS
       JNE !
       LI R0,>2B00     ; Only Arrows
!
       SRL R0,3
       AI R0,SPRPAT
       BL @READ32      ; Get the sprite pattern
       MOV R7,R0
       BL @PUTSCR      ; Save it

       B *R13          ; Return to saved address




TIFORC ; bit [7]=3wide [6-4]=y offset [2-0]=x offset
;       BYTE 2+(0*16)  ; Tiforce 1 piece 10,11   2,0
;       BYTE 2+(2*16)  ; Tiforce 2 piece 10,13   2,2
;       BYTE 4+(2*16)  ; Tiforce 3 piece 12,13   4,2
;       BYTE 6+(2*16)  ; Tiforce 4 piece 14,13   6,2
;       BYTE 0+(3*16)  ; Tiforce 5 piece  8,14   0,3
;       BYTE 2+(4*16)+128  ; Tiforce 6 piece 10,15   2,4
;       BYTE 5+(4*16)+128  ; Tiforce 7 piece 13,15   5,4
;       BYTE 3+(6*16)+128  ; Tiforce 8 piece 11,17   3,6

       DATA >0011,>0000  ; 0 0 1 1 0 0 0 0
       DATA >0011,>0000  ; 0 0 1 1 0 0 0 0
       DATA >0022,>3344  ; 0 0 2 2 3 3 4 4
       DATA >5522,>3344  ; 5 5 2 2 3 3 4 4
       DATA >5566,>6777  ; 5 5 6 6 6 7 7 7
       DATA >0066,>6770  ; 0 0 6 6 6 7 7 0
       DATA >0008,>8700  ; 0 0 0 8 8 7 0 0
       DATA >0008,>8000  ; 0 0 0 8 8 0 0 0

; Translate 4 TIFORCE characters
; R0 = screen offset
; R3 = 4 nibbles
TIFROW
       MOV R11,R10    ; Save return address

       LI R2,4       ; Go through each nibble
TIFRO1
       MOV R3,R1
       SLA R3,4
       SRL R1,12  ; Todo Test this bit in collected tiforces

       JEQ TIFRO3

       ANDI R0,>3FFF  ; Clear VDPWD bit
       BL @VDPRB      ; Read 1 byte
       CI R1,>3A00    ; /
       JNE !
       AI R1,>0200    ; Change to |/
       JMP TIFRO2
!
       CI R1,>3B00    ; \
       JNE !
       AI R1,>0200    ; Change to \|
       JMP TIFRO2
!
       CI R1,>3C00
       JEQ TIFRO3     ; Don't change |/
       CI R1,>3D00
       JEQ TIFRO3     ; Don't change \|

       LI R1,>5B00    ; Solid []
TIFRO2
       BL @VDPWB
TIFRO3
       INC R0
       DEC R2
       JNE TIFRO1

       B *R10         ; Return to saved address

MENUDN
       LI R0,SPRTAB+(6*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       LI R0,SCHSAV
       BL @PUTSCR      ; Save a backup of scratchpad

       LI R0,SPRTAB+(4*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off hero sprites

       LI R6,VDPRD     ; Keep VDPRD address in R6

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
       ANDI R4,INCAVE
       JEQ !
       BL @CLRCAV      ; Clear cave
!

       LI R5,TIFORC    ; Draw TIFORCE collected
       LI R0,MENUSC+(32*11)+10     ; TiForce offset at 10,11
       LI R8,8        ; 8 rows

!      MOV *R5+,R3     ; Draw TIFORCE pieces
       BL @TIFROW
       MOV *R5+,R3
       BL @TIFROW
       AI R0,32-8
       DEC R8
       JNE -!


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

       LI R0,>0300+(MCLRTB/>40)  ; VDP Register 3: Color Table
       BL @VDPREG

       LI R5,ITEMS
       LI R7,PATTAB+(>80*8)
       LI R8,20       ; Draw 20 items
       LI R9,>8082    ; Use characters starting at 80

!      MOV *R5+,R4

       MOV R7,R0
       BL @READ32
       AI R0,PATSAV-PATTAB-(>80*8)
       BL @PUTSCR

       ; TODO is item collected?

       BL @CPYITM
       AI R7,32

       MOV @FLAGS,R0   ; Set dest to flipped screen
       ANDI R0,SCRFLG
       ANDI R4,>00FF
       A R4,R0         ; Add screen pos

       MOV R9,R1       ; Get character number
       BL @VDPWB       ; Draw characters from sprite pattern
       MOVB @R1LB,*R15
       AI R0,>20
       AI R1,>0101
       BL @VDPWB
       MOVB @R1LB,*R15
       AI R9,>0404

       DEC R8
       JNE -!

       LI R0,SPRPAT+(91*32)  ; Selector sprite
       BL @READ32
       LI R0,SPRPAT+(7*32)
       BL @PUTSCR

       B @DONE3

MENUUP
       LI R0,SCHSAV
       BL @PUTSCR      ; Save a backup of scratchpad

       LI R5,ITEMS
       LI R8,20       ; Erase 20 items
       MOV @FLAGS,R9   ; Set dest to flipped screen
       ANDI R9,SCRFLG

!      MOV *R5+,R0
       ANDI R0,>00FF
       A R9,R0         ; Add screen pos

       LI R1,>2020     ; Erase 2 characters
       BL @VDPWB
       MOVB @R1LB,*R15
       AI R0,>20       ; Next row
       BL @VDPWB
       MOVB @R1LB,*R15

       DEC R8
       JNE -!

       BL @VSYNCM
       LI R0,>0300+(CLRTAB/>40)  ; VDP Register 3: Color Table
       BL @VDPREG

       LI R6,VDPRD     ; Keep VDPRD address in R6
       LI R7,PATSAV
       LI R8,20       ; Erase 20 meta-patterns

!      MOV R7,R0        ; Restore saved pattern tables
       BL @READ32
       AI R0,PATTAB+(>80*8)-PATSAV
       BL @PUTSCR

       AI R7,32
       DEC R8
       JNE -!

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

       B @DONE3







* Draw the byte number in R1 as (right-justified) [space][space]n or [space]nn or nnn
* Used for price underneath items in caves
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBRJ
       MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1,>6400      ; R1 >= 100 decimal ?
       JHE NUMBE2
       LI R0,>2000
       MOVB R0,*R15     ; Write a space
       CI R1,>0A00      ; R1 < 10 decimal ?
       JL NUMBE4
       LI R0,>3000      ; 0 ascii
       JMP NUMBE3

* Draw the byte number in R1 as Xn[space] or Xnn or nnn
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBER MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1, >6400  ; 100 decimal
       JHE NUMBE2
       LI R0, >5800           ; X ascii
       MOVB R0,*R15        ; Write X
       LI R0, >3000             ; 0 ascii
       CI R1, >A00   ; 10 decimal
       JHE NUMBE3
       A R0,R1
       MOVB R1,*R15        ; Write second digit
       LI R1, >2000
       MOVB R1,*R15           ; Write a space
       RT

NUMBE2 LI R0, >3100           ; 1 ascii
       AI R1, ->6400    ; R1 -= 100
       CI R1, >6400     ; R1 < 100 ?
       JL !
       AI R1, ->6400
       LI R0, >3200           ; 2 ascii
!      MOVB R0,*R15           ; Write first digit
       LI R0, >3000           ; 0 ascii
       JMP NUMBE3
!      AI R0,>100
       AI R1, ->A00        ; R1 -= 10
NUMBE3 CI R1, >A00         ; 10 decimal
       JHE -!
NUMBE4 MOVB R0,*R15        ; Write second digit
       AI R1, >3000        ; 0 ascii
       MOVB R1,*R15        ; Write final digit
       RT

* Draw number of rupees, keys, bombs and hearts
* Modifies R0-R3,R7-R11,R13
STATUS CLR R1
       MOVB @RUPEES,R1
       MOV @FLAGS,R3
       ANDI R3,SCRFLG
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*0)+12  ; Write mask + screen offset + row 0 col 12
       BL @NUMBER             ; Write rupee count

       MOVB @KEYS,R1
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*1)+12  ; Write mask + screen offset + row 1 col 12
       BL @NUMBER             ; Write keys count

       MOVB @BOMBS,R1
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*2)+12  ; Write mask + screen offset + row 2 col 12
       BL @NUMBER             ; Write bombs count

       AI R3,VDPWM+SCR1TB+(32*2)+22  ; Write mask + screen offset + row 2 col 22
       ; R3 = lower left heart position
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       AI R3,-32              ; R3 = upper left heart position

       CLR R9
       MOVB @HEARTS,R9        ; R9 = max hearts - 1
       AI   R9,>100
       MOV  @HFLAGS,R0
       LI   R10,1             ; R10 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R9,R9             ; double max hp
       INC  R10               ; R10 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R9,R9             ; double max hp again
       INCT R10               ; R10 = 4 hp per half-heart
!
       A    R9,R9             ; double max hp for half-hearts
       SWPB R10
       ;  write hearts and move half-heart sprite
       CLR R2
       LI R0,>1F01            ; Full heart / empty heart
       LI R13,8               ; Countdown to move up
       LI R7,>0BAC            ; Half-heart sprite coordinates
       LI R8,>E400            ; Half-heart sprite index and color (invisible)
       MOVB @HP,R1            ; R1 = hit points
       JEQ HALFH
       C R1,R9
       JL FILLH
       MOV R9,R1              ; Set HP to max HP
       MOVB R1,@HP
FILLH
       A   R10,R2
       CB  R2,R1              ; Compare counter to HP
       JL !
       LI  R8,>E406           ; Half-heart sprite index and color (red)
       S   R10,R2
       JMP HALFH
!      A   R10,R2
       AI  R7,>0008
       MOVB R0,*R15           ; Draw heart
       DEC R13
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       LI R7,>03AC            ; Half-heart sprite coordinates
!      CB  R2,R1              ; Compare counter to HP
       JL FILLH
HALFH  MOV R7,@HARTSP         ; Save sprite coordinates
       MOV R8,@HARTSP+2       ; Save sprite index and color
       SWPB R0                ; Switch hearts
       LI R7,FULLHP
       C R2,R9                ; Compare to max hearts
       JL EMPTYH
       SOC R7,@FLAGS          ; Set full hp flag
       JMP STDONE
EMPTYH
       A   R10,R2
       A   R10,R2
       MOVB R0,*R15           ; Draw heart
       DEC R13
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
!      C R2,R9                ; Compare counter to max hearts
       JL EMPTYH
       SZC R7,@FLAGS          ; Clear full hp flag
STDONE
       B @DONE2



* Store characters R1,R2 at R5 in name table
* Modifies R0,R1,R3
STORCH
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

       ORI R0,VDPWM
       LI R3,2
!
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address

       MOVB R1,*R15
       MOVB @R1LB,*R15

       AI R0,32
       MOV R2,R1

       DEC R3
       JNE -!

       RT

* Scan objects for empty slot: store R4 index & data, R5 in location, R6 in sprite index and color
* Modifies R0,R1
OBSLOT
       LI R1,LASTOB      ; Start at slot 13
!      MOV *R1,R0
       JEQ !
       INCT R1
       CI R1,SPRLST
       JNE -!
       RT            ; Unable to find empty slot
!      MOV R4,*R1
       AI R1,-OBJECT+(SPRLST/2)
       A R1,R1
       AI R5,->0100       ; Adjust Y pos
       MOV R5,*R1+
       AI R5,>0100        ; Adjust Y pos
       MOV R6,*R1
       RT

* Armos spawn underneath
* Preserve R4-R6
*
ARMOSS
       C @DOOR,R5
       JNE !
       ; TODO bracelet
       ;LI R1,>7879    ; Green stairs
       ;LI R2,>7A7B    ; Green stairs
       LI R1,>7071    ; Red stairs
       LI R2,>7273    ; Red stairs

       JMP !!!
!
       ; ground, either yellow or gray
       LI R0,CLRTAB+27  ; Get palette entry for Armos chars
       BL @VDPRB
       CI R1,>4E00      ; black on gray
       JNE !
       LI R1,>0808      ; gray char
       MOV R1,R2
       JMP !!
!
       CLR R1
       CLR R2
!
       BL @STORCH
       B @DONE2




* These need to match tilda_b0.asm
CAVEID EQU >001F ; Cave NPC ID
ITEMID EQU >001B ; Cave item ID
TEXTID EQU >0024 ; Cave Message Texter ID


* Load NPC, text and items
CAVEIT
       MOVB @MAPLOC,R3
       SRL R3,8           ; R3 = map location
       MOVB @CAVMAP(R3),R3
       SRL R3,8           ; R3 = cavmap(R3)
       MOV R3,R10    ; R10 = item index

       DEC R3
       A R3,R3

       MOV R5,R7      ; Save NPC pos
       MOV @CAVDAT(R3),R9 ; Get NPC type and text offset

       MOV R9,R2
       SRL R2,11
       AI R2,NPCSPR
       MOV *R2+,R8       ; Get primary sprite
       MOV *R2+,R6       ; Get secondary sprite
       BL @OBSLOT        ; Spawn secondary sprite
       MOV *R2+,R1       ; Get background chars
       MOV *R2+,R2       ; Get background chars
       BL @STORCH        ; Draw background characters

       ; TODO case >10, letter must be shown to old woman


       LI R4,TEXTID   ; Cave message texter
       LI R5,>D200    ; Counter
       MOV R9,R6
       ANDI R6,>03FF
       AI R6,CAVTXT   ; Cave text in VDP RAM
       BL @OBSLOT

       ; load items
       LI R3,CAVTBL   ; Table of item groups
!      MOV *R3+,R6
       MOV R6,R9
       SLA R9,7      ; Get group bit in carry
       JNC -!
       DEC R10        ; Decrement item index until zero
       JNE -!

       LI R2,CAVLOC   ; Spawn cave items
!      CLR R4
       MOV *R2+,R5    ; Sprite location
       JEQ !
       ANDI R6,>FC0F  ; Get sprite
       LI R4,ITEMID   ; Object ID
       BL @OBSLOT     ; Note: returns object offset in R1

       MOV R1,R0
       SRL R0,2       ; Convert double-word offset to byte offset
       AI R0,ENEMHP   ; R0 = Object HP address

       SRL R9,11      ; Get item price index
       MOVB @IPRICE(R9),R1 ; R1 = item price
       BL @VDPWB      ; Store item price in object HP

       MOVB R1,R4
       JEQ !          ; Don't draw if zero

       ; Convert pixel coordinate YYYYYYYY XXXXXXXX R5
       ; to character coordinate        YY YYYXXXXX R0
       ANDI R5,>F8F8
       MOV R5,R0
       SRL R0,3
       MOVB R0,R5
       SRL R5,3
       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       A R5,R0

       AI R0,VDPWM+(3*32)-1  ; Adjust position to 3 lines down and 1 left
       BL @NUMBRJ     ; Display item price R1 right-justified at R0

!      MOV *R3+,R6
       MOV R6,R9
       SLA R9,7      ; Get group bit in carry
       JNC -!!

       MOVB R4,R4
       JEQ !         ; Draw rupee and X
       LI R4,CAVEID
       LI R5,>8430  ; Rupee loc
       LI R6,>C00A   ; Rupee sprite
       BL @OBSLOT

       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       AI R0,32*17+8
       LI R1,'X'*256
       BL @VDPWB

!
       LI R4,CAVEID   ; Restore object id
       MOV R7,R5      ; Restore position
       MOV R8,R6      ; Restore sprite

       B @DONE2       ; return to bank0



* Dungeon starting positions
DUNGSP   ;    1   2   3   4   5   6   7   8   9
       BYTE >73,>7D,>7C,>71,>76,>79,>F1,>F6,>FE
       EVEN
* Go into door or something. R3=tile at our position
GODOOR
       LI R4,INCAVE

       MOVB @MAPLOC,R1
       SRL R1,8
       CLR R0
       MOVB @CAVMAP(R1),R0  ; get cave entry

       CI R0,>1800     ; raft?
       JNE !



       ; riding the raft here
       LI R0,>1000
       SB R0,@MAPLOC
       LI R2,1 ; scroll up
       CLR R4
       JMP !!
!
       LI   R2,6             ; Use cave animation

       CI R0,>2000
       JL !            ; entering dungeon if starting with 2X

       MOV R0,R4
       LI R0,MAPSAV    ; Save overworld map location in VDP ram
       MOVB @MAPLOC,R1
       BL @VDPWB

       SRL R4,8
       AI R4,->21            ; R4=dungeon level 0-8
       MOVB @DUNGSP(R4),R1   ; dungeon starting position
       MOVB R1,@MAPLOC

       SLA R4,12             ; Get dungeon level in >X000
       ORI R4,DUNGON         ; Set dungeon flag
!      SOC R4,@FLAGS         ; Set in cave or dungeon flag

       MOV R12,R11

       LI   R0,BANK2         ; Overworld is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       B    @BANKSW


* Cave map, index of item group in CAVTBL
CAVMAP BYTE >00,>05,>00,>05,>10,>29,>17,>05,>00,>00,>02,>25,>17,>10,>04,>0F
       BYTE >06,>00,>14,>0E,>05,>00,>06,>00,>00,>00,>11,>00,>07,>22,>05,>06
       BYTE >00,>03,>26,>0B,>19,>16,>00,>10,>0E,>00,>00,>00,>08,>0E,>00,>08
       BYTE >00,>00,>00,>10,>15,>00,>00,>21,>00,>1B,>00,>00,>22,>0E,>00,>18
       BYTE >00,>00,>27,>1B,>16,>24,>14,>08,>0E,>0C,>16,>10,>14,>00,>0D,>00
       BYTE >00,>0D,>00,>00,>00,>18,>0D,>00,>00,>00,>00,>00,>00,>00,>00,>1A
       BYTE >00,>00,>0F,>05,>10,>00,>17,>0E,>05,>00,>05,>0F,>00,>28,>00,>16
       BYTE >11,>0E,>00,>00,>23,>13,>06,>01,>10,>09,>00,>08,>06,>05,>00,>00
       ; 18: Raft ride
       ; 19: Power bracelet under armos
       ; 1A: Heart container on ground
       ; 1B: Fairy Pond
       ; 2X: indicates entrance to level X


CAVLOC DATA >7078,>7058,>7098  ; Center, left, right, leftmost  (merchant)
STAIRS DATA >8878,>8848,>88A8  ; Center, left, right   (stairs)

* Cave sprite table: index and color SSSSSSuu uuuuCCCC S=sprite index C=color
* u=6 bit index into price table, or
*     indicator of npc sprites and background tiles, or
*     indicator of fire sprites and background tiles, or
*     indicator of background tiles


OLDMAN EQU >0000 ; Old man NPC
CAVMOB EQU >4000 ; Cave moblin NPC
OLDWOM EQU >8000 ; Old woman NPC
MERCH  EQU >C000 ; Merchant NPC

* Cave npc type and text offsets (numbers are printed during cave string generation: ./tools/txt)
CAVDAT DATA OLDMAN+0         ; 1 IT'S DANGEROUS TO GO\ALONE! TAKE THIS.
       DATA OLDMAN+40        ; 2 MASTER USING IT AND\YOU CAN HAVE THIS.
       DATA OLDMAN+40        ; 3 MASTER USING IT AND\YOU CAN HAVE THIS.
       DATA OLDMAN+80        ; 4 SHOW THIS TO THE\OLD WOMAN.
       DATA OLDMAN+109       ; 5 PAY ME FOR THE DOOR\REPAIR CHARGE.
       DATA OLDMAN+145       ; 6 LET'S PLAY MONEY\MAKING GAME.
       DATA OLDMAN+176       ; 7 SECRET IS IN THE TREE\AT THE DEAD-END.
       DATA OLDMAN+216       ; 8 TAKE ANY ONE YOU WANT.
       DATA OLDMAN+240       ; 9 TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; A TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; B TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; C TAKE ANY ROAD YOU WANT.
       DATA CAVMOB+265       ; D IT'S A SECRET\TO EVERYBODY.
       DATA CAVMOB+265       ; E IT'S A SECRET\TO EVERYBODY.
       DATA CAVMOB+265       ; F IT'S A SECRET\TO EVERYBODY.
       DATA OLDWOM+294       ; 10 BUY MEDICINE BEFORE\YOU GO.
       DATA OLDWOM+323       ; 11 PAY ME AND I'LL TALK.
       DATA OLDWOM+323       ; 12 PAY ME AND I'LL TALK.
       ;DATA 346       ; THIS AIN'T ENOUGH TO TALK.
       ;DATA 374       ; GO NORTH,WEST,SOUTH,\WEST TO THE FOREST\OF MAZE.
       ;DATA 424       ; BOY, YOU'RE RICH!
       ;DATA 443       ; GO UP,UP THE MOUNTAIN AHEAD.
       DATA OLDWOM+474       ; 13 MEET THE OLD MAN\AT THE GRAVE.
       DATA MERCH+506       ; 14 BOY, THIS IS\REALLY EXPENSIVE!
       DATA MERCH+506       ; 15 BOY, THIS IS\REALLY EXPENSIVE!
       DATA MERCH+538       ; 16 BUY SOMETHIN' WILL YA!
       DATA MERCH+538       ; 17 BUY SOMETHIN' WILL YA!

NPCSPR ;    SPR1  SPR2  BGCH1 BGCH2
       DATA >500A,>5406,>2324,>2829  ; 2 Old man skin, robe
       DATA >5806,>0000,>2020,>2020  ; Moblin "IT'S A SECRET\TO EVERYBODY."
       DATA >400A,>4406,>5C5D,>2829  ; Old woman sprites
       DATA >480A,>4C02,>BCBD,>BEBF  ; Merchant sprites
*FIRECH DATA >2020,>5E5F  ; Fire background chars
*       DATA >7879,>7A7B  ; Warp Stairs background chars

CAVTBL ; SSSSSSGx PPPPCCCC  S=sprite index G=group bit P=price index C=color
       DATA >7E08      ; 1 Wood sword "IT'S DANGEROUS TO GO\ALONE! TAKE THIS."
       DATA >7E0F      ; 2 White sword "MASTER USING IT AND\YOU CAN HAVE THIS." (5h)
       DATA >5609      ; 3 Magic sword "MASTER USING IT AND\YOU CAN HAVE THIS." (12h)
       DATA >2A04      ; 4 Letter "SHOW THIS TO THE\OLD WOMAN."
       DATA >C20A      ; 5 -20 rupees TODO door repair charge

       DATA >C20A,>C00A,>C00A  ; 6 Rupees "LET'S PLAY MONEY\MAKING GAME."
       DATA >0200      ; 7 "SECRET IS IN THE TREE\AT THE DEAD-END." TODO
       DATA >0200,>2C06,>2006 ; 8 red potion, heart container "TAKE ANY ONE YOU WANT."
       DATA >0200,>0000,>0000 ; 9 warp stairs 1 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; A warp stairs 2 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; B warp stairs 3 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; C warp stairs 4 "TAKE ANY ROAD YOU WANT."

       DATA >C20A    ; D: 10 rupees
       DATA >C20A    ; E: 30 rupees
       DATA >C20A    ; F: 100 rupees

       DATA >0200,>2C54,>2C86  ; 10: Blue potion(40), red potion(68) "BUY MEDICINE BEFORE\YOU GO." (2nd line left aligned)
       DATA >C24A,>C02A,>C06A  ; 11: 10 30 50 "THIS AIN'T ENOUGH TO TALK" "GO NORTH WEST SOUTH WEST" "BOY,YOU'RE RICH"
       DATA >C22A,>C01A,>C03A  ; 12: 5 10 20 "THIS AIN'T ENOUGH TO TALK" "THIS AIN'T ENOUGH TO TALK" "GO UP,UP THE MOUNTAIN AHEAD"
       DATA >0200      ; 13: "MEET THE OLD MAN\AT THE GRAVE" TODO

       DATA >36B9,>3CA9,>C826  ; 14: Shield(90) bait(100) heart(10) "BOY, THIS IS\REALLY EXPENSIVE!"
       DATA >32E4,>249B,>3476  ; 15: Key(80) bluering(250) bait(60) "BOY, THIS IS\REALLY EXPENSIVE!"
       DATA >C634,>3CC9,>AC9B  ; 16: Shield(130) bomb(20) arrow(80) "BUY SOMETHIN' WILL YA!"
       DATA >26BB,>3CD9,>3874  ; 17: Shield(160) key(100) candle(60) "BUY SOMETHIN' WILL YA!"

       DATA >0200 ; Terminating group bit

* cave item prices (stored in object hp)
*           0 1 2  3  4  5  6  7  8  9  A  B   C   D   E
IPRICE BYTE 0,5,10,20,30,40,50,60,68,80,90,100,130,160,250
       EVEN
