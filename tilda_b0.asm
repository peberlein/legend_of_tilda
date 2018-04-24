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

       LI R0,>FA00           ; Initial Rupees
       MOVB R0,@RUPEES
       LI R0,>0000           ; Initial Keys
       MOVB R0,@KEYS
       LI R0,>0000           ; Initial Bombs
       MOVB R0,@BOMBS
       LI R0,>0400           ; Initial Hearts-1
       MOVB R0,@HEARTS

       CLR R0
       ;LI R0,MAGSHD      ; Test initial magic shield
       MOV R0,@HFLAGS     ; TODO get hero flags from save data
       CLR R0
       MOV R0,@HFLAG2

RESTRT
       CLR @FLAGS

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

       LI   R0,>7700         ; Initial map location is 7,7
       MOVB R0,@MAPLOC

       LI R0,>0A00           ; Initial HP
       MOVB R0,@HP

       CLR @FLAGS

       MOV @VDPINI,R0      ; Turn off blanking
       ORI R0,>0100        ; Reg 1
       BL @VDPREG


       LI R9,32-6
       LI R1,OBJECT+12     ; Clear object table, starting at sword
!      CLR *R1+
       DEC R9
       JNE -!

       LI   R0,BANK5         ; Menu functions in bank 5
       LI   R1,MAIN          ; First function in bank 1
       LI   R2,10            ; Get item selection
       BL   @BANKSW

       BL @STATUS            ; Draw status

       LI   R0,BANK2         ; Overworld is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       LI   R2,5             ; Use wipe from center 5
       BL   @BANKSW

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


; Object function pointer table, functions called with data in R4,
; sprite YYXX in R5, idx color in R6, must return by B @OBNEXT
OBJTAB DATA OBNEXT,PEAHAT,TKTITE,TKTITE  ; 0-3 - - Red Blue
       DATA OCTORK,OCTORK,OCTRKF,OCTRKF  ; 4-7 Red Blue Red Blue
       DATA MOBLIN,MOBLIN,LYNEL, LYNEL   ; 8-B Red Blue Red Blue
       DATA GHINI, ROCK, LEEVER,LEEVER   ; C-F - - Red Blue
       DATA ZORA, FLAME, FAIRY2, HEART2  ; 10-13
       DATA BSWORD,MAGIC,BSPLSH,BADNXT   ; 14-17
       DATA DEAD, BOMB, BMRNG, CAVITM    ; 18-1B
       DATA BULLET,ARROW,ASPARK,CAVNPC   ; 1C-1F
       DATA RUPEE, BRUPEE,HEART,FAIRY    ; 20-23
       DATA TEXTER                       ; 24-27
                                         ; 28-2B
                                         ; 2C-2F

BSWDID EQU >0014 ; Beam Sword ID
MAGCID EQU >0015 ; Magic ID
BPOPID EQU >0040 ; Beam Sword/Magic Pop ID (SOC on BSWDID or MAGCID)
BSPLID EQU >0816 ; Beam Sword Splash ID with initial counter
DEADID EQU >1218 ; Dead Enemy Pop ID w/ counter=18
RUPYID EQU >5020 ; Rupee ID with initial counter
BRPYID EQU >5021 ; Blue Rupee ID with initial counter
HARTID EQU >5022 ; Heart ID with initial counter
FARYID EQU >5023 ; Fairy ID with initial counter
ZORAID EQU >0010 ; Zora ID
BOMBID EQU >4C19 ; Bomb ID with initial counter
FLAMID EQU >5D11 ; Flame ID with initial counter
BMFMID EQU >BF11 ; Book of Magic Flame ID with initial counter
BMRGID EQU >001A ; Boomerang ID
ARRWID EQU >001D ; Arrow ID
SPRKID EQU >00DE ; Spark ID with initial counter=3
CAVEID EQU >001F ; Cave NPC ID
ITEMID EQU >001B ; Cave item ID
TEXTID EQU >0024 ; Cave Message Texter ID
BULLID EQU >001C ; Octorok bullet ID
FRY2ID EQU >0012 ; Fairy at pond ID
HRT2ID EQU >0013 ; Heart that spins around fairy ID

       ; Enemy sprite index and color
ECOLOR DATA >0000,>2009  ; None, Peahat
       DATA >3009,>3005  ; Red Tektite, Blue Tektite
       DATA >4008,>4004  ; Octorok sprites
       DATA >4008,>4004  ; Fast Octorok Sprites
       DATA >2006,>2004  ; Moblin Sprites
       DATA >4006,>4004  ; Lynel Sprites
       DATA >200F,>2009  ; Ghini, Rock
       DATA >3006,>3004  ; Leever Sprites
       DATA >680D,>0000  ; Zora, Fire
       DATA >0000,>0000  ;
       DATA >0000,>0000  ; Beam Sword, Magic
       DATA >0000,>0000  ; Beam splash
       DATA >0000,>0000  ; Dead
       DATA >0000,>0000  ;
       DATA >0000,>0000  ; Bullet,arrow
       DATA >0000,>0000  ;
       DATA >C004,>C004  ; Rupee, Blue rupee
       DATA >C800,>F400  ; Heart, Fairy

* Some sprites
CLOUD1 EQU >D00F    ; Cloud full
CLOUD2 EQU >D40F    ; Cloud mid
CLOUD3 EQU >D80F    ; Cloud sparse
BULLSP EQU >6006    ; Octorok bullet, red
FARYSP EQU >F409    ; Fairy
HRT2SP EQU >C806    ; Heart


       ; Damage enemies do to attack hero
       ; 1 dmg = 1/2 heart w/ no ring = 1/4 heart w/ blue ring = 1/8 heart w/ red ring
EDAMAG BYTE >00,>01  ; None, Peahat
       BYTE >01,>01  ; Red/Blue Tektite
       BYTE >01,>01  ; Octorok
       BYTE >01,>01  ; Fast Octorok
       BYTE >01,>01  ; Moblin
       BYTE >02,>04  ; Lynel
       BYTE >02,>01  ; Ghini, Rock
       BYTE >01,>02  ; Red/Blue Leevers
       BYTE >01,>01  ; Zora, Fire
       BYTE >00,>00  ;
       BYTE >04,>04  ; Beam Sword, Magic
       BYTE >00,>00  ; Beam splash
       BYTE >00,>00  ; Dead
       BYTE >00,>00  ;
       BYTE >01,>01  ; Bullet,arrow
       BYTE >00,>00  ;

OBNEXT
       MOV @OBJPTR,R1       ; Get sprite index
       MOV R4,@OBJECT(R1)   ; Save data
       A R1,R1
       AI R5,->0100         ; Adjust Y pos
       MOV R5,@SPRLST(R1)   ; Save sprite pos
       MOV R6,@SPRLST+2(R1) ; Save sprite id & color
       SRL R1,1
       JMP OBLOOP

INFLP
       ;LI   R0,>07FF          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @VSYNCM              ; wait for Vsync and play music
       
       ;LI   R0,>07F1          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @SPRUPD

       LI R1,7*2-2         ; Process sprites starting with flying sword (7)
OBLOOP INCT R1
       CI R1,64            ; Stop after last sprite
       JEQ INPUT

       MOV R1,@OBJPTR      ; Save pointer
       MOV @OBJECT(R1),R4  ; Get func index and data
       A R1,R1
       MOV @SPRLST(R1),R5  ; Get sprite location
       AI R5,>0100         ; Adjust Y pos
       MOV @SPRLST+2(R1),R6  ; Get sprite color
       
       SRL R1,1
       MOV R4,R3
       ANDI R3,>003F ; Get sprite function index
       JEQ OBLOOP
       
       A R3,R3
       MOV @OBJTAB(R3),R1
       B *R1       ; Jump to sprite function
       
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
       AI R5,>0100         ; Adjust Y pos

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
       SLA R0,14
       JOC MOVEDN

       MOV @KEY_FL,R0
       SLA R0,15
       JOC MOVEUP

HKEYS
       MOV @KEY_FL,R0
       SLA R0,13
       JOC MOVELT

       MOV @KEY_FL,R0
       SLA R0,12
       JOC MOVERT
!

       BL  @SWORD           ; Animate sword if needed

       B @DRAW




MOVEDN
       LI R3,DIR_DN
       BL @SWORD

       CI R5,(192-8)*256   ; Check at bottom edge of screen
       JL !
       BL @SCRLDN     ; Scroll down
       LI R3,DIR_DN
!
       MOV R5,R0
       AI R0,>1004    ; 16 pixels down, 4 right
       LI R2,HKEYS
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
       BL @SCRLUP     ; Scroll up
       LI R3,DIR_UP
!      
       MOV R5,R0
       AI R0,>0704    ; 7 pixels down, 4 right
       LI R2,HKEYS
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
       BL @SCRLRT     ; Scroll right

!      LI R3,DIR_RT
       MOV R5,R0
       AI R0,>0810    ; 8 pixels down, 16 right
       LI R2,MOVE4
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
       BL @SCRLLT     ; Scroll left

!      LI R3,DIR_LT
       MOV R5,R0
       AI R0,>07FF  ; 8 pixels down, 1 left
       LI R2,MOVE4
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


; Load sprite patterns for hero facing direction
; R3=FACE{DN,RT,LT,UP}
; Modifies R0-2,R10
DRAW
       AI R5,->0100          ; Move Y up one
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       AI R5,>0100           ; Move Y down one
LNKSPR
       MOV @FLAGS,R0
       MOV R0,R1
       ANDI R0,DIR_XX
       ANDI R1,DUNGON  ; Test for dungeon (sprite masking needed at doors)
       JNE LNKSP3

LNKSP1 C R3,R0        ; Update facing if up/down was pressed against a wall
       JEQ INFLP2
       LI R2,2       ; Load hero sprites
LNKSP4 SZC R0,@FLAGS
       SOC R3,@FLAGS
LNKSP2
       LI R0,BANK4   ; Load the new sprites
       LI R1,MAIN
       BL @BANKSW

INFLP2
       B @INFLP
; Draw masked sprites if going thru dungeon door
LNKSP3

       LI R4,>2800  ; Top of screen
       C R5,R4
       JHE !
       S R5,R4
       SRL R4,8
       INC R4
       LI R2,8       ; Mask top
       JMP LNKSP4
!
       LI R4,>A8FF ; Bottom of screen
       C R5,R4
       JLE !
       S R5,R4
       NEG R4
       SRL R4,8
       INC R4
       LI R2,7       ; Mask bottom
       JMP LNKSP4
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
       JMP LNKSP4
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
       JMP LNKSP4
!
       SWPB R5     ; Restore to YYXX
       JMP LNKSP1



* Go into doorway or stairs
GODOOR
       LI R0,BANK5
       LI R1,MAIN
       LI R2,13
       BL @BANKSW

       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       LI R2,2       ; Load hero sprites
       JMP LNKSP2


SCRLRT LI   R0,>0100         ; Add 1 to MAPLOC X
       LI   R2,4             ; Use scroll right 4
       JMP SCROLL

SCRLLT LI   R0,>FF00         ; Add -1 to MAPLOC X
       LI   R2,3             ; Use scroll left 3
       JMP SCROLL

SCRLDN LI  R0,INCAVE
       CZC @FLAGS,R0         ; Are we leaving a cave?
       JEQ !
       SZC  R0,@FLAGS        ; Clear in cave flag
       LI   R2,7             ; Use cave out animation
       JMP SCROLL

!      LI   R0,>1000         ; Add 1 to MAPLOC Y
       LI   R2,2             ; Use scroll down 2
       JMP SCROLL

SCRLUP LI   R0,>F000         ; Add -1 to MAPLOC Y
       LI   R2,1             ; Use scroll up 1

SCROLL AB   R0,@MAPLOC
       LI   R0,BANK2         ; Overworld is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       B    @BANKSW

MRODC  EQU >1804    ; Magic Rod sprite and color

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

SWORD4 B @LNKSPR

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

BSWJMP DATA BSWDRT,BSWDLT,BSWDDN,BSWDUP
BSWRDD DATA >0003,>FFFD,>0300,>FD00     ; Beam sword direction (move by 3)
BSWRDC BYTE >07,>0F,>06,>09             ; Beam sword colors: cyan, white, dark red, light red
BSPLSD DATA >FEFF,>FF01,>00FF,>0101     ; Beam splash direction data NW,NE,SW,SE
REVMSK ; Reverse direction mask, same as DATA >0002
MAGICD DATA >0002,>FFFE,>0200,>FE00     ; Magic beam direction (move by 2)
MAGICC BYTE >07,>04,>06,>01             ; Magic colors: cyan, dark blue, dark red, black

; Beam sword shoots when link is at full hearts, cycle colors white,cyan,red,brown
; R4[9..8] = color bits
; R4[6] = pop bit
BSWORD
       AI R4,>4000              ; Cycle colors
       MOV R4,R1
       SRL R1,14
       MOVB @BSWRDC(R1),@R6LB

BSWRD2
       MOV R6,R2
       ANDI R2,>0F00       ; Get facing from sprite index
       SRL  R2,9
       A @BSWRDD(R2),R5    ; Add movement from table
BSWRD3
       MOV R4,R1
       SLA R1,10           ; Check for hitting enemy
       JOC BSWPOP

       MOV R5,R0
       SWPB R0
       MOV @BSWJMP(R2),R1   ; Jump table for checking screen edge
       B *R1
BSWDLT
       CI R0,>0800          ; Check left edge of screen
       JH !
       JMP BSWPOP
BSWDRT
       CI R0,>E800         ; Check right edge of screen
       JL !
       JMP BSWPOP
BSWDUP
       CI R5,>1800         ; Check left edge of screen
       JH !
       JMP BSWPOP
BSWDDN
       CI R5,>B000          ; Check bottom edge of screen
       JHE BSWPOP
!
       MOV @OBJPTR,R0
       CI R0,LASTOB-OBJECT ; Is it the player beam sword?
       JL BSWNXT
       BL @LNKHIT         ; hit player if not player weapon
       JMP BSWNXT

BSWPOP
       MOV R4,R1
       ANDI R1,>003F       ; Get object idx
       CI R1,MAGCID
       JNE !
       MOV @FLAGS,R0
       ANDI R0,BOOKMG      ; Have Book of Magic?
       JEQ BSPOFF

       LI R0,BMFMID        ; Book of Magic Flame ID
       MOV R0,@FLAMOB      ; Flame object id
       MOV R5,@FLAMSP      ; Flame position
       LI R6,>F008         ; Flame sprite and color
       MOV R6,@FLAMSP+2

       JMP BSPOFF
!      CI R1,ARRWID
       JNE !

       ; TODO arrow spark at edge of screen
       ;CLR @ARRWOB       ; Clear arrow so it can be fired again
       LI R6,SPARK
       LI R4,SPRKID
       JMP BSWNXT

!      MOV @OBJPTR,R0
       CI R0,BSWDOB-OBJECT ; Is it the hero's beam sword?
       JNE SPROFF

       LI R4,BSPLID        ; Create splash NW
       LI R6,>800F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>40    ; Create splash NE
       LI R6,>840F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>80    ; Create splash SW
       LI R6,>880F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>C0    ; Create splash SE
       LI R6,>8C0F         ; Sprite
       BL @OBSLOT
       JMP !
BSPOFF ; Beam splash off (from below)
       CLR @BSWDOB       ; Clear sword so it can be fired again
SPROFF
!      CLR R4
       LI R5,>D200        ; Disappear (offscreen)
BSWNXT B @OBNEXT



MAGIC
       ; TODO enemy magic hero hit test and colors

       AI R4,>4000         ; Cycle colors
       MOV R4,R1
       SRL R1,14
       MOVB @MAGICC(R1),@R6LB

       MOV @COUNTR,R0
       SLA R0,4            ; Use low bit from counter6 nibble
       JNC BSWRD2          ; Move by 3 or 2 alternating frames
MAGIC2
       MOV R6,R2
       ANDI R2,>0C00       ; Get facing from sprite index
       SRL  R2,9
       A @MAGICD(R2),R5    ; Add movement from table
       JMP BSWRD3

ARROW
       MOV @OBJPTR,R0
       CI R0,ARRWOB-OBJECT
       JEQ BSWRD2         ; Hero arrow just moves like beam sword (by 3)
       ; Enemy arrow hit test will happen at BSWRD3
       JMP MAGIC2  ; Move by 2 (magic)

; Arrow spark
ASPARK
       LI R0,>0040
       C R0,R4
       JH SPROFF
       S R0,R4
       JMP BSWNXT


* Beam sword splash, or reflected bullet/arrow/sword
* R4[15..8] = countdown
*   [7..6] = direction (not from sprite since also used for bullet reflect)
BSPLSH
       ;MOV R6,R1
       ;ANDI R1,>0F00       ; Get facing from sprite index
       ;SRL  R1,9

       MOV R4,R1
       ANDI R1,>00C0       ; Get facing from object index
       SRL  R1,5

       MOV R5,R0
       A @BSPLSD(R1),R5    ; Add movement from table (NW,NE,SW,SE)
       XOR R5,R0
       ;ANDI R0,>0080       ; Check if X wrapped
       ;JEQ !
       SRC R0,8            ; Check if X wrapped
       JNC !
       ORI R6,>0080        ; Set early clock bit
       AI R5,>0020         ; Add early clock offset 32px

!
       AI R4,>0100         ; Decrement TTL
       MOV R4,R1
       ANDI R1,>1F00
       JEQ BSPOFF          ; Turn off

       MOV R6,R0
       ANDI R0,>F000       ; Get sprite index (upper nibble)
       CI R0,>7000         ; sword sprite?
       JEQ !
       CI R0,>8000         ; beam sword pop sprite?
       JNE BSWNXT          ; nope - done
!
       SWPB R1             ; Cycle colors
       ANDI R1,>0003
       ANDI R6,>FFF8        ; Mask off color
       AB @BSWRDC(R1),@R6LB ; Get cycled color
       
       JMP BSWNXT


RUPEE
BRUPEE
HEART
       LI R0,>0100
       C  R4,R0          ; Test counter for zero
       JHE !
       AI R4,>5000       ; Initialize counter
       MOV @ECOLOR(R3),R6 ; Initialize sprite and color
!      MOV @COUNTR,R1
       ANDI R1,>000F     ; Use only 16-counter
       MOV R1,R2
       ANDI R6,>FFF0     ; Mask off color
       SRL R1,3
       A R1,R3
       AB @RUPEEC->40(R3),@R6LB

       CI R4,>2000
       JLE !
       S  R0,R4          ; Decrement counter
       SLA R2,15
       JOC BSWNXT
       ANDI R6,>FFF0     ; Mask off color
       JMP BSWNXT

!      MOV  R2,R2
       JNE !
       S  R0,R4          ; Decrement counter
       C  R4,R0          ; Test counter for zero
       JL SPROFF

!      LI R2,GETITM
       MOV @HEROSP,R3    ; Get hero pos in R3
       BL @COLIDE
       MOV @SWRDSP,R3    ; Get sword pos in R3
       BL @COLIDE
       MOV @BMRGSP,R3    ; Get boomerang pos in R3
       BL @COLIDE
       JMP BSWNXT
GETITM
       ANDI R4,3
       JNE !
       LI R0,>0100       ; Get 1 rupee
       JMP GETRUP
!      DEC R4
       JNE !
       LI R0,>0500       ; Get 5 rupees
       JMP GETRUP
!      DEC R4
       JNE !
       MOV @HFLAGS,R0
       ANDI R0,BLURNG+REDRNG
       INC R0
       SLA R0,9
       AB R0,@HP         ; Get heart
!
DOSTAT BL @STATUS
       B @SPROFF
GETRUP AB R0,@RUPEES   ; Add R0 to rupees
       JNC DOSTAT      ; Overflow?
       SETO R0         ; Reset rupess to 255
       MOVB R0,@RUPEES
       JMP DOSTAT

; Rupee yellow, blue; 5 rupee blue blue; heart blue red
RUPEEC BYTE >0A,>05,>05,>05,>04,>06


ITEMFN DATA BMRGFN,BOMBFN,ARRWFN,CNDLFN
       DATA FLUTFN,BAITFN,POTNFN,MAGCFN

;PEAHAD DATA >0001,>0101,>0100,>00FF  ; 0 Right, 1 downright, 2 down, 3 downleft
;       DATA >FFFF,>FEFF,>FF00,>FF01  ; 4 Left,  5 upleft,    6 up,   7 upright

; bits right,left,down,up  (index by 4-bit dpad, counter directions cancel out)
BMRNGD BYTE 8,6,2,8 ; none, up, down, none
       BYTE 4,5,3,4 ; left, upleft, downleft, left
       BYTE 0,7,1,0 ; right, upright, downright, right
       BYTE 8,6,2,8 ; none, up, down, none
; bits right,left,down,up (index by facing direction)
BMRNGE BYTE 0,4,2,6 ; right, left, down, up
; bits right,left,down,up (screen edge tests, index by 3-bit direction)
BMRNGF BYTE >8,>A,>2,>6   ; Right, downright, down, downleft
       BYTE >4,>5,>1,>9   ; Left,  upleft,    up,   upright

THROWJ DATA THROWR,THROWL,THROWD,THROWU

; Check to see if hero has room to spawn an item in the direction he's facing
; Returns if ok, jumps to ITMNXT otherwise
; Modifes R1,R7
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
       LI R6,>900A       ; Boomerang

       JMP ITMSPN
!
       AI R4,>FE00       ; max counter
       LI R6,>9004       ; Magic boomerang

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
       MOV R4,R3           ; Save R4

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


FLAMXY DATA >00F0,>0000,>B800,>1800

FLMDOR LI R2,FLMDO2  ; Flame overlapped secret door location
       MOV @DOOR,R5
       MOV R5,R0
       BL @TESTCH    ; Get character under secret door location
FLMDO2 CI R1,>9000  ; Green bush
       JNE !
       LI R1,>7879  ; Green stairs
       LI R2,>7A7B
       JMP !!
!      CI R1,>9800  ; Red bush
       JNE FLAME0
       LI R1,>7071  ; Red stairs
       LI R2,>7273
!      BL @STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @SETBIT   ; Set bit R0 in VDP at R1

       JMP FLAME0


FLAME  CI R4,>FF00
       JHE !!!
       LI R0,>0100
       S  R0,R4
       C  R4,R0      ; Decrement counter
       JHE !
FLAME2
       MOV @DOOR,R3    ; Check for door collision
       LI R2,FLMDOR
       BL @COLIDE
FLAME0
       B @SPROFF
!      CI R4,FLAMID
       JEQ FLAME2    ; Book of Magic flame?
       JH !
       CI R4,>3900   ; Stop moving after 36 frames
       JLE !
       LI R0,>0100   ; Move every other frame
       CZC R0,R4
       JNE !
       MOV R4,R1
       ANDI R1,>00C0
       SRL R1,5        ; R1 = direction
       MOV R5,R0
       SZC @EMOVEC(R1),R0  ; Mask XX or YY
       C R0,@FLAMXY(R1)    ; Check screen edge
       JEQ !
       A @EMOVED(R1),R5 ; Move
!      BL @LNKHIT
!      JMP BOMNXT



       ;            Left Right  Down  Up
BOMBXY DATA >FF10,>FEF0,>0F00,>EF00
; Bomb jump  0  1   2  3
BOMBJ  BYTE -16,16,-32,32


BOMB   LI R0,>0100
       S  R0,R4
       C  R4,R0      ; Decrement counter
       JHE !
       B @SPROFF
!
       MOV R4,R0      ; Get counter in R0
       SRL R0,8
       CI R0,36       ; Bomb explode
       JNE !!!
       LI R6,CLOUD1   ; cloud 1, white

       MOV R5,R7

       MOV @DOOR,R3    ; Check for door collision
       LI R2,BOMDOR
       BL @COLIDE
BOMB0

       SWPB R7
       CI R7,>1000    ; At left edge?
       JHE !
       AI R5,>0020    ; Adjust right 32 pixels
       AI R6,>0080    ; Set early bit for left edge
!
       AI R4,>80      ; Middle left poof - toggles by 32
       AI R5,-16
       BL @OBSLOT
       AI R4,->80     ; Lower left poof - toggles by 16
       AI R5,(16*256)+8
       BL @OBSLOT
       AI R4,>40      ; Upper right poof - toggles by 16
       AI R5,(-32*256)+16
       BL @OBSLOT
       AI R5,(16*256)-8

       CI R7,>1000    ; At left edge?
       JHE !
       AI R5,->0020   ; Adjust left 32 pixels
       AI R6,->0080   ; Clear early bit
!

       JMP BOMB1
!
       CI R0,12
       JNE !
       AI R6,>0400       ; Poof dissapates slightly
!
BOMB1
       MOV @OBJPTR,R1
       CI R1,BOMBOB-OBJECT
       JEQ !             ; Primary bomb poof doesn't move

       LI R1,>0040       ; Wiggle back and forth
       XOR R1,R4
       MOV R4,R1
       ANDI R1,>00C0
       SRL R1,6
       AB @BOMBJ(R1),@R5LB

       JMP BOMNXT

!      CI R0,34         ; Bright colorset
       JEQ BOMB2
       CI R0,30         ; Normal colorset
       JEQ BOMB3
       CI R0,29         ; Bright colorset
       JEQ BOMB2
       CI R0,25         ; Normal colorset
       JNE BOMNXT
BOMB3
       LI R0,>0300+(CLRTAB/>40) ; VDP Register 3: Color Table
       LI R1,>07F1          ; VDP Register 7: White on Black
       JMP !
BOMB2
       LI R0,>0300+(BCLRTB/>40) ; VDP Register 3: Color Table
       LI R1,>07FE          ; VDP Register 7: White on Grey
!      BL @VDPREG
       MOV R1,R0
       BL @VDPREG
BOMNXT B @OBNEXT

BOMDOR LI R2,BOMDO2
       MOV @DOOR,R5
       MOV R5,R0
       BL @TESTCH    ; Get character under secret door location
BOMDO2 CI R1,>8000  ; Green brick
       JEQ !
       CI R1,>A000  ; Red brick
       JNE !!
!      LI R1,>7F7F
       LI R2,>2020
       BL @STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @SETBIT   ; Set bit R0 in VDP at R1

!      MOV R7,R5
       JMP BOMB0

; Set bit R0 in VDP at address R1
; Modifies R0-R3
SETBIT MOV R0,R2
       LI R3,>8000
       ANDI R0,7
       JEQ !
       SRL R3,R0  ; R3 = 0x80 >> (bit & 7)
!
       SRL R2,3
       A R2,R1    ; R1 += (bit >> 3)
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOV R1,R0   ; Save address for VDPWB
       MOVB @VDPRD,R1
       SOC R3,R1   ; R1 |= R3
       B @VDPWB



; Boomerang
; R4[15-9]= counter 0=returning 1-2=spark 3-7f=countdown
; R4[8-6] = direction (peahat style)

; 45 move by 3x15
; 30 move by 2 2
; 28 move by 1 0 1 0 1 0 1 0 1 0 1 0
; 16 move by 0 0
; 14 move by 1 0 1 0 1 0
; 8 move by 1 1 1 1 1 1 1 1
; 0 move by 2

SPARK  EQU >DC0F        ; Spark Sprite Index and color white

BMRNG
       CI R4,16*>0200
       JL BMRNG2  ; Returning

       MOV R4,R3
       SRL R3,6
       ANDI R3,>0007  ; Get direction in R3

       MOV R5,R7      ; R5=YYXX
       SWPB R7        ; R7=XXYY

       MOVB @BMRNGF(R3),R0  ; Get screen edge test flags in R0 right,left,down,up
       SLA R0,5       ; Get right test bit in carry
       JNC !
       CI R7,>F000    ; Test right screen edge
       JHE BMRNG7
!      SLA R0,1       ; Get left test bit in carry
       JNC !
       CI R7,>0300    ; Test left screen edge
       JLE BMRNG7
!      SLA R0,1       ; Get down test bit in carry
       JNC !
       CI R5,>B400    ; Test bottom screen edge
       JHE BMRNG7
!      SLA R0,1       ; Get up test bit in carry
       JNC !
       CI R5,>1800    ; Test top screen edge
       JLE BMRNG7
!
       A R3,R3
       MOV @PEAHAD(R3),R3  ; R3=peahat-style movement by 1
BMRNG1
       MOV R4,R0
       SRL R0,9        ; R0=counter
       JEQ BMOVE2      ; counter=0? Move by 2

       AI R4,->200     ; Decrement counter

       CI R6,SPARK
       JEQ BMRNG8

       CI R0,8
       JLE BMOVE1      ; Move by 1
       CI R0,28
       JH !
       ANDI R0,1       ; Move by 0 or 1
       JNE BMOVE1
       JMP BMOVE0
!      CI R0,30
       JLE BMOVE2      ; Move by 2

BMOVE3 A R3,R5
BMOVE2 A R3,R5
BMOVE1 A R3,R5
BMOVE0

       MOV @COUNTR,R0
       ANDI R0,3
       JNE BMRNXT     ; Animate every 4th frame

       MOV R6,R1
       SRL R1,10
       ANDI R1,3
       MOVB @BMRNGS(R1),R6

       JMP BMRNXT
BMRNG2
       MOV @HEROSP,R3   ; Sprite off if collision with hero
       LI R2,SPROFF
       BL @COLIDE

       CLR R3
       CB R5,@HEROSP    ; Move toward the hero
       JL  BMRNG3
       JH  BMRNG4
!      CB @R5LB,@HEROSP+1
       JL  BMRNG5
       JH  BMRNG6
       JMP BMRNG1
BMRNG3
       AI R3,>0100
       JMP -!
BMRNG4
       AI R3,>FF00
       JMP -!
BMRNG5
       AI R3,>0001
       JMP BMRNG1
BMRNG6
       AI R3,>FFFF
       JMP BMRNG1
BMRNG7 ; Screen edge hit
       LI R4,(BMRGID&>003F)+>0600  ; spark for 3 frames
       LI R6,SPARK
       JMP BMRNXT
BMRNG8 ; wait for spark countdown to 0
       CI R4,>0100
       JHE BMRNXT
       LI R6,>90
       MOV @HFLAGS,R0
       LI R6,>900A   ; normal boomerang color
       LI R0,MAGBMR
       COC @HFLAGS,R0
       JNE BMRNXT
       LI R6,>9004  ; magic boomerang color
BMRNXT B @OBNEXT


* Boomerang next sprite table (indexed by current sprite)
BMRNGS BYTE >9C,>98,>90,>94

; Compare YYXX in R3 and R5 for overlap, jump to R2 if collision
; Modifies R3
COLIDE
       S   R5,R3            ; subtract sprite pos from sword pos
       ABS R3
       CI R3,>0D00
       JH !
       SWPB R3
       ABS R3
       CI R3,>0D00
       JH !
       B *R2              ; collided
!      RT                 ; no collision


; Hit test R5 with our hero
; Enemy direction in R2: 0=right 2=left 4=down 6=up
; Modifies R0,R3
LNKHIT
       MOV @HURTC,R0     ; Can't get hurt again if still flashing
       JNE -!

       MOV @HEROSP,R3    ; Get hero pos in R3
       AI R3,>0100         ; Adjust Y pos
       MOV R3,R0           ; Save hero pos for later
       S   R5,R3           ; subtract enemy pos from hero pos
       ABS R3
       CI R3,>0A00
       JH -!       ; no collision RT
       SWPB R3
       ABS R3
       CI R3,>0A00
       JH -!        ; no collision RT

       ; calculate knockback direction
       ANDI R0,>0707
       JNE !
       ; horizontally and vertically aligned
       CB R3,@R3LB
       JL LNKHI2

!      ANDI R0,>0700
       JNE LNKHI2
       ; horizontally aligned
       CB @R5LB,@HEROSP+1
       JHE !
       CLR R0          ; right
       JMP LNKHI3
!      LI R0,DIR_LT    ; left
       JMP LNKHI3
LNKHI2
       ; vertically aligned
       CB R5,@HEROSP
       JHE !
       LI R0,DIR_DN    ; down
       JMP LNKHI3
!      LI R0,DIR_UP    ; up

LNKHI3
       ; don't change R0 until setting HURTC

       MOV R4,R1
       ANDI R1,>003F    ; Get enemy type

       ; TODO Enemy reverse direction, or bullet disappear
       CI R1,BULLID
       JEQ LNKHI4

       CI R1,ARRWID
       JEQ LNKHI4

       CI R1,BSWDID
       JNE !

       MOV @HFLAGS,R3
       ANDI R3,MAGSHD      ; Beam sword can only be blocked with magic shield
       JEQ ARRHIT

LNKHI4

       ; check sprite for action, can't block if hero attacking
       MOV @HEROSP+2,R3    ; Get hero sprite offset and color
       ANDI R3,>F000       ; Get sprite upper nibble
       JNE ARRHIT          ; Is zero? (hero walking sprites)


       ; bullets bounce off if facing the right way (and have magic shield in some cases)

       ; enemy arrow
       MOV @FLAGS,R3
       ANDI R3,DIR_XX     ; R3 = hero direction >0300
       SRL R3,7
       XOR @REVMSK,R3
       C R2,R3   ; check reverse direction
       JNE ARRHIT

       ; successful block
       MOV @BOUNCD(R2),R4  ; change to beam splash id
       RT                 ; return with no damage

BOUNCD DATA BSPLID,BSPLID+>40,BSPLID+>40,BSPLID+>80  ; Reflected bounce NW,NE,NE,SW

ARRHIT ; Arrow disappear (same as SPROFF)
       CLR R4
       LI R5,>D200
!

       AI R0,>C000      ; add 48<<10 frames hurt counter
       MOV R0,@HURTC

       SB @EDAMAG(R1),@HP  ; Subtract enemy attack damage
       JGT NOTDED

       CLR R1         ; Set HP to zero in case of underflow
       MOVB R1,@HP
       BL @STATUS     ; Show empty hearts

       LI R0,BANK4
       LI R1,MAIN
       LI R2,1       ; Do game over in bank 3
       BL @BANKSW
       B @RESTRT

NOTDED B @STATUS


; Link hurt animation
; R4 = counter & knockback direction
; Modifies R0-3,R9-10
LNKHRT
       MOV R11,R9              ; Save return address
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


; Hero movement, R3=direction 0=Right 2=Left 4=Down 6=Up, R5=YYXX position
; Modifies R0-2,R10
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


; Facing     Right Left  Down  Up
LMOVEA DATA >0810,>07FF,>1000,>0700     ; Test char offset 1
LMOVEB DATA >0F10,>0EFF,>100F,>070F     ; Test char offset 2





; Store characters R1,R2 at R5 in name table
; Modifies R0,R1,R3
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



; Look at character at pixel coordinate in R0, and jump to R2 if solid (character is in R0)
; Modifies R0,R1
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
       
       CI R1,>7DFF  ; Characters >7E and higher are solid
       JH !
       RT
!      B *R2        ; Jump alternate return address


; Update Sprite List to VDP Sprite Table (with flicker)
; Modifies R0-
SPRUPD
       LI R0,SPRTAB+VDPWM  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU

       MOV @COUNTR,R2
       SRC R2,1
       JOC  !

       LI R2,128     ; Copy all 32 sprites
       B @VDPW

!      MOVB @R0LB,*R14 ; VDP Write address
       MOVB R0,*R14    ; VDP Write address
       LI R2,4*6     ; Copy only 6 sprites
!      MOVB *R1+,*R15
       DEC R2
       JNE -!
       AI R1,25*4    ; Move to sprite 31
       LI R2,26      ; Copy 26 sprites in reverse
!      MOVB *R1+,*R15 ; Copy 4 bytes forward
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       AI R1,-8      ; Move to previous sprite
       DEC R2
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

FAIRY
BADNXT JMP BADNXT



* Rupee blink
RUPEEB
       CI R6,>C00A
       JEQ !
       CI R6,>C005
       JNE !!
!      MOV @COUNTR,R0
       ANDI R0,>0007
       JNE !
       LI R0,(>C00A^>C005)
       XOR R0,R6
!      RT

* Cave item object, check hero collision, enough money, already have it
* R4: object id
* R5: location
* R6: sprite and color
CAVITM
       BL @RUPEEB
       MOV @HEROSP,R0
       AI R0,>0100   ; Y adjust
       C R0,R5
       JNE TEXTRT
       MOV @OBJPTR,R0
       SRL R0,1      ; Get object byte offset
       AI R0,ENEMHP
       BL @VDPRB     ; R1 = item price
       CB R1,@RUPEES
       JH TEXTRT     ; Not enough rupees?

       ;TODO already have it?

       SB R1,@RUPEES ; Subtract price from rupees
       BL @STATUS    ; Update status

       ; TODO hold up item
       LI R0,BANK4
       LI R1,MAIN
       LI R2,9
       BL @BANKSW

       ; Put sprites in VDP in order
       LI R0,SPRTAB
       LI R1,SPRLST
       LI R2,32*4
       BL @VDPW

       LI R9,32
!      BL @VSYNCM
       BL @COUNT
       LI R0,SPRTAB+(14*4)
       LI R1,>5700
       BL @VDPWB

       BL @VSYNCM
       BL @COUNT
       LI R0,SPRTAB+(14*4)
       LI R1,>D000
       BL @VDPWB

       DEC R9
       JNE -!

       LI R9,64
!      BL @VSYNCM
       BL @COUNT

       DEC R9
       JNE -!

       ; Back to normal sprites
       LI R0,BANK4
       LI R1,MAIN
       LI R2,2
       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       BL @BANKSW


       ; TODO NPC disappears
       ; TODO set bit for collected item
       B @SPROFF

* Text writer object, writes one char every 6 frames
* R4[15:6] counter
* R5[7:0] screen offset
* R6[13:0] pointer to text in VDP RAM
TEXTER
       MOV @COUNTR,R0
       CI R0,>2000     ; Only update every 6 frames, when COUNTR is 1xxx
       JHE TEXTRT
       CLR R1       ; Initial offset zero
!      A R1,R5      ; Add offset (1-31)
       MOV R6,R0
       INC R6         ; Next character
       BL @VDPRB
       CI R1,>2000
       JHE !
       SRL R1,8
       JNE -!
       B @SPROFF    ; Zero byte - end of text
!      MOV @FLAGS,R2
       ANDI R2,SCRFLG   ; Get current screen ptr
       MOV R5,R0
       ANDI R0,>00FF    ; Get screen offset
       AI R0,8*32+4     ; Add text offset in cave 8,4
       A R2,R0
       BL @VDPWB
       INC R5
TEXTRT B @OBNEXT



* Fairy in pond (restore half-heart every 22 frames) (spawn heart every 11 frames)
* R4[15..8] = counter
*  0 = needs init
*  1 = waiting for hero to trigger
*  46..2 = countdown by 2  R4[8..6] = spawned heart counter
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
FAIRY2
       MOV R4,R0
       ANDI R0,>FF00
       JNE !
       ; initialize fairy position and sprite
       LI R5,>5378  ; Position
       LI R6,FARYSP ; Sprite

       BL @SAVESP   ; Save sprite, start with cloud animation
       ORI R4,>4FC0
       JMP TEXTRT

!      CI R0,51*>100
       JL !
       B @OCTOR4     ; Do cloud animation
!
       CI R0,>100
       JEQ FAIRYX   ; not triggered


       AI R4,>200

       ANDI R0,>FE00
       CI R0,12*>200
       JEQ !

       CI R0,23*>200
       JL TEXTRT
       AI R4,-22*>200
!
       MOV R4,R0
       ANDI R0,>01C0
       JEQ TEXTRT

       AI R4,->0040

       JMP FAIRY5  ; Spawn a heart

FAIRYX
       LI R2,FAIRY4
       LI R5,>7378
       MOV @HEROSP,R3
       BL @COLIDE
FAIRY3
       LI R5,>5378  ; Restore Position
       JMP TEXTRT

FAIRY4 ; start spawning hearts
       LI R4,FRY2ID+>05C0
FAIRY5 ; spawn a heart
       MOV R4,R7
       LI R4,HRT2ID
       LI R6,HRT2SP
       BL @OBSLOT
       MOV R7,R4
       LI R6,FARYSP
       JMP FAIRY3

* Hearts that spin around fairy in pond (counterclockwise)
* R4[15..7] = countdown 0..88
HEART2
       LI R0,>100
       C R4,R0
       JHE !
       AI R4,88*>100
!      S R0,R4

       MOV R4,R1    ; Get rotation from R4
       SRL R1,8

       LI R5,>786A  ; Center Position (byte swapped)

       BL @AR5SIN   ; Add sine to X

       MOV R4,R1    ; Get rotation from R4
       SRL R1,8
       AI R1,-22    ; Subtract 1/4 to get cosine
       JOC !        ; overflow?
       AI R1,88     ; wrap around
!
       SWPB R5
       BL @AR5SIN   ; Add cosine to Y
       JMP TEXTRT

* Add sine of R1 to R5
* R1 = 0..44..88 ~ 0..pi..2pi
AR5SIN
       CI R1,44
       JHE NEGSIN
       CI R1,23
       JL !
       NEG R1
       AI R1,44
!      AB @SINTBL(R1),R5
       RT
NEGSIN
       CI R1,67
       JL !
       NEG R1
       AI R1,88+44
!      SB @SINTBL-44(R1),R5
       RT

SINTBL ; sine table - 23 bytes to pi/2, scaled to 53
       BYTE >00,>04,>08,>0B,>0F,>13,>16,>19,>1D,>20,>23
       BYTE >25,>28,>2A,>2D,>2F,>30,>32,>33,>34,>34,>35,>35
       EVEN


* Store the current sprite in object HP and set to cloud
SAVESP
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS+VDPWM   ; Use HP/stun counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R6,*R15      ; Save sprite and facing
       MOVB @R6LB,*R15   ; Save color

       LI R6,CLOUD1  ; poof, white
       RT


* Rock AI
* R4: 0 init
*     1-18  y+=2
*     19-21 y+=1
*     22-23 y+=0
*     24-26 y-=1
*     27-29 y-=2
*     30+   y+=0 x+=0
ROCK   LI R3,>0100
       C R3,R4
       JLE !
ROCKI  BL @RANDOM
       MOV R0,R1
       ANDI R1,>3F80
       AI R1,>2000
       A R1,R4      ; R4+=(32+RND*16)*256

       ANDI R0,>00FF
       AI R0,>1800
       MOV R0,R5
       LI R6,>3009

!      BL @ANIM6
       CI R4,30*>100
       JL !
       BL @RANDOM
       ANDI R0,>0080
       XOR R0,R4      ; Change direction randomly
       JMP ROCK3

!      CI R4,27*>100
       JL !
       AI R5,->0200    ; Move up 2
       JMP ROCK2

!      CI R4,24*>100
       JL !
       S R3,R5        ; Move up 1
       JMP ROCK2

!      CI R4,22*>100
       JHE ROCK2
       CI R4,19*>100
       JL !
       A R3,R5       ; Move down 1
       JMP ROCK2

!      AI R5,>0200
       CI R5,>D000   ; Reinit at bottom of screen
       JHE ROCKI
ROCK2
       MOV R4,R0
       SLA R0,9
       JOC !
       INC R5        ; Move right
       JMP ROCK3
!      DEC R5        ; Move left

ROCK3  S R3,R4       ; Decrement counter
       C R3,R4
       JL !
       AI R4,30*>100   ; Bounce
!
       BL @LNKHIT
       JMP PEAHRT




* Peahat animation loop: 2 2 1 2 1  (01011011)
* And moves by 1 only when animation changes
* Peahat Direction data
PEAHAD DATA >0001,>0101,>0100,>00FF  ; 0 Right, 1 downright, 2 down, 3 downleft
       DATA >FFFF,>FEFF,>FF00,>FF01  ; 4 Left,  5 upleft,    6 up,   7 upright
PEAHAA DATA >DAAA,>AAAA,>AA4A,>4A4A,>4911,>1111,>1080,>8080 ; animation
* R4:  6 bits animation counter
*      3 bits direction
*      1 bits hurt/stun flag
*      6 bits object id
*  descending: 128 frames, counter=27..42
*  landed: 72 frames, counter=18..26
*  ascending: 128 frames, counter=2..17   init=17
*  flying: 8 frames, count=1
PEAHAT
       MOV R4,R1
       MOV @COUNTR,R2  ; R2=counter
       INV R2          ; counting down by default
       SRL R1,10      ; Get counter bits
       JEQ PEAHA3    ; If zero do setup
       CI R1,1
       JNE !         ; flying normally?
       MOV R2,R1
       ANDI R1,7     ; use 3 bits from counter
       JMP PEAHA2

!      CI R1,17      ; ascending?
       JH !
       ANDI R2,7     ; use 3 bits from counter
       JMP PEAHA1

!      CI R1,26      ; landed?
       JH PEAHA0
       ANDI R2,7     ; use 3 bits from counter
       JNE !
       AI R4,->0400  ; Decrement landed counter
!      BL @HITEST    ; can only be hit while landed
PEAHRT
       JMP OBNXT

PEAHA0 NEG R1        ; descending
       AI R1,27+17   ; reverse descending counter 27..42 -> 17..2
       INV R2
       ANDI R2,7     ; use 3 bits from counter
       CI R2,7
PEAHA1 JNE !
       AI R4,->0400  ; Decrement ascending/descending counter
!      DECT R1
       SLA R1,3
       A R2,R1       ; add them to counter

       LI R0,>0040   ; Test for hurt bit
       COC R0,R4
       JNE PEAHA2
       BL @HSBIT

PEAHA2
       BL @LNKHIT    ; Modifies R0,R3

       MOV R1,R0
       SRL R1,4
       A  R1,R1
       MOV @PEAHAA(R1),R1  ; Get animation bits
       ANDI R0,>000F
       INC R0
       SLA R1,R0      ; Put animation bit in carry status
       JNC OBNXT      ; Don't animate or move if bit not set

       LI R1,>0400
       XOR R1,R6      ; Toggle animation
       MOV R4,R1
       ANDI R1,>0380  ; Get direction bits (8 directions)
       SRL R1,6
       MOV R5,R2          ; Save old position
       A @PEAHAD(R1),R5   ; Move based on direction

       MOV R5,R0         ; Test edges of screen
       CI R0,>2800       ; Top edge
       JLE PEAHAR
       CI R0,>A800       ; Bottom edge
       JHE PEAHAR
       SWPB R0
       CI R0,>1000       ; Left side
       JLE PEAHAR
       CI R0,>E000       ; Right side
       JHE PEAHAR
       
       ANDI R0,>0707    ; Don't change direction unless 8-pixel aligned
       JNE OBNXT

       BL @RANDOM
       ANDI R0,>001F
       JNE !            ; 1 in 32 chance to land
       CI R4,>0800
       JHE !            ; flying normally?
       ANDI R4,>03FF    ; Clear counter bits
       ORI R4,42*>0400  ; Set counter=42
       JMP OBNXT
!
       MOV R4,R1
       ANDI R1,>0380    ; R1 = direction bits
       ANDI R0,7        ; 2 in 8 chance to change direction
       JEQ !            ; Turn right
       DEC R0
       JNE OBNXT
       AI R1,>FF80      ; Turn left
PEAHAL ANDI R1,>0380    ; Mask off direction overflow
       ANDI R4,>FC7F    ; Mask off old direction
       SOC R1,R4        ; Store new direction
       JMP OBNXT
!      AI R1,>0080      ; Turn right
       JMP PEAHAL
PEAHAR LI R0,>0200      ; Reverse direction
       XOR R0,R4
       MOV R2,R5        ; Restore old position
       JMP OBNXT
PEAHA3
       BL @SPAWN
       LI R6,>2009    ; Set sprite and color (ECOLOR+2)
       ORI R4,(17*>0400)+(6*>0080)   ; Set initial counter=17 and direction to spin-up=6
       JMP OBNXT



* Tektite
* R4[15-8] = counter
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
TKTITE
       MOV R4,R0
       SRL R0,8       ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       MOV @ECOLOR(R3),R6 ; Reload sprite and color
       JMP OCTOR1     ; use octorok to init cloud
!
       CI R4,51*>100  ; cloud animation?
       JHE OCTOR4

       AI R4,->0100   ; decrement counter
       DEC R0         ; decrement counter
       JNE !          ; toggle animation when counter hits zero
       AI R4,>1100    ; counter += 17
       LI R1,>0400
       XOR R1,R6      ; Toggle animation
!      BL @HITEST
       JMP OBNXT

OBNXT  B @OBNEXT

* Octorok, Moblin and Lynel AI
* R4[15..8] = counter
*  0 = needs init
*  1 = normal movement
*  2..50 = stationary for projectile
*  26 = projectile launch
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
LYNEL
MOBLIN       
OCTORK
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE OCTOR2    ; If zero do setup
OCTORI
       BL @SPAWN     ; Setup octorok
OCTOR1
       BL @SAVESP    ; Save sprite and facing to HP, change to cloud sprite

       AI R1,-(ENEMHS+VDPWM+>18)  ; R1=0,2,4,...
       SLA R1,11     ; R1 upper byte: 0,8,16

       CI R4,>0008   ; Moblin ID?
       JL !          ; less than moblin means octorok or tektite (longest delay)
       SRL R1,2      ; divide delay by 4  R1=0,2,4
       CI R4,>000A   ; Lynel ID?
       JL !          ; less than lynel means moblin
       CLR R1        ; Lynels all appear at the same time

!      AI R4,>4800   ;
       A R1,R4       ; delay cloud based on enemy index

OCTOR2
       CI R4,51*>100  ; cloud animation?
       JHE OCTOR4

       BL @HITEST
       BL @ANIM6     ; Animate - R0 contains counter
       SLA R0,8
       JOC OBNXT     ; Move every other frame (unless it's fast octorok)

OCTOR3
       ; check if shooting a bullet
       CI R4,>0200
       JL EMOVE      ; Not shooting, just move
       AI R4,->100   ; Decrement counter

       MOV R4,R1
       SRL R1,8      ; R1=counter 50..2
       CI R1,25      ; Shoot projectile at count=25
       JNE OBNXT

       ; shoot a bullet
       MOV R4,R7     ; Save object id
       MOV R6,R8     ; Save sprite

       MOV R6,R4
       ANDI R4,>1800
       SRL R4,5      ; R4= direction mask >00C0
       ORI R4,BULLID
       LI R6,BULLSP

       MOV R7,R0
       ANDI R0,>003F ; Get ID
       CI R0,>0008   ; Moblin ID?
       JL !          ; less than moblin means octorok or tektite (longest delay)

       ; moblin - shoot arrow
       MOV R8,R6
       ANDI R6,>1800 ; R6=direction
       SRL R6,1
       ORI R6,>A001  ; arrow sprite, black
       LI R4,ARRWID

       CI R0,>000A   ; Lynel ID?
       JL !          ; less than lynel means moblin

       ; lynel - shoot sword
       AI R6,>700F->A001  ; change arrow to sword
       LI R4,BSWDID
!
       BL @OBSLOT
       MOV R7,R4     ; Restore object id
       MOV R8,R6     ; Restore sprite

       JMP OBNXT

       ; Fast octorok
OCTRKF
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JEQ OCTORI    ; If zero do setup

       CI R4,51*>100 ; cloud animation?
       JHE OCTOR4

       BL @HITEST
       BL @ANIM6
       JMP OCTOR3    ; Move every frame

OCTOR4 ; cloud animation
       AI R4,->100
       MOV R4,R0
       SRL R0,8
       CI R0,62
       JEQ !
       CI R0,56
       JEQ !
       CI R0,50
       JNE OBNXT

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Use HP/stun counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP
       MOVB @VDPRD,R6      ; Load sprite and facing
       MOVB @VDPRD,@R6LB   ; Load color
       AI R4,-49*>100      ; Set R4HB to 1
       JMP OBNXT

!      AI R6,>0400
       JMP OBNXT2


GHINI
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       LI R6,>200F    ; Ghini sprite white
       AI R4,>0100
!
OBNXT2
       B @OBNEXT




* Enemy movement (octorok, moblin, lynels)
* Modifies R0-R3,R10
EMOVE
       LI R10,OBNEXT    ; Return to R10
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE3       ; No? Keep moving

       BL @RANDOM
       MOV R0,R1
       ANDI R0,7        ; 1 in 8 chance to change direction
       JNE EMOVE3

       ; TODO shoot projectile
       ANDI R1,>0003
       JNE EMOVE2       ; 1 in 4 chance to shoot

       AI R4,49*>100    ; set counter for projectile launch

EMOVE2 BL @RANDOM       ; Change direction
       ANDI R0,>1800
       XOR R0,R6

EMOVE3
       MOV R6,R3        ; Get enemy facing
       SRL R3,10
       ANDI R3,>0006         ; Mask only direction bits

       LI R2,EMOVE2     ; Change direction if wall or screen edge
* Enemy movement subroutine, goto R2 if solid, goto R10 otherwise
* R3 = direction 0=Down 2=Left 4=Right 6=Up
* Modifies R0,R1
EMOVE4
       MOV R5,R0
       SZC @EMOVEM(R3),R0    ; Aligned to 8 pixels?
       JNE EMOVE5            ; Not aligned, move and return
       MOV R5,R0
       SZC @EMOVEC(R3),R0    ; For edge test
       C @EMOVEE(R3),R0      ; At edge of screen?
       JNE !                 ; At edge, return
       B *R2                 ; Return to R2 address
!
       ; Check for walls, will return to R2 if solid
       MOV @EMOVEA(R3),R0
       A R5,R0
       BL @TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @TESTCH

EMOVE5 A @EMOVED(R3),R5     ; Perform movement
       B *R10               ; Jump to saved return address

* Leever random direction
LERAND
       BL @RANDOM
       ANDI R0,>0180
       XOR R0,R4          ; Get random direction
* Lever move
LEMOVE
       LI R2,LERAND      ; EMOVE4 will go to R2 if solid
       LI R10,OBNEXT     ; EMOVE4 will return to R10

       MOV R4,R3         ; Get direction in R3
       SRL R3,6
       ANDI R3,>0006

       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE5       ; No? Keep moving

       JMP EMOVE4


* Knockback, until hitting wall or edge of screen
* R3 = direction 0=Down 2=Left 4=Right 6=Up
* Modifies R0-R2
KNOCKB
       MOV R11,R10           ; Save return address in R10
       JMP EMOVE4


* Octorok Bullet
* R4[7..6] = direction
BULLET
       MOV R4,R2
       ANDI R2,>00C0
       SRL R2,5         ; Get bullet direction R2: 0=Down 2=Left 4=Right 6=Up
       BL @LNKHIT       ; hit test on hero
       MOV R4,R4        ; test R4 for zero?  (did bullet hit hero)
       JEQ OBNXT2
       MOV R2,R3
       LI R2,SPROFF     ; Goto SPROFF if wall or screen edge
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       JMP OBNXT2



LEVERP DATA >3806,>3804  ; Leever half-up sprite

* R4:  7 bits animation counter
*      2 bits direction
*      1 bits hurt/stun flag
*      6 bits object id
* _______________frames___animation___counter
*   half-down:     16                  35
*   pulsing:       96       11         29..34
*   underground:  129                  20..28
*   pulsing:       32       11         18..19
*   half-up:       15                  17
*   normal:       255        5         1..16
LEEVER
       MOV R4,R1
       SRL R1,9
       JNE !
       BL @SPAWN
       LI R6,>0000
       MOV @OBJPTR,R1
       SWPB R1
       ANDI R1,>0E00
       A R1,R4            ; Initial counter + object pointer
       AI R4,21*>0200     ; Initial counter + 21
       BL @RANDOM
       ANDI R0,>0180
       XOR R0,R4          ; Get random direction
       CLR R6
       B @OBNEXT

!      MOV @COUNTR,R0

       ANDI R0,>000F
       JNE LEEVR2
       AI R4,->0200    ; Decrement counter every 16 frames

       ; Set colors based on new counter
       DEC R1         ; Half-down?
       JNE !
       AI R4,35*>0200  ; Change counter to pulsing (down)
       LI R1,35
       JMP LHALF

!      CI R1,16
       JNE !
       MOV @ECOLOR(R3),R6 ; Normal sprite
       JMP LEEVR2

!      CI R1,17        ; Half-up?
       JNE !
LHALF  MOV @LEVERP-28(R3),R6 ; Half-up/down sprite
       JMP LEEVR2

* Lever move every 6 frames (TODO should be 6 then 7)
LEMOV6
       MOV @COUNTR,R0
       SRL R0,12
       DEC R0
       JEQ LEMOVE
       JMP OBNXT3

!      CI R1,19        ; Pulsing?
       JEQ LPULSE

       CI R1,28        ; Underground?
       JNE !
       CLR R6          ; Transparent sprite
       JMP LEEVR2

!      CI R1,34        ; Pulsing?
       JNE LEEVR2

LPULSE LI R6,>2809     ; Pulsing sprite

LEEVR2
       CI R1,16        ; Normal?
       JH !
       BL @ANIM5
       BL @HITEST
       MOV @COUNTR,R0
       ANDI R0,1
       JEQ LEMOVE      ; Move every other frame
       JMP OBNXT3
!
       MOV R4,R0
       ANDI R0,>0040
       JEQ !
       BL @HSBIT       ; Do knockback or blinking
!
       CI R1,17        ; Half-up?
       JLE LEMOV6

       CI R1,19        ; Pulsing?
       JLE LPULS2

       CI R1,28        ; Underground?
       JLE LEMOV6

       CI R1,34
       JH LEMOV6       ; Half-down

LPULS2 BL @ANIM11      ; Pulsing?
       JMP LEMOV6



* R4: 8 bits counter
*     1 bits reserved
*     1 bits hurt/stun flag
*     6 bits object id
* init                             counter=0
* pulsing  32 frames   anim 11     counter=10..11
* normal   48 frames               counter=7..9
*   bullet appears after 19 frames, then shoots after 16
* pulsing  96 frames   anim 11     counter=1..6
* disappear 2 frames
ZORA   CI R4,>0100
       JHE !

ZORA1  LI R2,ZORA3
ZORA2  BL @RANDOM      ; Get a random coordinate
       ANDI R0,>70F0   ; Align to 16 pixels
       AI R0,>2800     ; Moved down by 5 lines
       ; TODO fix respawning in same location
       MOV R0,R5       ; Save location if it's good
       BL @TESTCH
       JMP ZORA2
ZORA3  ANDI R1,>F000
       CI R1,>E000     ; Is it water?
       JNE ZORA2

       AI R4,>0C00     ; Set counter to 11
       JMP ZORA4
!
       MOV @COUNTR,R0
       ANDI R0,>000F   ; Get 16 counter
       JNE ZORA5
       AI R4,->100
       CI R4,>0100
       JL ZORA1       ; Reset counter
       CI R4,>0900+ZORAID
       JNE !
       LI R6,>680D     ; Zora sprite
       C R5,@HEROSP    ; Hero above or below zora?
       JL ZORA5
       AI R6,>0400     ; Zora face down toward hero
       JMP ZORA5
!      CI R4,>0600+ZORAID
       JNE ZORA5
ZORA4
       LI R6,>2805     ; Pulsing sprite

ZORA5
       CI R4,>0700
       JL !            ; Pulsing
       CI R4,>0A00
       JHE !           ; Pulsing
       BL @HITEST
       JMP OBNXT3

!      BL @ANIM11

       JMP OBNXT3


OBNXT3 B @OBNEXT

* dead - little 6 big 6 little 6
* R4[15..8] = counter, initially 18
DEAD   MOV R4,R1
       SRL R1,8
       LI R6,>E800   ; little star
       AI R1,-8
       CI R1,6
       JHE !
       LI R6,>EC00   ; big star
!      SRL  R1,1
       ANDI R1,>0003   ; animate colors
       MOVB @DEADC(R1),@R6LB
       AI R4,->0100
       CI R4,>0100
       JHE OBNXT3
       B @SPROFF


* test if sword is hitting enemy, and if enemy is hitting hero (LNKHIT)
* modifies R0-R3 R7 R8
HITEST
       ; currently getting knocked back or stunned?
       MOV R4,R0
       SLA R0,10   ; Get hurt/stun bit in carry flag
       JOC HSBIT

       ; get position of sword sprite
       LI R7,-8
HITES1
       MOV @SPRLST+32(R7),R3 ; Get sword pos in R3
       
       S   R5,R3            ; subtract sprite pos from sword pos
       ABS R3               ; absolute difference
       CI R3,>0E00          ; Y diff <= 13 ?
       JH HITES2
       SWPB R3              ; swap to compare X
       ABS R3               ; absolute difference
       CI R3,>0E00          ; X diff <= 13 ?
       JH HITES2
       
       CI R7,-4
       JNE !
       LI R0,BPOPID         ; Beam Sword Pop ID
       SOC R0,@BSWDOB       ; Set sword beam to sword pop

!      MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       CLR R2
       MOVB @VDPRD,R2       ; Enemy HP in R2

       MOV @HFLAGS,R0       ;
       ANDI R0,WSWORD+MSWORD ; Get sword bits
       AI  R0,>0100         ; R0 = >100,>200,>400 based on sword power
       S   R0,R2            ; Subtract sword damage from enemy hp
       JGT HURT             ; Jump if hp is greater than zero

!      ;LI R4,RUPYID         ; Rupee spawn
       ;CLR R6               ; Set color and sprite index to transparent
       ;BL @OBSLOT


       BL @RANDOM
       ANDI R0,>0007
       JNE !

       LI R4,RUPYID         ; Rupee spawn
       JMP SPITEM

!      DEC R0
       JNE !

       LI R4,BRPYID         ; 5 Rupee spawn
       JMP SPITEM

!      DEC R0
       JNE !

       LI R4,HARTID         ; Heart spawn
       JMP SPITEM

!
       LI R4,DEADID          ; Change object type to DEAD, counter to 19
       CLR R6                ; Clear sprite and color transparent

       JMP OBNXT3
* Spawn item
SPITEM
       MOV R4,R6
       ANDI R6,>003F
       A R6,R6
       MOV @ECOLOR(R6),R6               ; Set color and sprite index
       BL @OBSLOT
       JMP -!


HITES2 AI R7,4
       JNE HITES1
       B  @LNKHIT
HITES3 RT


HSBIT   ; Enemy is hurt or stunned
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP
       MOVB @VDPRD,R2       ; Enemy stun counter in R1
       SWPB R2
       MOVB @VDPRD,R2       ; Enemy hurt counter in R1
       JEQ STBIT

HURT2  AI R2,-256           ; Decrement counter
       INC R1
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Store updated Hurt counter in VDP

       MOV R2,R3
       ANDI R3,>0600        ; Get color counter, 2 frames each
       SRL R3,9
       MOVB @HRTCOL(R3),@R6LB

       MOV R2,R0
       ANDI R0,>3F00        ; Mask counter
       JNE !
       ANDI R0,>00FF        ; Clear direction and counter
       MOV R4,R3
       ANDI R3,>003F        ; Get object index
       A R3,R3
       MOVB @ECOLOR+1(R3),@R6LB  ; Reset sprite color
       ANDI R4,>FFBF        ; Clear hit/stun bit
!      CI R0,>1000
       JL HITES3

       MOV R4,R0
       ANDI R0,>003F
       CI R0,ZORAID
       JEQ HITES3           ; Zora cannot be knocked back

       MOV R2,R3
       ANDI R3,>C000        ; Mask direction bits
       SRL R3,13            ; R3 = direction bits * 2
       LI R2,OBNEXT
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       B @OBNEXT


HURT       ; Enemy hurt
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Store updated HP in VDP

       ORI R4,>0040         ; Set hurt/stun bit

       MOV @SPRLST+34(R7),R2 ; Get sword sprite index in R2
       ANDI R2,>0C00        ; Mask direction bits
       SLA R2,4
       ORI R2,>2000         ; Get new direction bits and hurt counter = 32

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       JMP HURT2


STBIT  ; TODO



* Enemy edge test, jump to R2 if at edge of screen
* R3 = direction 0=Down 1=Left 2=Right 3=Up
* Modifies R0,R1
TSTEDG
       MOV R5,R0
       SWPB R0
       MOV @TSTJMP(R3),R1
       B *R1
TESTLT
       CI R0,>1000          ; Check left edge of screen
       JLE !
       RT
TESTRT
       CI R0,>E000         ; Check right edge of screen
       JHE !
       RT
TESTUP
       CI R5,>1800         ; Check top edge of screen
       JLE !
       RT
TESTDN
       CI R5,>B000          ; Check bottom edge of screen
       JHE !
       RT
!      B *R2


TSTJMP DATA TESTDN,TESTLT,TESTRT,TESTUP


* R4=data R5=YYXX R6=SSEC
* Sets R6 to random facing
SPAWN
       MOV @ECOLOR(R3),R6    ; Set sprite and color
       MOV R11,R10          ; Save return address
SPAWN2 BL @RANDOM           ; Get a random screen location
       ANDI R0,>70F0
       AI R0,>2800
       MOV R0,R2
       ANDI R2,>00F0
       CI R2,>0010     ; Don't spawn too far left
       JLE SPAWN2
       CI R2,>00E0     ; or right
       JHE SPAWN2

       MOV R0,R5       ; Don't spawn on solid ground
       LI R2,SPAWN2
       AI R0,>0800
       BL @TESTCH
       MOV R5,R0
       AI R0,>0808
       BL @TESTCH

       C @DOOR,R5     ; Don't spawn on a door
       JEQ SPAWN2

       BL @RANDOM
       ANDI R0,>1800  ; Face random direction
       XOR R0,R6

       MOV R0,R1
       SRL R1,10      ; Make sure direction is clear
       MOV @EMOVEA(R1),R0  ; Check for walls
       A R5,R0
       BL @TESTCH
       CLR R1

       B *R10

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



* Animation functions, toggle sprite every 5, 6 or 11 frames
* Modifies R0,R1,R2
ANIM5
       MOV @COUNTR,R0
       ANDI R0,>00E0
       SLA R0,3             ; get 3-bit 5 counter
       LI R2,>0500
       JMP !
ANIM6
       MOV @COUNTR,R0
       SRL R0,4             ; get uppper nibble 6 counter
       LI R2,>0600
       JMP !
ANIM11
       MOV @COUNTR,R0
       LI R2,>0B00
!      ANDI R0,>0F00        ; get lower nibble 11 counter
       MOV @OBJPTR,R1
       SWPB R1
!      C R1,R2
       JLE !
       S R2,R1
       JMP -!
!      C R1,R0
       JNE !
       LI R1,>0400
       XOR R1,R6     ; Toggle animation every 5, 6 or 11 frames
!      RT

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


;R1     TB 0  TB 1  TB 2  TB 3  TB 4  TB 5  TB 6  TB 7
;0000   =     space enter fctn  shift ctrl
;0100   .     L     O     9     2     S     W     X
;0200   ,     K     I     8     3     D     E     C
;0300   M     J     U     7     4     F     R     V
;0400   N     H     Y     6     5     G     T     B
;0500   /     ;     P     0     1     A     Q     Z
;0600   Fire  Left  Right Down  Up  (Joystick 1)
;0700   Fire  Left  Right Down  Up  (Joystick 2)



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
       LI R2,12
       B @BANKSW


* Do the item selection menu
* Modifies R0-R12
DOMENU
       LI   R0,BANK5         ; Menu is in bank 5
       LI   R1,HDREND        ; First function in bank 1
       LI   R2,8             ; Use item selection / menu down
       BL   @BANKSW

       LI R0,SCHSAV        ; Save 32 byte scratchpad
       LI R1,SCRTCH
       LI R2,32
       BL @VDPW

       LI R1,>1F40          ; Position B item in box
       LI R0,SPRTAB+(2*4)
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
       LI R1,WRKSP+(5*2)
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

       LI R0,SCHSAV         ; Restore 32 byte scratchpad
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       SOC R4,@HFLAGS       ; Save selected item

       LI   R0,BANK5         ; Menu is in bank 5
       LI   R1,HDREND        ; First function in bank 1
       LI   R2,9             ; Use item selected / menu up
       BL   @BANKSW
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


; HP  Rings None  Blue  Red
;  0        Empty Empty Empty
;  1        Half  Half  Half
;  2        Full  Half  Half
;  3        Half  Full  Half
;  4        Full  Full  Half
;  5        Half  Half  Full
;  6        Full  Half  Full
;  7        Half  Full  Full
;  8        Full  Full  Full

* Enemy hurt colors: 2 frames each
HRTCOL BYTE >0C,>01,>08,>04  ; green black orange blue

;DEADC  BYTE >08,>06,>0F,>0E  ; dark red, red, cyan, white
DEADC  BYTE >09,>06,>0F,>07  ; red, dark red, red, white, cyan


* Facing     Right Left  Down  Up
EMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
EMOVEA DATA >0010,>FFFF,>1000,>FF00     ; Test char offset 1
EMOVEB DATA >0F10,>0EFF,>100F,>FF0F     ; Test char offset 2
EMOVEC DATA >FF00,>FF00,>00FF,>00FF     ; Screen edge mask (inverted for SZC)
EMOVEE DATA >00E0,>0010,>A800,>2800     ; Screen edge value
EMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)




SPRL0  DATA >D1D0,>E002  ; Map dot
       DATA >D1C8,>E406  ; Half-heart
       DATA >047C,>F804  ; B item
       DATA >0494,>7C08  ; Sword item
       DATA >D1D0,>0003  ; Link color
       DATA >D1D0,>0401  ; Link outline
SPRLE

* Cave item
* bits[15..12] counter
* bits[11..6] item number, 6 bits
* bits[5..0] object id
* item number:
*   0 fire
*   1 npc
*
* counter:
*   16..13 poof
*   12..7 dissolve 1
*   6..1 dissolve 2
*   0 item appearing
CAVNPC
       MOV R4,R0
       SRL R0,12
       JNE !
       BL @RUPEEB  ; Rupee blink
CAVNP2 B @OBNEXT

!      AI R4,->1000

       CI R0,13
       JNE !
       LI R6,CLOUD1   ; poof, white
!
       CI R0,12
       JNE !
       AI R6,>0400   ; dissolve 1
!
       CI R0,6
       JNE !
       AI R6,>0400   ; dissolve 2
!
       DEC R0
       JNE CAVNP2

       CI R5,>5878    ; NPC position? otherwise flame
       JEQ !

       LI R6,>F008    ; Fire sprite
       LI R1,>2020    ; Fire background chars
       LI R2,>5E5F    ; Fire background chars
       BL @STORCH     ; Store characters R1,R2 at R5 in name table
CAVNP3 JMP CAVNP2

!      ; load cave items in bank 5
       LI R0,BANK5
       LI R1,MAIN
       LI R2,11
       B @BANKSW
       JMP CAVNP2



SLAST  END  MAIN
