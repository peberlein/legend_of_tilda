;
; Legend of Tilda
; 
; Bank 2: overworld map
;

       COPY 'legend.asm'

       
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
;      8=item select (menu)
; Modifies R0-R12,R15
MAIN
       MOV R11,R12          ; Save return address for later
       
       LI R0,>D100
       LI R3,SPRTAB+(6*4)   ; Clear VDP sprite list
       ORI R3,>4000
       MOVB @R3LB,*R14
       MOVB R3,*R14
       LI R1,26*4
!      MOVB R0,*R15
       DEC R1
       JNE -!
       
       CI R2,8
       JNE !
       B @MENU      	   ; Do item select screen
!
       LI R0,OBJECT+12      ; Clear objects[6..31]
       LI R1,32-6
!      CLR *R0+
       DEC R1
       JNE -!

       MOV R2,R3
       CI R3,5              ; Load initial color table on WIPE
       JNE !

       LI   R0,PATTAB         ; Pattern table starting at char 0
       LI   R1,PAT0
       LI   R2,256*8
       BL   @VDPW
       
       LI   R0,CLRTAB+VDPWM         ; Color table
       LI   R1,CLRSET
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
       CI R2, 6
       JNE !
       CLR  @DOOR            ; Clear door location inside cave
       LI   R13,>B078        ; Put hero at cave entrance
       LI   R0,LEVELA+VDPWM  ; R0 is screen table address in VRAM (with write bits)
       LI   R3,CAVE          ; Use cave layout
       JMP  STINIT
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
       LI R0,VDPWM+CLRTAB+31      ; color table entry of dungeon edges
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
       MOVB @MAPLOC,R1      ; Mapdot Y = MAPDOT[(MAPLOC & 0x7000) >> 12]
       ANDI R1,>7000
       SRL  R1,12
       CLR R0
       MOVB @MAPDOT(R1),R0  ; Set YY
       
       MOVB @MAPLOC,R1      ; Mapdot X = ((MAPLOC & 0x0F00) >> 6) + 16
       ANDI R1,>0F00
       SRL  R1,6
       AI   R1,>0010
       A    R1,R0       ; Set XX
       MOV  R0,@SPRLST+8    ; Set Map Dot YYXX  (YY=16,20...76 XX=-13,-10,-7,-4,-1,2,5,8)
       
       B @LENEMY
DONE2
       LI R0,SPRLST+24      ; Clear sprite list [6..31]
       LI R2,64-12          ; (including scratchpad)
!      CLR *R0+
       DEC R2
       JNE -!
DONE3
       LI   R0,BANK0         ; Load bank 0
       MOV  R12,R1           ; Jump to our return address
       B    @BANKSW


; For calculating Y coordinate of MAPDOT sprite (Y*3)-14
MAPDOT BYTE -14,-11,-8,-5,-2,1,4,7
       
JMPLST DATA DONE,SCRLUP,SCRLDN,SCRLLT,SCRLRT,WIPE,CAVEIN,CAVOUT


DOSPRT
       AI R13,>FF00
       LI R0,SPRTAB+VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R13,*R15
       MOVB @R13LB,*R15

       LI R0,SPRTAB+VDPWM+4
       MOVB @R0LB,*R14
       MOVB R0,*R14
       MOVB R13,*R15
       MOVB @R13LB,*R15
       AI R13,>0100
       RT

; Test for vsync and play music if set
VMUSIC
       MOV R12,R0           ; Save R12
       LI R12,>0004         ; CRU Address bit 0002 - VDP INT
       TB 0
       JEQ !
       MOVB @VDPSTA,R12     ; Clear interrupt flag manually since we polled CRU
       MOV R0,R12           ; Restore R12
       B @MUSIC       
!      MOV R0,R12           ; Restore R12
       RT

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

       BL @VSYNC
       BL @FLIP
       BL @MUSIC
       B *R3           ; Return to saved address


SCRLDN
       LI R8,22        ; Scroll through 22 rows
       LI R4,LEVELA
SCRLD2
       LI R5,32        ; Direction down
       LI R9,21        ; Move 21 lines
       LI R10,32*3     ; Dest start at top
       BL @SCROLL      ; Scroll down

       AI R13,>F900
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

       AI R13,>0700
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

       BL @VSYNC
       BL @FLIP
       BL @MUSIC

       AI R13,8
       MOV R8,R0
       ANDI R0,1
       S R0,R13
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
       
       BL @VSYNC
       BL @FLIP
       BL @MUSIC

       AI R13,-8
       MOV R8,R0
       ANDI R0,1
       A R0,R13
       BL @DOSPRT

       DEC R8
       JNE SCRLR2
       B @DONE
       
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
       
       AI R0,(->4000)+32   ; Clear write bit and add 32
       DEC R4
       JNE -!

       BL @VSYNC
       BL @MUSIC

       BL @VSYNC
       BL @MUSIC

       BL @VSYNC
       BL @MUSIC

       DEC R9
       JNE STEPDN
       
       JMP !
CAVOUT
       MOV  @DOOR,R13        ; Move link to door location
!
       LI R0,SCRFLG
       XOR @FLAGS,R0  ; Set dest to flipped screen
       ANDI R10,SCRFLG
       AI R0,(3*32)+>4000
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address

       LI R0,>2000
       LI R9,(21*32)
!      MOVB R0,*R15         ; Clear the flipped screen with space
       DEC R9
       JNE -!
       
       BL @VSYNC
       BL @FLIP
       BL @MUSIC
       LI R9,10            ; Delay 10 frames
!      BL @VSYNC
       BL @MUSIC
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
       
       BL @VSYNC
       BL @FLIP
       BL @MUSIC
       BL @DOSPRT

       B @DONE
       
       

; Wipe screen from center
; R4 - pointer to new screen in VRAM
WIPE
       LI   R8,16           ; Scroll through 16 columns
       
WIPE2

       BL @VSYNC
       BL @VSYNC
       BL @VSYNC

; Copy two vertical strips from new screen to screen table

       LI  R4,LEVELA-1    ; Calculate left column source pointer
       A   R8,R4
       
       MOV @FLAGS,R3  ; Set dest to flipped screen
       ANDI R3,SCRFLG
       AI  R3,(32*3)-1+>4000  ; Calculate left column dest pointer with write flag
       A   R8,R3
       
       LI R9,22           ; Copy 22 characters
!      MOV R4,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
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
       AI  R3,(32*3)+32+>4000  ; Calculate right column dest pointer with write flag
       S   R8,R3
       
       LI R9,22           ; Copy 22 characters
!      MOV R4,R0
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
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

MENU
       LI R6,VDPRD        ; Keep VDPRD address in R6
       LI R8,21        ; Scroll through 21 rows
       LI R4,MENUSC+(32*20)    ; Menu screen VDP address
MENU2
       LI R5,-32       ; Direction down
       LI R9,23        ; Move 23 lines
       LI R10,32*23    ; Dest start at at bottom
       BL @SCROLL      ; Scroll down

       DEC R8
       JNE MENU2

       MOV R12,R10

!      BL @MUSIC
       BL @VSYNC
       LI R1,>0500
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 5
       LI R12, >0006
       TB 0                 ; Key /
       JNE -!               ; Start key down
       
!      BL @MUSIC
       BL @VSYNC
       LI R1,>0500
       LI R12, >0024
       LDCR R1,3            ; Turn on Keyboard Col 5
       LI R12, >0006
       TB 0                 ; Key /
       JEQ -!               ; Start key down

       MOV R10,R12

       LI R8,21        ; Scroll through 21 rows
       LI R4,LEVELA
MENU3
       LI R5,32        ; Direction up
       LI R9,23        ; Move 23 lines
       CLR R10         ; Dest start at at top
       BL @SCROLL      ; Scroll up

       DEC R8
       JNE MENU3

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
       MOVB @ENEMYS(R1),R0     ; Get enemy group index at map location
       SRL R0,8

       LI R7,ENEMYG           ; Pointer to enemy groups
       LI R9,OBJECT+24        ; Start filling the object list at index 12
       
       MOV  R0,R5
;       LI R4,4              ; 4 Armos sprites
;       LI R8, ENESPR+>590   ; Armos sprite source address index >2C
;       LI R10,SPRPAT+>C00   ; Destination sprite address index >60
;       ANDI R0,>0080        ; Test zora bit
;       JEQ LENEM2
;       LI R0,>1400          ; Zora enemy type
;       MOVB R0,*R9+         ; Store it
;       INC R4 	     	    ; 5 Zora sprites
;       LI R8,ENESPR+>400    ; Zora sprite source address index >20
;       AI R10,32            ; Destination sprite address index >61
;
;LENEM2 MOV R8,R0            ; Copy Zora or Armos sprites
;       BL @READ32           ; Read sprite into scratchpad
;       AI R8,32
;       
;       MOV R10,R0
;       BL @PUTSCR           ; Copy it back to the sprite pattern table
;       AI R10,32
;       
;       CI R10,SPRPAT+>E00
;       JNE !
;       LI R10,SPRPAT+>500   ; Pulsing ground dest address index >28
;       
;!      DEC R4
;       JNE LENEM2
;

       MOV R5,R1
       MOV R5,R0
       ANDI R0,>0040           ; Test edge loading bit
; TODO

       ANDI R1,>003F          ; Mask off zora and loading behavior bits to get group index
       JNE LENEM3
       B @DONE2                ; No enemies on this screen
       
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
       AI  R10,SPRPAT+>0100     ; Calculate dest offset into sprite pattern table (Y * 64 + 20 * 8)
       
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
       
       B @DONE2
       


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
       BYTE >0A,>05,>03,>0B,>01,>05,>02,>02,>82,>82,>89,>00,>00,>0C,>89,>0C
       BYTE >2a,>2a,>06,>01,>00,>0D,>8C,>8C,>8C,>0E,>0F,>10,>11,>92,>93,>00
       BYTE >2a,>2a,>05,>00,>14,>80,>80,>15,>96,>17,>10,>14,>18,>19,>92,>98
       BYTE >2a,>2a,>20,>17,>A1,>22,>80,>80,>8E,>16,>23,>24,>12,>19,>19,>AC
       BYTE >25,>26,>27,>28,>A1,>95,>A1,>2B,>2B,>8D,>A1,>27,>19,>19,>26,>92
       BYTE >05,>26,>26,>29,>12,>AB,>2B,>21,>21,>A1,>A1,>29,>1A,>1A,>29,>96
       BYTE >0D,>26,>1B,>19,>2D,>90,>11,>00,>21,>1D,>1E,>9F,>9F,>93,>A1,>98

       
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
       DATA >1C1D,>1C1D  ; Ladder
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

MT10   DATA >00ED,>0019  ; Water inner corner NE
       DATA >EC00,>1800  ; Water inner corner NW
       DATA >E7E8,>E1E9  ; Water corner NE
       DATA >E0E9,>E1EA  ; Water edge E
       DATA >E0EA,>E2EB  ; Water corner SE
       DATA >00F8,>FAC8  ; Brown Dungeon NW
       DATA >FBC9,>CBCA  ; Brown Dungeon SW
       DATA >C0C1,>C2C3  ; Brown Dungeon two eyes
       DATA >F900,>CCFA  ; Brown Dungeon NE
       DATA >CDFB,>CECB  ; Brown Dungeon SE
       DATA >7071,>7273  ; Red Steps
       DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >FCB0,>FDB0  ; Brown Tree NW
       DATA >00B2,>00B3  ; Brown Tree SW
       DATA >B400,>B500  ; Brown Tree NE
       DATA >B6FE,>B7FF  ; Brown Tree SE

MT20   DATA >D8D9,>DADB  ; Waterfall
       DATA >D8D9,>1F1F  ; Waterfall bottom
       DATA >B8B9,>BABB  ; Tree face
       DATA >F4F5,>F6F7  ; Gravestone
       DATA >9899,>9A9B  ; Bush
       DATA >1A00,>EE00  ; Water inner corner SW
       DATA >1011,>1213  ; Sand
       DATA >7474,>7575  ; Bridge
       DATA >878E,>8F60  ; Grey corner SE
       DATA >6060,>6060  ; Grey Ground
       DATA >F4F5,>F6F7  ; Gravestone
       DATA >8485,>8B8C  ; Grey top
       DATA >6465,>6667  ; Grey stairs
       DATA >F0F1,>F2F3  ; Grey bush
       DATA >6062,>FAC8  ; White Dungeon NW
       DATA >FBC9,>CBCA  ; White Dungeon SW

MT30   DATA >C4C5,>C6C7  ; White Dungeon one eye
       DATA >6360,>CCFA  ; White Dungeon NE
       DATA >2020,>2020  ; Black square
       DATA >DCDD,>DEDF  ; Armos
       DATA >001B,>00EF  ; Water inner corner SE
       DATA >6C6D,>6E6F  ; Brown brick Hidden path
       DATA >E0E9,>E1EA  ; Water edge E

MTGREY ; white metatiles
       DATA >6060,>6060  ; Grey Ground
       DATA >5C5D,>5C5D  ; White Ladder
       DATA >878E,>8F67  ; Green corner SE
       DATA >8566,>8C8D  ; Green corner NE
       DATA >8889,>6586  ; Green corner SW
       DATA >6484,>8A8B  ; Green corner NW
       DATA >F0F1,>F2F3  ; Grey bush
       DATA >7879,>7A7B  ; Grey stairs
       DATA >60F8,>FAC8  ; White Dungeon NW
       DATA >F960,>CCFA  ; White Dungeon NE

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
PALMTW BYTE >01,>02,>04,>05,>06,>08,>24,>1A,>15,>18  ; white conversions
PALMTG BYTE >00,>03,>04,>05,>06,>08,>09,>1A,>24,>27  ; green conversions
PALMTE

;       DATA >E7E7,>E1E1  ; Water edge N
;       DATA >E0E0,>E1E1  ; Water Green
;       DATA >E7E8,>E1E9  ; Water corner NE
;       DATA >E0E9,>E1EA  ; Water edge E
;       DATA >9091,>9293  ; Green bush
;       DATA >1011,>1213  ; Green Steps
;       DATA >0405,>0607  ; Sand
;       DATA >C0C1,>C2C3  ; White Dungeon two eyes
;       DATA >5C5D,>5C5D  ; White Ladder
;       DATA >8889,>6086  ; Grey corner SW
;       DATA >6084,>8A8B  ; Grey corner NW
;
;MT40   DATA >8560,>8C8D  ; Grey corner NE
;       DATA >B8B9,>BABB  ; Tree face
;       DATA >1C1C,>1D1D  ; Red Bridge
;       DATA >E6E7,>E5E1  ; Water corner NW
;       DATA >E5E0,>E4E1  ; Water edge W
;       DATA >E4E0,>E3E2  ; Water corner SW
;       DATA >E0E0,>E2E2  ; Water edge S
;       DATA >E0EA,>E2EB  ; Water corner SE
;       DATA >8081,>8283  ; Green brick
;       DATA >878E,>8F7B  ; Green corner SE
;       DATA >857A,>8C8D  ; Green corner NE
;       DATA >8485,>8B8C  ; Green top
;       DATA >00F8,>FAC8  ; Green Dungeon NW
;       DATA >FBC9,>CBCA  ; Green Dungeon SW
;       DATA >C0C1,>C2C3  ; Green Dungeon two eyes
;       DATA >7475,>7475  ; Blue/green Ladder
;       
;MT50   DATA >F900,>CCFA  ; Green Dungeon NE
;       DATA >CDFB,>CECB  ; Green Dungeon SE
;       DATA >8889,>7986  ; Green corner SW
;       DATA >7884,>8A8B  ; Green corner NW
;       DATA >9899,>9A9B  ; Brown bush
;       DATA >0809,>0A07  ; Sand NW
;       DATA >0A05,>0A07  ; Sand W
;       DATA >0A05,>0B0C  ; Sand SW
;       DATA >0909,>0607  ; Sand N
;       DATA >0405,>0607  ; Sand
;       DATA >0405,>0C0C  ; Sand S
;       DATA >090D,>060E  ; Sand NE
;       DATA >040E,>060E  ; Sand E
;       DATA >040E,>0C0F  ; Sand SE
;       DATA >C4C5,>C6C7  ; Green Dungeon one eye
;       DATA >EC00,>7000  ; Water inner corner NW
;
;MT60   DATA >9495,>9697  ; Green rock
;       DATA >00ED,>0071  ; Water inner corner NE
;       DATA >1414,>1515  ; Green Bridge
;
;       DATA >2020,>2020  ; Black cave floor
;       DATA >0073,>00EF  ; Water inner corner SE
;       DATA >DCDD,>DEDF  ; Armos
      
       

****************************************
* Colorset Definitions                  
****************************************
CLRNUM DATA 32                         ;
CLRSET BYTE >1B,>1B,>6B,>4B            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >1E,>16,>16,>1C            ;
       BYTE >1C,>1C,>CB,>6B            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>14,>4B            ;
       BYTE >4B,>4B,>1F,>1B            ;
****************************************
* Character Patterns                    
****************************************
PAT0   DATA >0000,>0000,>0000,>0000    ;
PAT1   DATA >9301,>0101,>0183,>C7EF    ;
PAT2   DATA >E0C2,>8203,>0709,>7317    ;
PAT3   DATA >F1EC,>EEF6,>E9DF,>AF5F    ;
PAT4   DATA >0000,>0000,>0303,>070F    ;
PAT5   DATA >1F0F,>0700,>0000,>0000    ;
PAT6   DATA >0000,>0000,>0000,>0038    ;
PAT7   DATA >8080,>8080,>0000,>0000    ;
PAT8   DATA >0003,>0F3C,>1030,>60C0    ;
PAT9   DATA >CEFF,>3900,>0000,>0000    ;
PAT10  DATA >8000,>0040,>C080,>0000    ;
PAT11  DATA >8080,>0000,>2030,>0006    ;
PAT12  DATA >0000,>0000,>0000,>0024    ;
PAT13  DATA >00C0,>FC08,>0000,>0C02    ;
PAT14  DATA >0101,>0100,>0002,>0203    ;
PAT15  DATA >0101,>0001,>0208,>0CC0    ;
PAT16  DATA >0000,>2002,>0040,>0008    ;
PAT17  DATA >0108,>0000,>4004,>0000    ;
PAT18  DATA >0001,>2000,>0082,>0010    ;
PAT19  DATA >1000,>0002,>1000,>0040    ;
PAT20  DATA >003C,>7EFF,>FFFF,>FFFF    ;
PAT21  DATA >7F7F,>3F1F,>0F07,>0301    ;
PAT22  DATA >FEFE,>FCF8,>F0E0,>C080    ;
PAT23  DATA >0000,>0000,>0000,>0000    ;
PAT24  DATA >8080,>8000,>0000,>0000    ;
PAT25  DATA >0307,>0000,>0000,>0000    ;
PAT26  DATA >0000,>0000,>8080,>80C0    ;
PAT27  DATA >0000,>0000,>0000,>0103    ;
PAT28  DATA >7F55,>6A55,>7F55,>6A55    ;
PAT29  DATA >FD55,>A955,>FD55,>A955    ;
PAT30  DATA >0000,>0000,>0000,>0000    ;
PAT31  DATA >FEFF,>7FFF,>FFFF,>6BD0    ;
PAT32  DATA >0000,>0000,>0000,>0000    ;
PAT33  DATA >1818,>1818,>1800,>1800    ;
PAT34  DATA >2424,>2400,>0000,>0000    ;
PAT35  DATA >000A,>0800,>040F,>0C1F    ;
PAT36  DATA >0050,>1000,>20F0,>30F8    ;
PAT37  DATA >FF00,>0000,>0000,>0000    ;
PAT38  DATA >7088,>5020,>5488,>7600    ;
PAT39  DATA >1808,>1000,>0000,>0000    ;
PAT40  DATA >0003,>070C,>0808,>0808    ;
PAT41  DATA >00C0,>E030,>1010,>1010    ;
PAT42  DATA >1B0B,>0101,>0100,>0000    ;
PAT43  DATA >D8D0,>8080,>8000,>0000    ;
PAT44  DATA >0000,>0000,>1808,>1000    ;
PAT45  DATA >0000,>007E,>0000,>0000    ;
PAT46  DATA >0000,>0000,>0018,>1800    ;
PAT47  DATA >8080,>8080,>8080,>8080    ;
PAT48  DATA >384C,>C6C6,>C664,>3800    ;
PAT49  DATA >1838,>1818,>1818,>7E00    ;
PAT50  DATA >7CC6,>0E3C,>78E0,>FE00    ;
PAT51  DATA >7E0C,>183C,>06C6,>7C00    ;
PAT52  DATA >1C3C,>6CCC,>FE0C,>0C00    ;
PAT53  DATA >FCC0,>FC06,>06C6,>7C00    ;
PAT54  DATA >3C60,>C0FC,>C6C6,>7C00    ;
PAT55  DATA >FEC6,>0C18,>3030,>3000    ;
PAT56  DATA >78C4,>E478,>8686,>7C00    ;
PAT57  DATA >7CC6,>C67E,>060C,>7800    ;
PAT58  DATA >0102,>0408,>1020,>4080    ;
PAT59  DATA >8040,>2010,>0804,>0201    ;
PAT60  DATA >FFFE,>FCF8,>F0E0,>C080    ;
PAT61  DATA >FF7F,>3F1F,>0F07,>0301    ;
PAT62  DATA >FF80,>8080,>8080,>8080    ;
PAT63  DATA >3844,>0408,>1000,>1000    ;
PAT64  DATA >FFFF,>FFFF,>FFFF,>FFFF    ;
PAT65  DATA >386C,>C6C6,>FEC6,>C600    ;
PAT66  DATA >FCC6,>C6FC,>C6C6,>FC00    ;
PAT67  DATA >3C66,>C0C0,>C066,>3C00    ;
PAT68  DATA >F8CC,>C6C6,>C6CC,>F800    ;
PAT69  DATA >FEC0,>C0FC,>C0C0,>FE00    ;
PAT70  DATA >FEC0,>C0FC,>C0C0,>C000    ;
PAT71  DATA >3E60,>C0CE,>C666,>3E00    ;
PAT72  DATA >C6C6,>C6FE,>C6C6,>C600    ;
PAT73  DATA >3C18,>1818,>1818,>3C00    ;
PAT74  DATA >1E06,>0606,>C6C6,>7C00    ;
PAT75  DATA >C6CC,>D8F0,>D8CC,>C600    ;
PAT76  DATA >6060,>6060,>6060,>7E00    ;
PAT77  DATA >C6EE,>FEFE,>D6C6,>C600    ;
PAT78  DATA >C6E6,>F6FE,>DECE,>C600    ;
PAT79  DATA >7CC6,>C6C6,>C6C6,>7C00    ;
PAT80  DATA >FCC6,>C6FC,>C0C0,>C000    ;
PAT81  DATA >7CC6,>C6C6,>DECC,>7A00    ;
PAT82  DATA >FCC6,>C6FC,>D8CC,>C600    ;
PAT83  DATA >78CC,>C07C,>06C6,>7C00    ;
PAT84  DATA >7E18,>1818,>1818,>1800    ;
PAT85  DATA >C6C6,>C6C6,>C6C6,>7C00    ;
PAT86  DATA >C6C6,>C6EE,>7C38,>1000    ;
PAT87  DATA >C6C6,>D6FE,>FEEE,>C600    ;
PAT88  DATA >C6EE,>7C38,>7CEE,>C600    ;
PAT89  DATA >CCCC,>CC78,>3030,>3000    ;
PAT90  DATA >FE0E,>1C38,>70E0,>FE00    ;
PAT91  DATA >0000,>0000,>0000,>0000    ;
PAT92  DATA >80AA,>95AA,>80AA,>95AA    ;
PAT93  DATA >02AA,>56AA,>02AA,>56AA    ;
PAT94  DATA >0000,>0107,>0703,>0000    ;
PAT95  DATA >0000,>80E0,>E0C0,>0000    ;
PAT96  DATA >0000,>0000,>0000,>0000    ;
PAT97  DATA >0000,>0000,>0000,>0000    ;
PAT98  DATA >0000,>0000,>0000,>0000    ;
PAT99  DATA >0000,>0000,>0000,>0000    ;
PAT100 DATA >0000,>0000,>0303,>070F    ;
PAT101 DATA >1F0F,>0700,>0000,>0000    ;
PAT102 DATA >0000,>0000,>0000,>0038    ;
PAT103 DATA >8080,>8080,>0000,>0000    ;
PAT104 DATA >9F9F,>9F9F,>9F9F,>81FF    ;
PAT105 DATA >C3E7,>E7E7,>E7E7,>C3FF    ;
PAT106 DATA >819F,>9F83,>9F9F,>9FFF    ;
PAT107 DATA >819F,>9F83,>9F9F,>81FF    ;
PAT108 DATA >56AD,>5CAD,>5A29,>5AA9    ;
PAT109 DATA >B44E,>AD57,>AD53,>A64A    ;
PAT110 DATA >5A39,>7AA3,>54CB,>14A9    ;
PAT111 DATA >954B,>D74A,>D68A,>F766    ;
PAT112 DATA >007F,>1F3F,>513B,>553B    ;
PAT113 DATA >00FE,>FEFE,>FEFE,>1EBE    ;
PAT114 DATA >553B,>553B,>553B,>5500    ;
PAT115 DATA >50BA,>54BA,>54BA,>5400    ;
PAT116 DATA >0145,>0101,>0101,>0101    ;
PAT117 DATA >0101,>0101,>0145,>01FF    ;
PAT118 DATA >FFFF,>FF81,>FFFF,>FFFF    ;
PAT119 DATA >9301,>0101,>0183,>C7EF    ;
PAT120 DATA >007F,>1F3F,>513B,>553B    ;
PAT121 DATA >00FE,>FEFE,>FEFE,>1EBE    ;
PAT122 DATA >553B,>553B,>553B,>5500    ;
PAT123 DATA >50BA,>54BA,>54BA,>5400    ;
PAT124 DATA >0145,>0101,>0101,>0101    ;
PAT125 DATA >0101,>0101,>0145,>01FF    ;
PAT126 DATA >0000,>0000,>0000,>0000    ;
PAT127 DATA >FFFF,>FFFF,>FFFF,>FFFF    ;
PAT128 DATA >56AD,>5CAD,>5A29,>5AA9    ;
PAT129 DATA >B44E,>AD57,>AD53,>A64A    ;
PAT130 DATA >5A39,>7AA3,>54CB,>14A9    ;
PAT131 DATA >954B,>D74A,>D68A,>F766    ;
PAT132 DATA >2C56,>AA57,>2B57,>2B56    ;
PAT133 DATA >0018,>2C56,>AA55,>2B57    ;
PAT134 DATA >BA79,>FAF9,>0A05,>0603    ;
PAT135 DATA >2B55,>3A2D,>5A2D,>5A2D    ;
PAT136 DATA >52A5,>52B5,>52B5,>F275    ;
PAT137 DATA >EB65,>AB65,>AA75,>BA79    ;
PAT138 DATA >1D2B,>552B,>5F2B,>57AB    ;
PAT139 DATA >AA54,>AA57,>AB57,>EEBA    ;
PAT140 DATA >AA56,>AE57,>AB15,>AB59    ;
PAT141 DATA >EC54,>AA56,>2A56,>6E74    ;
PAT142 DATA >D7CB,>D7CA,>D6CC,>F0C0    ;
PAT143 DATA >5B2D,>9BAD,>9BBE,>C000    ;
PAT144 DATA >000B,>552E,>75AA,>55AA    ;
PAT145 DATA >00C0,>78B4,>5CAE,>7CBE    ;
PAT146 DATA >77AA,>556E,>350A,>081F    ;
PAT147 DATA >5ABE,>7CAC,>F8D0,>3FFC    ;
PAT148 DATA >2854,>8E15,>AC59,>AA59    ;
PAT149 DATA >0000,>B058,>AC54,>AEDE    ;
PAT150 DATA >2A59,>2A59,>AA55,>AEFF    ;
PAT151 DATA >B6DE,>F65E,>BA74,>BFFC    ;
PAT152 DATA >000B,>552E,>75AA,>55AA    ;
PAT153 DATA >00C0,>78B4,>5CAE,>7CBE    ;
PAT154 DATA >57EA,>556E,>350A,>081F    ;
PAT155 DATA >5ABE,>7CAC,>F8D0,>3FFC    ;
PAT156 DATA >2854,>8E15,>AC59,>AA59    ;
PAT157 DATA >0000,>B058,>AC54,>AEDE    ;
PAT158 DATA >2A59,>2A59,>AA55,>AEFF    ;
PAT159 DATA >B6DE,>F65E,>BA74,>BFFC    ;
PAT160 DATA >56AD,>5CAD,>5A29,>5AA9    ;
PAT161 DATA >B44E,>AD57,>AD53,>A64A    ;
PAT162 DATA >5A39,>7AA3,>54CB,>14A9    ;
PAT163 DATA >954B,>D74A,>D68A,>F766    ;
PAT164 DATA >2C56,>AA57,>2B57,>2B56    ;
PAT165 DATA >0018,>2C56,>AA55,>2B57    ;
PAT166 DATA >BA79,>FAF9,>0A05,>0603    ;
PAT167 DATA >2B55,>3A2D,>5A2D,>5A2D    ;
PAT168 DATA >52A5,>52B5,>52B5,>F275    ;
PAT169 DATA >EB65,>AB65,>AA75,>BA79    ;
PAT170 DATA >1D2B,>552B,>5F2B,>57AB    ;
PAT171 DATA >AA54,>AA57,>AB57,>EEBA    ;
PAT172 DATA >AA56,>AE57,>AB15,>AB59    ;
PAT173 DATA >EC54,>AA56,>2A56,>6E74    ;
PAT174 DATA >D7CB,>D7CA,>D6CC,>F0C0    ;
PAT175 DATA >5B2D,>9BAD,>9BBE,>C000    ;
PAT176 DATA >6867,>6168,>F8F0,>3414    ;
PAT177 DATA >0448,>44E4,>F4FC,>F8F8    ;
PAT178 DATA >F2F2,>F2D2,>D2D2,>D2D2    ;
PAT179 DATA >96B4,>A4A4,>A028,>0832    ;
PAT180 DATA >0206,>CEFF,>FFFB,>3727    ;
PAT181 DATA >878F,>0F0E,>4656,>564E    ;
PAT182 DATA >4D4D,>6D6D,>6763,>6A6A    ;
PAT183 DATA >4A5B,>5317,>0346,>3E06    ;
PAT184 DATA >78FC,>F777,>0301,>0808    ;
PAT185 DATA >7EFF,>FFFF,>F8E0,>D011    ;
PAT186 DATA >1C14,>1408,>001B,>7B7F    ;
PAT187 DATA >3929,>2911,>01C1,>F4FD    ;
PAT188 DATA >F0E0,>E7F7,>D3DB,>9098    ;
PAT189 DATA >0F07,>E7EF,>CBDB,>0919    ;
PAT190 DATA >8FBF,>BEF0,>FEE7,>E1F3    ;
PAT191 DATA >F1FD,>7D0F,>7FE7,>87CF    ;
PAT192 DATA >07FC,>0403,>7C82,>02FE    ;
PAT193 DATA >E01F,>10F0,>3E41,>407F    ;
PAT194 DATA >3901,>FE00,>0F4F,>6FEF    ;
PAT195 DATA >5C40,>3F00,>F0F2,>F6F7    ;
PAT196 DATA >0798,>A0A7,>4B13,>1013    ;
PAT197 DATA >E119,>05E5,>D2C8,>08D0    ;
PAT198 DATA >0E0A,>0008,>4D6F,>EFFF    ;
PAT199 DATA >7050,>0010,>B2F6,>F7FF    ;
PAT200 DATA >A9A9,>2828,>2020,>4080    ;
PAT201 DATA >8080,>C0FE,>BEC0,>C0FE    ;
PAT202 DATA >FEC0,>C0FE,>BE80,>80FF    ;
PAT203 DATA >7E81,>8181,>8181,>81FF    ;
PAT204 DATA >9595,>1414,>043C,>4647    ;
PAT205 DATA >A9A9,>ADFD,>F985,>85FD    ;
PAT206 DATA >F985,>85FD,>F981,>81FF    ;
PAT207 DATA >0000,>0000,>0000,>0000    ;
PAT208 DATA >FEC2,>A140,>4000,>81C3    ;
PAT209 DATA >FFFF,>FFF0,>E0E7,>E7E7    ;
PAT210 DATA >FFFF,>FF0F,>07E7,>E7E7    ;
PAT211 DATA >E7E7,>E7E7,>E7E0,>F0FF    ;
PAT212 DATA >E7E7,>E7E7,>E707,>0FFF    ;
PAT213 DATA >E7E7,>E7E7,>E7E7,>E7E7    ;
PAT214 DATA >FFFF,>FFFF,>FF00,>00FF    ;
PAT215 DATA >FFFF,>FF00,>00FF,>FFFF    ;
PAT216 DATA >BFBF,>37F5,>5942,>1052    ;
PAT217 DATA >FFFF,>FEB8,>6D49,>4EDA    ;
PAT218 DATA >DAFE,>FBFB,>DBFF,>FFFF    ;
PAT219 DATA >BABB,>BFFF,>FFFF,>FEFF    ;
PAT220 DATA >372C,>1C1F,>FFB7,>FCFC    ;
PAT221 DATA >B4D4,>E4E4,>F4EC,>0612    ;
PAT222 DATA >FCFF,>FDFF,>B4FC,>7FFF    ;
PAT223 DATA >1212,>FE0E,>3E44,>86FF    ;
PAT224 DATA >FFFF,>DFFF,>FFFF,>7FFF    ;
PAT225 DATA >FFF7,>FFFF,>FFEF,>FFFF    ;
PAT226 DATA >FEFF,>7FFF,>FFFF,>6BD0    ;
PAT227 DATA >6F3F,>0F07,>0F1F,>0300    ;
PAT228 DATA >FEBF,>FFFF,>6F7F,>7F7F    ;
PAT229 DATA >3B7F,>7F6F,>7F7D,>5F7F    ;
PAT230 DATA >0001,>071F,>0E1F,>3F3F    ;
PAT231 DATA >67FF,>FFFE,>FFF7,>FFFF    ;
PAT232 DATA >80E0,>FCF8,>F0D0,>FCFE    ;
PAT233 DATA >7FF7,>FFFE,>EEFC,>FCFC    ;
PAT234 DATA >F6FE,>FEFE,>FEDE,>FFFF    ;
PAT235 DATA >FEBA,>FCF0,>F87C,>E000    ;
PAT236 DATA >EFFC,>F8A0,>F0F8,>F060    ;
PAT237 DATA >FB4F,>0F03,>0203,>0301    ;
PAT238 DATA >C0C0,>C0F0,>70FC,>BEFF    ;
PAT239 DATA >0103,>0706,>073F,>1FFE    ;
PAT240 DATA >000B,>552E,>75AA,>55AA    ;
PAT241 DATA >00C0,>78B4,>5CAE,>7CBE    ;
PAT242 DATA >57EA,>556E,>350A,>081F    ;
PAT243 DATA >5ABE,>7CAC,>F8D0,>3FFC    ;
PAT244 DATA >0F10,>2343,>4F4F,>4F43    ;
PAT245 DATA >F018,>8C86,>E6E6,>E686    ;
PAT246 DATA >43C3,>C0C0,>FF80,>80FF    ;
PAT247 DATA >8687,>0707,>FF01,>01FF    ;
PAT248 DATA >0307,>071F,>3F3F,>7F7F    ;
PAT249 DATA >C0E0,>E0F8,>FCFC,>FEFE    ;
PAT250 DATA >3C6E,>DFBD,>FDFB,>663C    ;
PAT251 DATA >C3FF,>466E,>2C18,>3C6E    ;
PAT252 DATA >4C7E,>7878,>7EFF,>3F03    ;
PAT253 DATA >0703,>0301,>0107,>0F03    ;
PAT254 DATA >0307,>1E3F,>7CF0,>E0E0    ;
PAT255 DATA >E0E0,>C0C0,>C0E0,>E0B0    ;
