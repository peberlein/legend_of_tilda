;
; Legend of Tilda
;
; Bank 0: initialization and main loop
;

       COPY 'tilda.asm'
MAIN
       LIMI 0                ; Disable interrupts, always
       LI   R14,VDPWA        ; Keep VDPWA address in R14
       LI   R15,VDPWD        ; Keep VDPWD address in R15

       LI R1,VDPINI         ; Load initial VDP registers
       LI R4,8
!      MOV *R1+,R0
       BL @VDPREG
       DEC R4
       JNE -!

       LI R0,BANK3           ; Title screen in bank 3
       LI R1,MAIN
       CLR R2               ; Mode = title screen
       BL   @BANKSW

       LI R0,>01A5          ; VDP Register 1: Blank screen
       BL @VDPREG
       LI R0,>07F1          ; VDP Register 7: White on Black
       BL @VDPREG

       LI   R0,CLRTAB+VDPWM   ; Clear the palette
       LI   R1,>1100          ; Black on black
       LI   R2,32
       MOVB @R0LB,*R14
       MOVB R0,*R14
!      MOVB R1,*R15
       DEC  R2
       JNE -!

RESTRT
       LI   R0,SPRPAT+(28*32)         ; Sprite Pattern Table
       LI   R1,SPR8
       LI   R2,(SPR43-SPR8)+32
       BL   @VDPW
       
;                               Draw the screen
       CLR  R0                ; Start at top left corner of the screen
       LI   R1,MD0
       LI   R2,32*3            ; Number of bytes to write
       BL   @VDPW
       LI   R2,32*21           ; Fill the rest with space
       LI   R1,>2000
!      MOVB R1,*R15
       DEC  R2
       JNE -!


       LI   R0,SCR2TB
       LI   R1,MD0
       LI   R2,32*3            ; Number of bytes to write
       BL   @VDPW
       
       LI   R0,MENUSC
       LI   R1,MD2             ; Menu screen data
       LI   R2,32*21           ; Number of bytes to write
       BL   @VDPW

       
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

       LI R0,>0000           ; Initial Rupees
       MOVB R0,@RUPEES
       LI R0,>0000           ; Initial Keys
       MOVB R0,@KEYS
       LI R0,>0000           ; Initial Bombs
       MOVB R0,@BOMBS
       LI R0,>0400           ; Initial Hearts-1
       MOVB R0,@HEARTS
       LI R0,>0600           ; Initial HP
       MOVB R0,@HP

       CLR @FLAGS
       BL @STATUS            ; Draw status

       MOV @VDPINI+2,R0      ; Turn off blanking
       BL @VDPREG

       LI R9,32
       LI R1,OBJECT        ; Clear object table
!      CLR *R1+
       DEC R9
       JNE -!

       LI   R0,BANK2         ; Overworld is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       LI   R2,5             ; Use wipe from center 5
       BL   @BANKSW

       CLR @MOVE12

       ;LI R0,MAGSHD      ; Test initial magic shield
       CLR R0
       MOV R0,@HFLAGS

       CLR @KEY_FL


       LI R5,>7078        ; Link Y X position in pixels
       MOV R5,@HEROSP
       MOV R5,@HEROSP+4
       LI R3,FACEDN        ; Initial facing down
       LI R11,DRAW
       B @LNKSPR           ; Load facing sprites


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

       BL @VSYNC
       

       ;LI   R0,>07F1          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       BL @MUSIC
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
       

       ;LI   R0,>07FE          ; VDP Register 7: White on Black
       ;BL   @VDPREG

       MOV @HEROSP,R5    ; Hero YYXX position
       AI R5,>0100         ; Adjust Y pos
       
       MOVB @HURTC,R4   ; Hurt counter
       JEQ !
       BL @LNKHRT

!

       MOV @KEY_FL, R0
       SLA R0,1             ; Shift EDG_C bit into carry status
       JNC !
       LI   R2,8            ; Use item selection
       CLR R0               ; Don't change MAPLOC
       BL @SCROLL

DOMENU
       BL @VSYNC
       BL @DOKEYS
       MOV @KEY_FL, R0
       SLA R0,1             ; Shift EDG_C bit into carry status
       JNC DOMENU

       LI   R2,9            ; Exit item selection
       CLR R0               ; Don't change MAPLOC
       BL @SCROLL

!


       BL @DOKEYS

       MOVB @SWORDC,R0   ; Sword animation counter
       JNE !

       MOV @KEY_FL,R0
       SLA R0,3          ; Shift EDG_A bit into carry status
       JNC !

       LI R0,>0C00          ; Sword animation is 12 frames
       MOVB R0,@SWORDC
!

; Up/down movement has priority over left/right, unless there is an obstruction
       MOV @FACING,R3

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

       CB R3,@FACING        ; Update facing if up/down was pressed against a wall
       JNE !
       B @DRAW
!      LI R11,DRAW
       B @LNKSPR

MOVEDN
       LI R3,FACEDN
       BL @SWORD

       CI R5,(192-16)*256   ; Check at bottom edge of screen
       JL !
       BL @SCRLDN     ; Scroll down
       LI R3,FACEDN
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
       LI R3,FACEUP
       BL @SWORD
       
       CI R5,25*256  ; Check at top edge of screen
       JHE !
       BL @SCRLUP     ; Scroll up
       LI R3,FACEUP
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
       LI R3,FACERT
       BL @SWORD

       MOV R5,R0     ; Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ MOVER2     ; Already aligned
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
MOVELT
       LI R3,FACELT
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

!      LI R3,FACERT
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

!      LI R3,FACELT
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
       MOV @FACING,R3
       CLR R1
MOVE3
       MOVB R1,@SPRLST+2       ; Set color sprite index
       AI R1,>0400
       MOVB R1,@SPRLST+6       ; Set outline sprite index

MOVE4  CB R3,@FACING
       LI R11,DRAW
       JNE LNKSPR
       JMP DRAW


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

LNKSPR MOVB R3,@FACING   ; Save facing direction
       LI R0,BANK3
       LI R1,MAIN
       LI R2,2
       B @BANKSW


DRAW
       AI R5,->0100          ; Move Y up one
       MOV R5,@HEROSP	    ; Update color sprite
       MOV R5,@HEROSP+4    ; Update outline sprite
       AI R5,>0100            ; Move Y down one

INFLP2 B @INFLP

GODOOR LI R0,INCAVE
       SOC R0,@FLAGS         ; Set in cave flag
       
       AI R5,->0100          ; Move Y up one
       MOV R5,@HEROSP	     ; Update color sprite
       MOV R5,@HEROSP+4      ; Update outline sprite
       AI R5,>0100           ; Move Y down one
       MOV R11,R12
       BL @SPRUPD
       MOV R12,R11
       
       CLR  R0               ; Don't change MAPLOC
       LI   R2,6             ; Use cave animation
       JMP SCROLL
       
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



SWORD  CLR R0
       MOVB @SWORDC,R0       ; Get sword counter
       JNE !
       RT                    ; Return if zero
!      AI R0,>FF00
       MOVB R0,@SWORDC       ; Decrement and save sword counter
       JNE !
       
       CLR R1                ; Set link to standing
       MOVB R1,@HEROSP+2
       LI R1,>0400
       MOVB R1,@HEROSP+6
       LI R1,>D200          ; Sword YY address (hide)       
       MOVB R1,@SPRLST+(6*4)+0

       JMP SWBEAM            ; Do sword beam 

!      CI R0,>0B00
       JNE !

       LI R1,>1000          ; Set link to sword stance
       MOVB R1,@HEROSP+2
       LI R1,>1400
       MOVB R1,@HEROSP+6
       
       JMP SWORD4

!      C @FACING,R3          ; Redraw sword if facing changed
       JNE !

       CI R0,>0800           ; Sword appears on fourth frame
       JNE SWORD4
; Draw sword
!
       MOV R3,R1
       SRL R1,7

       MOV R5,R7           ; Position relative to link
       A   @SWORDX(R1),R7

       MOV R3,R8
       SLA R8,2
       ORI R8,>7008          ; Sword facing (TODO sword color)
       
       MOV R7,@SPRLST+(6*4)+0
       MOV R8,@SPRLST+(6*4)+2

SWORD4 C @FACING,R3          ; Update facing as needed
       JEQ INFLP2            ; Sword done
       LI R11,DRAW
       B @LNKSPR             ; Change direction (sword facing changed already)

SWBEAM
       LI R0,FULLHP
       CZC @FLAGS,R0         ; Test for sword beam
       JEQ SWORD4

       MOV @OBJECT+14,R0     ; Sword beam already active?
       JNE SWORD4

       MOV R3,R1            ; Launch sword beam
       SRL R1,7

       MOV @HEROSP,R5      ; Position relative to hero
       A   @SWORDX(R1),R5
       
       MOV R3,R6            ; Get facing from sword sprite
       SLA R6,2
       ORI R6,>700f          ; Sword facing
       
       MOV R5,@SPRLST+(7*4)+0
       MOV R6,@SPRLST+(7*4)+2
       
       LI R0,>0010
       MOV R0,@OBJECT+14
       
       JMP SWORD4
       
       
SWORDX DATA >0A00,>00F5,>010B,>F4FF

; Beam sword shoots when link is at full hearts, cycle colors white,cyan,red,brown
; R4[9..8] = color bits
; R4[6] = pop bit
BSWORD
       MOV R4,R1
       SLA R1,10
       JOC BSWPOP

       AI R4,>0100              ; Cycle colors
       ANDI R4,>03FF
       MOV R4,R1
       SRL R1,8
       MOVB @BSWRDC(R1),@R6LB

       MOV R6,R3
       ANDI R3,>0F00       ; Get facing from sprite index
       SRL  R3,9
       A @BSWRDD(R3),R5    ; Add movement from table

       MOV R5,R0
       SWPB R0
       MOV @BSWJMP(R3),R1
       B *R1
BSWDLT
       CI R0,>0800          ; Check left edge of screen
       JH BSWNXT
       JMP BSWPOP
BSWDRT
       CI R0,>E800         ; Check right edge of screen
       JL BSWNXT
       JMP BSWPOP
BSWDUP
       CI R5,>1800         ; Check left edge of screen
       JH BSWNXT
       JMP BSWPOP
BSWDDN
       CI R5,>B000          ; Check bottom edge of screen
       JL BSWNXT
BSWPOP
       LI R4,BSPLID        ; Create splash
       LI R6,>800F
       BL @OBSLOT
       LI R6,>840F
       BL @OBSLOT
       LI R6,>880F
       BL @OBSLOT
       LI R6,>8C0F
       BL @OBSLOT
       LI R4,>0100
       JMP !
BSPOFF
       CLR @OBJECT+14       ; Clear sword so it can be fired again
SPROFF
       CLR R4
!      LI R5,>D200        ; Disappear
BSWNXT B @OBNEXT

BSWJMP DATA BSWDDN,BSWDLT,BSWDRT,BSWDUP
BSWRDD DATA >0300,>FFFD,>0003,>FD00     ; Beam sword direction
BSWRDC BYTE >07,>0F,>06,>09             ; Beam sword colors: cyan, white, dark red, light red
BSPLSD DATA >FEFF,>FF01,>00FF,>0101     ; Beam splash direction data


; Beam sword splash
BSPLSH
       MOV R6,R1
       ANDI R1,>0F00       ; Get facing from sprite index
       SRL  R1,9
       MOV R5,R0
       A @BSPLSD(R1),R5    ; Add movement from table
       XOR R5,R0
       ANDI R0,>0080       ; Check if X wrapped
       JEQ !
       ORI R6,>0080        ; Set early clock bit
       AI R5,>0020         ; Add early clock offset

!      AI R4,>0100              ; Cycle colors
       MOV R4,R1
       ANDI R1,>1F00
       JEQ BSPOFF
       SWPB R1
       ANDI R1,>0003
       ANDI R6,>FFF8        ; Mask off color
       AB @BSWRDC(R1),@R6LB ; Get cycled color
       
       JMP BSWNXT


; Rupee yellow, blue; 5 rupee blue blue; heart blue red

RUPEEC BYTE >0A,>05,>05,>05,>04,>06

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
       MOV @SPRLST,R3    ; Get hero pos in R3
       BL @COLIDE
       MOV @SPRLST+24,R3 ; Get sword pos in R3
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
       JMP SPROFF
GETRUP AB R0,@RUPEES   ; Add R0 to rupees
       JNC DOSTAT      ; Overflow?
       SETO R0         ; Reset rupess to 255
       MOVB R0,@RUPEES
       JMP DOSTAT


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
; Enemy direction in R2
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
       JH -!
       SWPB R3
       ABS R3
       CI R3,>0A00
       JH -!

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
       CLR R0         ; left
       JMP LNKHI3
!      LI R0,>0100    ; right
       JMP LNKHI3
LNKHI2
       ; vertically aligned
       CB R5,@HEROSP
       JHE !
       LI R0,>0200    ; down
       JMP LNKHI3
!      LI R0,>0300    ; up

LNKHI3

       ; TODO bullets bounce off if facing the right way (and have magic shield in some cases)


       AI R0,>C000      ; add 48<<10 frames hurt counter
       MOV R0,@HURTC

       MOV R4,R1
       ANDI R1,>003F    ; Get enemy type

       ; TODO Enemy reverse direction, or bullet disappear

       SB @EDAMAG(R1),@HP  ; Subtract enemy attack damage
       JGT NOTDED

       CLR R1         ; Set HP to zero in case of underflow
       MOVB R1,@HP
       BL @STATUS     ; Show empty hearts

       LI R0,BANK3
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
       A @EMOVEB(R3),R0
       BL @TESTCH

!      A @EMOVED(R3),R5     ; Do movement
       BL *R10              ; Return to saved address


; Facing     Right Left  Down  Up
LMOVEA DATA >0810,>07FF,>1000,>0700     ; Test char offset 1
LMOVEB DATA >0F10,>0EFF,>100F,>070F     ; Test char offset 2
; Facing     Right Left  Down  Up
;EMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
;EMOVEA DATA >0010,>FFFF,>1000,>FF00     ; Test char offset 1
;EMOVEB DATA >0F10,>0EFF,>100F,>FF0F     ; Test char offset 2
;EMOVEC DATA >FF00,>FF00,>00FF,>00FF     ; Screen edge mask (inverted for SZC)
;EMOVEE DATA >00E0,>0010,>A800,>2800     ; Screen edge value
;EMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)


; Look at character at pixel coordinate in R0, and jump to R2 if solid
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
       NOP
       MOVB @VDPRD,R1
       
       CI R1,>7EFF
       JH !
       RT
!      B *R2        ; Jump alternate return address


; Update Sprite List to VDP Sprite Table (with flicker)
; Modifies R0-
SPRUPD
       LI R0,SPRTAB+VDPWM  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU

       MOV @COUNTR,R2
       ANDI R2,>0001
       JEQ  !

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


; Scan objects for empty slot: store R4 index & data, R5 in location, R6 in sprite index and color
OBSLOT
       LI R1,24      ; Start at slot 12
!      MOV @OBJECT(R1),R0
       JEQ !
       INCT R1
       CI R1,64
       JNE -!
       RT            ; Unable to find empty slot
!      MOV R4,@OBJECT(R1)
       A R1,R1
       MOV R5,@SPRLST(R1)
       MOV R6,@SPRLST+2(R1)
       RT

       
VDPINI
       DATA >0000          ; VDP Register 0: 00
       DATA >01E2          ; VDP Register 1: 16x16 Sprites
       DATA >0200          ; VDP Register 2: 00
       DATA >0300+(CLRTAB/>40)  ; VDP Register 3: Color Table
       DATA >0400+(PATTAB/>800) ; VDP Register 4: Pattern Table
       DATA >0500+(SPRTAB/>80)  ; VDP Register 5: Sprite List Table
       DATA >0600+(SPRPAT/>800) ; VDP Register 6: Sprite Pattern Table
       DATA >07F1          ; VDP Register 7: White on Black


       
; Object function pointer table, functions called with data in R4, sprite YYXX in R5, idx color in R6, must return by B @OBNEXT
OBJTAB DATA OBNEXT,PEAHAT,TKTITE,TKTITE  ; 0-3 - - Red Blue
       DATA OCTORK,OCTORK,OCTRKF,OCTRKF  ; 4-7 Red Blue Red Blue
       DATA MOBLIN,MOBLIN,LYNEL, LYNEL   ; 8-B Red Blue Red Blue
       DATA GHINI, ROCK, LEEVER,LEEVER  ; C-F - - Red Blue
       DATA BSWORD,BADNXT,BSPLSH,BADNXT  ; 10-13
       DATA ZORA0, ZORA1, ZORA2, BADNXT   ; 14-17
       DATA DEAD, BADNXT, BADNXT,BADNXT  ; 18-1B
       DATA BULLET,ARROW,LARROW,BSWORD   ; 1C-1F
       DATA RUPEE, BRUPEE,HEART,FAIRY    ; 20-23

BSWDID EQU >0010 ; Beam Sword ID
BSWPID EQU >0050 ; Beam Sword Pop ID
BSPLID EQU >0812 ; Beam Sword Splash ID with initial counter
DEADID EQU >1218 ; Dead Enemy Pop ID w/ counter=18
RUPYID EQU >5020 ; Rupee ID with initial counter
BRPYID EQU >5021 ; Blue Rupee ID with initial counter
HARTID EQU >5022 ; Heart ID with initial counter
FARYID EQU >5023 ; Fairy ID with initial counter



; Enemy sprite index and color
ECOLOR DATA >0000,>2009  ; None, Peahat
       DATA >3009,>3005  ; Red Tektite, Blue Tektite
       DATA >4008,>4004  ; Octorok sprites
       DATA >4008,>4004  ; Fast Octorok Sprites
       DATA >2006,>2004  ; Moblin Sprites
       DATA >4006,>4004  ; Lynel Sprites
       DATA >200F,>2009  ; Ghini, Rock
       DATA >3006,>3004  ; Leever Sprites
       DATA >0000,>0000  ; Beam Sword
       DATA >0000,>0000  ; Beam splash
       DATA >0000,>0000  ; Zora0-1
       DATA >0000,>0000  ; Zora2
       DATA >0000,>0000  ; Dead
       DATA >0000,>0000  ;
       DATA >0000,>0000  ; Bullet,arrow
       DATA >0000,>0000  ; Larrow,bsword
       DATA >C004,>C004  ; Rupee, Blue rupee
       DATA >C800,>F400  ; Heart, Fairy

; Damage enemies do to attack hero
; 1 dmg = 1/2 heart w/ no ring = 1/4 heart w/ blue ring = 1/8 heart w/ red ring
EDAMAG BYTE >00,>01  ; None, Peahat
       BYTE >01,>01  ; Red/Blue Tektite
       BYTE >01,>01  ; Octorok
       BYTE >01,>01  ; Fast Octorok
       BYTE >01,>01  ; Moblin
       BYTE >02,>04  ; Lynel
       BYTE >02,>01  ; Ghini, Rock
       BYTE >01,>02  ; Red/Blue Leever
       BYTE >00,>00  ; Beam Sword
       BYTE >00,>00  ; Beam splash
       BYTE >00,>00  ; Zora0-1
       BYTE >00,>00  ; Zora2
       BYTE >00,>00  ; Dead
       BYTE >00,>00  ;
       BYTE >01,>00  ; Bullet,arrow
       BYTE >00,>00  ; Larrow,bsword



ARROW
LARROW
FAIRY
BADNXT JMP BADNXT




; Peahat animation loop: 2 2 1 2 1  (01011011)
; And moves by 1 only when animation changes
; Peahat Direction data
PEAHAD DATA >0001,>0101,>0100,>00FF  ; 0 Right, 1 downright, 2 down, 3 downleft
       DATA >FFFF,>FEFF,>FF00,>FF01  ; 4 Left,  5 upleft,    6 up,   7 upright
PEAHAA DATA >DAAA,>AAAA,>AA4A,>4A4A,>4911,>1111,>1080,>8080 ; animation
; R4:  6 bits animation counter
;      3 bits direction
;      1 bits hurt/stun flag
;      6 bits object id
;  descending: 128 frames, counter=27..42
;  landed: 72 frames, counter=18..26
;  ascending: 128 frames, counter=2..17   init=17
;  flying: 8 frames, count=1
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



; Tektite
; R4[15-8] = counter
TKTITE
       MOV R4,R0
       SRL R0,8       ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       MOV @ECOLOR(R3),R6 ; Reload sprite and color
       AI R4,>1100    ; counter += 17
!      AI R4,->0100   ; decrement counter
       DEC R0         ; decrement counter
       JNE !          ; toggle animation when counter hits zero
       AI R4,>1100    ; counter += 17
       LI R1,>0400
       XOR R1,R6      ; Toggle animation
!      BL @HITEST
       JMP OBNXT

OBNXT  B @OBNEXT

; Octorok, Moblin and Lynel AI
LYNEL
MOBLIN       
OCTORK
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE OCTOR2    ; If zero do setup
OCTORI
       ;MOV @ECOLOR(R3),R6  ; Setup sprite index and color
       BL @SPAWN     ; Setup octorok
       AI R4,>0100
OCTOR2
       BL @HITEST
       BL @ANIM6
       SLA R0,8
       JNC EMOVE     ; Move every other frame (unless it's fast octorok)
       JMP OBNXT

; Fast octorok
OCTRKF
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JEQ OCTORI    ; If zero do setup
       BL @HITEST
       BL @ANIM6
       JMP EMOVE     ; Move every frame

GHINI
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       LI R6,>200F    ; Ghini sprite white
       AI R4,>0100
!      JMP OBNXT

ROCK
       JMP OBNXT

       
; Enemy movement (octorok, moblin, lynels)
; Modifies R0-R3,R10
EMOVE
       LI R10,OBNEXT    ; Return to R10
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE3       ; No? Keep moving

       BL @RANDOM
       ANDI R0,7        ; 1 in 8 chance to change direction
       JNE EMOVE3

EMOVE2 BL @RANDOM       ; Change direction
       ANDI R0,>1800
       XOR R0,R6

EMOVE3
       MOV R6,R3        ; Get enemy facing
       SRL R3,10
       ANDI R3,>0006         ; Mask only direction bits

       LI R2,EMOVE2     ; Change direction if wall or screen edge
; Enemy movement subroutine, goto R2 if solid, goto R10 otherwise
; R3 = direction 0=Down 2=Left 4=Right 6=Up
; Modifies R0,R1
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

; Leever random direction
LERAND
       BL @RANDOM
       ANDI R0,>0180
       XOR R0,R4          ; Get random direction
; Lever move
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

       B @EMOVE4
; Lever move every 6 frames (TODO should be 6 then 7)
LEMOV6
       MOV @COUNTR,R0
       SRL R0,12
       DEC R0
       JEQ LEMOVE
       JMP OBNXT


; Knockback, until hitting wall or edge of screen
; R3 = direction 0=Down 2=Left 4=Right 6=Up
; Modifies R0-R2
KNOCKB
       MOV R11,R10           ; Save return address in R10
       JMP EMOVE4


BULLET
       MOV R4,R3
       ANDI R3,>00C0
       SRL R3,3         ; Get bullet direction
       LI R2,SPROFF     ; Goto SPROFF if wall or screen edge
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       JMP OBNXT


LEVERP DATA >3806,>3804  ; Leever half-up sprite

; R4:  7 bits animation counter
;      2 bits direction
;      1 bits hurt/stun flag
;      6 bits object id
; _______________frames___animation___counter
;   half-down:     16                  35
;   pulsing:       96       11         29..34
;   underground:  129                  20..28
;   pulsing:       32       11         18..19
;   half-up:       15                  17
;   normal:       255        5         1..16
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
       JMP OBNXT2

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
       JMP OBNXT2
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




ZORA0  MOV R4,R0
       ANDI R0,>00FF
       JNE !
; TODO find a random spot in water
       LI R6,>2806  ; Sprite and color
       LI R4,>1420  ; Countdown
       A R0,R4
!      DEC R4
       DEC R0
       JEQ ZORA1I

ZORA0B MOV R4,R1
       SRL R1,3
       ANDI R1,>000F
;       MOVB @PULSEM(R1),R1   ; Lookup animation in table
       ANDI R0,>0007
       INC R0
       SLA R1,R0     ; Test for animate bit
       JNC OBNXT2
       LI R0,>0400
       XOR R0,R6     ; Toggle animation
       JMP OBNXT2

ZORA1I
       LI R6,>6806  ; Sprite and color
       LI R4,>1540  ; Setup counter
ZORA1  DEC R4
       MOV R4,R0
       ANDI R0,>00FF
       JNE OBNXT2

       LI R6,>2806  ; Sprite and color
       LI R4,>1660   ; Setup counter
ZORA2  DEC R4
       MOV R4,R0
       ANDI R0,>00FF
       JNE ZORA0B
       JMP ZORA0

OBNXT2 B @OBNEXT

; dead - little 6 big 6 little 6
; R4[15..8] = counter, initially 18
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
       JHE OBNXT2
       B @SPROFF


; test if sword is hitting enemy, and if enemy is hitting hero (LNKHIT)
; modifies R0-R3 R7 R8
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
       CI R3,>0D00          ; Y diff <= 13 ?
       JH HITES2
       SWPB R3              ; swap to compare X
       ABS R3               ; absolute difference
       CI R3,>0D00          ; X diff <= 13 ?
       JH HITES2
       
       CI R7,-4
       JNE !
       LI R0,BSWPID         ; Beam Sword Pop ID
       MOV R0,@OBJECT+14    ; Set sword beam to sword pop

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

       JMP OBNXT2
; Spawn item
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
       SRL R2,9
       MOV @REDIR(R2),R2    ; Get new direction bits and hurt counter = 32

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       JMP HURT2

REDIR  DATA >A000,>6000,>2000,>E000 ; Convert DLRU -> RLDU and hurt counter = 32

STBIT  ; TODO



; Enemy edge test, jump to R2 if at edge of screen
; R3 = direction 0=Down 1=Left 2=Right 3=Up
; Modifies R0,R1
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


; R4=data R5=YYXX R6=SSEC
; Sets R6 to random facing
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


; Animation functions, toggle sprite every 5, 6 or 11 frames
; Modifies R0,R1,R2
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

; Set keyboard lines in R1 to CRU
SETCRU
       LI R12,>0024    ; Select address lines starting at line 18
       LDCR R1,3       ; Send 3 bits to set one 8 of output lines enabled
       LI R12,>0006    ; Select address lines to read starting at line 3
       RT

; Read keys and joystick into KEY_FL
; Modifies R0-2,R10,R12
DOKEYS
       MOV R11,R10     ; Save return address
       CLR R0
       CLR R1
       BL @SETCRU
       TB 2            ; Test Enter
       JEQ !
       ORI R0, KEY_A
!      LI R1,>0100
       BL @SETCRU
       TB 5            ; Test S
       JEQ !
       ORI R0, KEY_DN
!      TB 6            ; Test W
       JEQ !
       ORI R0, KEY_UP
!      LI R1,>0200
       BL @SETCRU
       TB 5            ; Test D
       JEQ !
       ORI R0, KEY_RT
!      TB 6            ; Test E
       JEQ !
       ORI R0, KEY_B
!      LI R1,>0500
       BL @SETCRU
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
!      LI R1,>0600
       BL @SETCRU
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
!      LI R1,>0700
       BL @SETCRU
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



; Get random number in R0 (modifies R1)
; RAND16 must be seeded with nonzero, Period is 65535
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

; Draw the byte number in R1 as Xn or Xnn or nnn
; R1: number
; R3: VDP address
; Modifies R0,R1
NUMBER MOVB @R3LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R3,*R14          ; Send high byte of VDP RAM write address

       CI R1, >6400  ; 100 decimal
       JHE !
       LI R0, >5800           ; X ascii
       MOVB R0,*R15        ; Write X
       LI R0, >3000             ; 0 ascii
       CI R1, >A00   ; 10 decimal
       JHE NUMBE2
       A R0,R1
       MOVB R1,*R15        ; Write second digit
       LI R1, >2000
       MOVB R1,*R15           ; Write a space
       RT

!      LI R0, >3100           ; 1 ascii
       AI R1, ->6400    ; R1 -= 100
       CI R1, >6400     ; R1 < 100 ?
       JL !
       AI R1, ->6400
       LI R0, >3200           ; 2 ascii
!      MOVB R0,*R15           ; Write first digit
       LI R0, >3000           ; 0 ascii
       JMP NUMBE2
!      AI R0,>100
       AI R1, ->A00    ; R1 -= 10
NUMBE2 CI R1, >A00
       JHE -!
       MOVB R0,*R15        ; Write second digit
       AI R1, >3000             ; 0 ascii
       MOVB R1,*R15        ; Write final digit
       RT

; Draw number of rupees, keys, bombs and hearts
; Modifies R0-R3,R7-R12
STATUS MOV R11,R10            ; Save return address
       CLR R1
       MOVB @RUPEES,R1
       LI R3,VDPWM+SCR1TB+12  ; Write mask + screen offset + row 0 col 12
       BL @NUMBER             ; Write rupee count

       MOVB @KEYS,R1
       AI R3,32               ; Next row
       BL @NUMBER             ; Write keys count

       MOVB @BOMBS,R1
       AI R3,32               ; Next row
       BL @NUMBER             ; Write bombs count

       MOV R10,R11            ; Restore saved return address

       AI R3,10               ; R3 = lower left heart position
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       AI R3,-32              ; R3 = upper left heart position

       CLR R9
       MOVB @HEARTS,R9        ; R4 = max hearts - 1
       AI   R9,>100
       MOV  @HFLAGS,R0
       LI   R10,1              ; R5 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R9,R9             ; double max hp
       INC  R10                ; R5 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R9,R9             ; double max hp again
       INCT R10                ; R5 = 4 hp per half-heart
!
       A    R9,R9             ; double max hp for half-hearts
       SWPB R10
       ;  write hearts and move half-heart sprite
       CLR R2
       LI R0,>6F08            ; Full heart / empty heart
       LI R12,8                ; Countdown to move up
       LI R7,>07B0            ; Half-heart sprite coordinates
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
       DEC R12
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       LI R7,>FFB0            ; Half-heart sprite coordinates
!      CB  R2,R1              ; Compare counter to HP
       JL FILLH
HALFH  MOV R7,@SPRLST+20      ; Save sprite coordinates
       MOV R8,@SPRLST+22      ; Save sprite index and color
       SWPB R0                ; Switch hearts
       LI R7,FULLHP
       C R2,R9                ; Compare to max hearts
       JL EMPTYH
       SOC R7,@FLAGS          ; Set full hp flag
       RT
EMPTYH
       A   R10,R2
       A   R10,R2
       MOVB R0,*R15           ; Draw heart
       DEC R12
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
!      C R2,R9                ; Compare counter to max hearts
       JL EMPTYH
       SZC R7,@FLAGS          ; Clear full hp flag
       RT



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

; Enemy hurt colors: 2 frames each
HRTCOL BYTE >0C,>01,>08,>04  ; green black orange blue

;DEADC  BYTE >08,>06,>0F,>0E  ; dark red, red, cyan, white
DEADC  BYTE >09,>06,>0F,>07  ; red, dark red, red, white, cyan


; Facing     Right Left  Down  Up
EMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
EMOVEA DATA >0010,>FFFF,>1000,>FF00     ; Test char offset 1
EMOVEB DATA >0F10,>0EFF,>100F,>FF0F     ; Test char offset 2
EMOVEC DATA >FF00,>FF00,>00FF,>00FF     ; Screen edge mask (inverted for SZC)
EMOVEE DATA >00E0,>0010,>A800,>2800     ; Screen edge value
EMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)




SPRL0  DATA >D0D0,>0003  ; Link color
       DATA >D0D0,>0401  ; Link outline
       DATA >0000,>E002  ; Map dot
       DATA >047B,>C404  ; Bomb item
       DATA >0494,>7C08  ; Sword item
       DATA >07C8,>E406  ; Half-heart
       DATA >D800,>3001
       DATA >D810,>3401
       DATA >D820,>3801
       DATA >D830,>3C01
       DATA >D800,>3001
       DATA >D810,>3401
       DATA >D820,>3801
       DATA >D830,>3C01
       DATA >D800,>4001
       DATA >D810,>4401
       DATA >D820,>4801
       DATA >D830,>4C01
       DATA >D800,>5001
       DATA >D810,>5401
       DATA >D820,>5801
       DATA >D830,>5C01
SPRLE

****************************************
; Map Data                              
****************************************
; -- Map Row 0 --                       
MD0    DATA >2020,>6060,>6060,>6060    ;
       DATA >6060,>2009,>5830,>20D1    ;
       DATA >42D2,>D141,>D220,>206E    ;
       DATA >6869,>6A6B,>6E20,>2020    ;
* -- Map Row 1 --
       DATA >2020,>6060,>6060,>6060    ;
       DATA >6060,>200A,>5830,>20D5    ;
       DATA >20D5,>D520,>D520,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 2 --
       DATA >2020,>6060,>6060,>6060    ;
       DATA >6060,>20D0,>5830,>20D3    ;
       DATA >D6D4,>D3D6,>D420,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;





****************************************
; Sprite Patterns                       
****************************************
SPR8   DATA >0100,>0104,>0701,>0101    ; Color 9
       DATA >0101,>0101,>0101,>0100    ; 
       DATA >C000,>C010,>F0C0,>C0C0    ; 
       DATA >C0C0,>C0C0,>C0C0,>C080    ; 
SPR9   DATA >0000,>0000,>0000,>7FFF    ; Color 9
       DATA >7F00,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>1810,>F5F5    ; 
       DATA >F510,>1800,>0000,>0000    ; 
SPR10  DATA >0000,>0000,>1808,>AFAF    ; Color 9
       DATA >AF08,>1800,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>FEFF    ; 
       DATA >FE00,>0000,>0000,>0000    ; 
SPR11  DATA >0103,>0303,>0303,>0303    ; Color 9
       DATA >0303,>030F,>0803,>0003    ; 
       DATA >0080,>8080,>8080,>8080    ; 
       DATA >8080,>80E0,>2080,>0080    ; 
SPR12  DATA >0000,>0000,>0000,>0000    ; Color 1
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>78FC    ; 
       DATA >FCE6,>C3DB,>C860,>7030    ; 
SPR13  DATA >0000,>0000,>0000,>1E3F    ; Color 1
       DATA >3F67,>C3DB,>1306,>0E0C    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
SPR14  DATA >0000,>0000,>0000,>0000    ; Color 1
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >3070,>60C8,>DBC3,>E6FC    ; 
       DATA >FC78,>0000,>0000,>0000    ; 
SPR15  DATA >0C0E,>0613,>DBC3,>673F    ; Color 1
       DATA >3F1E,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
SPR16  DATA >0000,>0000,>0307,>0F0C    ; Color 10
       DATA >0800,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>C0E0,>F030    ; 
       DATA >1000,>0000,>0000,>0000    ; 
SPR17  DATA >0000,>0000,>0100,>0000    ; Color 10
       DATA >0000,>0001,>0000,>0000    ; 
       DATA >0000,>0000,>C0E0,>7070    ; 
       DATA >7070,>E0C0,>0000,>0000    ; 
SPR18  DATA >0000,>0000,>0000,>0008    ; Color 10
       DATA >0C0F,>0703,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0010    ; 
       DATA >30F0,>E0C0,>0000,>0000    ; 
SPR19  DATA >0000,>0000,>0307,>0E0E    ; Color 10
       DATA >0E0E,>0703,>0000,>0000    ; 
       DATA >0000,>0000,>8000,>0000    ; 
       DATA >0000,>0080,>0000,>0000    ; 
SPR20  DATA >0503,>0503,>0503,>0101    ; Color 6
       DATA >0101,>0101,>0102,>0301    ; 
       DATA >4080,>4080,>4080,>0000    ; 
       DATA >0000,>0000,>0080,>8000    ; 
SPR21  DATA >0000,>0000,>0000,>60DF    ; Color 6
       DATA >6000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0015,>2AFF    ; 
       DATA >2A15,>0000,>0000,>0000    ; 
SPR22  DATA >0000,>0000,>00A8,>54FF    ; Color 6
       DATA >54A8,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>06FB    ; 
       DATA >0600,>0000,>0000,>0000    ; 
SPR23  DATA >0103,>0201,>0101,>0101    ; Color 6
       DATA >0101,>0305,>0305,>0305    ; 
       DATA >0080,>8000,>0000,>0000    ; 
       DATA >0000,>8040,>8040,>8040    ; 
SPR24  DATA >100C,>0721,>180F,>4360    ; Color 4
       DATA >3C1F,>8740,>703F,>1F07    ; 
       DATA >0830,>E084,>18F0,>C206    ; 
       DATA >3CF8,>E102,>0EFC,>F8E0    ; 
SPR25  DATA >0418,>3173,>63E7,>E6E6    ; Color 4
       DATA >E6E6,>E763,>7331,>1804    ; 
       DATA >00C0,>8811,>3226,>646C    ; 
       DATA >6C64,>2632,>1188,>C000    ; 
SPR26  DATA >0003,>1188,>4C64,>2636    ; Color 4
       DATA >3626,>644C,>8811,>0300    ; 
       DATA >2018,>8CCE,>C6E7,>6767    ; 
       DATA >6767,>E7C6,>CE8C,>1820    ; 
SPR27  DATA >071F,>3F70,>4087,>1F3C    ; Color 4
       DATA >6043,>0F18,>2107,>0C10    ; 
       DATA >E0F8,>FC0E,>02E1,>F83C    ; 
       DATA >06C2,>F018,>84E0,>3008    ; 
SPR28  DATA >0100,>040D,>0303,>0303    ; Color 10
       DATA >0303,>0305,>0E07,>0301    ; 
       DATA >80C0,>E050,>B0B0,>B0B0    ; 
       DATA >B0B0,>B0B0,>50E0,>C080    ; 
SPR29  DATA >0000,>0000,>0000,>0003    ; Color 4
       DATA >040B,>0B0F,>0F07,>0300    ; 
       DATA >0040,>4020,>1010,>20C0    ; 
       DATA >E0F0,>F0F0,>F0E0,>C000    ; 
SPR30  DATA >0000,>0000,>060F,>0F0F    ; Color 6
       DATA >0703,>0100,>0000,>0000    ; 
       DATA >0000,>0000,>C0E0,>E0E0    ; 
       DATA >C080,>0000,>0000,>0000    ; 
SPR31  DATA >0307,>0E0C,>0C0F,>0F01    ; Color 10
       DATA >0101,>0107,>0703,>0701    ; 
       DATA >C0E0,>7030,>30F0,>F080    ; 
       DATA >8080,>8080,>8080,>8080    ; 
SPR32  DATA >070F,>3F77,>6F6F,>EFF7    ; Color 15
       DATA >FFDF,>5F5B,>293C,>1F0E    ; 
       DATA >E0F0,>FCEE,>F6F6,>F7EF    ; 
       DATA >FFFB,>FADA,>943C,>F870    ; 
SPR33  DATA >030E,>2923,>1130,>7694    ; Color 15
       DATA >A829,>236B,>3118,>170A    ; 
       DATA >C070,>94C4,>880C,>6E29    ; 
       DATA >1594,>C4D6,>8C18,>E850    ; 
SPR34  DATA >0200,>0820,>0310,>200A    ; Color 15
       DATA >8009,>2001,>2004,>0106    ; 
       DATA >4000,>1004,>C008,>0450    ; 
       DATA >0190,>0480,>0420,>8060    ; 
SPR35  DATA >0000,>0000,>0004,>020B    ; Color 15
       DATA >0703,>0709,>0000,>0000    ; 
       DATA >0000,>0000,>0040,>D0E0    ; 
       DATA >C080,>C000,>8000,>0000    ; 
SPR36  DATA >0000,>0000,>0000,>0000    ; Color 3
       DATA >0000,>0000,>00F0,>F0F0    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
SPR37  DATA >0000,>0000,>0000,>0000    ; Color 6
       DATA >60F0,>E0F0,>E070,>2010    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
SPR38  DATA >0000,>0010,>0104,>010A    ; Color 9
       DATA >0A01,>0401,>1000,>0000    ; 
       DATA >0000,>0008,>8020,>8050    ; 
       DATA >5080,>2080,>0800,>0000    ; 
SPR39  DATA >0140,>0110,>0904,>03AA    ; Color 9
       DATA >AA03,>0409,>1001,>4001    ; 
       DATA >8002,>8008,>9020,>C055    ; 
       DATA >55C0,>2090,>0880,>0280    ; 
SPR40  DATA >0014,>292B,>0F6F,>7F7F    ; Color 8
       DATA >7FBF,>FEFA,>7C7C,>3F07    ; 
       DATA >4484,>A0E4,>E8DA,>FEFD    ; 
       DATA >FDFF,>FFBE,>1E3C,>FCF0    ; 
SPR41  DATA >2221,>0527,>175B,>7FBF    ; Color 8
       DATA >BFFF,>FF7D,>783C,>3F0F    ; 
       DATA >0028,>94D4,>F0F6,>FEFE    ; 
       DATA >FEFD,>7F5F,>3E3E,>FCE0    ; 
SPR42  DATA >0402,>080B,>0B05,>030D    ; Color 9
       DATA >060C,>0203,>0302,>0202    ; 
       DATA >4080,>5090,>9020,>A040    ; 
       DATA >C060,>80C0,>0000,>0000    ; 
SPR43  DATA >0402,>0003,>0709,>0B0D    ; Color 9
       DATA >0408,>0203,>0302,>0202    ; 
       DATA >4080,>4080,>9010,>B060    ; 
       DATA >6030,>80C0,>0000,>0000    ; 

; Menu screen
* -- Map Row 0 --
MD2    DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 1 --
       DATA >2020,>2020,>494E,>5645    ;
       DATA >4E54,>4F52,>5920,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 2 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 3 --
       DATA >2020,>2020,>2020,>20D1    ;
       DATA >D7D7,>D220,>2020,>20D1    ;
       DATA >D7D7,>D7D7,>D7D7,>D7D7    ;
       DATA >D7D7,>D7D2,>2020,>2020    ;
* -- Map Row 4 --
       DATA >2020,>2020,>2020,>20D5    ;
       DATA >2020,>D520,>2020,>20D5    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>20D5,>2020,>2020    ;
* -- Map Row 5 --
       DATA >2020,>2020,>2020,>20D5    ;
       DATA >2020,>D520,>2020,>20D5    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>20D5,>2020,>2020    ;
* -- Map Row 6 --
       DATA >2020,>2020,>2020,>20D3    ;
       DATA >D6D6,>D420,>2020,>20D5    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>20D5,>2020,>2020    ;
* -- Map Row 7 --
       DATA >2020,>5553,>4520,>4220    ;
       DATA >4255,>5454,>4F4E,>20D5    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>20D5,>2020,>2020    ;
* -- Map Row 8 --
       DATA >2020,>2020,>464F,>5220    ;
       DATA >5448,>4953,>2020,>20D3    ;
       DATA >D6D6,>D6D6,>D6D6,>D6D6    ;
       DATA >D6D6,>D6D4,>2020,>2020    ;
* -- Map Row 9 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 10 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>203A,>2525,>3B20    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 11 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>202F,>3E25,>2F2F    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 12 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>202F,>2F20,>2F25    ;
       DATA >2525,>3B20,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 13 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >203A,>2520,>2F20,>2525    ;
       DATA >2525,>2F2F,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 14 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >202F,>3E25,>2020,>2020    ;
       DATA >2020,>2F2F,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 15 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >203B,>3B20,>2020,>2020    ;
       DATA >203A,>3A20,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 16 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>3B25,>3B20,>2020    ;
       DATA >3A3A,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 17 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2025,>2F2F,>203A    ;
       DATA >3A20,>5449,>464F,>5243    ;
       DATA >4520,>2020,>2020,>2020    ;
* -- Map Row 18 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>3B3B,>202F    ;
       DATA >2F20,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 19 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>203B,>253A    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 20 --
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2520    ;
       DATA >2020,>2020,>2020,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;

SLAST  END  MAIN
