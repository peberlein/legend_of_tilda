
* Wipe screen from center
* R4 - pointer to new screen in VRAM
WIPE
       MOV R11,R10        ; Save return address

       ;TODO turn on screen
       LI R0,>01E2          ; VDP Register 1: 16x16 Sprites
       BL @VDPREG

       BL @SCHSTR         ; Save scratch

       LI R8,16           ; Scroll through 16 columns
       LI R6,VDPRD

WIPE2

       BL @VSYNCM
       ;BL @VSYNCM
       ;BL @VSYNCM
       ;BL @VSYNCM
       ;BL @VSYNCM

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


       ; clear recent map locations
       LI R0,RECLOC+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       CLR R1
       LI R2,8
!      MOVB R1,*R15
       DEC R2
       JNE -!


       BL @SCHRST      ; restore scratchpad
       ;LI R3,DIR_UP

       B *R10          ; return to saved address




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
* modifies R0-R3,R7,R12,R13
SCROLL
       MOV R11,R7      ; Save return address

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

       ;BL @VMUSIC

       DEC R9
       JNE -!

       MOV R4,R0       ; Source from new screen pointer
       BL @READ32      ; Read 32 bytes into scratchpad

       MOV R10,R0      ; Dest to top of screen
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       A  R5,R4

       BL @VSYNCM
       BL @VSYNCM
       BL @FLIP
       B *R7           ; Return to saved address


SCRLDN
       MOV R11,R6        ; Save return address
       BL @VSYNCM
       LI R8,22        ; Scroll through 22 rows
       LI R4,LEVELA
SCRLD2
       LI R5,32        ; Direction down
       LI R9,21        ; Move 21 lines
       LI R10,32*3     ; Dest start at top
       BL @SCROLL      ; Scroll down

       LI R1,>F900
       BL @ADDSPR

       DEC R8
       JNE SCRLD2

       BL @SCHRST      ; restore scratchpad
       ;LI R3,DIR_DN
       B *R6          ; return to saved address

SCRLUP
       MOV R11,R6        ; Save return address
       BL @VSYNCM
       LI R8,22        ; Scroll through 22 rows
       LI R4,LEVELA+(32*21)
SCRLU2
       LI R5,-32       ; Direction down
       LI R9,21        ; Move 21 lines
       LI R10,32*24    ; Dest start at at bottom
       BL @SCROLL      ; Scroll down

       LI R1,>0700
       BL @ADDSPR

       DEC R8
       JNE SCRLU2

       BL @SCHRST      ; restore scratchpad
       ;LI R3,DIR_UP
       B *R6          ; return to saved address

* Scroll screen left
* R4 - pointer to new screen in VRAM
SCRLLT
       MOV R11,R6        ; Save return address
       BL @VSYNCM
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
       MOVB @VDPRD,*R1+        ; Copy byte from new screen

       XOR R10,R0      ; Set source to current screen
       BL @READ31      ; Read 31 bytes into scratchpad

       MOV R10,R0
       BL @PUTSCR      ; Write 32 bytes from scratchpad

       AI R4,32
       AI R10,32

       ;BL @VMUSIC

       DEC R9
       JNE -!

       AI R4,(-32*22)-1

       BL @VSYNCM
       BL @VSYNCM
       BL @FLIP

       MOV R8,R1
       ANDI R1,1
       NEG R1
       AI R1,8
       BL @ADDSPR

       DEC R8
       JNE SCRLL2
       BL @SCHRST      ; restore scratchpad
       ;LI R3,DIR_LT
       B *R6          ; return to saved address


* Scroll screen right
* R4 - pointer to new screen in VRAM
SCRLRT
       MOV R11,R6        ; Save return address
       BL @VSYNCM
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
       MOVB @VDPRD,*R1         ; Copy byte from new screen

       BL @PUTSCR      ; Write 32 bytes from scratchpad

       AI R4,32
       AI R10,32

       ;BL @VMUSIC

       DEC R9
       JNE -!

       AI R4,(-32*22)+1

       BL @VSYNCM
       BL @VSYNCM
       BL @FLIP

       MOV R8,R1
       ANDI R1,1
       AI R1,-8
       BL @ADDSPR

       DEC R8
       JNE SCRLR2
       BL @SCHRST      ; restore scratchpad
       ;LI R3,DIR_RT
       B *R6          ; return to saved address


* Add R1 to hero sprite YYXX, and update VDP sprite list
ADDSPR
       A R1,@HEROSP
       A R1,@HEROSP+4

       MOV R8,R0     ; animate every 4 frames
       ANDI R0,3     ; if counter low bits is zero
       JNE DRWSPR

       LWPI HEROSP      ; use workspace for easier XOR on registers
       LI R0,>0800      ; toggle this bit to animate
       XOR R0,R1        ; effectively toggle HEROSP+2
       XOR R0,R3        ; effectively toggle HEROSP+6
       MOV R2,R0        ; restore position
       LWPI WRKSP
       ; fall thru

DRWSPR ; draw hero and sword sprites
       LI R0,SPRTAB+(HEROSP-SPRLST)+VDPWM
       LI R1,HEROSP
       LI R2,3

       MOVB @R0LB,*R14 ; VDP Write address
       MOVB R0,*R14    ; VDP Write address
!
       MOVB *R1+,R0
       AI R0,->0100   ; adjust Y
       MOVB R0,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       DEC R2
       JNE -!

       RT

* Store 32B scratchpad to VDP
SCHSTR
       LI R0,SCHSAV
       ; fall thru

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

* Restore 32B scratchpad from VDP
SCHRST
       LI R0,SCHSAV
       ; fall thru

* Copy screen at R0 into scratchpad 32 bytes
* Modifies R1,R2,R15
READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH         ; Dest pointer to scratchpad ram
       LI R2,8              ; Read 32 bytes to scratchpad
       LI R15,VDPRD          ; Keep VDPRD address in R15
!      MOVB *R15,*R1+
READ3  MOVB *R15,*R1+
       MOVB *R15,*R1+
       MOVB *R15,*R1+
       DEC R2
       JNE -!
       LI R15,VDPWD         ; Restore VDPWD address in R15
       RT

* Copy screen at R0 into R1 31 bytes
* Note: R6 must be VDPRD address
* Modifies R1,R2
READ31
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R2,8             ; Read 31 bytes to scratchpad
       LI R15,VDPRD          ; Keep VDPRD address in R15
       JMP READ3           ; Use loop in READ32 minus 1
