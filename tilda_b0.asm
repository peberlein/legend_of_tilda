;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 0: initialization and main loop
;

       COPY 'tilda.asm'
MAIN
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

       LI R0,BANK3           ; Title screen in bank 3
       LI R1,MAIN
       CLR R2               ; Mode = 0 title screen
       BL   @BANKSW

       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG
       LI R0,>07F1          ; VDP Register 7: White on Black
       BL @VDPREG

;       LI   R0,CLRTAB+VDPWM   ; Clear the palette
;       LI   R1,>1100          ; Black on black
;       LI   R2,32
;       MOVB @R0LB,*R14
;       MOVB R0,*R14
;!      MOVB R1,*R15
;       DEC  R2
;       JNE -!

       LI R0,>0000           ; Initial Rupees
       MOVB R0,@RUPEES
       LI R0,>0000           ; Initial Keys
       MOVB R0,@KEYS
       LI R0,>0000           ; Initial Bombs
       MOVB R0,@BOMBS
       LI R0,>0400           ; Initial Hearts-1
       MOVB R0,@HEARTS

       CLR R0
       LI R0,MAGSHD+RAFT      ; Test initial magic shield
       MOV R0,@HFLAGS     ; TODO get hero flags from save data
       CLR R0
       MOV R0,@HFLAG2

RESTRT
       CLR @FLAGS         ; Reset flags
       CLR @HURTC         ; Reset hurt counter

       LI   R0,BANK1         ; Music is in bank 1
       LI   R1,HDREND        ; First function in bank 1
       CLR  R2               ; Overworld song is 0
       BL   @BANKSW

       
       LI   R0,SPRLST         ; Initial Sprite List Table
       LI   R1,SPRL0
       LI   R2,SPRLE-SPRL0
!      MOV *R1+,*R0+
       DECT R2
       JNE -!
       BL @SPRUPD

       ;LI   R0,>7700         ; Initial map location is 7,7 (5,3 is by fairy)(3,7 is D-1)
       LI R0,>5500
       MOVB R0,@MAPLOC

       LI R0,>0A00           ; Initial HP
       ;LI R0,>0100
       MOVB R0,@HP

       CLR @FLAGS


       LI R9,32-6
       LI R1,OBJECT+12     ; Clear object table, starting at sword
!      CLR *R1+
       DEC R9
       JNE -!

       BL @GETSEL

       BL @STATUS            ; Draw status

       LI   R0,BANK3         ; Overworld tiles in bank 2
       LI   R1,MAIN          ; First function in bank 1
       LI   R2,1             ; load overworld tiles
       BL   @BANKSW

       LI   R0,BANK2         ; Overworld screen is in bank 2
       LI   R1,MAIN          ; First function in bank 1
       BL   @BANKSW

       BL   @WIPE            ; Do wipe animation

       CLR @MOVE12

       CLR @KEY_FL

       LI R5,>7078        ; Link Y X position in pixels
       LI R3,DIR_DN       ; Initial facing down
       LI R11,INFLP
       B @DRAW            ; Load facing sprites


VDPINI
       BYTE >00          ; VDP Register 0: 00
       BYTE >E2          ; VDP Register 1: 16x16 Sprites
       BYTE >00          ; VDP Register 2: 00
       BYTE >00+(CLRTAB/>40)  ; VDP Register 3: Color Table
       BYTE >00+(PATTAB/>800) ; VDP Register 4: Pattern Table
       BYTE >00+(SPRTAB/>80)  ; VDP Register 5: Sprite List Table
       BYTE >00+(SPRPAT/>800) ; VDP Register 6: Sprite Pattern Table
       BYTE >F1          ; VDP Register 7: White on Black


INFLP
       ;LI   R0,>07FF          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @VSYNCM              ; wait for Vsync and play music

       ;LI   R0,>07F1          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @SPRUPD

       LI R0,BANK5
       LI R1,MAIN
       CLR R2               ; do moving objects
       BL @BANKSW


INPUT
       BL @COUNT

       ;LI   R0,>07FE          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @DOKEYS

       MOV @KEY_FL, R0
       SLA R0,1             ; Shift EDG_C bit into carry status
       JNC MENUX
       B @DOMENU
MENUX

       MOV @HEROSP,R5    ; Hero YYXX position

       MOVB @HURTC,R4   ; Hurt counter
       JEQ !
       BL @LNKHRT
!

       MOV @FLAGS,R3
       ANDI R3,DIR_XX    ; Get direction in R3

       MOVB @SWRDOB,R0   ; Sword animation counter
       JNE !

       MOV @KEY_FL,R0
       SLA R0,2          ; Shift EDG_B bit into carry status
       JNC ITEMX

       MOV @HFLAGS,R1    ; Get selected item
       ANDI R1,SELITM
       A R1,R1
       MOV @ITEMFN(R1),R1 ; Get function for item
       B *R1
ITEMX ; item done


       MOV @KEY_FL,R0
       SLA R0,3          ; Shift EDG_A bit into carry status
       JNC !

       LI R0,>0C00       ; Sword animation is 12 frames
       MOVB R0,@SWRDOB
!

; Up/down movement has priority over left/right, unless there is an obstruction

       MOVB @HURTC,R0   ; Hurt counter
       CI R0,>A000      ; compare to 40<<10
       JHE !

       MOV @KEY_FL,R0
       SRC R0,3
       JOC MOVEDN

       MOV @KEY_FL,R0
       SRC R0,2
       JOC MOVEUP

HKEYS
       MOV @KEY_FL,R0
       SRC R0,4
       JOC MOVELT

       MOV @KEY_FL,R0
       SRC R0,5
       JOC MOVERT
!

       BL  @SWORD           ; Animate sword if needed

       B @DRAW




MOVEDN
       LI R3,DIR_DN
       BL @SWORD

       CI R5,(192-8)*256   ; Check at bottom edge of screen
       JL !
       BL @SCRNDN     ; Scroll down
       LI R3,DIR_DN
!
       MOV R5,R0
       AI R0,>1004    ; 16 pixels down, 4 right
       LI R2,VSOLID
       BL @TESTCH
       MOV R5,R0
       AI R0,>100C    ; 16 pixels down, 12 right
       BL @TESTCH

       MOV R5,R0     ; Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVED2     ; Already aligned
       ANDI R0,>0004
       JEQ MOVEL3
       JMP MOVER3

MOVEUP
       LI R3,DIR_UP
       BL @SWORD
       
       CI R5,25*256  ; Check at top edge of screen
       JHE !
       BL @SCRNUP     ; Scroll up
       LI R3,DIR_UP
!      
       MOV R5,R0
       AI R0,>0704    ; 7 pixels down, 4 right
       LI R2,VSOLID
       BL @TESTCH
       MOV R5,R0
       AI R0,>070C    ; 7 pixels down, 12 right
       BL @TESTCH

       MOV R5,R0     ; Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVEU2     ; Already aligned
       ANDI R0,>0004
       JEQ MOVEL3
       JMP MOVER3

MOVERT
       LI R3,DIR_RT
       BL @SWORD

       MOV R5,R0     ; Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ MOVER2     ; Already aligned
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
MOVELT
       LI R3,DIR_LT
       BL @SWORD

       MOV R5,R0    ; Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ MOVEL2    ; Already aligned
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
       
       
MOVER2 MOV R5,R0     ; Check at right edge of screen
       ANDI R0,>00FF
       CI R0,256-16
       JNE !
       BL @SCRNRT     ; Scroll right

!      LI R3,DIR_RT
       MOV R5,R0
       AI R0,>0810    ; 8 pixels down, 16 right
       LI R2,HSOLID
       BL @TESTCH

MOVER3 INC R5        ; Move X coordinate right
       INV @MOVE12
       JEQ !          ; Check if additional movement needed
       MOV R5,R1
       ANDI R1,>0007  ; Check if 8-pixel aligned
       JEQ !
       INC R5        ; Add additional movement if not aligned
!      MOV R5, R1
       SWPB R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

MOVEL2 MOV R5,R0     ; Check at left edge of screen
       ANDI R0,>00FF
       JNE !
       BL @SCRNLT     ; Scroll left

!      LI R3,DIR_LT
       MOV R5,R0
       AI R0,>07FF  ; 8 pixels down, 1 left
       LI R2,HSOLID
       BL @TESTCH
       
MOVEL3 DEC R5        ; Move X coordinate left
       INV @MOVE12    ; Check if additional movement needed
       JEQ !
       MOV R5,R1
       ANDI R1,>0007  ; Check if 8-pixel aligned
       JEQ !
       DEC R5        ; Add additional movement if not aligned
!      MOV R5, R1
       SWPB R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

MOVED2 AI R5,>0100   ; Move Y coordinate down
       INV @MOVE12     ; Check if additional movement needed
       JEQ !
       MOV R5,R1
       ANDI R1,>0700  ; Check if 8-pixel aligned
       JEQ !
       AI R5,>0100   ; Add additional movement if not aligned
!      MOV R5,R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       
MOVE2  
       C @DOOR,R5
       JNE MOVE3
       BL @GODOOR

       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       CLR R1
MOVE3
       MOVB R1,@HEROSP+2       ; Set color sprite index
       AI R1,>0400
       MOVB R1,@HEROSP+6       ; Set outline sprite index

MOVE4  JMP DRAW


MOVEU2 AI R5,>FF00   ; Move Y coordinate up
       INV @MOVE12     ; Check if additional movement needed
       JEQ !
       MOV R5,R1
       ANDI R1,>0700  ; Check if 8-pixel aligned
       JEQ !
       AI R5,>FF00   ; Add additional movement if not aligned
!      MOV R5,R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

; Update hero sprite location and sprite patterns
; R5=YYXX
; Load sprite patterns for hero facing direction
; R3=FACE{DN,RT,LT,UP}
; Modifies R0-2,R10
DRAW
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite

LNKSPR
       MOV @FLAGS,R0
       MOV R0,R1
       ANDI R0,DIR_XX
       ANDI R1,DUNLVL  ; Test for dungeon (sprite masking needed at doors)
       JEQ LNKSP1

       CLR R1
       BL @DOSPRT     ; update hero sprite location in VDP
       LI R2,2        ; Load hero sprites
       BL @MASKSP     ; modifies R2 if masking is needed, R4 is count
       JMP LNKSP4

LNKSP1 C R3,R0        ; Update facing if up/down was pressed against a wall
       JEQ INFLP2
       LI R2,2       ; Load hero sprites
LNKSP4 LI R0,DIR_XX
       SZC R0,@FLAGS
       SOC R3,@FLAGS
LNKSP2
       LI R0,BANK4   ; Load the new sprites
       LI R1,MAIN
       BL @BANKSW
INFLP2
       B @INFLP


; Draw masked sprites if going thru dungeon door
MASKSP
       LI R4,>2800  ; Top of screen
       C R5,R4
       JHE !
       S R5,R4
       SRL R4,8
       INC R4
       LI R2,8       ; Mask top
       RT
!
       LI R4,>A8FF ; Bottom of screen
       C R5,R4
       JLE !
       S R5,R4
       NEG R4
       SRL R4,8
       INC R4
       LI R2,7       ; Mask bottom
       RT
!
       SWPB R5      ; Change to XXYY

       LI R4,>1000  ; Left of screen
       C R5,R4
       JHE !
       S R5,R4
       SRL R4,8
       INC R4
       LI R2,5       ; Mask left
       SWPB R5
       RT
!
       LI R4,>E0FF  ; Left of screen
       C R5,R4
       JLE !
       S R5,R4
       NEG R4
       SRL R4,8
       INC R4
       LI R2,6       ; Mask right
       SWPB R5
       RT
!
       SWPB R5     ; Restore to YYXX
       RT

; jumped to by TESTCH with char in R1
VSOLID
       BL @SOLID     ; armos touched? push block?
       B @HKEYS

HSOLID
       BL @SOLID     ; armos touched? push block?
       B @MOVE4


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

* Dungeon starting positions
DUNGSP   ;    1   2   3   4   5   6   7   8   9
       BYTE >73,>7D,>7C,>71,>76,>79,>F1,>F6,>FE
       EVEN

* Go into doorway or stairs or dock(raft)
GODOOR
       MOV R11,R13    ; FIXME this gets overwritten by calling ANDOOR

       LI R8,SWRDSP
!      CLR *R8+
       CI R8,WRKSP+256        ; Clear sprite table
       JNE -!

       MOV R5,R0
       LI R2,GODOO2
       BL @TESTCH
       ; Either stairs or dock
       CI R1,>7C00    ; Green dock char
       JEQ RAFTUP
       CI R1,>1C00    ; Red dock char
       JEQ RAFTUP

       LI R9,16   ; delay 16 frames
!      BL @VSYNCM
       DEC R9
       JNE -!

       JMP GODOO3

GODOO2 ; Solid tile means Cave/Doorway
       CLR R9
       LI R10,3
!
       BL @ANDOOR       ; Animate going in the door

       LI R0,BANK4
       LI R1,MAIN
       LI R2,7          ; Load masked sprites at bottom
       LI R3,DIR_UP
       INC R9
       MOV R9,R4       ; R4=number of lines to mask
       BL @BANKSW
       AI R5,>0100     ; Move down

       CI R9,16
       JNE -!

GODOO3
       MOVB @MAPLOC,R1
       SRL R1,8
       CLR R2
       MOVB @CAVMAP(R1),R2  ; get cave entry
       MOVB R2,@CAVTYP      ; store it

       ;CI R2,>1800     ; raft?
       ;JEQ RAFTUP

       CI R2,>2000
       JHE GODUNG            ; entering dungeon if starting with 2X

       LI R4,INCAVE
       SOC R4,@FLAGS         ; Set in cave or dungeon flag

       LI   R0,BANK2         ; Overworld/deungon is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       BL   @BANKSW

       LI   R0,>B178        ; Put hero at cave entrance
       MOV  R0,@HEROSP      ; Update color sprite
       MOV  R0,@HEROSP+4    ; Update outline sprite

       BL   @CAVEIN

GODOO5

       LI R0,BANK4           ; Hero sprites in bank 4
       LI R1,HDREND          ; First function in bank 4
       LI R2,2               ; Load hero sprites
       LI R3,DIR_UP
       BL @BANKSW

       ; TODO animate up movement

       LI R9,5                ; Hero walks upward for 5 frames
!      BL @VSYNCM
       LI R1,->100
       BL @DOSPRT
       DEC R9
       JNE -!

       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM

       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       LI R2,2       ; Load hero sprites
       B @LNKSP2



* Ride the raft upward, or return to R13 if no raft
RAFTUP
       LI R0,RAFT
       CZC @HFLAGS,R0
       JNE !
       B *R13     ; dock - no raft
!
       LI R7,->0100          ; Move up
       MOV R5,R8
       ANDI R8,>00FF
       ORI R8,>1800
RAFTGO

       LI R0,SPRPAT+(>110*8) ; Raft sprite pattern
       BL @READ32            ; Get the sprite pattern
       LI R0,SPRPAT+(>1C*8)  ; extra hero sprite pattern
       BL @PUTSCR            ; Save it

       LI R0,RAFTSC          ; Raft sprite and color
       MOV R0,@SWRDSP+2

       LI R1,SWRDSP+4        ; Clear remaining sprites and scratchpad
!      CLR *R1+
       CI R1,SPRLST+>80
       JNE -!
!
       A R7,R5               ; Move Y up one
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       MOV R5,R0
       AI R0,>0600
       MOV R0,@SWRDSP        ; Use sword index for raft

       BL @SPRUPD

       BL @VSYNCM
       C R5,R8
       JNE -!

       CLR @SWRDSP+2       ; hide raft
       CI R7,->0100    ; going up?
       JEQ SCRNUP

       B @INFLP

GODUNG
       LI R0,MAPSAV    ; Save overworld map location in VDP ram
       MOVB @MAPLOC,R1
       BL @VDPWB

       SRL R2,8
       AI R2,->20            ; R4=dungeon level 1-9
       MOVB @DUNGSP-1(R2),R1 ; dungeon starting position
       MOVB R1,@MAPLOC

       SLA R2,12             ; Get dungeon level in >X000
       SOC R2,@FLAGS         ; Store dungeon level

       BL @CLRSCN          ; clear screen before updating tiles

       LI R0,BANK3
       LI R1,MAIN
       LI R2,2             ; Load dungeon tileset
       BL @BANKSW

       LI   R0,BANK2         ; Overworld/deungon is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       BL   @BANKSW

       BL   @WIPE

       LI   R0,>B178        ; Put hero at cave entrance
       MOV  R0,@HEROSP      ; Update color sprite
       MOV  R0,@HEROSP+4    ; Update outline sprite
       CLR  R1
       BL   @DOSPRT

       B @GODOO5

RAFTDN
       LI R7,>0100          ; Move down
       MOV @DOOR,R8         ; Stop here
       JMP RAFTGO


SCRNRT LI   R0,>0100         ; Add 1 to MAPLOC X
       AB   R0,@MAPLOC
       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW
       BL   @SCRLRT
       MOV  @HEROSP,R5
       B    @DRAW

SCRNLT LI   R0,>FF00         ; Add -1 to MAPLOC X
       AB   R0,@MAPLOC
       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW
       BL   @SCRLLT
       MOV  @HEROSP,R5
       B    @DRAW

SCRNDN LI  R0,INCAVE
       CZC @FLAGS,R0         ; Are we leaving a cave?
       JNE CAVOUT
       LI R0,DUNLVL
       CZC @FLAGS,R0         ; Are we in a dungeon?
       JEQ !
       MOVB @MAPLOC,R0
       ANDI R0,>7000
       CI R0,>7000           ; Going down at bottom of dungeon map?
       JEQ DUNOUT             ; Exit dungout, wipe and animate exiting door

!      LI   R0,>1000         ; Add 1 to MAPLOC Y
       AB   R0,@MAPLOC
       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW
       BL   @SCRLDN
       MOV  @HEROSP,R5

       MOVB @MAPLOC,R1
       SRL R1,8
       CLR R0
       MOVB @CAVMAP(R1),R0  ; get cave entry
       CI R0,>1800    ; Raft ride?
       JEQ RAFTDN

       B    @DRAW

SCRNUP LI   R0,>F000         ; Add -1 to MAPLOC Y
       AB   R0,@MAPLOC
       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW
       BL   @SCRLUP
       MOV  @HEROSP,R5
       B    @DRAW


CAVOUT
       SZC  R0,@FLAGS        ; Clear in cave flag

       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW          ; Load outside screen

       MOV @DOOR,R5
       MOV R5,@HEROSP
       MOV R5,@HEROSP+4

       BL   @CAVEOT          ; Update the flipped screen
CAVOU2
       ; check what tile is under hero (doorway, stairs, or dock)
       MOV @DOOR,R5  ; R5=YYXX hero
       MOV R5,R0
       LI R2,!
       BL @TESTCH
!
       CI R1,>7F00           ; doorway
       JEQ !
       ; TODO test for water - ride raft down

       AI R5,-(17*256)-16
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       JMP CAVOU3

!
       AI R5,>1100
       LI R9,16
       LI R10,3
!
       LI R0,BANK4
       LI R1,MAIN
       LI R2,7
       LI R3,DIR_DN
       MOV R9,R4
       BL @BANKSW
       AI R5,->0100     ; Move up

       BL @ANDOOR       ; Animate going out door

       DEC R9
       JNE -!
CAVOU3
       B @INFLP


DUNOUT
       LI R0,DUNLVL
       SZC  R0,@FLAGS        ; Clear dungeon flag and level

       LI R0,MAPSAV
       BL @VDPRB
       MOVB R1,@MAPLOC   ; Restore saved overworld map location

       BL @CLRSCN

       LI   R0,BANK3         ; Overworld tiles in bank 2
       LI   R1,MAIN          ; First function in bank 1
       LI   R2,1             ; load overworld tiles
       BL   @BANKSW

       LI   R0,BANK2
       LI   R1,MAIN
       BL   @BANKSW          ; Load outside screen

       MOV @DOOR,R5
       MOV R5,@HEROSP
       MOV R5,@HEROSP+4

       BL @WIPE

       JMP CAVOU2

* Animate going in/out the door
* Move 4 frames, animate every 6 (R10 counts down from 3 every 2 frames)
* R5=hero pos
* R10=counter 3..0
* Modifies R0,R10,R13
ANDOOR
       MOV R11,R13        ; Save return address
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       BL @SPRUPD

       BL @VSYNCM
       BL @VSYNCM

       DEC R10
       JNE !
       LI R10,3
       ; Animate by toggle sprite index bit on
       LI R0,>0800
       SOC R0,@HEROSP+2
       SOC R0,@HEROSP+6
!
       BL @VSYNCM
       BL @VSYNCM

       DEC R10
       JNE !
       LI R10,3
       ; Animate by toggle sprite index bit off
       LI R0,>0800
       SZC R0,@HEROSP+2
       SZC R0,@HEROSP+6
!
       B *R13         ; Return to saved address

* touching armos, or pushing block?
SOLID
       ANDI R1,>FC00
       CI R1,>DC00    ; armos statue DC-DF
       JEQ ARMOST
       CI R1,>F400    ; gravestone F4-F7
       ; TODO spawn ghini

       ; TODO have bracelet?
       CI R1,>9400    ; green rock 94-97
       JEQ ROCKMV
       CI R1,>9C00    ; red rock 9C-9F
       JEQ ROCKMV
!      RT
ROCKMV ; rock move
       ; locate rock
       MOV R5,R9     ; save hero pos
       CI R3,DIR_UP
       JEQ !
       CI R3,DIR_DN
       JNE -!
       AI R5,>1800   ; rock is below player
!      AI R5,->0800  ; rock is above player

       ; find location of door
       MOV R5,R0
       AI R0,16      ; right 16
       C R0,@DOOR    ; door to right of rock
       JEQ !
       AI R0,->2000+16  ; up 32 right 16
       C R0,@DOOR    ; door two space up and right
       JEQ !
       MOV R9,R5     ; restore hero pos
       RT
!
       MOV R11,R10   ; save return address
       LI R6,>1C06   ; red rock
       CI R1,>9400
       JNE !
       LI R6,>1C02   ; green rock
!

       LI R0,SCHSAV
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW      ; save scratch area

       LI R0,PATTAB+(>9C*8)
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR      ; read rock pattern

       LI R0,SPRPAT+(>1C*8)
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW      ; store rock pattern in sprite

       LI R0,SCHSAV
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR      ; restore scratch area

       MOV R3,R4     ; save direction in rock object
       ORI R4,ROCKID ; rock ID and initial counter
       BL @OBSLOT    ; spawn rock sprite

       ; erase rock tiles
       CLR R1
       CLR R2
       BL @STORCH    ; Draw R1 R2 at R5 (modifies R3)

       MOV R4,R3
       ANDI R3,DIR_XX ; restore direction
       MOV R9,R5     ; restore hero pos
       B *R10        ; return to saved address


ARMOST ; armos touched
       MOV R5,R9  ; save R5

       AI R0,-3*32   ; -3 rows
       SLA R0,3
       ; R0 = screen pointer, extra bits 000yyyy0 xxxx0000
       MOV R0,R5
       SLA R0,3
       MOVB R0,R5
       ANDI R5,>F0F0  ; mask Y and X
       AI R5,>1800  ; +3 rows

       ; make sure armos not already spawned here
       LI R1,LASTSP      ; Start at sprite 13
!      C *R1+,R5
       JEQ !
       INCT R1
       CI R1,SPRLST+128
       JNE -!
       ; Didn't find existing sprite

       MOV R11,R10  ; Save return address
       LI R4,ARMOID
       LI R6,ARMOSC
       BL @OBSLOT
       MOV R10,R11  ; Restore return address

!      MOV R9,R5  ; restore R5
       RT


SWORD  CLR R0
       MOVB @SWRDOB,R0       ; Get sword counter
       JNE !
       RT                    ; Return if zero
!
       MOV @SWRDSP+2,R8      ; Get sprite index and color

       AI R0,>FF00
       MOVB R0,@SWRDOB       ; Decrement and save sword counter
       JNE !
       
       CLR R1                ; Set link to standing
       MOVB R1,@HEROSP+2
       LI R1,>0400
       MOVB R1,@HEROSP+6
       LI R1,>D200          ; Sword YY address (hide)       
       MOV R1,@SWRDSP
       MOV R1,@SWRDSP+2

       CI R8,MRODC
       JEQ MRBEAM            ; Do Magic Rod beam
       JMP SWBEAM            ; Do sword beam 

!      CI R0,>0B00
       JNE !

       LI R0,BANK4
       LI R1,MAIN
       LI R2,3              ; Load attack sprites
       BL @BANKSW

       LI R1,>1000          ; Set link to sword stance
       MOVB R1,@HEROSP+2
       LI R1,>1400
       MOVB R1,@HEROSP+6
       
       JMP SWORD4

!      MOV @FLAGS,R4
       ANDI R4,DIR_XX
       C R4,R3          ; Redraw sword if facing changed
       JNE !

       CI R0,>0800           ; Sword appears on fourth frame
       JNE SWORD4
       ; Draw sword
!
       MOV R3,R1
       SRL R1,7

       MOV R5,R7           ; Position relative to link
       A   @SWORDX(R1),R7

       CI R8,MRODC           ; Don't change Magic Rod sprite
       JEQ !
       MOV R3,R8
       SLA R8,2
       ORI R8,>7008          ; Sword facing (TODO sword color)
       MOV R8,@SWRDSP+2
!
       MOV R7,@SWRDSP

SWORD4 MOV @HEROSP,R5        ; Get hero position before changing sprite
       B @LNKSPR

SWBEAM
       LI R0,FULLHP
       CZC @FLAGS,R0         ; Test for sword beam
       JEQ SWORD4

       MOV @BSWDOB,R0     ; Sword beam already active?
       JNE SWORD4

       LI R0,BSWDID
       LI R6,>700F          ; Sword sprite and color
!
       MOV R3,R1            ; Launch sword beam
       SRL R1,7

       MOV @HEROSP,R5      ; Position relative to hero
       A   @SWORDX(R1),R5
       
       MOV R3,R1            ; Get facing from sword sprite
       SLA R1,2
       SOC R1,R6

       MOV R0,@BSWDOB
       MOV R5,@BSWDSP
       MOV R6,@BSWDSP+2

       JMP SWORD4

MRBEAM ; Magic Rod beam
       MOV @BSWDOB,R0
       ANDI R0,>003F      ; Magic can override beam sword
       CI R0,MAGCID       ; but not itself
       JEQ SWORD4

       LI R0,MAGCID
       ORI R6,>B00F       ; Magic sprite and color

       JMP -!

       
SWORDX DATA >000B,>FFF5,>0A01,>F4FF



ITEMFN DATA BMRGFN,BOMBFN,ARRWFN,CNDLFN
       DATA FLUTFN,BAITFN,POTNFN,MAGCFN

* bits right,left,down,up  (index by 4-bit dpad, counter directions cancel out)
BMRNGD BYTE 8,6,2,8 ; none, up, down, none
       BYTE 4,5,3,4 ; left, upleft, downleft, left
       BYTE 0,7,1,0 ; right, upright, downright, right
       BYTE 8,6,2,8 ; none, up, down, none
* bits right,left,down,up (index by facing direction)
BMRNGE BYTE 0,4,2,6 ; right, left, down, up

THROWJ DATA THROWR,THROWL,THROWD,THROWU

* Check to see if hero has room to spawn an item in the direction he's facing
* Returns if ok, jumps to ITMNXT otherwise
* Modifes R1,R7
THROW
       MOV R3,R1
       SRL R1,7
       MOV @THROWJ(R1),R1
       MOV R5,R7
       SWPB R7
       B *R1
THROWL
       CI R7,(16)*256
       JLE ITMNXT
       RT
THROWR
       CI R7,(256-32)*256
       JHE ITMNXT
       RT
THROWD
       CI R5,(192-32)*256
       JHE ITMNXT
       RT
THROWU
       CI R5,(24+16)*256
       JLE ITMNXT
       RT

BMRGFN ; Boomerang
       MOV @BMRGOB,R0
       JNE ITMNXT    ; Boomerang already active

       MOV @HFLAGS,R0
       ANDI R0,BMRANG+MAGBMR
       ;JEQ ITMNXT

       BL @THROW

       LI R7,BMRGOB-OBJECT
       LI R4,BMRGID*4

       MOV @KEY_FL,R1       ; Get direction from currently pressed keys
       SRL R1,1
       ANDI R1,>000F
       MOVB @BMRNGD(R1),R4
       CI R4,>0800
       JL !

       ; Get direction from facing
       MOV R3,R1
       SRL R1,8
       MOVB @BMRNGE(R1),R4
!
       SRL R4,2

       ANDI R0,MAGBMR
       JNE !

       AI R4,45*>0200
       LI R6,BOOMSC       ; Boomerang

       JMP ITMSPN
!
       AI R4,>FE00       ; max counter
       LI R6,MBOMSC       ; Magic boomerang

ITMSPN ; Item spawn: R7=index, R4=object id, R6=sprite idx and color
       MOV R4,@OBJECT(R7)
       A R7,R7

       MOV R5,R0
       MOV R3,R1
       SRL R1,7
       A @BOMBXY(R1),R0
       MOV R0,@SPRLST(R7)
       MOV R6,@SPRLST+2(R7)

ITMNXT B @ITEMX


*            Left Right  Down  Up
BOMBXY DATA >FF10,>FEF0,>0F00,>EF00

BOMBFN ; Bomb
       MOV @BOMBOB,R0
       JNE ITMNXT    ; Bomb already active

       ; TODO have enough bombs?

       BL @THROW
       ; TODO decrement bombs

       LI R7,BOMBOB-OBJECT
       LI R4,BOMBID
       LI R6,>C404          ; Bomb is C4

       JMP ITMSPN

ARRWFN ; Arrow
       MOV @ARRWOB,R0
       JNE ITMNXT   ; Arrow already active

       BL @THROW

       ; TODO have enough rupees?
       CLR R0
       MOVB @RUPEES,R0
       JEQ ITMNXT    ; No rupees?

       AI R0,->100         ; Decrement rupees
       MOVB R0,@RUPEES
       ; TODO update status
       MOV R3,R4           ; Save R3
       BL @STATUS          ; Update status
       MOV R4,R3           ; Restore R3

       LI R7,ARRWOB-OBJECT
       MOV R3,R6
       SLA R6,2
       AI R6,>A005         ; Blue arrow
       LI R4,ARRWID

       JMP ITMSPN

CNDLFN ; Candle
       MOV @FLAMOB, R0
       JNE ITMNXT  ; Candle already active

       ; TODO have used already on this screen or red candle?

       BL @THROW

       LI R7,FLAMOB-OBJECT
       LI R6,>F008

       MOV R3,R4
       SRL R4,2
       AI R4,FLAMID

       JMP ITMSPN


FLUTFN ; Flute
       JMP ITMNXT
BAITFN ; Bait
       JMP ITMNXT
POTNFN ; Letter/Potion
       JMP ITMNXT
MAGCFN ; Magic Rod

       BL @THROW

       LI R0,>0C00       ; Magic Rod animation is 12 frames
       MOVB R0,@SWRDOB
       LI R0,MRODC       ; Magic Rod is single sprite, dark blue
       MOV R0,@SWRDSP+2

       JMP ITMNXT




* Link hurt animation
* R4 = counter & knockback direction
* Modifies R0-3,R9-10
LNKHRT
       MOV R11,R9              ; Save return address

       MOVB @HP,R0
       JNE !
       ; HP is zero, game over and restart
       LI R0,BANK4
       LI R1,MAIN
       LI R2,1       ; Do game over in bank 3
       BL @BANKSW
       B @RESTRT

!
       AI R4,>FC00             ; Dec counter bits
       MOV R4,R1               ; Get counter in R1
       SRL R1,10
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2

       CI R4,>A000             ; Compare to 40<<10
       JLE !                   ; Only knockback for 8 frames

       MOV R4,R3
       SRL R3,7
       ANDI R3,>0006           ; Get knockback direction

       MOV R5,R0            ; R5=YYXX
       SWPB R0              ; R0=XXYY
       MOV @LNKHJT(R3),R1
       B *R1
LNKHJL
       CI R0,>0800          ; Check left edge of screen
       JLE !
       JMP LNKHR2
LNKHJR
       CI R0,>E800          ; Check right edge of screen
       JHE !
       JMP LNKHR2
LNKHJU
       CI R5,>1800         ; Check top edge of screen
       JLE !
       JMP LNKHR2
LNKHJD
       CI R5,>B000         ; Check bottom edge of screen
       JHE !

LNKHR2
       BL @LNKMOV
       BL @LNKMOV
       BL @LNKMOV
       BL @LNKMOV

!      CI R4,>0400
       JHE !
       CLR R4           ; Countdown finished
!
       MOVB R4,@HURTC
       BL *R9           ; Return to saved address

LNKHJT ; Hero hurt jump table
       DATA LNKHJR,LNKHJL,LNKHJD,LNKHJU

LNKHRC ; Hero hurt colors, 2 frames each
       DATA >0301      ; green, black  (normal colors)  TODO blue/red based on rings
       DATA >040F      ; dark blue, white
       DATA >060F      ; red, white
       DATA >0106      ; black, red


* Hero movement, R3=direction 0=Right 2=Left 4=Down 6=Up, R5=YYXX position
* Modifies R0-2,R10
LNKMOV
       MOV R11,R10          ; Save return address
       MOV R5,R0
       SZC @EMOVEM(R3),R0   ; Position aligned to 8 pixels?
       JNE !                ; Not aligned so move normally

       MOV R11,R2           ; Return immediately if obstruction
       MOV R5,R0
       A @LMOVEA(R3),R0
       BL @TESTCH
       MOV R5,R0
       A @LMOVEB(R3),R0
       BL @TESTCH

!      A @EMOVED(R3),R5     ; Do movement
       BL *R10              ; Return to saved address


* Facing     Right Left  Down  Up
LMOVEA DATA >0810,>07FF,>1000,>0700     ; Test char offset 1
LMOVEB DATA >0F10,>0EFF,>100F,>070F     ; Test char offset 2





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



* Look at character at pixel coordinate in R0, and jump to R2 if solid (character is in R1)
* Modifies R0,R1
TESTCH
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
       ANDI R0,>F8F8
       MOV R0,R1
       SRL R1,3
       MOVB R1,R0
       SRL R0,3
       MOV @FLAGS,R1
       ANDI R1,SCRFLG
       A R1,R0
       
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       CLR R1
       MOVB @VDPRD,R1
       
       CI R1,>7E00  ; Characters >7E and higher are solid
       JHE !
       RT
!      B *R2        ; Jump alternate return address


* Update Sprite List to VDP Sprite Table (with flicker)
* Modifies R0-R3
SPRUPD
       LI R0,SPRTAB+VDPWM  ; Copy to VDP Sprite Table
       LI R1,SPRLST    ; from Sprite List in CPU
       LI R2,6         ; Copy first 6 sprites
       CLR R3
       MOVB @R0LB,*R14 ; VDP Write address
       MOVB R0,*R14    ; VDP Write address

!      MOVB *R1+,R0
       AI R0,->0100   ; adjust Y
       MOVB R0,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       A R3,R1      ; Move to next sprite
       DEC R2
       JNE -!

       CI R1,SPRLST+(4*6)
       JNE !        ; done?

       LI R2,32-6   ; Copy remaining sprites
       MOV @COUNTR,R0
       SRC R0,1
       JOC  -!      ; every other frame
       ; do in reverse order (flickering)
       LI R1,SPRLST+(4*31)
       LI R3,-8
       JMP -!
!
       RT

* Add R1 to hero sprite YYXX, and update VDP sprite list
DOSPRT
       A R1,@HEROSP
       A R1,@HEROSP+4
       LI R0,SPRTAB+(HEROSP-SPRLST)+VDPWM
       LI R1,HEROSP

       MOVB @R0LB,*R14 ; VDP Write address
       MOVB R0,*R14    ; VDP Write address

       MOVB *R1+,R0
       AI R0,->0100   ; adjust Y
       MOVB R0,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15

       MOVB *R1+,R0
       AI R0,->0100   ; adjust Y
       MOVB R0,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
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
       MOV R5,*R1+
       MOV R6,*R1
       RT


* Increment counters (And animate fire)
COUNT
       MOV R11,R13  ; Save return address
       MOV @COUNTR,R0
       AI R0,->1120  ; Add -1 to left 3 counters
       CI R0,>1000   ; Left nibble 0?
       JHE !
       AI R0,>6000   ; Add 6

!      MOV R0,R1
       ANDI R1,>0F00 ; Right nibble 0?
       JNE !
       AI R0,>0B00   ; Add 11
!      MOV R0,R1
       ANDI R1,>00E0 ; 5 bit counter 0?
       JNE !
       AI R0,>00A0   ; Add 5
!      INC R0
       ANDI R0,>FFEF
       MOV R0,@COUNTR

       ANDI R0,>0003    ; Every 4 frames
       JNE !

       LI R0,BANK1
       LI R1,MAIN
       LI R2,100        ; Animate fire + fairy sub-function
       BL @BANKSW
!
       B *R13     ; Return to saved address




* Set keyboard lines in R1 to CRU
SETCRU
       MOV *R11+,R1    ; Get ouput line from callers DATA
       LI R12,>0024    ; Select address lines starting at line 18
       LDCR R1,3       ; Send 3 bits to set one 8 of output lines enabled
       LI R12,>0006    ; Select address lines to read starting at line 3
       RT

* Read keys and joystick into KEY_FL
* Modifies R0-2,R10,R12
DOKEYS
       MOV R11,R10     ; Save return address
       CLR R0
       BL @SETCRU
       DATA >0000
       TB 2            ; Test Enter
       JEQ !
       ORI R0, KEY_A
!      BL @SETCRU
       DATA >0100
       TB 5            ; Test S
       JEQ !
       ORI R0, KEY_DN
!      TB 6            ; Test W
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0200
       TB 5            ; Test D
       JEQ !
       ORI R0, KEY_RT
!      TB 6            ; Test E
       JEQ !
       ORI R0, KEY_B
!      BL @SETCRU
       DATA >0500
       TB 0            ; Test Slash
       JEQ !
       ORI R0, KEY_C
!      TB 1            ; Test Semicolon
       JEQ !
       ORI R0, KEY_B
!      TB 5            ; Test A
       JEQ !
       ORI R0, KEY_LT
!      TB 6            ; Test Q
       JEQ !
       ORI R0, KEY_C
!      BL @SETCRU
       DATA >0600
       TB 0            ; Test J1 Fire
       JEQ !
       ORI R0, KEY_A
!      TB 1            ; Test J1 Left
       JEQ !
       ORI R0, KEY_LT
!      TB 2            ; Test J1 Right
       JEQ !
       ORI R0, KEY_RT
!      TB 3            ; Test J1 Down
       JEQ !
       ORI R0, KEY_DN
!      TB 4            ; Test J1 Up
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0700
       TB 0            ; Test J2 Fire
       JEQ !
       ORI R0, KEY_B
!      TB 1            ; Test J2 Left
       JEQ !
       ORI R0, KEY_A
!      TB 2            ; Test J2 Right
       JEQ !
       ORI R0, KEY_C
!      TB 3            ; Test J2 Down
       JEQ !
       ORI R0, KEY_B
!      TB 4            ; Test J2 Up
       JEQ !
       ORI R0, KEY_C
!
       ; Calculate edges
       MOV R0,R1
       XOR @KEY_FL,R1
       INV R0
       SZC R0,R1
       INV R0
       SLA R1,8
       SOC R1,R0
       MOV R0,@KEY_FL

       B *R10  ; Return to saved address


*R1     TB 0  TB 1  TB 2  TB 3  TB 4  TB 5  TB 6  TB 7
*0000   =     space enter fctn  shift ctrl
*0100   .     L     O     9     2     S     W     X
*0200   ,     K     I     8     3     D     E     C
*0300   M     J     U     7     4     F     R     V
*0400   N     H     Y     6     5     G     T     B
*0500   /     ;     P     0     1     A     Q     Z
*0600   Fire  Left  Right Down  Up  (Joystick 1)
*0700   Fire  Left  Right Down  Up  (Joystick 2)



* Get random number in R0 (modifies R1)
* RAND16 must be seeded with nonzero, Period is 65535
RANDOM MOV @RAND16,R0    ; Get initial seed
       MOV R0,R1
       A   R1,R1
       XOR R1,R0         ; R0 ^= R0 << 1
       MOV R0,R1
       SRL R1,7
       XOR R1,R0         ; R0 ^= R0 >> 7
       MOV R0,R1
       SLA R1,4
       XOR R1,R0         ; R0 ^= R0 << 4
       MOV R0,@RAND16    ; Save new seed
       RT


* Draw number of rupees, keys, bombs and hearts
* Modifies R0-R3,R7-R11,R13
STATUS
       LI R0,BANK5
       LI R1,MAIN
       LI R2,1
       B @BANKSW


* Do the item selection menu
* Modifies R0-R12
DOMENU
       LI R0,SCHSAV
       BL @PUTSCR      ; Save a backup of scratchpad

       BL @MENUDN       ; Scroll menu screen down

       LI R0,SPRTAB+(2*4)
       LI R1,>1F40          ; Position B item in box
       BL @VDPWB
       MOVB @R1LB,*R15

       MOV @HFLAGS,R4       ; Current selection
       ANDI R4,SELITM
       SZC R4,@HFLAGS       ; Set zeros
       LI R6,>1C04          ; Selector sprite and color

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
       LI R0,SPRTAB+(3*4)     ; Update selector sprite
       LI R1,WRKSP+(5*2)      ; Copy bytes from R5 and R6
       LI R2,4
       BL @VDPW
!
       BL @DOKEYS
       MOV @KEY_FL, R0
       MOV R0,R1

       SLA R1,4             ; Shift EDG_RT into carry
       JNC !
       LI R3,1
       JMP MENUMV
!
       MOV R0,R1
       SLA R1,5             ; Shift EDG_LT into carry
       JNC !
       LI R3,-1
       JMP MENUMV

!
       SLA R0,1             ; Shift EDG_C bit into carry status
       JNC MENULP

       SOC R4,@HFLAGS       ; Save selected item

       BL @MENUUP           ; Scroll menu screen up

       LI R0,SCHSAV         ; Restore 32 byte scratchpad
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       B @MENUX

MENUMV
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
       JMP MENUMV
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
       MOVB R1,@ITEMSP+3    ; Save color in CPU sprite list
       LI R0,SPRTAB+(2*4)+3 ; Set color in VDP sprite table
       BL @VDPWB

       LI R0,SPRPAT+(>AC*8) ; Special case for arrows, use Arrow Up sprite
       CI R4,2
       JEQ !

       ; copy pattern from character index to sprite 62
       MOV R2,R0
       SRL R0,5
       AI R0,PATTAB
!
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR
       LI R0,SPRPAT+(62*32)
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW

       JMP MENUSP


* HP  Rings None  Blue  Red
*  0        Empty Empty Empty
*  1        Half  Half  Half
*  2        Full  Half  Half
*  3        Half  Full  Half
*  4        Full  Full  Half
*  5        Half  Half  Full
*  6        Full  Half  Full
*  7        Half  Full  Full
*  8        Full  Full  Full



* Facing     Right Left  Down  Up
EMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
EMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)


SPRL0  DATA >D2D0,>E002  ; Map dot
       DATA >D2C8,>E406  ; Half-heart
       DATA >057C,>F804  ; B item
       DATA >0594,>7C08  ; Sword item
       DATA >D2D0,>0003  ; Link color
       DATA >D2D0,>0401  ; Link outline
SPRLE



SCHRST ; Restore the scratchpad from saved area in VDP
       LI R0,SCHSAV
       LI R1,SCRTCH
       LI R2,32
       B @VDPR



* Test for vsync and play music if set
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



* Copy scratchpad to the screen at R0
* Modifies R0,R1,R2
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

* Copy screen at R0 into scratchpad 32 bytes
* Modifies R1,R2,R6
READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH         ; Dest pointer to scratchpad ram
       LI R2,8              ; Read 32 bytes to scratchpad
       LI R6,VDPRD          ; Keep VDPRD address in R6
!      MOVB *R6,*R1+
READ3  MOVB *R6,*R1+
       MOVB *R6,*R1+
       MOVB *R6,*R1+
       DEC R2
       JNE -!
       RT

* Copy screen at R0 into R1 31 bytes
* Note: R6 must be VDPRD address
* Modifies R1,R2
READ31
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R2,8             ; Read 31 bytes to scratchpad
       JMP READ3           ; Use loop in READ32 minus 1


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

* Scroll all or a portion of the screen up or down
* R4 = source address of row to scroll in
* R5 = direction to scroll (-32 or 32)
* R9 = number of rows to scroll
* R10 = starting offset off screen
* modifies R0-R3
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
       MOV R11,R12        ; Save return address
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

       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_DN
       B *R12          ; return to saved address

SCRLUP
       MOV R11,R12        ; Save return address
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

       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_UP
       B *R12          ; return to saved address

* Scroll screen left
* R4 - pointer to new screen in VRAM
SCRLLT
       MOV R11,R12        ; Save return address
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
       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_LT
       B *R12          ; return to saved address


* Scroll screen right
* R4 - pointer to new screen in VRAM
SCRLRT
       MOV R11,R12        ; Save return address
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
       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_RT
       B *R12          ; return to saved address






CAVEOT
       MOV R11,R12        ; Save return address

       ;MOV  @DOOR,R5        ; Move link to door location
       ;AI R5,->0100         ; Move Y up one
       ;MOV R5,@HEROSP	    ; Update color sprite
       ;MOV R5,@HEROSP+4     ; Update outline sprite
       ;LI R0,>0100
       ;MOVB R0,@HEROSP+7    ; Set outline color to black

       ; fall thru
CAVEIN
       MOV R11,R12        ; Save return address
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

       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_DN
       B *R12          ; return to saved address



* Wipe screen from center
* R4 - pointer to new screen in VRAM
WIPE
       MOV R11,R12        ; Save return address
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

       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_UP
       B *R12          ; return to saved address



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


* Status sprites move by R0
STMOVE
       A R0,@MPDTSP
       A R0,@ITEMSP
       A R0,@ASWDSP
       A R0,@HARTSP
       LI R0,SPRTAB
       LI R1,SPRLST
       LI R2,4*4
       B @VDPW


* items that get copied to pattern table
* 80  ladder  raft   brown
* 88  magkey boomer  brown
* 90  arrows flute   brown
* 98  silver boomer  blue
* A0  bombs  candle  blue
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
* Get selected item sprite and color into sprite 62
* Modifies R0-R2,R4-5,R7-R10,R13   (R3,R6,R12 must be preserved)
GETSEL
       MOV R11,R12        ; Save return address
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

       B *R12         ; Return to saved address

* Copy item from sprite pattern to character pattern (or selected item sprite)
* R4=IIPP  II=sprite index PP=screen pos
* R7=destination VDP address
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

* Translate 4 TIFORCE characters
* R0 = screen offset
* R3 = 4 nibbles
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
       MOV R11,R12        ; Save return address
       LI R0,SPRTAB+(6*4)
       LI R1,>D000
       BL @VDPWB       ; Turn off most sprites

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

       B *R12     ; Return to saved address

MENUUP
       MOV R11,R12        ; Save return address

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

       B *R12         ; Return to saved address













SLAST  END  MAIN
