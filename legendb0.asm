;
; Legend of Tilda
; 
; Bank 0: initialization and main loop
;
       
       COPY 'legend.asm'
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

       
       LI   R0,SPRPAT+(28*32)         ; Sprite Pattern Table
       LI   R1,SPR8
       LI   R2,(SPR43-SPR8)+32
       BL   @VDPW
       
;                               Draw the screen
       CLR  R0                ; Start at top left corner of the screen
       LI   R1,MD0
       LI   R2,32*3            ; Number of bytes to write
       BL   @VDPW

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

       LI   R0,>7700         ; Initial map location is 7,7
       MOVB R0,@MAPLOC

       LI R0,>0000           ; Initial Rupees
       MOVB R0,@RUPEES
       LI R0,>0000           ; Initial Keys
       MOVB R0,@KEYS
       LI R0,>0000           ; Initial Bombs
       MOVB R0,@BOMBS
       LI R0,>0200           ; Initial Hearts-1
       MOVB R0,@HEARTS
       LI R0,>0600           ; Initial HP
       MOVB R0,@HP

       BL @STATUS            ; Draw status

       LI   R0,BANK2         ; Overworld is in bank 2
       LI   R1,HDREND        ; First function in bank 1
       LI   R2,5             ; Use wipe from center 5
       BL   @BANKSW

       CLR  R0
       MOV R0,@MOVE12

       LI R0,FULLHP
       MOV R0,@FLAGS

       LI R0,MAGSHD      ; Test initial magic shield
       MOV R0,@HFLAGS


       LI R9,32
       LI R1,OBJECT        ; Clear object table
!      CLR *R1+
       DEC R9
       JNE -!


       LI R0,1
       MOV R0,@RAND16      ; Set random seed (TODO: set from title screen duration)
       
       
       LI R13,>7078        ; Link Y X position in pixels
       LI R3,FACEDN        ; Initial facing down
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
       AI R0,->1100  ; Add -1 to both nibbles
       CI R0,>1000   ; Left nibble 0?
       JHE !
       AI R0,>6000   ; Add 6 to left nibble
!      MOV R0,R1
       ANDI R1,>0F00 ; Right nibble 0?
       JNE !
       AI R0,>0B00   ; Add 11 to right nibble
!      INC R0
       ANDI R0,>FF0F
       MOV R0,@COUNTR
       

       ;LI   R0,>07FE          ; VDP Register 7: White on Black
       ;BL   @VDPREG
       
       
       MOVB @HURTC,R0   ; Hurt counter
       JEQ !
       AI R0,>FF00      ; Dec byte
       MOVB R0,@HURTC
       

; TODO: hurt animation and movement

!

       LI R1,>0500
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 5
       LI R12, >0006
       TB 0                 ; Key /           
       JEQ !                ; Start key down
       LI   R2,8            ; Use item selection
       BL @SCROLL
!






       MOVB @SWORDC,R0   ; Sword animation counter
       JNE !

       CLR R1
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 0
       LI R12, >0006
       TB 2                 ; Key Enter
       JNE SWORD1           ; Sword key down

       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            ; Turn on Joystick Col 0
       LI R12, >0006
       TB 0                 ; Joystick 1 Fire
       JNE SWORD1           ; Sword key down


SWORD0
       LI R0,SWORDP
       SZC R0,@FLAGS        ; Clear sword pressed bit
       JMP !
SWORD1
       LI R0,SWORDP
       CZC @FLAGS,R0        ; Test sword already pressed?
       JNE !

       SOC R0,@FLAGS        ; Set sword pressed bit
       LI R0,>0C00          ; Sword animation is 12 frames
       MOVB R0,@SWORDC
!

; Up/down movement has priority over left/right, unless there is an obstruction
       
       LI R1,>0100
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 1
       LI R12, >0006
       TB 5                 ; Key W
       JNE MOVEDN
       TB 6                 ; Key S
       JNE MOVEUP
       TB 4                 ; Key 2
       JEQ !
       BL @SCRLDN
!

       LI R1,>0300
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 3
       LI R12, >0006
       TB 4                 ; Key 4
       JEQ !
       BL @SCRLLT
!

       LI R1,>0400
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 4
       LI R12, >0006
       TB 3                 ; Key 6
       JEQ !
       BL @SCRLRT
!
       MOV @FACING,R3

       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 6 (Joystick 1)
       LI R12, >0006
       TB 3                 ; JS1 DOWN
       JNE MOVEDN
       TB 4                 ; JS1 UP
       JNE MOVEUP

HKEYS
       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 6 (Joystick 1)
       LI R12, >0006
       TB 2                 ; JS1 RIGHT
       JNE MOVERT
       TB 1                 ; JS1 LEFT
       JNE MOVELT

       LI R1,>0200
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 2
       LI R12, >0006
       TB 5                 ; Key D
       JNE MOVERT
       TB 3                 ; Key 8
       JEQ !
       BL @SCRLUP
!

       LI R1,>0500
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 5
       LI R12, >0006
       TB 5                 ; Key A
       JNE MOVELT

       BL  @SWORD           ; Animate sword if needed
       
       CB R3,@FACING        ; Update facing if up/down was pressed against a wall
       JNE !
       B   @INFLP
!      B   @LNKSPR


MOVEDN
       LI R3,FACEDN
       BL @SWORD

       CI R13,(192-16)*256   ; Check at bottom edge of screen
       JL !
       BL @SCRLDN     ; Scroll down
       LI R3,FACEDN
!
       MOV R13,R0
       AI R0,>1004    ; 16 pixels down, 4 right
       LI R2,HKEYS
       BL @TESTCH
       MOV R13,R0
       AI R0,>100C    ; 16 pixels down, 12 right
       BL @TESTCH

       MOV R13,R0     ; Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVED2     ; Already aligned
       ANDI R0,>0004
       JEQ MOVEL3
       JMP MOVER3

MOVEUP
       LI R3,FACEUP
       BL @SWORD
       
       CI R13,25*256  ; Check at top edge of screen
       JHE !
       BL @SCRLUP     ; Scroll up
       LI R3,FACEUP
!      
       MOV R13,R0
       AI R0,>0704    ; 7 pixels down, 4 right
       LI R2,HKEYS
       BL @TESTCH
       MOV R13,R0
       AI R0,>070C    ; 7 pixels down, 12 right
       BL @TESTCH

       MOV R13,R0     ; Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVEU2     ; Already aligned
       ANDI R0,>0004
       JEQ MOVEL3
       JMP MOVER3

MOVERT
       LI R3,FACERT
       BL @SWORD

       MOV R13,R0     ; Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ MOVER2     ; Already aligned
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
MOVELT
       LI R3,FACELT
       BL @SWORD

       MOV R13,R0    ; Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ MOVEL2    ; Already aligned
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
       
       
MOVER2 MOV R13,R0     ; Check at right edge of screen
       ANDI R0,>00FF
       CI R0,256-16
       JNE !
       BL @SCRLRT     ; Scroll right

!      LI R3,FACERT
       MOV R13,R0
       AI R0,>0810    ; 8 pixels down, 16 right
       LI R2,MOVE4
       BL @TESTCH

MOVER3 INC R13        ; Move X coordinate right
       INV @MOVE12
       JEQ !          ; Check if additional movement needed
       MOV R13,R1
       ANDI R1,>0007  ; Check if 8-pixel aligned
       JEQ !
       INC R13        ; Add additional movement if not aligned
!      MOV R13, R1
       SWPB R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

MOVEL2 MOV R13,R0     ; Check at left edge of screen
       ANDI R0,>00FF
       JNE !
       BL @SCRLLT     ; Scroll left

!      LI R3,FACELT
       MOV R13,R0
       AI R0,>07FF  ; 8 pixels down, 1 left
       LI R2,MOVE4
       BL @TESTCH
       
MOVEL3 DEC R13        ; Move X coordinate left
       INV @MOVE12    ; Check if additional movement needed
       JEQ !
       MOV R13,R1
       ANDI R1,>0007  ; Check if 8-pixel aligned
       JEQ !
       DEC R13        ; Add additional movement if not aligned
!      MOV R13, R1
       SWPB R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

MOVED2 AI R13,>0100   ; Move Y coordinate down
       INV @MOVE12     ; Check if additional movement needed
       JEQ !
       MOV R13,R1
       ANDI R1,>0700  ; Check if 8-pixel aligned
       JEQ !
       AI R13,>0100   ; Add additional movement if not aligned
!      MOV R13,R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       
MOVE2  
       C @DOOR,R13
       JNE MOVE3
       BL @GODOOR
       MOV @FACING,R3
       CLR R1
MOVE3
       MOVB R1,@SPRLST+2
       AI R1,>0400
       MOVB R1,@SPRLST+6

MOVE4  CB R3,@FACING
       JNE LNKSPR
       JMP DRAW


MOVEU2 AI R13,>FF00   ; Move Y coordinate up
       INV @MOVE12     ; Check if additional movement needed
       JEQ !
       MOV R13,R1
       ANDI R1,>0700  ; Check if 8-pixel aligned
       JEQ !
       AI R13,>FF00   ; Add additional movement if not aligned
!      MOV R13,R1
       ANDI R1,>0800  ; Set sprite animation based on coordinate
       JMP MOVE2      ; Update the sprite animation

LNKSPR MOVB R3,@FACING   ; Save facing direction
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       A R3,R1
       A R3,R1
       SRA R1,1
       AI R1,LSPR0

       CI R3,FACEUP
       JEQ !          ; No shield sprite for facing up
       LI R0,MAGSHD
       CZC @HFLAGS,R0  ; Got magic shield?
       JNE LNKSHD

!      LI R0,SPRPAT   ; Copy walking+attack sprites to sprites pattern table
       LI R2,32*6
       BL @VDPW
       JMP DRAW
LNKSHD
       LI R0,SPRPAT   
       AI R1,32*8     ; Copy magic shield walking sprites to sprites pattern table
       LI R2,32*4
       BL @VDPW
       LI R0,SPRPAT+(32*4)
       AI R1,-32*4    ; Copy attack sprites to sprites pattern table
       LI R2,32*2
       BL @VDPW
DRAW
       AI R13,->0100          ; Move Y up one
       MOV R13,@SPRLST	    ; Update color sprite
       MOV R13,@SPRLST+4    ; Update outline sprite
       AI R13,>0100            ; Move Y down one

INFLP2 B @INFLP

GODOOR LI R0,INCAVE
       SOC R0,@FLAGS         ; Set in cave flag
       
       AI R13,->0100          ; Move Y up one
       MOV R13,@SPRLST	    ; Update color sprite
       MOV R13,@SPRLST+4    ; Update outline sprite
       AI R13,>0100            ; Move Y down one
       BL @SPRUPD
       
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
       MOVB R1,@SPRLST+2
       LI R1,>0400
       MOVB R1,@SPRLST+6
       LI R1,>D200          ; Sword YY address (hide)       
       MOVB R1,@SPRLST+24   ; (6*4)

       JMP SWBEAM            ; Do sword beam 

!      CI R0,>0B00
       JNE !

       LI R1,>1000          ; Set link to sword stance
       MOVB R1,@SPRLST+2
       LI R1,>1400
       MOVB R1,@SPRLST+6
       
       JMP SWORD4

!      C @FACING,R3          ; Redraw sword if facing changed
       JNE !

       CI R0,>0800           ; Sword appears on fourth frame
       JNE SWORD4
; Draw sword
!
       MOV R3,R1
       SRL R1,7

       MOV R13,R5           ; Position relative to link
       A   @SWORDX(R1),R5

       MOV R3,R6
       SLA R6,2
       ORI R6,>7008          ; Sword facing (TODO sword color)
       
       MOV R5,@SPRLST+24     ;(6*4)
       MOV R6,@SPRLST+26     ;(6*4+2)

SWORD4 C @FACING,R3          ; Update facing as needed
       JEQ INFLP2            ; Sword done
       B @LNKSPR             ; Change direction (sword facing changed already)

SWBEAM
       LI R0,FULLHP
       CZC @FLAGS,R0         ; Test for sword beam
       JEQ SWORD4

       SZC R0,@FLAGS        ;  Clear FULLHP flag (TODO: SWDBMA flag)

       MOV R3,R1            ; Launch sword beam
       SRL R1,7

       MOV R13,R5           ; Position relative to link
       A   @SWORDX(R1),R5
       
       MOV R3,R6
       SLA R6,2
       ORI R6,>700f          ; Sword facing (TODO dynamic sword color)
       
       MOV R5,@SPRLST+28    ;(7*4)
       MOV R6,@SPRLST+30    ;(7*4+2)
       
       LI R0,>0010
       MOV R0,@OBJECT+14
       
       JMP SWORD4
       
       
SWORDX DATA >0A00,>00F5,>010B,>F4FF

; Beam sword shoots when link is at full hearts, cycle colors white,cyan,red,brown
BSWORD 
       AI R4,>0100              ; Cycle colors
       ANDI R4,>033F
       MOV R4,R1
       SRL R1,8
       MOVB @BSWRDC(R1),@R6LB

       MOV R6,R1
       ANDI R1,>0F00       ; Get facing from sprite index
       SRL  R1,9
       A @BSWRDD(R1),R5    ; Add movement from table

       MOV R5,R0
       SWPB R0
       MOV @BSWJMP(R1),R1
       B *R1

BSWDN
       CI R5,>B000          ; Check bottom edge of screen
       JH BSWPOP
       JMP BSWNXT
BSWLT       
       CI R0,>0800          ; Check left edge of screen
       JL BSWPOP
       JMP BSWNXT
BSWUP       
       CI R5,>1800         ; Check for edge of screen
       JL BSWPOP
       JMP BSWNXT
BSWRT
       CI R0,>E800
       JLE BSWNXT
BSWPOP
!      LI R4,>0812        ; Create splash
       LI R6,>800F
       BL @OBSLOT
       LI R6,>840F
       BL @OBSLOT
       LI R6,>880F
       BL @OBSLOT
       LI R6,>8C0F
       BL @OBSLOT
BSPOFF       
       LI R0,FULLHP
       SOC R0,@FLAGS
SPROFF 
       CLR R4
       LI R5,>D200        ; Disappear
BSWNXT B @OBNEXT

BSWJMP DATA BSWDN,BSWLT,BSWRT,BSWUP
BSWRDD DATA >0300,>FFFD,>0003,>FD00
BSWRDC BYTE >07,>0F,>06,>09

BSPLSD DATA >FEFF,>FF01,>00FF,>0101

; Beam sword splash
BSPLSH
       MOV R6,R1
       ANDI R1,>0F00       ; Get facing from sprite index
       SRL  R1,9
       A @BSPLSD(R1),R5    ; Add movement from table

       AI R4,>0100              ; Cycle colors
       MOV R4,R1
       ANDI R1,>1F00
       JEQ BSPOFF
       
       SWPB R1
       ANDI R1,>0003
       MOVB @BSWRDC(R1),@R6LB
       
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

!      LI R2,GETIT
       MOV @SPRLST,R3    ; Get hero pos in R3
       BL @COLLID
       MOV @SPRLST+24,R3 ; Get sword pos in R3
       BL @COLLID
       JMP BSWNXT
GETIT
       INC @RUPEES
       BL @STATUS
       JMP SPROFF

COLLID
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
       MOVB @VDPRD,R1
       
       CI R1,>7EFF
       JH !
       RT
!      B *R2        ; Jump alternate return address


; Update Sprite List to VDP Sprite Table
SPRUPD
       LI R0,SPRTAB  ; Copy to VDP Sprite Table
       LI R1,SPRLST  ; from Sprite List in CPU
       LI R2,128     ; 128 bytes
       B @VDPW

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
       DATA GHINI, ROCK, LEEVRI,LEEVRI  ; C-F - - Red Blue
       DATA BSWORD,BSWPOP,BSPLSH,PEAHT2  ; 10-13
       DATA ZORA0, ZORA1, ZORA2, BADNXT   ; 14-17
       DATA DEAD, BADNXT, LEEVER,LEEVER  ; 18-1B
       DATA BULLET,ARROW,LARROW,BSWORD   ; 1C-1F
       DATA RUPEE, BRUPEE,HEART,FAIRY    ; 20-23

; Enemy sprite index and color
ECOLOR DATA >0000,>2009  ; None, Peahat
       DATA >3009,>3005  ; Red Tektite, Blue Tektite
       DATA >4008,>4004  ; Octorok sprites
       DATA >4008,>4004  ; Fast Octorok Sprites
       DATA >2009,>2005  ; Moblin Sprites
       DATA >4006,>4004  ; Lynel Sprites
       DATA >200F,>2009  ; Ghini, Rock
       DATA >3006,>3004  ; Leever Sprites
       DATA >0000,>0000  ; Beam Sword
       DATA >0000,>0000  ; Beam splash, peahat
       DATA >0000,>0000  ; Zora0-1
       DATA >0000,>0000  ; Zora2
       DATA >0000,>0000  ; Dead
       DATA >0000,>0000  ; Leever
       DATA >0000,>0000  ; Bullet,arrow
       DATA >0000,>0000  ; Larrow,bsword
       DATA >C004,>C004  ; Rupee, Blue rupee
       DATA >C800,>F400  ; Heart, Fairy


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
; Peahat data: counter=7bits direction=3bits
PEAHAT
       MOV R4,R0
       SRL R0,9      ; Get counter bits
       JEQ PEAHA3    ; If zero do setup
       AI R4,->0200  ; Decrement counter
       DEC R0
       JNE PEAHA2
       ORI R4,>1000  ; Reset counter in upper part
PEAHA2 MOV R0,R1
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
       ANDI R1,>01C0  ; Get direction bits (8 directions)
       SRL R1,5
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
       ANDI R0,>003F
       JNE !            ; 1 in 64 chance to land
       LI R4,>0013      ; Change object type to PEAHT2
       JMP OBNXT
       
!      ANDI R0,7        ; 2 in 8 chance to change direction
       JEQ !            ; Turn right
       DEC R0
       JNE OBNXT
       AI R4,>0700      ; Turn left
       ANDI R4,>F7FF
       JMP OBNXT
!      AI R4,>0100      ; Turn right
       ANDI R4,>F7FF
       JMP OBNXT
PEAHAR LI R0,>0400      ; Reverse direction
       XOR R0,R4
       JMP OBNXT
PEAHA3
       BL @SPAWN
       LI R6,>2009    ; Set sprite and color
       ORI R4,>FF80   ; Set initial counter and direction to spin-up
       JMP OBNXT
       
PEAHT2 ; Landing peahat
       AI R4,>0200
       MOV R4,R1
       SRL R1,9
       CI R1,>0080         ; animate less than 128
       JLE PEAHA2
       BL @HITEST           ; can only be hit while stopped
       CI R1,>00C9          ; sit for 73 frames
       JLE OBNXT
       ORI R0,>FE01        ; Change object type to PEAHAT, preserve direction
       JMP OBNXT
       


TKTITE
       MOV R4,R0
       SRL R0,8       ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       MOV @ECOLOR(R3),R6    ; Set sprite and color
       AI R4,17*>0040
!      AI R4,->0040
       BL @HITEST
       DEC R0
       JNE OBNXT
       AI R4,17*>0040
       LI R1,>0400
       XOR R1,R6      ; Toggle animation
       JMP OBNXT
;TKTITS DATA >3009,>3005  ; Tektite sprites and colors


OBNXT  B @OBNEXT

LYNEL
MOBLIN       
OCTORK
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE OCTOR2    ; If zero do setup
OCTORI
       MOV @ECOLOR(R3),R6  ; Setup sprite index and color
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

       
; Enemy movement (Modifies R0-R3)       
EMOVE
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE4       ; No? Keep moving

       BL @RANDOM
       ANDI R0,7        ; 1 in 8 chance to change direction
       JNE EMOVE3

EMOVE2 BL @RANDOM       ; Change direction
       ANDI R0,>1800
       XOR R0,R6
EMOVE3
       MOV R6,R3        ; Get enemy facing
       ANDI R3,>1800
       SRL R3,10

       MOV R5,R0        ; Change direction at edges of screen
       SZC @EMOVEC(R3),R0
       C @EMOVEE(R3),R0
       JEQ EMOVE2

       LI R2,EMOVE2     ; Change direction if solid
       MOV @EMOVEA(R3),R0  ; Check for walls
       A R5,R0
       BL @TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @TESTCH
EMOVE4 
       MOV R6,R3        ; Get enemy facing
       ANDI R3,>1800
       SRL R3,10
       A @EMOVED(R3),R5  ; Move in the right direction
       JMP OBNXT

BULLET
       MOV R4,R3
       ANDI R3,>00C0
       SRL R3,3         ; Get bullet direction
       BL @BMOVE
       BL @BMOVE
       BL @BMOVE
       JMP OBNXT

; Bullet movement, dies if hits wall or edge of screen
; R3 = direction
BMOVE
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE BMOVE4       ; No? Keep moving

       MOV R5,R0        ; Disappear at edges of screen
       SZC @EMOVEC(R3),R0
       C @EMOVEE(R3),R0
       JNE !
       B @SPROFF
!
       MOV R11,R12      ; Save return address
       LI R2,SPROFF     ; Disappear if solid
       MOV @EMOVEA(R3),R0  ; Check for walls
       A R5,R0
       BL @TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @TESTCH
       MOV R12,R11      ; Restore return address

BMOVE4
       A @EMOVED(R3),R5  ; Move in the right direction
       RT

       
LEVERP DATA >3806,>3804  ; Leever half-up sprite

; Leever Counter values
; 254: 8 frames     half-down sprite
; 246: 11 frames
; 235: 11 frames
; 224: 11 frames
; 213: 11 frames
; 202: 11 frames
; 191: 11 frames
; 180: 11 frames
; 169: 8 frames 
; 161: >112 frames  hidden
; 49: 8 frames  ;; start here
; 41: 11 frames
; 30: 11 frames
; 19: 4 frames    
; 15: 15 frames   half-up sprite

; R4:  8 bits animation counter
;      2 bits direction
;      2 bits ?
;      4 bits movement mask or stun counter

LEEVRI ; Leever going up
       MOV R4,R0
       JNE !
       BL @SPAWN
       LI R6,>2809   ; Set to pulsing ground
       BL @RANDOM
       ANDI R0,>00C0 ; Get random direction
       XOR R0,R4
       AI R4,49*256+8  ; Init animation counter
       
!      AI R4,-257    ; Decrement both animation counters
       MOV R4,R0
       ANDI R0,>000F
       JNE !
       AI R4,11
       LI R0,>0400
       XOR R0,R6     ; Toggle animation every 11 frames
!      
       CI R4,>0F00
       JHE OBNXT2
       MOV @OBJPTR,R1
       MOVB @OBJECT(R1),R3
       MOV @LEVERP-28(R3),R6  ; Load lever sprite and color
       CI R4,>00FF
       JHE OBNXT2

       LI R0,>000C
       AB R0,@OBJECT(R1)  ; Change object type to LEEVER
       MOV @OBJECT(R3),R6  ; Load lever sprite and color
       LI R4,1
       
LEEVER
       DEC R4
       BL @HITEST
       MOV R4,R0
       ANDI R0,>0007
       JNE !
       AI R4,>0005
       LI R1,>0400
       XOR R1,R6      ; Toggle animation
!      LI R0,>0008
       XOR R0,R4      ; Toggle movment bit
       CZC R0,R4
       JEQ OBNXT2      ; No movement

       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F  ; Aligned to 16 pixels?
       JEQ !          ; No?  Keep moving
LEEVE4 MOV R4,R3      ; Get enemy facing
       ANDI R3,>00C0
       SRL R3,5
       A @EMOVED(R3),R5  ; Move in the right direction
       JMP OBNXT2

!      BL @RANDOM
       ANDI R0,63     ; 1 in 64 chance to dive
       
       
       ANDI R0,7      ; 1 in 8 chance to change direction
       JNE LEEVE3
LEEVE2 
       BL @RANDOM     ; Change direction
       ANDI R0,>00C0
       XOR R0,R4
LEEVE3
       MOV R4,R3      ; Get enemy facing
       ANDI R3,>00C0
       SRL R3,5
       MOV R5,R0
       SZC @EMOVEC(R3),R0
       C @EMOVEE(R3),R0   ; Test for edges of screen
       JEQ LEEVE2
       
       LI R2,LEEVE2    ; Change direction if solid
       MOV @EMOVEA(R3),R0  ; Check for walls
       A R5,R0
       BL @TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @TESTCH
       JMP LEEVE4

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
DEAD   MOV R4,R1
       SRL R1,6
       LI R6,>E800   ; little star
       AI R1,-8
       CI R1,6
       JHE !
       LI R6,>EC00   ; big star
!      SRL  R1,1
       ANDI R1,>0003   ; animate colors
       MOVB @DEADC(R1),@R6LB
       AI R4,->0040
       CI R4,>0040
       JHE OBNXT2
       B @SPROFF


; test if sword is hitting enemy
; modifies R3 R0 R7 R8
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
       ABS R3
       CI R3,>0D00
       JH HITES2
       SWPB R3
       ABS R3
       CI R3,>0D00
       JH HITES2
       
       CI R7,-4
       JNE !
       LI R0,>0011
       MOV R0,@OBJECT+14    ; Set sword beam to sword pop

!      MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @VDPRD,R2       ; Enemy HP in R2
       MOV @HFLAGS,R0
       ANDI R0,WSWORD+MSWORD ; Get sword bits
       AI  R0,>0100         ; R0 = >100,>200,>400 based on sword power
       S   R0,R2            ; Subtract sword damage from enemy hp
       JGT HURT             ; Jump if hp is greater than zero

!      LI R4,>0020          ; Rupee spawn
       CLR R6               ; Set color and sprite index to transparent
       BL @OBSLOT

       LI R4,>0518          ; Change object type to DEAD, counter to 19
       JMP OBNXT2

HITES2 AI R7,4
       JNE HITES1
       
HITES3 RT



HSBIT   ; Enemy is hurt or stunned
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @VDPRD,R2       ; Enemy stun counter in R1
       SWPB R2
       MOVB @VDPRD,R2       ; Enemy hurt counter in R1
       JEQ STBIT

       AI R2,-256           ; Decrement counter
HURT2  INC R1
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
       SRL R3,13
       A  @HURTD(R3), R5    ; Do knockback


       B @OBNEXT

HURT       ; Enemy hurt
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Store updated HP in VDP

       ORI R4,>0040         ; Set hurt/stun bit

       MOV @SPRLST+34(R7),R2 ; Get sword sprite index in R2
       ANDI R2,>0C00        ; Mask direction bits
       SLA R2,4             ; Put direction bits in upper 2
       AI  R2,>2000         ; Set hurt counter = 32

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       JMP HURT2

STBIT

; Direction to move during hurt animation
HURTD  DATA >0400,>FFFC,>0004,>FC00



; R4=data R5=YYXX R6=SSEC
; Sets R6 to random facing
SPAWN
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


; Animation functions, toggle sprite every 6 or 11 frames
; Modifies R0,R1,R2
ANIM6
       MOVB @COUNTR,R0
       SRL R0,4             ; get uppper nibble 6 counter
       LI R2,>0600
       JMP !
ANIM11
       MOVB @COUNTR,R0
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
       XOR R1,R6     ; Toggle animation every 6 or 11 frames
!      RT


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

       LI R0, >5800           ; X ascii
       CI R1, >6400  ; 100 decimal
       JL !
       LI R0, >3100           ; 1 ascii
       AI R1, ->6400
       CI R1, >6400
       JL !
       AI R1, ->6400
       LI R0, >3200           ; 2 ascii
!      MOVB R0,*R15           ; Write first digit
       CI R1, >A00
       JL NUMBE2
       LI R0, >30             ; 0 ascii
!      INC R0
       AI R1, ->A00
       CI R1, >A00
       JHE -!
       MOVB @R0LB,*R15        ; Write second digit
       AI R1, >3000             ; 0 ascii
       MOVB R1,*R15        ; Write final digit
       RT
NUMBE2 AI R1, >3000             ; 0 ascii
       MOVB R1,*R15        ; Write second digit
       LI R1, >2000
       MOVB R1,*R15           ; Write a space
       RT

       ; Draw number of rupees, keys, bombs and hearts
       ; Modifies R0-R10
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

       AI R3,10               ; R3 = lower left heart position
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       AI R3,-32              ; R3 = upper left heart position

       CLR R4
       MOVB @HEARTS,R4        ; R4 = max hearts
       AI   R4,>100
       MOV  @HFLAGS,R0
       LI   R5,1              ; R5 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R4,R4             ; double max hp
       INC  R5                ; R5 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R4,R4             ; double max hp again
       INCT R5                ; R5 = 4 hp per half-heart
!
       A    R4,R4             ; double max hp for half-hearts
       SWPB R5
       ;  write hearts and move half-heart sprite
       CLR R2
       LI R0,>7701            ; Full heart / empty heart
       LI R6,8                ; Countdown to move up
       LI R7,>07B0            ; Half-heart sprite coordinates
       LI R8,>E400            ; Half-heart sprite index and color (invisible)
       MOVB @HP,R1            ; R1 = hit points
       JEQ HALFH
FULLH
       A   R5,R2
       CB  R2,R1              ; Compare counter to HP
       JL !
       LI  R8,>E406           ; Half-heart sprite index and color (red)
       S   R5,R2
       JMP HALFH
!      A   R5,R2
       AI  R7,>0008
       MOVB R0,*R15           ; Draw heart
       DEC R6
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       LI R7,>FFB0            ; Half-heart sprite coordinates
!      CB  R2,R1              ; Compare counter to HP
       JL FULLH
HALFH  MOV R7,@SPRLST+20      ; Save sprite coordinates
       MOV R8,@SPRLST+22      ; Save sprite index and color
       SWPB R0                ; Switch hearts
       JMP !
EMPTYH
       A   R5,R2
       A   R5,R2
       MOVB R0,*R15           ; Draw heart
       DEC R6
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
!      C R2,R4                ; Compare counter to max hearts
       JL EMPTYH

       B *R10                 ; Return to saved address

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
EMOVEC DATA >FF00,>FF00,>00FF,>00FF     ; Screen edge mask (inverted)
EMOVEE DATA >00E0,>0010,>A800,>2800     ; Screen edge value


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
       DATA >6060,>2002,>5830,>20D1    ;
       DATA >42D2,>D141,>D220,>2076    ;
       DATA >6869,>6A6B,>7620,>2020    ;
* -- Map Row 1 --                       
       DATA >2020,>6060,>6060,>6060    ;
       DATA >6060,>2003,>5830,>20D5    ;
       DATA >20D5,>D520,>D520,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;
* -- Map Row 2 --                       
       DATA >2020,>6060,>6060,>6060    ;
       DATA >6060,>20D0,>5830,>20D3    ;
       DATA >D6D4,>D3D6,>D420,>2020    ;
       DATA >2020,>2020,>2020,>2020    ;


LSPR0  DATA >072F,>2830,>351F,>3603    ; Color 3
       DATA >2071,>2021,>0003,>0000    ; 
       DATA >E0F4,>140C,>ACF8,>60C0    ; 
       DATA >30EC,>6C04,>70F0,>0000    ; 
LSPR1  DATA >0000,>070F,>0A00,>49FC    ; Color 1
       DATA >DF8E,>DFDE,>FFFC,>7E0E    ; 
       DATA >0000,>E0F0,>5000,>9038    ; 
       DATA >CC12,>92FA,>8C00,>7000    ; 
LSPR2  DATA >072F,>2830,>351F,>1603    ; Color 3
       DATA >1038,>1010,>0000,>0000    ; 
       DATA >E0F4,>140C,>ACF8,>60D0    ; 
       DATA >38F8,>3088,>30E0,>0000    ; 
LSPR3  DATA >0000,>070F,>0A00,>297C    ; Color 1
       DATA >6F47,>6F6F,>7F7F,>3E00    ; 
       DATA >0000,>E0F0,>5000,>9028    ; 
       DATA >C404,>CC74,>C010,>7070    ; 
LSPR4  DATA >0317,>1C38,>3597,>4E26    ; Color 3
       DATA >1807,>0A0C,>0602,>0000    ; 
       DATA >E0F0,>180A,>AEEC,>7860    ; 
       DATA >00C0,>0484,>6CE8,>E000    ; 
LSPR5  DATA >1828,>63C7,>CA68,>3119    ; Color 1
       DATA >0708,>0503,>1939,>0000    ; 
       DATA >0000,>E0F0,>5010,>8098    ; 
       DATA >FC3C,>F878,>9217,>0F00    ; 
LSPR6  DATA >6374,>0815,>1F0E,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ; 
       DATA >C62E,>10A8,>F870,>60C0    ; 
       DATA >30F0,>3880,>38F8,>0000    ; 
LSPR7  DATA >0003,>676A,>6031,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ; 
       DATA >00C0,>E656,>068C,>9C3C    ; 
       DATA >C808,>C078,>C000,>7070    ; 
LSPR8  DATA >072F,>2830,>351F,>0018    ; Color 7
       DATA >187E,>7E18,>1818,>0000    ; 
       DATA >E0F4,>140C,>ACF8,>60C0    ; 
       DATA >30EC,>6C04,>70F0,>0000    ; 
LSPR9  DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ; 
       DATA >0000,>E0F0,>5000,>9038    ; 
       DATA >CE12,>92FA,>8C00,>7000    ; 
LSPR10 DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ; 
       DATA >E0F4,>140C,>ACF8,>60D0    ; 
       DATA >38F8,>3088,>30E0,>0000    ; 
LSPR11 DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ; 
       DATA >0000,>E0F0,>5000,>9028    ; 
       DATA >C404,>CC74,>C010,>7070    ; 
LSPR12 DATA >0100,>0000,>0B3F,>0F0F    ; Color 3
       DATA >2326,>0703,>0007,>0000    ; 
       DATA >F0EC,>5637,>7564,>C030    ; 
       DATA >18E0,>6080,>64FE,>0000    ; 
LSPR13 DATA >000F,>1F0F,>0440,>4040    ; Color 1
       DATA >5C59,>5844,>4700,>0001    ; 
       DATA >0010,>A8C8,>8898,>38C0    ; 
       DATA >E41E,>9E7E,>9800,>E0E0    ; 
LSPR14 DATA >0003,>0100,>0016,>7E1F    ; Color 3
       DATA >1E27,>2B0C,>0710,>0F00    ; 
       DATA >00E0,>D8AC,>6EEA,>C880    ; 
       DATA >3088,>0004,>0CF8,>F000    ; 
LSPR15 DATA >0000,>1E3F,>1F09,>0140    ; Color 1
       DATA >4158,>5453,>484F,>301C    ; 
       DATA >0000,>2050,>9010,>3070    ; 
       DATA >C070,>F8F8,>F006,>0E1C    ; 
LSPR16 DATA >0003,>0100,>0016,>7E0F    ; Color 3
       DATA >7778,>5808,>0700,>0F00    ; 
       DATA >00C0,>D0A8,>68EC,>CE82    ; 
       DATA >F018,>080C,>1EFC,>F800    ; 
LSPR17 DATA >0000,>1E3F,>1F09,>0110    ; Color 1
       DATA >080F,>0F07,>181F,>3078    ; 
       DATA >0000,>2050,>9010,>3070    ; 
       DATA >00E0,>F0F0,>E003,>070E    ; 
LSPR18 DATA >6374,>0815,>1F0D,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ; 
       DATA >E0F0,>1404,>ACEC,>78C0    ; 
       DATA >3CFC,>3088,>38E0,>0000    ; 
LSPR19 DATA >0003,>676A,>6032,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ; 
       DATA >0000,>E0F0,>5010,>843C    ; 
       DATA >C000,>C870,>C010,>7070    ; 
LSPR20 DATA >0100,>0000,>0BBF,>8F8F    ; Color 8
       DATA >A3A6,>8783,>8007,>0000    ; 
       DATA >F0EC,>5637,>7564,>C030    ; 
       DATA >18E0,>6080,>64FE,>0000    ; 
LSPR21 DATA >000F,>1FCF,>C440,>4040    ; Color 1
       DATA >5C59,>5844,>47C0,>C001    ; 
       DATA >0010,>A8C8,>8898,>38C0    ; 
       DATA >E41E,>9E7E,>9800,>E0E0    ; 
LSPR22 DATA >0003,>0100,>0016,>BE9F    ; Color 8
       DATA >9EA7,>AB8C,>8790,>0F00    ; 
       DATA >00E0,>D8AC,>6EEA,>C880    ; 
       DATA >3088,>0004,>0CF8,>F000    ; 
LSPR23 DATA >0000,>1E3F,>DFC9,>4140    ; Color 1
       DATA >4158,>5453,>484F,>F0DC    ; 
       DATA >0000,>2050,>9010,>3070    ; 
       DATA >C070,>F8F8,>F006,>0E1C    ; 
LSPR24 DATA >0F37,>6AEC,>AE26,>030C    ; Color 3
       DATA >1807,>0601,>267F,>0000    ; 
       DATA >8000,>0000,>D0FC,>F0F0    ; 
       DATA >C464,>E0C0,>00E0,>0000    ; 
LSPR25 DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ; 
       DATA >00F0,>F8F0,>2002,>0202    ; 
       DATA >3A9A,>1A22,>E200,>0080    ; 
LSPR26 DATA >0007,>1B35,>7657,>1301    ; Color 3
       DATA >0C11,>0020,>301F,>0F00    ; 
       DATA >00C0,>8000,>0068,>7EF8    ; 
       DATA >78E4,>D430,>E008,>F000    ; 
LSPR27 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ; 
       DATA >0000,>78FC,>F890,>8002    ; 
       DATA >821A,>2ACA,>12F2,>0C38    ; 
LSPR28 DATA >0003,>0B15,>1637,>7341    ; Color 3
       DATA >0F18,>1030,>783F,>1F00    ; 
       DATA >00C0,>8000,>0068,>7EF0    ; 
       DATA >EE1E,>1A10,>E000,>F000    ; 
LSPR29 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0007,>0F0F,>07C0,>E070    ; 
       DATA >0000,>78FC,>F890,>8008    ; 
       DATA >10F0,>F0E0,>18F8,>0C1E    ; 
LSPR30 DATA >0003,>0B15,>3677,>4301    ; Color 3
       DATA >070C,>0810,>381F,>0F00    ; 
       DATA >00C0,>8000,>0068,>7EF8    ; 
       DATA >E61E,>1A10,>E008,>F000    ; 
LSPR31 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0107,>0F0F,>0760,>7038    ; 
       DATA >0000,>78FC,>F890,>8000    ; 
       DATA >18E0,>E4E0,>18F8,>0C1E    ; 
LSPR32 DATA >0F37,>6AEC,>AE26,>030C    ; Color 8
       DATA >1807,>0601,>267F,>0000    ; 
       DATA >8000,>0000,>D0FD,>F1F1    ; 
       DATA >C565,>E1C1,>01E0,>0000    ; 
LSPR33 DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ; 
       DATA >00F0,>F8F3,>2302,>0202    ; 
       DATA >3A9A,>1A22,>E203,>0380    ; 
LSPR34 DATA >0007,>1B35,>7657,>1301    ; Color 8
       DATA >0C11,>0020,>301F,>0F00    ; 
       DATA >00C0,>8000,>0068,>7DF9    ; 
       DATA >79E5,>D531,>E109,>F000    ; 
LSPR35 DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >030E,>1F1F,>0F60,>7038    ; 
       DATA >0000,>78FC,>FB93,>8202    ; 
       DATA >821A,>2ACA,>12F2,>0F3B    ; 
LSPR36 DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0727,>2718,>1F07,>0000    ; 
       DATA >C0E0,>F4F4,>E4CC,>8810    ; 
       DATA >F0F0,>E018,>F8C0,>0000    ; 
LSPR37 DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3858,>5827,>0008,>0600    ; 
       DATA >0000,>0008,>1830,>70E8    ; 
       DATA >0C0C,>1CE0,>0038,>7830    ; 
LSPR38 DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0F0F,>0718,>1F03,>0000    ; 
       DATA >C0E0,>F4F4,>E4CC,>8810    ; 
       DATA >E0E4,>E418,>F8E0,>0000    ; 
LSPR39 DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3030,>3807,>001C,>1E0C    ; 
       DATA >0000,>0008,>1830,>70E8    ; 
       DATA >1C1A,>1AE4,>0010,>6000    ; 
LSPR40 DATA >0F5F,>5F7F,>2F27,>1218    ; Color 3
       DATA >1F1F,>2F30,>3F01,>0000    ; 
       DATA >80C0,>E0E8,>D811,>3244    ; 
       DATA >C8D0,>A010,>F8E0,>0000    ; 
LSPR41 DATA >1000,>2000,>5058,>6D67    ; Color 1
       DATA >2020,>104F,>C0E0,>0000    ; 
       DATA >0000,>0000,>20E0,>C1BB    ; 
       DATA >372F,>5EEC,>0018,>3C3C    ; 



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
