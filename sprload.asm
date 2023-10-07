;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 1: compressed sprites
;


; TODO attack animation & Magic Rod could be shared in 0x with walking animation
; Sprite patterns (16x16 pixels, total of 64) (four per line, 4*8 bytes per sprite)
; 0x Link (fg and outline, 2 frame animation)  (replaced when changing direction)
;    Link Attack (fg and outline)   MagicRod (same direction), Raft/Pushed block
; 1x reserved for enemies (zora 1-2, zora bullet, armos 1-4)
; 2x reserved for enemies (moblin 1-4, pulsing ground 1-2, peahat 1-2, ghini 1-4
; 3x reserved for enemies (moblin 5-8, leever 1-3, tektite 1-2, rock 1-2
; 4x reserved for enemies (octorok 1-4, lynel 1-4,
; 5x reserved for enemies (octorok 5-8, lynel 5-8,
; 60 reserved for enemies (octorok bullet)
; 64-6x OPEN     6C=menu selector(only in menu)
; 7x Sword S,W,E,N
; 8x Sword projectile pop
; 9x Boomerang S,W,E,N
; Ax Arrow S,W,E,N
; Bx Magic S,W,E,N
; Cx Rupee, Bomb, Heart, Clock,
; Dx Cloud puff (3 frames), Spark (arrow or boomerang hitting edge of screen)
; Ex Map dot, Half-heart (status bar), Disappearing enemy (2 frames)
; Fx Flame (1 frame pattern-animated) Fairy (1 frame pattern-animated), B-item (compass), magicsword
;    Flame2, Fairy2, tornado 1, tornado 2,
;    Raft, Book, Magic Rod, Ladder
;    Magic Key, Power Bracelet, Arrow&Bow, Flute
;    Heart, Key, Letter/Map, Potion
;    Ring, Bait, Candle, Magic Shield
;    Old Woman 1&2, Merchant 1&2
;    Old Man 1&2, Master Sword, Item Selector
; NOTE: Extra sprites get copied to enemy area for cave, or patterns for menu screen


; enemy sprites loaded on demand per level
; 20-27 Peahat 2 sprites
; 28-2F pulsing ground 2 sprites (with Leever or Zora)
; 20-2F Ghini 4 sprites
; 20-3F Moblin 8 sprites
; 30-3B Leever 3 sprites
; 30-37 Tektite 2 sprites
; 30-37 Rock 2 sprites
; 40-5F Lynel 8 sprites
; 40-63 Octorok 9 sprites (2 anim, 4 directions, + bullet)
; 60-6F Armos 4 sprites
; 64-6F Zora 3 sprites (bullet, front, back)

; groups
; lynel  leever
; lynel  peahat
; leever peahat
; moblin octorok
; armos peahat
; armos lynel
; armos leever
; armos moblin
; armos octorok (near lvl-2) FIXME octorok bullet overwrites 1 frame of armos
; rocks zora

; Sprite list layout
; 0-3  Mapdot, half-heart, item, sword
; 4-5  Link, outline
; 6    Sword/Magic Rod
; 7    Beam sword/Magic
; 8    Arrow
; 9    Boomerang
; 10   Flame
; 11   Bomb
; 12+  all other objects


; TODO load enemy objects/sprites
;  save enemy count (and if zero, put in zeroenemy fifo)
;  load enemies
;  load enemy sprites (in this bank)
;  set enemy number to saved count, or none if in zeroenemy fifo
;

; FFANIM R2=100 animate fire/fairy sprites
; R2=10 Load enemies (called from bank2, return to bank 0)

; TODO make it possible to load ranges of sprites, from bank4 (I forget why)
       
; modifies R0-R10,R13
LOADSP
       MOV R11,@OBJPTR         ; Save return address

       ; Load menu sprites
       LI  R2,40        ; sprite index
       LI  R4,MENTAB+(>78*8)  ; Start output at menu item sprites
       LI  R3,SPRITE    ; Pointer to compressed sprites
       LI  R7,MODES     ; pointer to compress metadata nibbles
       CLR R8
       LI  R9,25        ; count
       BL @DECOM1

       LI  R4,SPRPAT+(28*32)    ; Start output at item sprites
       ;LI  R9,112      ; old: normal sprites + extra sprites
       LI R9,36         ; count of sprites to decompress
       LI  R3,SPRITE    ; Pointer to compressed sprites
       LI  R7,MODES     ; pointer to compress metadata nibbles
       CLR R8
DECOM0
* R3 = pointer to compressed sprites data
* R4 = sprite pattern address in VDP
* R7 = pointer to next compression type nibbles
* R8 = current compression type nibble word
* R9 = count of sprites to decompress
       BL  @DECOM2            ; Decompress sprites

DONESP
       MOV  @OBJPTR,R13       ; Jump to our return address
       JMP  BANK0

LDITEM ; load dungeon item sprite in R2 (called from bank2 map.asm, but returns to bank 0)
       MOV R11,@OBJPTR         ; Save return address
       LI R4,SPRPAT+(26*32)    ; Dungeon item sprite index
       LI R9,1
       BL @DECOM1
       JMP DONESP

LDMPCM ; load map and compass for dungeon menu (called from bank 0)
       MOV R11,@OBJPTR         ; Save return address
       LI R2,50                ; map index
       LI R4,SPRPAT+(24*32)    ; Dungeon item sprite index
       LI R9,1
       BL @DECOM1
       LI R2,34                ; compass index
       LI R4,SPRPAT+(25*32)    ; Dungeon item sprite index
       LI R9,1
       BL @DECOM1
       JMP DONESP


; Flame and fairy animation
FFANIM
       MOV R11,@OBJPTR         ; Save return address
       LI R3,FFSPR1            ; Pointer to compressed sprites
       MOV @COUNTR,R0
       ANDI R0,>0004
       JNE !
       LI R3,FFSPR2            ; Pointer to compressed sprites
!
       LI R4,SPRPAT+(60*32)    ; Start output at flame sprite
       LI R7,MODEND
       LI R8,>01C0             ; Normal, H-center
       LI R9,2                 ; 2 sprites
       JMP DECOM0


DECOMO ; decompress overworld enemy sprites
       LI R3,SPR_64 ; overworld mob sprites start at 64
       LI R7,MODES+32
       JMP DECOMX

;DECOMD ; decompress dungeon enemy sprites
;       LI R3,SPR_128 ; dungeon mob sprites start at 128
;       LI R7,MODES+64
;       JMP DECOMX

* Sprite decompression entry point
* R2 = sprite index
* R4 = sprite pattern address in VDP
* R9 = count of sprites to decompress
* Modifies R0-R5,R7-R10
* R6 is modified only in one place
* R7 = pointer to next compression type nibbles
* R8 = current compression type nibble word
DECOM1 ; decompress sprites
       LI R3,SPR_0
       LI R7,MODES

DECOMX
       MOV R11,R10      ; sprite decompressor returns to R10

       ; R3 = pointer to compressed sprites data
       ; R7 = pointer to next compression type nibbles
       ; R8 = current compression type nibble word

       CLR R8
       MOV R2,R2  ;  if R2 is zero, start decompression immediately
       JEQ !!!

!      SLA R8,4        ; Get next code from R8
       JNE !
       MOV *R7+,R8     ; Refill R8 if empty
!      MOV R8,R1
       ANDI R1,>F000   ; Get offset into jump table
       SRL R1,12
       CLR R0
       MOVB @SIZTBL(R1),R0
       SWPB R0
       A R0,R3         ; offset to next sprite

       DEC R2
       JNE -!!

!
       LI R5,NEXTDC   ; SETVDP will branch to R5
       JMP SETVDP

* Decompression sizes in sprite compressor (spritec.c)
SIZTBL BYTE 0,32,0,0, 0,0,0, 0,0,0, 8,8,16,16,16,16

* Decompression jump table
JMPTBL DATA DONESP,NORMAL,HFLIP1,VFLIP1,HFLIP2,VFLIP2,VFLIP3,CLKWS1
       DATA CLKWS2,CLKWS4,HVCENT,HVSYMM,HCENT,VCENT,HSYMM,VSYMM


* Reverse the 16-bit word in R0
* Modifies R1
;REVB16
;       SWPB R0      ; Reverse groups of 8 bits

* Reverse the 8-bit byte in R0 and write to VDP
* Modifies R1
REVB8
;       MOV R0,R1    ; Reverse even and odd bits
;       SRL R1,1
;       ANDI R1,>5555
;       ANDI R0,>5555
;       SLA R0,1
;       SOC R1,R0
;
;       MOV R0,R1    ; Reverse groups of 2 bits
;       SRL R1,2
;       ANDI R1,>3333
;       ANDI R0,>3333
;       SLA R0,2
;       SOC R1,R0
;
;       MOV R0,R1    ; Reverse groups of 4 bits
;       SRL R1,4
;       ANDI R1,>0F0F
;       ANDI R0,>0F0F
;       SLA R0,4
;       SOC R1,R0
       ANDI R0,>FF00
       LI  R1,>0002
!
       SLA R0,1
       JNC !
       SOC R1,R0
!
       SLA R1,2
       JNE -!!
       MOVB R0,*R15  ; write VDP data
       RT

HFLIP1
       MOV R4,R0
       AI R0,-32
       JMP HFLIP

HFLIP2
       MOV R4,R0
       AI R0,-64
       JMP HFLIP

VFLIP1
       MOV R4,R0
       AI R0,-32
       JMP VFLIP

VFLIP2
       MOV R4,R0
       AI R0,-64
       JMP VFLIP

VFLIP3
       MOV R4,R0
       AI R0,-96
       JMP VFLIP

CLKWS1
       MOV R4,R0
       AI R0,-32
       JMP CLKWIS

CLKWS2
       MOV R4,R0
       AI R0,-64
       JMP CLKWIS

CLKWS4
       MOV R4,R0
       AI R0,-128
       JMP CLKWIS


* Copy R2 bytes from R3 to VDP, reversing the bits
* Modifies R0-R2,R5
CPREVB MOV R11,R5   ; Save return address
!      MOVB *R3+,R0  ; read a byte from the right column
       BL @REVB8     ; reverse the bits and write to VDP
       DEC R2
       JNE -!
       B *R5        ; Return to saved address


UPCP16 LI R2,16
       A R2,R3
       JMP UPCOPY
* Copy R2 bytes from *R3 to *R15, moving backward
UPCPY8 LI R2,8
UPCOPY
!      DEC R3
       MOVB *R3,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT


* Read sprite from VDP at R0 in scratch, then set R4 VDP write address
* Saves R3 to R13
* Modifies R0-R3,R5
GETSPR
       MOV R11,R5   ; Save return address
       MOV R3,R13    ; Save R3
       LI R1,SCRTCH
       MOV R1,R3
       LI R2,32
       BL @VDPR      ; Read sprite to flip from VDP
SETVDP ; When branched from elsewhere, set R5 to return address
       MOV R4,R0      ; Set VDP write address
       ORI R0,VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       B *R5        ; Return to saved address


* source in R3, dest VDP address in R4 (already loaded)
HFLIP
       BL @GETSPR    ; Get sprite from R0 to scratch

       LI R2,16      ; Copy 16 bytes
       A R2,R3       ; Start reading from right column
       BL @CPREVB    ; Copy bytes reversing the bits
       LI R2,16      ; Copy 16 bytes
       AI R3,-32     ; Start reading from left column
       BL @CPREVB    ; Copy bytes reversing the bits
       MOV R13,R3    ; Restore R3
       JMP NEXTSP


* source in R3, dest VDP address in R4 (already loaded)
VFLIP
       BL @GETSPR    ; Get sprite from R0 to scratch
       BL @UPCP16    ; Start reading from the bottom
       AI R3,16      ; Start reading from bottom of next column
       BL @UPCP16
       MOV R13,R3    ; Restore R3
       JMP NEXTSP

CLKWIS
       BL @GETSPR    ; Get sprite from R0 to scratch

       LI R2,32      ; Copy 32 bytes
       AI R3,8       ; Start from lower left
CLKWI2
       CI R2,24
       JEQ !
       CI R2,8
       JNE CLKWI3
!      AI R3,16      ; Get next offset
       JMP !
CLKWI3 CI R2,16
       JNE !
       AI R3,-24     ; Get next offset
!      MOV R2,R0
       NEG R0
       ANDI R0,7     ; Get shift amount
       INC R0

       LI R6,8       ; Copy 8 bits
CLKWI4
       SRL R1,1
       MOVB *R3+,R5
       SLA R5,R0     ; Shift pixel into carry status
       JNC !
       ORI R1,>8000  ; Set a pixel
!      DEC R6
       JNE CLKWI4
       MOVB R1,*R15

       AI R3,-8

       DEC R2
       JNE CLKWI2
       MOV R13,R3    ; Restore R3

       JMP NEXTSP

CPZER4 LI R2,4
       JMP CPZERO
CPZER8 LI R2,8

* Copy R2 zeros to *R15
CPZERO CLR R0
!      MOVB R0,*R15  ; Copy zero to VDP
       DEC R2
       JNE -!
       RT

* Copy R2 bytes from *R3 to *R15, shifting right by 4
CPSR4
!      MOVB *R3+,R1
       SRL R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
CPSL4  CLR R1
!      MOVB *R3+,R1
       SLA R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

HVCENT
       BL @CPZER4    ; Copy 4 zero bytes
       LI R2,8       ; Copy 8 shifted bytes
       BL @CPSR4
       BL @CPZER8    ; Copy 8 zero bytes
       LI R2,8       ; Copy 8 bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       BL @CPZER4    ; Copy 4 zero bytes
       JMP NEXTSP


* Sprite decompression entry point
* R3 = pointer to compressed sprites data
* R4 = sprite pattern address in VDP
* R7 = pointer to next compression type nibbles
* R8 = current compression type nibble word
* R9 = count of sprites to decompress
DECOM2
       MOV R11,R10
       LI R5,!
       JMP SETVDP      ; This will return to R5
NEXTSP
       AI R4,32        ; next vdp sprite
       DEC R9          ; decrement sprite count
       JNE !
       B *R10          ; Return to saved address

!
NEXTDC
       SLA R8,4        ; Get next code from R8
       JNE !
       MOV *R7+,R8     ; Refill R8 if empty
!
       MOV R8,R1
       ANDI R1,>F000   ; Get offset into jump table
       SRL R1,11
       MOV @JMPTBL(R1),R1      ; Get jump table entry
       B *R1


HCENT
       LI R2,16      ; Copy 16 shifted bytes
       BL @CPSR4
       LI R2,16      ; Copy 16 shifted bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       JMP NEXTSP

VCENT
       BL @CPZER4    ; Copy 4 zero bytes
       BL @COPY8     ; Copy 8 bytes
       BL @CPZER8    ; Copy 8 zero bytes
       BL @COPY8     ; Copy 8 bytes
       BL @CPZER4    ; Copy 4 zero bytes
       JMP NEXTSP

HVSYMM
       BL @COPY8     ; Copy 8 bytes
       BL @UPCPY8    ; Copy 8 bytes upward
       LI R2,8       ; Copy 8 bytes
       BL @CPREVB    ; Copy bytes reversing the bits
       LI R2,8       ; Copy 8 bytes
!      DEC R3
       MOVB *R3,R0   ; read a byte from the left column
       BL @REVB8     ; reverse the bits and write to VDP
       DEC R2
       JNE -!
       AI R3,8
       JMP NEXTSP

* source in R3, dest VDP address in R4 (already loaded)
VSYMM
       BL @COPY16    ; Copy 16 bytes
       LI R2,16      ; Copy 16 bytes
       S R2,R3       ; Start reading from left column
       BL @CPREVB    ; Copy bytes reversing the bits
       JMP NEXTSP

HSYMM
       BL @COPY8     ; Copy 8 bytes
       BL @UPCPY8    ; Copy 8 bytes upward
       AI R3,8
       BL @COPY8
       BL @UPCPY8    ; Copy 8 bytes upward
       AI R3,8
       JMP NEXTSP

NORMAL BL @COPY16
       LI R11,NEXTSP  ; return to NEXTSP
COPY16 ; Copy 16 bytes from R3 to VDP
       ; Unrolling uses more space, but frees up a register
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
COPY8  ; Copy 8 bytes from R3 to VDP
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       MOVB *R3+,*R15 ; Copy byte to VDP data
       RT

       COPY 'sprites.asm'

FFSPR1 EQU SPRITE+>E8
FFSPR2 EQU SPRITE+>148
