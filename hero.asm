
* if dpad pushed matches direction, move
* otherwise pick from pressed keys: UP DN LT RT
* if aligned to 8 pixels in direction to move, check if direction is blocked
*    if so, try other pressed keys
* if not aligned to 8 pixels, move perpendicular to get aligned
*
*  after moving, if not aligned to 8 pixels, move again if frame counter is odd


DOHERO
       MOV @HEROSP,R5     ; R5 = Hero YYXX position

       MOVB @HURTC,R4   ; R4 = Hurt counter
       JEQ !
       BL @LNKHRT
!

       MOV @FLAGS,R3
       ANDI R3,DIR_XX    ; Get direction in R3

       CLR R0
       MOVB @SWRDOB,R0   ; Sword animation counter
       JEQ !
       B   @SWORD           ; Animate sword if needed
!
       MOV @KEY_FL,R0
       SLA R0,2          ; Shift EDG_B bit into carry status
       JNC !

       MOV @HFLAGS,R1    ; Get selected item
       ANDI R1,SELITM
       A R1,R1
       MOV @ITEMFN(R1),R1 ; Get function for item
       B *R1
!
       MOV @KEY_FL,R0
       SLA R0,3          ; Shift EDG_A bit into carry status
       JNC !

       MOV @HFLAGS,R1    ; Get sword flags
       ANDI R1,ASWORD+WSWORD+MSWORD
       JEQ !             ; no sword yet

       BL @THROW         ; Make sure there's room for sword (returns to ITEMX if not)

       LI R0,>0C00       ; Sword animation is 12 frames
       MOVB R0,@SWRDOB
       LI R0,x#TSF222     ; Sword sound effect
       MOV R0,@SOUND3
       LI R0,x#TSF223     ; Sword sound effect
       MOV R0,@SOUND4

       LI R0,>0800
       SZC R0,@HEROSP+2   ; set animation frame to 0
       SZC R0,@HEROSP+6   ; set animation frame to 0
       BL @DRWSPR         ; update sprite list before changing patterns
       BL @BANK4X         ; herospr.asm
       DATA x#LNKATK      ; load attack sprites

       JMP MAINLP
!
ITEMX ; item done


       CLR R7    ; will be modfied if any direction is pressed

       ; get key flags and check if a direction is pressed
       MOV  @KEY_FL,R1
       ANDI R1,>001E   ; mask direction bits
       JEQ MAINLP

       ; vertical direction tests
       SRC R1,2
       JOC MOVEUP

       SRC R1,1
       JOC MOVEDN
HKEYS  ; horizontal direction tests
       MOV R5,R0
       SB R0,R0   ;ANDI R0,>00FF  ; Set up R0 with X only

       SRC R1,1
       JOC MOVELT

       SRC R1,1
       JOC MOVERT

HERORT
       MOV R7,R7    ; will be nonzero if any direction is pressed (against a wall)
       JEQ MAINLP

       BL @MOVDIR   ; animate and possibly change direction

       JMP MAINLP



* jumped to by TESTCH with char in R1
VSOLID
       BL @SOLID     ; armos touched? push block?

       MOV  @KEY_FL,R1
       ANDI R1,>001E   ; mask direction bits
       SRC R1,3

       JMP HKEYS
HSOLID
       BL @SOLID     ; armos touched? push block?
       JMP HERORT


MOVEUP
       SRC R1,1
       JOC HKEYS     ; both up and down pressed

       LI R7,UPDATA
       CI R5,>1900    ; min Y = 24
       JHE MOVEA
       BL @CHGDIR
       B @SCRNUP
MOVEDN
       LI R7,DNDATA
       CI R5,>B800    ; max Y = 192-8
       JL MOVEA
       BL @CHGDIR
       B @SCRNDN
MOVELT
       SRC R1,1
       JOC HERORT     ; both left and right pressed

       LI R7,LTDATA
       CI R0,>0000   ; min X = 0
       JH MOVEA
       BL @CHGDIR
       B @SCRNLT
MOVERT
       LI R7,RTDATA
       CI R0,>00F0    ; max X = 256-16
       JL MOVEA
       BL @CHGDIR
       B @SCRNRT
MOVEA  ; move in any direction  R5=hero pos R7=direction xxDATA

       MOV R7,R3    ; calculate R3=direction from xxDATA
       AI R3,-RTDATA
       SLA R3,5    ; table width is 8 bytes 00000000000xx000 -> 000000xx00000000
       MOV *R7+,R4    ; VDATA or HDATA

* R5 = hero pos
* R7 = LTDATA or RTDATA

       ; check if aligned to 8 in the direction we are moving
       CZC *R4+,R5 ; mask X or Y
       JNE MOVE0 ; not aligned to 8, just move

       ; if we're in a dungeon, moving through doors doesn't check solid
       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !
       CI R5,>3000
       JL DUNGMV
       CI R5,>98FF
       JH DUNGMV
       SWPB R5
       CI R5,>2000
       JL DUNGMH
       CI R5,>D0FF
       JH DUNGMH
       SWPB R5
!
       ; check if path is clear
       MOV *R4+,R2     ; HSOLID or VSOLID
       MOV R5,R0
       A *R7+,R0     ; first test pixel offset
       BL @TESTCH

       MOV R5,R0
       A *R7+,R0     ; second test pixel offset
       BL @TESTCH

       LI R0,SLOWMV    ; slower movement (1px/frame)
       CI R1,>6300     ; overworld/dungeon ladder
       JEQ !
       CI R1,>0B00     ; gray ladder
       JEQ !
       SZC R0,@FLAGS   ; clear slow movement
       JMP !!
!
       SOC R0,@FLAGS   ; set slow movement
!
       LI R11,MAINLP     ; Return to main loop

MOVEAL  ; check if aligned to 8 perpendicular
       MOV R5,R0
       SZC *R4+,R0     ; mask >0700 or >0007
       JEQ MOVE
       MOV *R4+,R7     ; 4-7: go down or right
       C R0,*R4+      ; >0400 or >0004
       JHE MOVE
       MOV *R4,R7     ; 1-3: go up or left
       JMP MOVE

MOVED0 ; get aligned horizontally
       LI R7,DNDATA+6
       LI R4,HDATA+4
       JMP MOVEAL
MOVEU0 ; get aligned vertically
       LI R7,UPDATA+6
       LI R4,VDATA+4
       JMP MOVEAL
MOVEU2
       LI R7,UPDATA+6
       JMP MOVE
MOVEV2  ; move vertically
       CI R0,>0400    ; y < 4  move up
       JL MOVEU2
MOVED2
       LI R7,DNDATA+6
       JMP MOVE

MOVEH3
       LI R11,MAINLP  ; don't return, get aligned instead
       CI R0,>0100    ; vertical?
       JHE MOVEV2
       CI R0,>0004    ; x < 4  move left
       JL MOVEL3
MOVER3
       LI R7,RTDATA+6
       JMP MOVE
MOVEL3
       LI R7,LTDATA+6
       JMP MOVE

MOVEX2 ; move any direction based on FLAGS
       MOV @HEROSP,R5
       MOV @FLAGS,R3
       ANDI R3,DIR_XX
MOVEX  ; move any direction with R3=DIR
       MOV R3,R7
       SRL R7,5      ; table stride is 8
       AI R7,RTDATA+6
       JMP MOVE


GALIGN ; get aligned to 8 pixels (return if already aligned)
       MOV R5,R0
       ANDI R0,>0707
       JNE MOVEH3
       RT     ; already aligned

DUNGMV ; dungeon move through vertical door
       MOV R3,R0
       SLA R0,7
       JOC MOVE0  ; only DIR_UP or DIR_DN
!      B @MAINLP

DUNGMH ; dungeon move through horizontal door
       SWPB R5   ; undo previous SWPB
       MOV R3,R0
       SLA R0,7
       JNC MOVE0  ; only DIR_RT or DIR_LT
       CLR R7     ; don't animate if up or down was pressed
       B @HKEYS
       ; only DIR_LT or DIR_RT

MOVE0
       LI R11,MAINLP     ; Return to main loop
       AI R7,4      ; skip to movement
MOVE
       A *R7,R5    ; move

       ; check if aligned to 8
       MOV R5,R0
       ANDI R0,>0707
       JEQ !

       MOV R3,R0
       ANDI R0,DIR_DN   ; mask up/down bit, check for zero
       JEQ MOVE1

       LI R0,SLOWMV     ; check slow move, vertical only
       CZC @FLAGS,R0
       JNE !
MOVE1
       ; move again if frame counter odd and not aligned to 8
       MOV @COUNTR,R0
       SRC R0,1
       JOC !
       A *R7,R5    ; move again
!
       ; store moved position to sprites
       MOV R5,@HEROSP
       MOV R5,@HEROSP+4

       C @DOOR,R5

       JNE MOVDIR
       B @GODOOR

MOVDIR
       ; animate walking sprites every 6 frames
       MOV @COUNTR,R0
       SRL R0,12        ; get 6..1 counter
       DEC R0
       JNE !            ; only animate when zero
       LWPI HEROSP      ; use workspace for easier XOR on registers
       LI R0,>0800      ; toggle this bit to animate
       XOR R0,R1        ; effectively @HEROSP+2
       XOR R0,R3        ; effectively @HEROSP+6
       MOV R2,R0        ; restore position
       LWPI WRKSP
!

LNKSP4
       LI R13,x#LNKSPR   ; load new facing sprites

       MOV @FLAGS,R2  ; get flags
       MOV R2,R0
       ANDI R0,DUNLVL
       JEQ NOMASK

       ; Dungeon only: Draw masked sprites if going thru door
       ; must preserve R2,R3
MASKSP
       LI R4,>28FF  ; Top of screen
       C R5,R4
       JH !
       S R5,R4
       SRL R4,8
       JEQ DOMASK
       LI R13,x#MSKTOP       ; Mask top
       JMP DOMASK
!
       LI R4,>A800 ; Bottom of screen
       C R5,R4
       JL !
       S R5,R4
       NEG R4
       SRL R4,8
       JEQ DOMASK
       LI R13,x#MSKBOT       ; Mask bottom
       JMP DOMASK
!
       SWPB R5      ; Change to XXYY

       LI R4,>10FF  ; Left of screen
       C R5,R4
       JH !
       S R5,R4
       SRL R4,8
       JEQ DOMASK
       LI R13,x#MSKLFT       ; Mask left
       SWPB R5
       JMP DOMASK
!
       LI R4,>E000  ; Left of screen
       C R5,R4
       JL !
       S R5,R4
       NEG R4
       SRL R4,8
       JEQ DOMASK
       LI R13,x#MSKRGT       ; Mask right
       SWPB R5
       JMP DOMASK
!
       SWPB R5     ; Restore to YYXX

NOMASK
       XOR R2,R3
       ANDI R3,DIR_XX ; R3 will be nonzero if direction changed
       JNE !           ; same as current direction
       RT
!      XOR R2,R3         ; update direction
       MOV R3,@FLAGS     ; save the new flags
       ANDI R3,DIR_XX
       B @BANK4        ; returns to R11

CHGDIR
       AI R7,-RTDATA  ; remove table offset
       SLA R7,5      ; table stride is 8
       MOV R7,R3     ; get new direction
       LI R0,PUSHC
       SZC R0,@FLAGS ; Clear push counter
       JMP LNKSP4

DOMASK ; masking required and update direction R2=FLAGS R3=DIR
       ANDI R2,~DIR_XX
       SOC R3,R2       ; update direction
       MOV R2,@FLAGS   ; save the new flags
       B @BANK4        ; returns to R11





*                 test1,test2,delta
RTDATA DATA HDATA,>0B10,>0C10,>0001
LTDATA DATA HDATA,>0BFF,>0CFF,>FFFF
DNDATA DATA VDATA,>1004,>100C,>0100
UPDATA DATA VDATA,>0704,>070C,>FF00
* note: the above must be in
;    X or Y mask, TESTCH, mask, JHE-data, compare, JL-data
VDATA  DATA >0700,VSOLID,~>0007,RTDATA+6,>0004,LTDATA+6
HDATA  DATA >0007,HSOLID,~>0700,DNDATA+6,>0400,UPDATA+6





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
DUNGSP   ;   0   1   2   3   4   5   6   7   8   9
       BYTE >77,>73,>7D,>7C,>71,>64,>79,>F1,>F6,>FE
       EVEN ; FIXME D5 should be >76

* Go into doorway or stairs or dock(raft)
GODOOR
       BL @DRWSPR     ; Update sprite list in VDP

       LI R8,SWRDSP
!      CLR *R8+
       CI R8,SPRLST+128        ; Clear sprite table
       JNE -!

       MOV R5,R0
       LI R2,GODOO2
       BL @TESTCH
       ; Either stairs or dock  (dungeon stairs are >7400)
       CI R1,>7C00    ; Green dock char
       JEQ RAFTUP
       CI R1,>1C00    ; Red dock char
       JEQ RAFTUP
       CI R1,>7400
       JEQ GODOO3     ; dungeon stairs don't mute audio

       BL @QUIET             ; Mute all sound channels

       JMP GODOO3

GODOO2 ; Solid tile means Cave/Doorway
       CLR R9
       LI R10,3
       BL @QUIET             ; Mute all sound channels

       LI R0,x#TSF212      ; Stairs sound
       MOV R0,@SOUND3
       LI R0,x#TSF213      ; Stairs sound
       MOV R0,@SOUND4

!
       BL @ANDOOR       ; Animate going in the door (modifies R0,R8,R10)

       LI R3,DIR_UP
       INC R9
       MOV R9,R4       ; R4=number of lines to mask
       BL @BANK4X      ; herospr.asm
       DATA x#MSKBOT   ; Load masked sprites at bottom

       AI R5,>0100     ; Move down

       CI R9,16
       JNE -!
       BL @VSYNCM
       BL @VSYNCM
       BL @VSYNCM

GODOO3  ; entering cave or dungeon cellar/tunnel
       LI R0,DUNLVL
       CZC @FLAGS,R0
       JNE CELLAR        ; in a dungeon?

       ; overworld dungeon or cave
       MOVB @MAPLOC,R1
       SRL R1,8
       CLR R2
       MOVB @CAVMAP(R1),R2  ; get cave entry
       MOVB R2,@CAVTYP      ; store it

       CI R2,>2000
       JL !
       B @GODUNG            ; entering dungeon if starting with 2X
!
       LI R4,INCAVE
       SOC R4,@FLAGS         ; Set in cave flag

       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       ; overworld cave
       LI  R5,>B878        ; Put hero at cave entrance
       LI R3,DIR_UP
       MOV @AMOVEX+6,@TEMPRT   ; set target location

       MOV R5,@HEROSP      ; Update color sprite
       MOV R5,@HEROSP+4    ; Update outline sprite
       BL @DRWSPR
!
       LI R0,DIR_XX
       SZC R0,@FLAGS       ; Clear current direction
       SOC R3,@FLAGS       ; Set new direction
       BL @BANK4X          ; herospr.asm
       DATA x#LNKSPR       ; Load facing sprites

       BL  @CAVEIN

       B @AUTOMV

CELLAR ; dungeon cellar
       BL @DLAY10          ; delay 10 frames

       LI R0,HEROST
       LI R1,>D000     ; player and all other sprites
       BL @VDPWB       ; Turn off most sprites

       BL @DARKEN

       BL @BANK2X       ; map.asm
       DATA x#CLRSCN    ; clear screen before updating tiles

       BL @DLAY10          ; delay 10 frames

       LI R4,INCAVE
       SOC R4,@FLAGS         ; Set in cave flag

       BL @BANK2X        ; map.asm
       DATA x#LOADSC     ; Load map into screen at current position

       MOV @HEROSP,R5    ; Hero location is set by GETDNC get dungeon cellar type
       MOV R5,@HEROSP+4  ; Update outline sprite (not set y GETDNC)
       LI  R3,DIR_DN
       MOV R5,R0
       AI R0,>2000
       MOV R0,@TEMPRT      ; set target location

       JMP -!


* Ride the raft upward, or return to R13 if no raft
RAFTUP
       LI R0,RAFT
       CZC @HFLAGS,R0
       JNE !
       B @MOVDIR     ; dock - no raft
!
       LI R7,->0100          ; Move up
       MOV R5,R8
       SB R8,R8   ;ANDI R8,>00FF
       ORI R8,>1800
RAFTGO
       LI R0,x#TSF191   ; Secret
       MOV R0,@SOUND2

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
       MOV R5,@HEROSP        ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       MOV R5,R0
       AI R0,>0600
       MOV R0,@SWRDSP        ; Use sword index for raft

       BL @DRWSPR

       BL @VSYNCM
       C R5,R8
       JNE -!

       CLR @SWRDSP+2       ; hide raft
       CI R7,->0100    ; going up?
       JEQ SCRNUP

       B @MAINLP

CELOUT    ; exit dungeon cellar/tunnel
       BL @DARKEN

       BL @BANK2X       ; map.asm
       DATA x#CLRSCN    ; clear screen before updating tiles

       BL @BANK3X       ; tiles.asm
       DATA x#DNBRD2    ; Load dungeon border walls

       ; TODO move hero position to near stairs
       BL @BANK2X       ; map.asm
       DATA x#GETDCX    ; Get dungeon cellar exit position and MAPLOC

       LI R0,INCAVE+DARKRM
       SZC R0,@FLAGS        ; Clear in cave flag

       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL @BANK3X          ; tiles.asm
       DATA x#DRKCOL       ; set dark colorset

       BL @CAVEOT       ; Update the flipped screen

       BL @DLAY10          ; delay 10 frames
       BL @LIGHTN

       BL @DLAY10          ; delay 10 frames
       BL @DLAY10          ; delay 10 frames

       LI R3,DIR_DN
       BL @BANK4X        ; herospr.asm
       DATA x#LNKDIR     ; load hero sprites and set direction flag

       B @AUTOM1

RAFTDN
       MOV  @HEROSP,R5
       LI R7,>0100          ; Move down
       MOV @DOOR,R8         ; Stop here
       JMP RAFTGO

SCRNRT LI   R0,>0100         ; Add 1 to MAPLOC X
       LI   R3,DIR_RT
       BL   @DOMAZE
       AB   R0,@MAPLOC
       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL   @SCRLRT
       B    @SCRLED

SCRNLT LI   R0,->0100         ; Add -1 to MAPLOC X
       LI   R3,DIR_LT
       BL   @DOMAZE
       AB   R0,@MAPLOC
       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL   @SCRLLT
       B    @SCRLED

SCRNUP
       LI  R0,INCAVE
       CZC @FLAGS,R0         ; Are we leaving a cave?  (dungeon)
       JNE CELOUT

       LI   R0,->1000         ; Add -1 to MAPLOC Y
       LI   R3,DIR_UP
       BL   @DOMAZE
       AB   R0,@MAPLOC
       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL   @SCRLUP
       B    @SCRLED

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
       LI   R3,DIR_DN
       BL   @DOMAZE
       AB   R0,@MAPLOC
       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL   @SCRLDN

       MOVB @MAPLOC,R1
       SRL R1,8
       CLR R0
       MOVB @CAVMAP(R1),R0  ; get cave entry
       CI R0,>1800    ; Raft ride?
       JEQ RAFTDN

       B    @SCRLED




CAVOUT ; R0=INCAVE
       SZC  R0,@FLAGS        ; Clear in cave flag

       LI R0,HEROST
       LI R1,>D000     ; player and all other sprites
       BL @VDPWB       ; Turn off most sprites

       BL @CLRCAV      ; Clear cave with spaces

       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

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
       CI R1,>D800           ; waterfall
       JEQ !
       ; TODO test for water - ride raft down

       AI R5,-8*256         ; -(17*256)-16    ; appear up and to the left
       MOV R5,@HEROSP        ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       JMP CAVOU3

!
       AI R5,>1100
       LI R9,17
       LI R10,3

       BL @QUIET
       LI R0,x#TSF212      ; Stairs sound
       MOV R0,@SOUND3
       LI R0,x#TSF213      ; Stairs sound
       MOV R0,@SOUND4

!
       LI R13,x#MSKBOT   ; load hero sprites masked BOTTOM (R3 = direction, R4=count)
       LI R3,DIR_DN
       MOV R9,R4
       DEC R4
       JNE !
       LI R13,x#LNKSPR   ; load hero sprites
!      BL @BANK4        ; herospr.asm

       AI R5,->0100     ; Move up

       BL @ANDOOR       ; Animate going out door

       DEC R9
       JNE -!!

CAVOU3
       BL @BANK6X
       DATA x#LMUSIC    ; Load overworld music

       BL @VSYNCM
       BL @VSYNCM
CAVOU4
       B @MAINLP


DUNOUT
       BL @QUIET          ; Turn off music

       LI R0,DUNLVL
       SZC R0,@FLAGS        ; Clear dungeon flag and level

       LI R0,MAPSAV
       BL @VDPRB
       MOVB R1,@MAPLOC  ; Restore saved overworld map location

       BL @BANK2X       ; map.asm
       DATA x#CLRSCN    ; clear screen before updating tiles

       BL @BANK3X       ; tiles.asm
       DATA x#OWTILE    ; Load overworld tiles in bank3

       BL @BANK5X       ; status.asm
       DATA x#STATS     ; Draw status bar information

       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position


       MOV @DOOR,R5     ; move hero to the door location
       MOV R5,@HEROSP
       MOV R5,@HEROSP+4

       BL @WIPE

       JMP CAVOU2

GODUNG
       LI R0,MAPSAV    ; Save overworld map location in VDP ram
       MOVB @MAPLOC,R1
       BL @VDPWB

       LI R0,DNENEM+VDPWM   ; clear dungeon enemies counts
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,128            ; 256 nibbles
!      CLR *R15
       DEC R1
       JNE -!

       SRL R2,8
       AI R2,->20            ; R2=dungeon level 1-9
       MOVB @DUNGSP(R2),R1   ; dungeon starting position
       MOVB R1,@MAPLOC

       SLA R2,12             ; Get dungeon level in >X000
       ORI R2,DIR_UP         ; Set up direction
       SOC R2,@FLAGS         ; Store dungeon level and direction

       BL @BANK2X       ; map.asm
       DATA x#CLRSCN    ; clear screen before updating tiles

       BL @BANK3X       ; tiles.asm
       DATA x#DNTILE    ; Load dungeon tiles in bank3

       ;LI R0,>400+(DRKTAB/>800)   ; VDP register 4
       ;BL @VDPREG

       ; fill in dungeon dark tileset
       LI R0,PATTAB
!      BL @READ32
       AI R0,DRKTAB-PATTAB
       BL @PUTSCR
       AI R0,PATTAB-DRKTAB+32-VDPWM
       CI R0,PATTAB+(96*8)
       JNE !
       LI R0,PATTAB+(>F0*8)
!      CI R0,PATTAB+(>100*8)
       JNE -!!


       BL @BANK5X       ; status.asm
       DATA x#STATS     ; Draw status bar information

       BL @BANK2X       ; map.asm
       DATA x#LOADSC    ; Load map into screen at current position

       BL @BANK6X       ; main.asm
       DATA x#LMUSIC    ; Load dungeon music

       BL  @WIPE

       LI R5,>B878        ; Put hero at cave entrance
       MOV R5,@HEROSP      ; Update color sprite
       MOV R5,@HEROSP+4    ; Update outline sprite

SCRLED ; after scrolling, check if darkened room and try lighting up
       MOV @FLAGS,R0
       ANDI R0,DARKRM
       JEQ !

       ;BL @VSYNCM        ; Wait for vertical sync and play music
       BL @BANK2X       ; map.asm
       DATA x#LITEUP    ; Light up room
       ;BL @VSYNCM        ; Wait for vertical sync and play music
!
       MOV @FLAGS,R0
       ANDI R0,DUNLVL   ; in a dungeon?
       JEQ AUTOM3 ; done

       ;  move player before closing shutters
       BL @BANK2X    ; map.asm
       DATA x#SHUTR2 ; get shutter mask R2 = NSWE bits

       MOV @FLAGS,R3
       ANDI R3,DIR_XX      ; Get direction RT=0 LT=1 DN=2 UP=3
       SWPB R3
       LI R0,1
       XOR R3,R0          ; change R0 so that LT=0 RT=1 UP=2 DN=3
       INC R0
       SLA R2,R0       ; shift shutter bit into carry
       JNC !
       AI R3,4         ; skip to shutter door spots
!
       SLA R3,1
       MOV @AMOVEX(R3),@TEMPRT  ; set target location

AUTOMV

       ; move the player to the target
!      BL @VSYNCM          ; Vsync+music
       BL @COUNT           ; update counters
       BL @MOVEX2          ; move any direction based on flags
       BL @DRWSPR          ; update hero sprites in VDP
       C  @HEROSP,@TEMPRT  ; Finished moving?
       JNE -!

       MOV @FLAGS,R0
       MOV R0,R1
       ANDI R0,DUNLVL   ; in a dungeon?
       JEQ AUTOM3     ; no

       ANDI R1,INCAVE
       JNE DUNCAV
AUTOM1 ; (from CELOUT)
       ; TODO player moves more if in shutter doorway
       BL @BANK2X       ; map.asm
       DATA x#SHUTTR    ; Close shutter doors
AUTOM2 ; (from DUNCAV)
       BL @BANK1X
       DATA x#LENEMY  ; Load dungeon enemies

       BL @BANK2X     ; map.asm
       DATA x#DNINIT  ; Load initial dungeon items

       BL @!SPRUPD

       LI R0,ECOUNT
       BL @VDPRB
       JNE AUTOM3     ; is ecount zero?

       BL @BANK2X
       DATA x#SHUTR2  ; get shutter mask bits
       JEQ AUTOM3     ; are there any shutters to open?

       BL @DLAY10      ; delay 10 frames
       BL @DLAY10      ; delay 10 frames

       BL @BANK2X
       DATA x#OPENER     ; check enemy count, open doors etc
AUTOM3 ; (from SCRLED)

       B @MAINLP

       ; automove coordinates targets
AMOVEX DATA >6810,>68E0,>2878,>A878  ; normal door spots
       DATA >6820,>68D0,>3878,>9878  ; shutter door spots

DUNCAV ; entering dungeon cave

       ;BL @BANK2X          ; map.asm
       ;DATA x#LITCAV       ; Load light tileset and palette (Modifies R0..R10,R13)
       ;BL @LIGHTN           ; Lighten darkened cave?

       ; set light pattern table
       LI R0,>400+(PATTAB/>800)   ; VDP register 4
       BL @VDPREG

       ; TODO load cellar bats

       JMP AUTOM3   ; done


* Do Forest Maze or Up Up Up Mountain
* Must preserve R0 if not in maze, CLR R0 otherwise
* R3 = direction (preserve)
* Modifies R1, R2
DOMAZE
       LI R1,DUNLVL
       CZC @FLAGS,R1
       JNE !
       LI R2,FRSTMZ ; Forest maze directions
       CB *R2+,@MAPLOC
       JEQ INMAZE
       LI R2,UPUPMT ; Up up mountain directions
       CB *R2+,@MAPLOC
       JEQ INMAZE
MAZE0  ; reset the maze state to zero
       ; TODO MAZEST could be moved to CPU RAM
       LI R1,MAZEST+VDPWM ; Maze state + VDP write mask
       MOVB @R1LB,*R14
       MOVB R1,*R14
       CLR *R15      ; Set it to zero
!      RT
INMAZE
       CB *R2,R3     ; Test exit
       JEQ MAZE0     ; Exit the maze

       LI R1,MAZEST
       MOVB @R1LB,*R14
       MOVB R1,*R14
       LI R1,VDPRD     ; VDP read data
       MOVB *R1,R1
       SWPB R1
       INC R1
       A R1,R2
       CB *R2,R3     ; Compare direction
       JEQ !         ; Went the right way
       CLR R0        ; Stay in the maze
       JMP MAZE0     ; Reset the maze state
!
       LI R2,MAZEST+VDPWM  ; Maze state + VDP write mask
       MOVB @R2LB,*R14
       MOVB R2,*R14
       MOVB @R1LB,*R15  ; Save maze state

       CI R1,4       ; Final step?
       JEQ !
       CLR R0        ; Stay in the maze
       RT
!
       LI R1,x#TSF191   ; Secret
       MOV R1,@SOUND2
       RT

       ; maploc  exit        step 1     step 2     step 3     step 4
FRSTMZ BYTE >61, DIR_RT/256, DIR_UP/256,DIR_LT/256,DIR_DN/256,DIR_LT/256 ; Forest maze directions
UPUPMT BYTE >1B, DIR_LT/256, DIR_UP/256,DIR_UP/256,DIR_UP/256,DIR_UP/256 ; Up up mountain directions


* Animate going in/out the door
* Move 4 frames, animate every 6 (R10 counts down from 3 every 2 frames)
* R5=hero pos
* R10=counter 3..0
* Modifies R0,R10,R8
ANDOOR
       MOV R11,R8        ; Save return address
       MOV R5,@HEROSP        ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       BL @DRWSPR

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
       B *R8         ; Return to saved address

       ;     Right,Left, Down, Up
PUSHDR DATA >0410,>03F0,>1004,>F804


* Push solid block
BLCKMV
       MOV R11,R10   ; save return address
       MOV R5,R9     ; save hero pos

       ; check to see if we're pushing the secret block
       MOV R3,R1
       SRL R1,7
       A @PUSHDR(R1),R5
       ANDI R5,>F8F8
       C @PSHBLK,R5
       JNE !

       BL @GALIGN    ; get aligned if needed

       MOV @FLAGS,R0
       ANDI R0,PUSHC
       CI R0,>00E0   ; compare push counter 14
       JEQ !!
       LI R0,>0010
       A R0,@FLAGS   ; increment push counter
!      MOV R9,R5     ; restore hero pos
       B *R10        ; return to saved address

!      ; pushed for 14 frames

       BL @SCHSTR     ; save scratch area

       LI R0,PATTAB+(>84*8)  ; char pattern address
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR      ; read rock pattern

       LI R0,SPRPAT+(>1C*8)  ; sprite pattern address
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW      ; store rock pattern in sprite

       BL @SCHRST      ; restore scratch area

       MOV R3,R4     ; save direction in rock object
       ORI R4,ROCKID ; rock ID and initial counter

       LI R0,CLRTAB+16  ; color table containing block character
       BL @VDPRB
       MOV R1,R6
       SRL R6,12     ; shift color into lowest nibble
       ORI R6,>1C00  ; set sprite index
       BL @!OBSLOT    ; spawn rock sprite

       ; erase rock tiles
       LI R1,>7879   ; Ground
       LI R2,>7A7B
       BL @STORCH    ; Draw R1 R2 at R5 (modifies R3)

       MOV R4,R3
       ANDI R3,DIR_XX ; restore direction
       CLR @PSHBLK    ; can't push again
       JMP -!!




* R3=direction pushed  R1=char that was solid
DNPUSH ; push something in a dungeon

       CI R1,>8100   ; Water
       JNE !
       B @LADDE1
!
       ANDI R1,>FC00
       CI R1,>8400   ; pushable block
       JEQ BLCKMV

       ANDI R1,>F000
       CI R1,>D000   ; locked door
       JEQ PUSHKD
       RT

* Push key door
PUSHKD
       MOV @FLAGS,R0
       ANDI R0,PUSHC
       CI R0,>00E0   ; compare push counter 14
       JEQ !
       LI R0,>0010
       A R0,@FLAGS   ; increment push counter
PUSHRT RT
!      ; pushed for 14 frames
       ; TODO do we have a key? or the magic key
       ; TODO decrement keys

       LI R0,x#TSF282    ; Door open sound
       MOV R0,@SOUND3
       LI R0,x#TSF283    ; Door open sound
       MOV R0,@SOUND4

       LI R13,x#UNLOKD    ; Unlock door at facing R3
       B @BANK2    ; return thru bank switch


* touching armos, or pushing block?
* R3=direction pushed  R1=char that was solid   R0=char position
SOLID
       LI R2,DUNLVL
       CZC @FLAGS,R2
       JNE DNPUSH     ; in a dungeon?

       CI R1,>DA00    ; Waterfall?
       JNE !
       CI R3,DIR_UP
       JNE !
       LI R11,MAINLP     ; Return to main loop
       B @MOVEU0
!

       ANDI R1,>FC00
       CI R1,>F400    ; gravestone F4-F7
       JEQ GRAVE
       ; TODO spawn ghini
       CI R1,>DC00    ; armos statue DC-DF
       JNE !
       B @ARMOST
!

       CI R1,>9400    ; green rock 94-97
       JEQ ROCKMV
       CI R1,>9C00    ; red rock 9C-9F
       JEQ ROCKMV

       ANDI R1,>F000  ; Mask to water group
       CI R1,>E000    ; water group?
       JNE PUSHRT
       B @LADDE1     ; use ladder

GRAVE
       ; is grave a secret entrance
       MOV R5,R9     ; save hero pos
       CI R3,DIR_UP
       JEQ !
       CI R3,DIR_DN
       JNE GHINI    ; return
       AI R5,>1800   ; grave is below player
!      AI R5,->0800+4  ; grave is above player
       ANDI R5,>FFF8
       C @DOOR,R5
       JNE GHINI
       LI R6,>1C01   ; sprite and color
       JMP ROCKM2

ROCKMV ; rock move
       MOV @HFLAG2,R2
       ANDI R2,PBRACE  ; have power bracelet?
       JEQ PUSHRT

       ; locate rock
       MOV R5,R9     ; save hero pos
       CI R3,DIR_UP
       JEQ !
       CI R3,DIR_DN
       JNE PUSHRT
       AI R5,>1800   ; rock is below player
!      AI R5,->0800+4  ; rock is above player
       ANDI R5,>FFF8

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
;       MOV R9,R0
;       ANDI R0,>0007
;       JEQ !
;       MOV R9,R5
;       B @MOVEU0
;!
       MOV R9,R5
       BL @GALIGN    ; get aligned to multiple of 8 pixels

       MOV R11,R10   ; save return address
       LI R6,>1C06   ; red rock
       CI R1,>9400
       JNE !
       LI R6,>1C02   ; green rock
!
ROCKM2
       LI R0,SCHSAV
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW      ; save scratch area

       LI R0,PATTAB+(>9C*8)  ; rock
       CI R6,>1C01
       JNE !
       LI R0,PATTAB+(>F4*8)  ; gravestone
!
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
       BL @!OBSLOT    ; spawn rock sprite

       ; erase rock tiles
       LI R1,>1414   ; Ground
       CI R6,>1C01
       JNE !
       LI R1,>0808   ; Grey ground
!      MOV R1,R2
       BL @STORCH    ; Draw R1 R2 at R5 (modifies R3)

       MOV R4,R3
       ANDI R3,DIR_XX ; restore direction
       MOV R9,R5     ; restore hero pos
       B *R10        ; return to saved address

GHINI
       MOV R9,R5
       LI R4,GHINID |>FF00 ; ghini id
       LI R6,GHINIC ; ghini color
       JMP !
ARMOST ; armos touched
       LI R4,ARMOID ; armos id
       LI R6,ARMOSC ; armos color
!
       MOV R5,R9  ; save R5

       AI R0,32*-3   ; -3 rows
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
       BL @!OBSLOT
       MOV R10,R11  ; Restore return address

!      MOV R9,R5  ; restore R5
!      RT



* R3=direction pushed
LADDE1 ; use ladder (water already checked)
       LI R0,LADDER
       CZC @HFLAGS,R0
       JEQ -!

       ; TODO check if space on other side
       MOV R11,R12   ; Save return address
       MOV R3,R4    ; Save direction

       SRL R3,7
       LI R2,LADDE3   ; Return if solid

       MOV R5,R0
       ORI R0,>0800
       MOV R0,R8

       A @LADDXY(R3),R0
       BL @TESTCH
       ANDI R1,>FE00
       CI R1,>6000   ; ladder chars
       JEQ LADDE3

       MOV R5,R0
       A @LAD2XY(R3),R0
       BL @TESTCH
       ANDI R1,>FE00
       CI R1,>6000   ; ladder chars
       JEQ LADDE3

       A @LAD3XY(R3),R8  ; Hero pos + ladder offset

       ; Make sure not already standing on ladder
       LI R0,LADPOS   ; Load ladder position
       MOVB @R0LB,*R14
       MOVB R0,*R14

       MOVB @VDPRD,R9
       JEQ LADDE2        ; Ladder is not placed yet
       MOVB @VDPRD,@R9LB

       MOV R9,R0
       S R5,R0
       CI R0,->0700     ; Hero above ladder
       JLT !

       CI R0,>0F00     ; Hero below ladder
       JGT !

       SWPB R0
       ABS R0
       CI R0,>0F00
       JL LADDE3     ; Standing on ladder
!
       BL @GALIGN    ; get aligned to multiple of 8 pixels

       LI R0,LADPOS+2
       LI R1,R6LB-1 ; Load regs R6-R7
       LI R2,4
       BL @VDPR

       MOV R6,R1
       MOV R7,R2
       BL @STORC9   ; Erase old ladder with old chars at position R9

LADDE2
       BL @BANK2X       ; map.asm
       DATA x#DRWLAD    ; Draw ladder and save chars underneath  R5=ladder pos
LADDE3
       MOV R4,R3    ; Restore direction
       B *R12    ; Return to saved address

* Facing     Right Left  Down  Up
LADDXY DATA >0420,>04EF,>2004,>EF04     ; Test char offset 1
LAD2XY DATA >0C20,>0CEF,>200C,>EF0C     ; Test char offset 2
LAD3XY DATA >0410,>03F0,>1004,>F004     ; Place ladder offset
DUNCZC DATA DUNLVL



* Sword subroutine, SWRDOB is nonzero, returns to MAINLP
* R0=SWRDOB counter
* R3=facing DIR_xx
* R5=HEROSP sprite yx
SWORD  ; R0=SWRDOB
       MOV @SWRDSP+2,R8      ; Get sprite index and color

       ; Check for direction changes
       MOV @KEY_FL,R1
       SLA R1,4     ; shift right edge into carry
       JNC !
       LI R1,DIR_RT
       JMP SWORD1

!      SLA R1,1     ; shift left edge into carry
       JNC !
       LI R1,DIR_LT
       JMP SWORD1

!      SLA R1,1     ; shift down edge into carry
       JNC !
       LI R1,DIR_DN
       JMP SWORD1

!      SLA R1,1     ; shift up edge into carry
       JNC !
       LI R1,DIR_UP
SWORD1 XOR @FLAGS,R1
       XOR R1,R3
       MOV R3,@FLAGS    ; set new direction flags
       ANDI R3,DIR_XX
       BL @BANK4X       ; herospr.asm
       DATA x#LNKATK    ; load new attack direction sprites
       CLR R0
       MOVB @SWRDOB,R0  ; get sword counter again
       JMP SWORD2       ; reposition sword sprite
!

       AI R0,->100
       MOVB R0,@SWRDOB       ; Decrement and save sword counter
       JNE !

       LI R1,>D200          ; Sword YY address (hide)
       MOV R1,@SWRDSP
       CLR @SWRDSP+2         ; reset sprite index and color
       BL @BANK4X            ; herospr.asm
       DATA x#LNKSPR         ; load normal sprites

       CI R8,MRODSC          ; Magic rod sprite & color?
       JEQ MRBEAM            ; Do Magic Rod beam
       JMP SWBEAM            ; Do sword beam
       JMP SWORD4
!
       CI R0,>0800           ; Sword appears on fourth frame
       JNE !!

SWORD2
       MOV R3,R1             ; Get facing and offset into SWORDX table
       SRL R1,7

       MOV R5,R7           ; Position relative to link
       A   @SWORDX(R1),R7

       CI R8,MRODSC           ; Don't change Magic Rod sprite
       JEQ !
       MOV R3,R8             ; Get direction
       SLA R8,2              ; shift it into sprite index
       ORI R8,>7000+(ASWORC & 15) ; Sword facing, sprite and color
       LI R1,WSWORD+MSWORD   ; Determine the sword color
       CZC @HFLAGS,R1
       JEQ !
       ORI R8,>000F          ; make it white
!
       MOV R8,@SWRDSP+2      ; set sword sprite and color
       MOV R7,@SWRDSP        ; set sword coordinate
!
       CI R0,>0200           ; Sword retract for 2 frames
       JH !
       MOV R3,R1             ; Get facing and offset into SWORDX table
       SRL R1,7
       A   @SWORDY(R1),@SWRDSP  ; Retract sword
!
SWORD4
       B  @MAINLP


SWBEAM
       LI R0,FULLHP
       CZC @FLAGS,R0         ; Test for sword beam
       JEQ SWORD4

       MOV @BSWDOB,R0     ; Sword beam already active?
       JNE SWORD4

       LI R0,x#TSF232    ; Lasersword sound
       MOV R0,@SOUND3
       LI R0,x#TSF233    ; Lasersword sound
       MOV R0,@SOUND4

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

       MOV R0,@BSWDOB       ; object type
       MOV R5,@BSWDSP       ; sprite YYXX
       MOV R6,@BSWDSP+2     ; sprite index and color

       JMP SWORD4

MRBEAM ; Magic Rod beam
       MOV @BSWDOB,R0
       ANDI R0,OBJMSK      ; Magic can override beam sword
       CI R0,MAGCID       ; but not itself
       JEQ SWORD4

       LI R0,x#TSF80       ; Magic sound
       MOV R0,@SOUND1

       LI R0,MAGCID
       LI R6,>B00F       ; Magic sprite and color

       JMP -!


SWORDX DATA >010B,>00F5,>0B01,>F3FF
SWORDY DATA -4,4,->400,>400     ; Sword retract offsets



ITEMFN DATA BMRGFN,BOMBFN,ARRWFN,CNDLFN
       DATA FLUTFN,BAITFN,POTNFN,MAGCFN

* bits right,left,down,up  (index by 4-bit dpad, counter directions cancel out)
BMRNGD BYTE 8,6,2,8 ; none, up, down, none
       BYTE 4,5,3,4 ; left, upleft, downleft, left
       BYTE 0,7,1,0 ; right, upright, downright, right
       BYTE 8,6,2,8 ; none, up, down, none
* bits right,left,down,up (index by facing direction)
BMRNGE BYTE 0,4,2,6 ; right, left, down, up

THROWJ DATA THROWR,THROWL,THROWD,THROWU   ; overworld
       DATA THRDNR,THRDNL,THRDND,THRDNU   ; dungeon

* Check to see if hero has room to spawn an item in the direction he's facing
* Returns if ok, jumps to ITMNXT otherwise
* Modifes R1,R7
THROW
       MOV R3,R1
       SRL R1,7
       MOV @FLAGS,R7
       ANDI R7,DUNLVL
       JEQ !
       AI R1,8       ; table stride
!      MOV @THROWJ(R1),R1
       MOV R5,R7     ; R5=YYXX
       SWPB R7       ; R7=XXYY
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
THRDNL
       CI R7,(32)*256
       JL ITMNXT
       RT
THRDNR
       CI R7,(256-24-16+1)*256
       JHE ITMNXT
       RT
THRDND
       CI R5,(192-16-24+1)*256
       JHE ITMNXT
       RT
THRDNU
       CI R5,(24+24)*256
       JL ITMNXT
       RT

BMRGFN ; Boomerang
       MOV @BMRGOB,R0
       JNE ITMNXT    ; Boomerang already active

       MOV @HFLAGS,R0
       ANDI R0,BMRANG+MAGBMR   ; test to see if we have either boomerang
       JEQ ITMNXT

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


*            Right Left  Down  Up
BOMBXY DATA >0010,>FFF0,>1000,>F000
       ;BOMBXY DATA >FF10,>FEF0,>0F00,>EF00  ; was this old version to adjust for Y offset?

BOMBFN ; Bomb
       MOV @BOMBOB,R0
       JNE ITMNXT    ; Bomb already active

       ; TODO have enough bombs?

       BL @THROW
       ; TODO decrement bombs

       LI R7,BOMBOB-OBJECT
       LI R4,BOMBID
       LI R6,BOMBSC          ; Bomb is C4

       LI R0,x#TSF100     ; Bomb drop sound
       MOV R0,@SOUND1

       JMP ITMSPN

ARRWFN ; Arrow
       MOV @ARRWOB,R0
       JNE ITMNXT   ; Arrow already active

       BL @THROW

       ; TODO have enough rupees?
       ;CLR R0
       ;MOVB @RUPEES,R0
       LI R0,SDRUPE
       BL @VDPRB
       JEQ ITMNXT    ; No rupees?

       AI R1,->100         ; Decrement rupees
       ;MOVB R0,@RUPEES
       BL @VDPWB

       ; TODO update status
       MOV R3,R4           ; Save R3
       ;BL @STATUS          ; Update status
       BL @BANK5X
       DATA x#STATS     ; Draw status bar information
       
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

       LI R0,x#TSF132   ; Flame sound
       MOV R0,@SOUND3
       LI R0,x#TSF133   ; Flame sound
       MOV R0,@SOUND4

       JMP ITMSPN


FLUTFN ; Flute
       LI R0,DUNLVL
       CZC @FLAGS,R0
       JNE FLUTDN

       LI R0,x#TSF141       ; Flute sound
       MOV R0,@SOUND2


       LI R4,152    ; for 152 frames
!      BL @VSYNCM
       DEC R4
       JNE -!

       MOVB @MAPLOC,R0
       CI R0,>4200    ; Level 7 entrance
       JEQ OPENL7

       LI R4,TORNID
       MOV R5,R9
       ANDI R5,>FF00   ; move left
       LI R6,CLOUD1
       BL @!OBSLOT
       MOV R9,R5
       JMP ITMNXT

FLUTDN ; Flute played in dungeon
       ; TODO break digdogger
       JMP ITMNXT

BAITFN ; Bait
       JMP ITMNXT
POTNFN ; Letter/Potion
       JMP ITMNXT
MAGCFN ; Magic Rod
       BL @THROW

       LI R0,>0C00       ; Magic Rod animation is 12 frames
       MOVB R0,@SWRDOB
       LI R0,MRODSC       ; Magic Rod is single sprite, dark blue
       MOV R0,@SWRDSP+2

       LI R0,>0800
       SZC R0,@HEROSP+2   ; set animation frame to 0
       SZC R0,@HEROSP+6   ; set animation frame to 0
       BL @DRWSPR         ; update sprite list before changing patterns
       BL @BANK4X         ; herospr.asm
       DATA x#LNKATK      ; load attack sprites

       JMP ITMNXT


OPENL7
       LI R4,LAKEID
       MOV R5,R9
       LI R5,>D200   ; hidden
       BL @!OBSLOT
       MOV R9,R5

       B @ITEMX




HLDITM
       LI R0,x#TSF170      ; cave item music
       MOV R0,@SOUND1
       LI R0,x#TSF121      ; fairy/item sound
       MOV R0,@SOUND2
       LI R0,x#TSF172
       MOV R0,@SOUND3

       BL @BANK4X         ; herospr.asm
       DATA x#LNKITM      ; holding item sprites

       LI R4,128*>0100
       MOVB R4,@HURTC    ; store the counter in HURTC

       LI R0,SCRFLG
       SZC R0,@FLAGS    ; force flip flag to known value

!      BL @VSYNCM

       CLR R0
       MOVB @HURTC,R0
       CI R0,65*>0100
       JLE !
       BL @FLIP
!
       BL @DRWSPR

       ;BL @BANK5X
       ;DATA x#MOVOBJ         ; do moving objects

       BL @COUNT    ; Modifies R0-R13

       LI R0,>FF00
       AB R0,@HURTC    ; decrement until zero
       JNE -!!

       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       BL @BANK4X       ; herospr.asm
       DATA x#LNKSPR    ; load normal sprites

       B @MENUX


* Link hurt animation
* R4[15..10] = counter
* R4[9..8] = knockback direction
* Modifies R0-3,R9-10
LNKHRT
       MOV R11,R9              ; Save return address

       MOVB @HP,R0
       JNE !
       B @!GAMOVR

!      ANDI R4,>FF00
       CI R4,50*>0400          ; Holding item
       JEQ HLDITM

       AI R4,->0400            ; Dec counter bits
       MOV R4,R1               ; Get counter in R1
       SRL R1,10
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2

       CI R4,40*>400           ; Compare to 40<<10
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

!      MOV R9,R11       ; Restore saved address
       CI R4,>0400
       JHE LNKCL2
LNKCLR CLR R4           ; Countdown finished
       ; set the color of the map and link sprite (except green, which returns immediately)
       MOV @HFLAG2,R0
       ANDI R0,REDRNG+BLURNG
       JEQ LNKCL2  ; if no rings, then green (last color in hurt pattern)
       LI R1,BLUCLR ; Light Blue
       ANDI R0,REDRNG
       JEQ !
       LI R1,REDCLR ; Medium Red
!      LI R0,MPDTST+2  ; copy hero color to map dot sprite color
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R0,>E000     ; map dot sprite index
       MOVB R0,*R15
       MOVB R1,*R15


       MOVB R1,@HEROSP+3  ; hero sprite color
LNKCL2
       MOVB R4,@HURTC
       RT
LNKCL4      ; LNKCLR called from bank 4
       MOV R11,R13     ; save return address
       BL @LNKCLR
       B @BANK4       ; return to saved address in bank 4


LNKHJT ; Hero hurt jump table
       DATA LNKHJR,LNKHJL,LNKHJD,LNKHJU

LNKHRC ; Hero hurt colors, 2 frames each
       DATA GRNCLR+1   ; green, black  (normal colors)  TODO blue/red based on rings
       DATA >040F      ; dark blue, white
       DATA >060F      ; red, white
       DATA >0106      ; black, red


* Hero movement, R3=direction 0=Right 2=Left 4=Down 6=Up, R5=YYXX position
* Modifies R0-2,R10
LNKMOV
       MOV R11,R10          ; Save return address
       MOV R5,R0
       SZC @HMOVEM(R3),R0   ; Position aligned to 8 pixels?
       JNE !                ; Not aligned so move normally

       MOV R11,R2           ; Return immediately if obstruction
       MOV R5,R0
       A @LMOVEA(R3),R0
       BL @TESTCH
       MOV R5,R0
       A @LMOVEB(R3),R0
       BL @TESTCH

!      A @HMOVED(R3),R5     ; Do movement
       BL *R10              ; Return to saved address


* Facing     Right Left  Down  Up
HMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
HMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)

* Facing     Right Left  Down  Up
LMOVEA DATA >0810,>07FF,>1000,>0700     ; Test char offset 1
LMOVEB DATA >0F10,>0EFF,>100F,>070F     ; Test char offset 2




STORC9 ; same as below but at R9
       MOV R9,R0
       JMP !
* Store characters R1,R2 at R5 in name table
* Modifies R0,R1,R3
STORCH
       MOV R5,R0
!      ; Convert pixel coordinate YYYYYYYY XXXXXXXX
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

; TODO remove this if it isn't used
* STORCH and returns characters in R6,R7
;SAVECH
;       MOV R5,R0
;       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
;       ; to character coordinate        YY YYYXXXXX
;       ANDI R0,>F8F8
;       MOV R0,R3
;       SRL R3,3
;       MOVB R3,R0
;       SRL R0,3
;       MOV @FLAGS,R3
;       ANDI R3,SCRFLG
;       A R3,R0
;
;       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
;       MOVB R0,*R14         ; Send high byte of VDP RAM read address
;       AI R0,32
;       MOVB @VDPRD,R6
;       MOVB @VDPRD,@R6LB
;
;       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
;       MOVB R0,*R14         ; Send high byte of VDP RAM read address
;       AI R0,-32+VDPWM
;       MOVB @VDPRD,R7
;       MOVB @VDPRD,@R7LB
;       LI R3,2
;       JMP -!


CAVEOT
       MOV R11,R13        ; Save return address

       ;MOV  @DOOR,R5        ; Move link to door location
       ;AI R5,->0100         ; Move Y up one
       ;MOV R5,@HEROSP	    ; Update color sprite
       ;MOV R5,@HEROSP+4     ; Update outline sprite
       ;LI R0,>0100
       ;MOVB R0,@HEROSP+7    ; Set outline color to black


       ; fall thru
CAVEIN
       MOV R11,R7        ; Save return address
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
       BL @DLAY10        ; Delay 10 frames
       ; fall thru
CUT
       BL @SCHSTR       ; store scratchpad to VDP
       LI R4,LEVELA     ; Set source to new screen
       LI  R9,22        ; Copy 22 lines
       LI  R8,SCRFLG
       XOR @FLAGS,R8   ; Set dest to flipped screen
       ANDI R8,SCRFLG
       AI R8,(3*32)
!
       MOV R4,R0
       BL @READ32

       MOV R8,R0
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       AI R4,32
       AI R8,32

       DEC R9
       JNE -!

       BL @VSYNCM
       BL @FLIP

       CLR R1
       BL @ADDSPR      ; FIXME why is this here?

       BL @SCHRST      ; restore scratchpad
       LI R3,DIR_DN
       B *R7          ; return to saved address





* Scan objects for empty slot: store R4 index & data, R5 in location, R6 in sprite index and color
* Modifies R0,R1
!OBSLOT
       LI R1,MOVEOB      ; Start at slot 13
!      MOV *R1+,R0
       JEQ !
       CI R1,SPRLST
       JNE -!
       RT            ; Unable to find empty slot
!      DECT R1
       MOV R4,*R1    ; Store object data
       AI R1,-OBJECT+(SPRLST/2)
       A R1,R1
       MOV R5,*R1+   ; Store sprite location
       MOV R6,*R1    ; Store sprite index and color
       RT

SPRLS1 EQU SPRLST+(4*6)
SPRLS2 EQU SPRLST+(4*31)
!GAMOVR
       LI R0,>D000
       MOVB R0,@SPRLS1  ; Turn off sprites 6+
       MOVB R0,@SPRLS2  ; Turn off sprites 6+
       BL @-DRWSPR
       BL @VSYNC0
       LI R3,DIR_DN

       BL @BANK3
       DATA x#LNKSPR

       LI R4,32      ; Hurt Blink 32 frames
!      MOV R4,R1
       ANDI R1,>0006           ; Get animation index (changes every 2 frames)
       MOV @LNKHRC(R1),R1      ; Get flashing color
       MOVB R1,@HEROSP+3       ; Store color 1
       MOVB @R1LB,@HEROSP+7    ; Store color 2
       BL @VSYNC0
       BL @-DRWSPR
       DEC R4
       JNE -!

       BL @BANK3
       DATA x#LNKSPR
       BL @-DRWSPR

       BL @QUIET
       B @BANK3X       ; doesn't return
       DATA x#GAMOVR

* Modifies R0-R4,R8-R10,R12,R13
DARKEN
       MOV R11,R8
       BL @DLAY10          ; delay 10 frames

       ; TODO Set dark palette
       BL @BANK3X          ; tiles.asm
       DATA x#DRKCOL       ; set dark colorset

       BL @DLAY10          ; delay 10 frames

       ; set dark pattern table
       LI R0,>400+(DRKTAB/>800)   ; VDP register 4
       BL @VDPREG

       BL @DLAY10          ; delay 10 frames

       B *R8

DARKN2   ; called from bank 2
       MOV R11,R9
       BL @DARKEN
       MOV R9,R13
       B @BANK2



* Modifies R0-R5,R10,R12,R13
LIGHTN
       MOV R11,R5    ; save return address

       ; set light pattern table
       LI R0,>400+(PATTAB/>800)   ; VDP register 4
       BL @VDPREG

       BL @DLAY10          ; delay 10 frames

       BL @BANK3X          ; tiles.asm
       DATA x#LITCOL       ; set light colorset

       BL @DLAY10          ; delay 10 frames

       B *R5      ; return to saved address

; called from map.asm: LITCDL
LITUP5  ; light up then return to bank 5. R6=return address
       BL @LIGHTN
       MOV R6,R13    ; set return address
       B @BANK5
