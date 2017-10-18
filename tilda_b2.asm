;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 2: overworld map and transition functions
;

       COPY 'tilda.asm'

       
; Load a map into VRAM
; Load map screen from MAPLOC
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
; Modifies R0-R12,R15
MAIN
       MOV R11,R12          ; Save return address for later

       LI R0,SPRTAB+(6*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

       CI R2,8
       JNE !
       B @MENUDN      	   ; Do item select screen
!      CI R2,9
       JNE !
       B @MENUUP      	   ; Do item select screen
!
       LI R0,OBJECT+12      ; Clear objects[6..31]
       LI R1,32-6
!      CLR *R0+
       DEC R1
       JNE -!


       MOV R2,R3
       CI R3,5              ; Load initial color table on WIPE
       JNE !

       BL @GETSEL

       ;LI   R0,PATTAB         ; Pattern table starting at char 0
       ;LI   R1,PAT0
       ;LI   R2,256*8
       ;BL   @VDPW

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
       LI   R10,LEVELA+VDPWM ; R0 is screen table address in VRAM (with write bits)
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

       LI   R6,VDPRD        ; Keep VDPRD address in R6
       
       A    R2,R2
       MOV  @JMPLST(R2),R2
       B    *R2

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

       B @LENEMY

DONE3
       LI R0,SCHSAV
       BL @READ32            ; Restore saved scratchpad

       MOV @HEROSP,R5        ; Get hero YYXX
       AI R5,>0100           ; Move Y down one

       LI   R0,BANK0         ; Load bank 0
       MOV  R12,R1           ; Jump to our return address
       B    @BANKSW



JMPLST DATA DONE,SCRLUP,SCRLDN,SCRLLT,SCRLRT,WIPE,CAVEIN,CAVOUT

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

CLRCAV
       LI R1,>2020  ; ASCII space
       LI R8,16     ; clear 16 lines
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

CAVEIN
       LI R9,16             ; Step down 16 lines

       CLR R1
       MOVB R1,@SCRTCH      ; Clear top line
       
STEPDN LI R4, 4             ; Step downward first four sprites
       LI R0,SPRPAT         ; Read 1st sprite pattern
!      LI R1,SCRTCH+1       ; Write to scratchpad
       BL @READ31
       CLR R1
       MOVB R1,@SCRTCH+16  ; Clear top right edge
       BL @PUTSCR
       
       AI R0,-VDPWM+32   ; Clear write bit and add 32
       DEC R4
       JNE -!

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM

       DEC R9
       JNE STEPDN

       ;LI R0,>0400
       ;MOVB R0,@HEROSP+7    ; Set outline color to blue

       JMP !
CAVOUT
       MOV  @DOOR,R5        ; Move link to door location
       AI R5,->0100         ; Move Y up one
       MOV R5,@HEROSP	    ; Update color sprite
       MOV R5,@HEROSP+4     ; Update outline sprite
       ;LI R0,>0100
       ;MOVB R0,@HEROSP+7    ; Set outline color to black

!
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

SELPOS BYTE >90,>93,>96,>99,>D0,>D3,>D6,>D9
; Get selected item sprite and color into sprite 62
; Modifies R0-R2,R4-5,R7-R10,R13   (R3,R6,R12 must be preserved)
GETSEL
       MOV R11,R10    ; Save return address

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

       B *R10           ; Return to saved address

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


; Load enemies
LENEMY
       MOVB @MAPLOC,R1         ; Get map location
       SRL R1,8

       LI R9,LASTOB        ; Start filling the object list at last index

       MOV @FLAGS,R0
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

       LI R9,OBJECT+24      ; Read objects
       LI R4,32-12
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

       B @DONE3

LCAVE

       LI R8,LASTSP
!      CLR *R8+
       CI R8,WRKSP+256        ; Clear sprite table
       JNE -!

       LI R0,BANK3
       LI R1,MAIN
       LI R2,4                ; Link face direction up
       BL @BANKSW

       LI R9,5                ; Link walks upward for 5 frames
!      BL @VSYNCM             ; FIXME link isn't visible yet due to sprite animation
       LI R1,->100
       BL @DOSPRT

       DEC R9
       JNE -!

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM


       LI R5,SPRPAT+(77*32)   ; copy cave item sprites
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

       B @DONE3

CAVDAT DATA >D05F,>5748,>0000 ; Flame object id, location, sprite
       DATA >D05F,>57A8,>0000 ; Flame object id, location, sprite
       DATA >C0DF,>5778,>D00F ; Old man object id, location, sprite





****************************************
* Enemy pattern indexes (XXYZ -> XX = source pattern offset, Y = dest index*4+20, Z = count)
* Y table 0:20 1:28 2:30 3:38 4:40 5:48 6:50 7:58 8:60 9:68
****************************************
ENEMYP DATA >2C84  ; 0 Armos
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
       BYTE >00     ; 17  fairy
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

       EVEN

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


DOORS  BYTE >00,>19,>00,>47,>1C,>65,>00,>4A,>00,>00,>12,>47,>18,>19,>45,>48
       BYTE >19,>00,>18,>12,>1C,>00,>16,>00,>00,>00,>46,>00,>4B,>35,>1C,>46
       BYTE >00,>59,>47,>54,>00,>1A,>13,>1E,>6D,>00,>00,>00,>69,>15,>00,>46
       BYTE >00,>00,>00,>1A,>44,>00,>00,>47,>00,>00,>00,>00,>47,>49,>00,>46
       BYTE >00,>00,>56,>00,>14,>48,>79,>7B,>2D,>35,>1B,>2B,>00,>6D,>4A,>00
       BYTE >00,>69,>00,>00,>00,>48,>6A,>00,>00,>00,>00,>62,>00,>00,>17,>00
       BYTE >00,>00,>28,>66,>17,>00,>17,>17,>62,>00,>6C,>68,>00,>2A,>00,>13
       BYTE >1B,>15,>00,>00,>48,>12,>16,>14,>64,>59,>00,>19,>16,>16,>00,>00

; 01 Sword - it's dangerous to go alone! take this.
; 02 Red medicine or heart container
; 03 Let's play money making game
; 04 -20
; 05 10
; 06 30
; 07 100
; 08 160 shield 100 key 60 candle
; 09 90 shield 100 bait 10 heart
; 0a 80 key 250 blue ring 60 bait
; 0b 130 shield 20 bomb 80 arrows
; 0c 40 blue medicine 68 red medicine
; 0d take this to the old woman (letter)
; 0d meet the old man at the grave
; 0e (pay me and I'll talk. 10,30,50 >=30) go north,west,south,west to the forest of maze.
;    (pay me and I'll talk. ) secret is in the tree at the dead-end.
;    (pay me and I'll talk. 5,10,20 >=20)  go up,up, the mountain ahead
;    white Sword - master using it and you can have this.
;    dungeon entrance
;    raft ride
;     (pay me and I'll talk. / This ain't enough to talk)
       
       
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
       DATA >001B,>00EF  ; Water inner corner SE
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
* Colorset Definitions                  
****************************************
CLRSET BYTE >1B,>1E,>4B,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >6B,>1B,>16,>1C            ;
       BYTE >1C,>1C,>CB,>6B            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>1B,>4B            ;
       BYTE >4B,>4B,>1F,>41           ;

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
