*
* Legend of Tilda
* 
* Bank 3: dungeon map
*

       COPY 'legend.asm'

       
* Load title screen
MAIN
       MOV R11,R13      ; Save return address for later

       LI R0,CLRTAB     ; Load color table
       LI R1,CLRSET
       LI R2,32
       BL @VDPW

       LI R0,PATTAB     ; Load pattern table
       LI R1,PAT32
       LI R2,SPR0-PAT32
       BL @VDPW

       LI R0,SPRPAT     ; Load sprite patterns
       LI R1,SPR0
       LI R2,MCOUNT-SPR0
       BL @VDPW

       LI R0,SCR1TB     ; Load screen table
       LI R1,MD0
       LI R2,32*24
       BL @VDPW

       LI R0,SPRTAB     ; Load sprite table
       LI R1,SL0
       LI R2,17*4
       BL @VDPW

MLOOP
       BL @VSYNC
       BL @MUSIC
       
       JMP MLOOP


       LI   R0,BANK0         ; Load bank 0
       MOV  R13,R1           ; Jump to our return address
       B    @BANKSW






; source in R3, dest VDP address in R4 (already loaded)
HFLIP
       LI R2,16      ; Copy 16 bytes
       A R2,R3       ; Start reading from right column
!      MOVB *R3+,R0  ; read a byte from the right column
       BL @REVB8      ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       LI R2,16      ; Copy 16 bytes
       AI R3,-32     ; Start reading from left column
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8      ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       AI R3,16
       JMP NEXTSP


UPCPY8 LI R2,8
       JMP !
UPCP16 LI R2,16
!      A R2,R3
; Copy R2 bytes from *R3 to *R15, moving upward
UPCOPY
!      DEC R3
       MOVB *R3,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

; source in R3, dest VDP address in R4 (already loaded)
VFLIP
       BL @UPCP16    ; Start reading from the bottom
       AI R3,16      ; Start reading from bottom of next column
       BL @UPCP16
       AI R3,16
       JMP NEXTSP
       
CLKWIS
       LI R2,32      ; Copy 32 bytes
       AI R3,8       ; Start from lower left
CLKWI2
       CI R2,24
       JNE CLKWI3
       CI R2,8
       JNE CLKWI3
       AI R3,16      ; Get next offset
       JMP !
CLKWI3 CI R2,16
       JNE !
       AI R3,-24     ; Get next offset
!      MOV R2,R0
       NEG R0
       LI R5,>7F7F
       SRC R5,R0     ; Get bitmask
       
       LI R4,8       ; Copy 8 bits
       CLR R0
CLKWI4 SRL R1,1
       MOVB *R3+,R0
       SZC R5,R0     ; AND bitmask
       JEQ !
       ORI R1,>8000
!      DEC R4
       JNE CLKWI4
       
       DEC R2
       JNE CLKWI2
       AI R3,16      ; Get next offset

       JMP NEXTSP

; Copy R2 zeros to *R15
CPZERO CLR R0
!      MOVB R0,*R15  ; Copy zero to VDP
       DEC R2
       JNE -!

; Copy R2 bytes from *R3 to *R15, shifting right by 4
CPSR4
!      MOVB *R3+,R1
       SRL R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
CPSL4
!      MOVB *R3+,R1
       SLA R1,4      ; Shift it
       MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

HVCENT
       LI R2,4       ; Copy 4 zero bytes
       BL @CPZERO
       LI R2,8       ; Copy 8 shifted bytes
       BL @CPSR4
       LI R2,8       ; Copy 8 zero bytes
       BL @CPZERO
       LI R2,8       ; Copy 8 bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       LI R2,8       ; Copy 4 zero bytes
       BL @CPZERO
       JMP NEXTSP

HCENT
       LI R2,16      ; Copy 16 shifted bytes
       BL @CPSR4
       LI R2,16      ; Copy 16 shifted bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       JMP NEXTSP

NEXTSP

COPY16 LI R2,16
       JMP !
COPY8
       LI R2,8
; Copy R2 bytes from *R3 to *R15
COPY
!      MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
       
VCENT
       LI R2,4       ; Copy 4 zero bytes
       BL @CPZERO
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 zero bytes
       BL @CPZERO
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 4 zero bytes
       BL @CPZERO
       JMP NEXTSP

HVSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes upward
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       LI R2,8       ; Copy 8 bytes
!      DEC R3
       MOVB *R3,R0   ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       AI R3,8
       JMP NEXTSP

; source in R3, dest VDP address in R4 (already loaded)
HSYMM
       BL @COPY16    ; Copy 16 bytes
       LI R2,16      ; Copy 16 bytes
       S R2,R3       ; Start reading from left column
!      MOVB *R3+,R0  ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       JMP NEXTSP

VSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes reverse
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
       A R2,R3
       BL @COPY
       LI R2,8       ; Copy 8 bytes
       BL @UPCOPY
       AI R3,8
       JMP NEXTSP


; Reverse the 16-bit word in R0
; Modifies R1
REVB16
       SWPB R0      ; Reverse groups of 8 bits
REVB8
       MOV R0,R1    ; Reverse even and odd bits
       SRL R1,1
       ANDI R1,>5555
       ANDI R0,>5555
       SLA R0,1
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 2 bits
       SRL R1,2
       ANDI R1,>3333
       ANDI R0,>3333
       SLA R0,2
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 4 bits
       SRL R1,4
       ANDI R1,>0F0F
       ANDI R0,>0F0F
       SLA R0,4
       SOC R1,R0

       RT



TILDA  COPY "tilda.asm" 