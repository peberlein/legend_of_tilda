;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 1: music, compressed sprites



       COPY 'tilda.asm'

       
; Load a song into VRAM, R2 indicates song 0=overworld 1=dungeon
; R2=100 animate fire/fairy sprites
MAIN
       MOV  R11,R12           ; Save our return address
       CI R2,100
       JEQ FFANIM

       MOV  R2,R0
       JNE  !                ; is R2 nonzero?


       LI   R1,SNDLST        ; Music Address in ROM
       LI   R2,SNDEND-SNDLST  ; Music Length in bytes
       JMP  SND2
!
;       LI   R1,SNDLS2        ; Music Address in ROM
;       LI   R2,SNDEN2-SNDLS2  ; Music Length in bytes
SND2
       LI   R0,MUSICV        ; Music Address in VRAM
       BL   @VDPW            ; Copy to VRAM
       
       LI   R0,1             ; Music counter = 1
       MOV  R0,@MUSICC
       LI   R0,MUSICV
       MOV  R0,@MUSICP

       B @DECOMP            ; Decompress sprites

DONE
       LI   R0,BANK0         ; Load bank 0
       MOV  R12,R1            ; Jump to our return address
       B    @BANKSW

; Flame and fairy animation
FFANIM
       LI R3,FFSPR1            ; Pointer to compressed sprites
       MOV @COUNTR,R0
       ANDI R0,>0004
       JNE !
       LI R3,FFSPR2            ; Pointer to compressed sprites
!
       LI R4,SPRPAT+(60*32)    ; Start output at flame sprite
       LI R7,MODEND
       LI R8,>01C0             ; Normal, H-center
       B @DECOM2

SNDLST BCOPY "music.snd"
;SNDLST BCOPY "title.snd"
SNDEND

;SNDLS2 BCOPY "dungeon.snd"
;SNDEN2



; Decompression jump table
JMPTBL DATA DONE,NORMAL,HFLIP1,VFLIP1,HFLIP2,VFLIP2,VFLIP3,CLKWS1
       DATA CLKWS2,CLKWS4,HVCENT,HVSYMM,HCENT,VCENT,HSYMM,VSYMM


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


; Copy R2 bytes from R3 to VDP, reversing the bits
CPREVB MOV R11,R10   ; Save return address
!      MOVB *R3+,R0  ; read a byte from the right column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       B *R10        ; Return to saved address


NORMAL LI R11,NEXTSP
       LI R2,32
       JMP COPY
COPY16 LI R2,16
       JMP COPY
COPY8
       LI R2,8
; Copy R2 bytes from *R3 to *R15
COPY
!      MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

UPCPY8 LI R2,8
       JMP !
UPCP16 LI R2,16
!      A R2,R3
; Copy R2 bytes from *R3 to *R15, moving backward
UPCOPY
!      DEC R3
       MOVB *R3,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT


; Read sprite from VDP at R0 in scratch, then set R4 VDP write address
; Saves R3 to R13
GETSPR
       MOV R11,R10   ; Save return address
       MOV R3,R13    ; Save R3
       LI R1,SCRTCH
       MOV R1,R3
       LI R2,32
       BL @VDPR      ; Read sprite to flip from VDP
SETVDP
       MOV R4,R0      ; Set VDP write address
       ORI R0,VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       B *R10        ; Return to saved address


; source in R3, dest VDP address in R4 (already loaded)
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


; source in R3, dest VDP address in R4 (already loaded)
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

; Copy R2 zeros to *R15
CPZERO CLR R0
!      MOVB R0,*R15  ; Copy zero to VDP
       DEC R2
       JNE -!
       RT

; Copy R2 bytes from *R3 to *R15, shifting right by 4
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


DECOMP
       LI R3,SPRITE            ; Pointer to compressed sprites
       LI R4,SPRPAT+(28*32)    ; Start output at item sprites
       LI R7,MODES
       CLR R8
DECOM2
       LI R10,!
       JMP SETVDP      ; This will return to R10
NEXTSP
       AI R4,32
!      SLA R8,4        ; Get next code from R8
       JNE !
       MOV *R7+,R8     ; Refill R8 if empty
!      MOV R8,R1
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
       LI R2,8       ; Copy 8 bytes upward
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
       BL @CPREVB    ; Copy bytes reversing the bits
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
VSYMM
       BL @COPY16    ; Copy 16 bytes
       LI R2,16      ; Copy 16 bytes
       S R2,R3       ; Start reading from left column
       BL @CPREVB    ; Copy bytes reversing the bits
       JMP NEXTSP

HSYMM
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



MODES  DATA >d283,>c252,>a283,>d283,>e283,>ccaf,>fffa,>aabb,>1ca2,>1c12,>fccb,>cccc,>fccc,>cccc,>ffff,>ffcb
       DATA >ffff,>ee44,>9955,>ca11,>1144,>1212,>1144,>1212,>bfff,>ffff,>1212,>1111,>1111,>ffff,>11a2,>2222
MODEND DATA >0000

SPRITE
       DATA >0018,>08af,>afaf,>0818,>0000,>00fe,>fffe,>0000  ; 0: Vcenter
       ; 1: Hflip-1
       ; 2: Clockwise-2
       ; 3: Vflip-1
       DATA >0000,>0000,>0000,>78fc,>fce6,>c3db,>c860,>7030  ; 4: Hcenter
       ; 5: Hflip-1
       ; 6: Vflip-2
       ; 7: Hflip-1
       DATA >381c,>0e0e,>0e0e,>1c38  ; 8: HVcenter
       ; 9: Hflip-1
       ; 10: Clockwise-2
       ; 11: Vflip-1
       DATA >00a8,>54ff,>54a8,>0000,>0000,>06fb,>0600,>0000  ; 12: Vcenter
       ; 13: Hflip-1
       ; 14: Clockwise-2
       ; 15: Vflip-1
       DATA >0003,>1188,>4c64,>2636,>2018,>8cce,>c6e7,>6767  ; 16: Hsymmetry
       ; 17: Hflip-1
       ; 18: Clockwise-2
       ; 19: Vflip-1
       DATA >080c,>0e55,>3b3b,>3b3b,>3b3b,>3b5b,>e57e,>3c18  ; 20: Hcenter
       DATA >0004,>0402,>0101,>023c,>4ebf,>bfff,>ff7e,>3c00  ; 21: Hcenter
       DATA >6cfe,>fefe,>7c38,>1000  ; 22: HVcenter
       DATA >0707,>0107,>0d18,>1034,>2231,>2030,>1018,>0d07  ; 23: Vsymmetry
       DATA >070f,>3f77,>6f6f,>eff7,>ffdf,>5f5b,>293c,>1f0e  ; 24: Vsymmetry
       DATA >030e,>2923,>1130,>7694,>a829,>236b,>3118,>170a  ; 25: Vsymmetry
       DATA >0200,>0820,>0310,>200a,>8009,>2001,>2004,>0106  ; 26: Vsymmetry
       DATA >442d,>be7c,>387c,>9008  ; 27: HVcenter
       DATA >0000,>0000,>003c,>3c3c  ; 28: HVcenter
       DATA >60f0,>e0f0,>e070,>2010  ; 29: HVcenter
       DATA >0000,>0010,>0104,>010a  ; 30: HVsymmetry
       DATA >0140,>0111,>0805,>02b5  ; 31: HVsymmetry
FFSPR1 DATA >0014,>292b,>0f6f,>7f7f,>7fbf,>fefa,>7c7c,>3f07,>4484,>a0e4,>e8da,>fefd,>fdff,>ffbe,>1e3c,>fcf0
       DATA >4428,>0438,>7991,>bbd6,>4683,>283c,>3020,>2020  ; 33: Hcenter
       DATA >0000,>0000,>0000,>0000  ; 34: HVcenter
       ; 35: Hflip-1
FFSPR2 DATA >2221,>0527,>175b,>7fbf,>bfff,>ff7d,>783c,>3f0f,>0028,>94d4,>f0f6,>fefe,>fefd,>7f5f,>3e3e,>fce0
       DATA >4428,>85b9,>b952,>3ad4,>6cc6,>283c,>3020,>2020  ; 37: Hcenter
       DATA >0000,>0780,>b00c,>0350,>2e10,>0c01,>3608,>0003,>f806,>110d,>000c,>3204,>8224,>c02c,>9028,>d020
       ; 39: Hflip-1
       DATA >317b,>7b7b,>403b,>7b7f,>7b7b,>403b,>7b7f,>4a31  ; 40: Vsymmetry
       DATA >feab,>55ab,>7fff,>41ff,>55ff,>7ff7,>63f7,>7f7e  ; 41: Hcenter
       DATA >182c,>3c18,>2418,>2418,>1818,>1818,>1818,>1818  ; 42: Hcenter
       DATA >e0ff,>ffe0,>e0ff,>ffe0  ; 43: HVsymmetry
       DATA >041f,>2e2f,>ffef,>0f7e,>0808,>0808,>7808,>7808  ; 44: Hcenter
       DATA >0014,>3a0b,>73f0,>31d0,>d031,>f073,>0b3a,>1400  ; 45: Hcenter
       DATA >e098,>8c86,>8683,>8383,>8383,>8386,>868c,>98e0  ; 46: Hcenter
       DATA >3828,>3828,>3828,>3828,>3828,>3838,>1038,>2838  ; 47: Hcenter
       DATA >0000,>1c3e,>7f7f,>7f7f,>3f3f,>1f0f,>0703,>0100  ; 48: Vsymmetry
       DATA >3c7e,>e7c3,>c3ff,>ff18,>1818,>1878,>7838,>7818  ; 49: Hcenter
       DATA >dbff,>ffcb,>7fd7,>ffaf,>ffff,>fefe,>ae7e,>fcfc  ; 50: Hcenter
       DATA >3c18,>243c,>2424,>6681,>81ff,>fbdf,>f7bd,>c37e  ; 51: Hcenter
       DATA >0000,>003c,>5eff,>ff7e,>c181,>c27c,>0000,>0000  ; 52: Hcenter
       DATA >2c18,>183c,>7eab,>7fef,>5ffd,>563c,>1818,>1834  ; 53: Hcenter
       DATA >083c,>746e,>2400,>3c3c,>3c3d,>3d3d,>3d3d,>ff7e  ; 54: Hcenter
       DATA >0000,>ffff,>e7e7,>8181,>e7e7,>e7e7,>7e3c,>0000  ; 55: Hcenter
       DATA >0000,>0003,>0507,>0502,>0121,>2000,>0000,>000e  ; 56: Vsymmetry
       DATA >070c,>1810,>1010,>3034,>7656,>5f5e,>566f,>2f21  ; 57: Vsymmetry
       DATA >0000,>0515,>131b,>0000,>0030,>3870,>6000,>0000  ; 58: Vsymmetry
       DATA >0000,>0000,>0000,>1018,>0f0f,>0600,>1e07,>0000  ; 59: Vsymmetry
       DATA >0705,>0d0d,>0300,>0000,>8080,>8000,>0000,>0006  ; 60: Vsymmetry
       DATA >0000,>0000,>0810,>3064,>6c7c,>7677,>772f,>0f19  ; 61: Vsymmetry
       DATA >80c0,>e0e0,>7070,>343a,>1a5f,>4e2e,>1e15,>0303  ; 62: Hcenter
       DATA >e080,>8000,>0000,>0000  ; 63: HVsymmetry
; Enemy Symmetries
; Peahat  0-1  Vertical Symmetry
; Tektite 2-3  Vertical Symmetry
; Octorok 4-5  Horizontal Symmetry
;         6-7  Horizontal Flip  source - 2
;         8-9  Rotate counter-clockwise  source - 2
;         10-11 Vertical Flip  source - 2
; Bullet  12  8x8 centered
; ZBullet 13 Vertical Symmetry
; Rock    14-15  Normal
; Moblin  16-17 Normal
;         18-19 Horizontal Flip  source - 2
;         20 Normal
;         21 Horizontal Flip source - 1
;         22 Normal
;         23 Horizontal Flip source - 1
; Lynel   24-25 Normal
;         26-27 Horizontal Flip  source - 2
;         28 Normal
;         29 Horizontal Flip source - 1
;         30 Normal
;         31 Horizontal Flip source - 1
; Zora    32-33  Vertical Symmetry
; Pulsing 34-35  Vertical Symmetry
; Leever  36-38  Vertical Symmetry
; Ghost   40  Normal
;         41  Horizontal Flip source - 1
;         42  Normal
;         43  Horizontal Flip source - 1
; Armos   44-47  Normal

; Enemies compressed
       DATA >0103,>037e,>fe7d,>092b,>6b0b,>2d36,>0718,>0302  ; 0: Vsymmetry
       DATA >0038,>7d3e,>0207,>1f3d,>3d7b,>0f17,>3708,>0d01  ; 1: Vsymmetry
       DATA >0000,>0000,>63b5,>8fbf,>b71f,>79b9,>8c87,>8280  ; 2: Vsymmetry
       DATA >0305,>1f3f,>375f,>5999,>3477,>4240,>4040,>4080  ; 3: Vsymmetry
       DATA >2436,>3f6c,>78bb,>edfc,>00c0,>80f0,>31a1,>df1f  ; 4: Hsymmetry
       DATA >486d,>3f6c,>78bb,>edfc,>8080,>90f0,>24ac,>dc1c  ; 5: Hsymmetry
       ; 6: Hflip-2
       ; 7: Hflip-2
       ; 8: Clockwise-4
       ; 9: Clockwise-4
       ; 10: Vflip-2
       ; 11: Vflip-2
       DATA >0000,>0000,>3864,>a68e,>a595,>8fce,>7e18,>0000  ; 12: Hcenter
       DATA >0000,>0000,>0000,>0000  ; 13: HVcenter
       DATA >0307,>192e,>5d5d,>fdf8,>f0ef,>6f7f,>3f1f,>0701,>c0b0,>c8e8,>e4d2,>fafa,>7a3a,>b2b4,>a498,>20c0
       DATA >0103,>0f1b,>1125,>3e7e,>5e5e,>5e5e,>2c19,>0f03,>e020,>d8c8,>e4e4,>e2e2,>625a,>7e7c,>f8f8,>70e0
       DATA >0301,>0e11,>2120,>6747,>3e4f,>7f26,>e01c,>3f3f,>e0f8,>ece6,>fef5,>736f,>3e3e,>fc0c,>1010,>9c7c
       DATA >0003,>010e,>1121,>2066,>4737,>434f,>20c3,>3f07,>00e0,>f8ec,>e6fe,>f573,>6fbe,>fcff,>ec90,>e0e0
       ; 18: Hflip-2
       ; 19: Hflip-2
       DATA >3c0f,>0b49,>7edb,>d8db,>eeaf,>4750,>4c37,>7b7c,>3cf0,>d090,>78de,>1ada,>76f7,>ef0f,>1ae4,>de00
       ; 21: Hflip-1
       DATA >3c1f,>0728,>3060,>6040,>4040,>5847,>2019,>3f3c,>3cf8,>e012,>0a0c,>0e0e,>0e06,>34c2,>0214,>ee00
       ; 23: Hflip-1
       DATA >1f05,>0c02,>0682,>c4fe,>7f7f,>3f7f,>ff70,>2000,>f0f0,>a888,>103e,>213e,>f0f0,>f8fc,>fc38,>1000
       DATA >000f,>0206,>0103,>0186,>ffff,>7f3f,>3f1f,>1d1d,>00f8,>f854,>4408,>3e21,>3ef8,>f8f8,>f8f0,>f0e0
       ; 26: Hflip-2
       ; 27: Hflip-2
       DATA >0b0f,>0f05,>041d,>2245,>447b,>4f2f,>2f2f,>2e30,>e8f8,>f850,>1cd2,>22cf,>096a,>fafa,>fafe,>3c38
       ; 29: Hflip-1
       DATA >0b0f,>0f07,>071a,>2044,>4549,>3e1f,>1f1f,>0e00,>e8f8,>f8f0,>fc22,>0282,>d4d8,>bcfc,>fcfc,>3c38
       ; 31: Hflip-1
       DATA >0000,>0003,>0706,>0c0d  ; 32: HVsymmetry
       DATA >8141,>776b,>e96a,>6a6f,>d853,>57d0,>2f33,>1c07  ; 33: Vsymmetry
       DATA >8141,>656d,>f575,>7575,>f777,>6ddd,>2d31,>1c07  ; 34: Vsymmetry
       DATA >0000,>0000,>0000,>0000,>0003,>0d37,>0e00,>0000  ; 35: Vsymmetry
       DATA >0000,>0000,>0000,>0000,>0305,>0f1a,>0700,>0000  ; 36: Vsymmetry
       DATA >0406,>090b,>0d0e,>0e06,>0e1b,>1e2f,>3b5e,>7712  ; 37: Vsymmetry
       DATA >0121,>2235,>3919,>1909,>0d36,>3d6f,>bef7,>1d09  ; 38: Vsymmetry
       DATA >0000,>0000,>0406,>090b,>0d0e,>0e16,>16da,>3d07  ; 39: Vsymmetry
       DATA >0798,>aec0,>ff5c,>4040,>5c3f,>1f0f,>0300,>0000,>e0f8,>733e,>fcf8,>7830,>30f0,>f8f8,>fc3e,>0000
       ; 41: Hflip-1
       DATA >0f1f,>ffef,>773f,>3f1f,>1f0f,>0f07,>0300,>0000,>c0f0,>fbf6,>f6fc,>fcf8,>f8fc,>fcfe,>fe7f,>0000
       ; 43: Hflip-1
       DATA >1b16,>0e0f,>ffb4,>fcfc,>fcff,>feff,>b4fd,>1e1e,>d075,>65f7,>ea06,>0207,>0fc7,>7ac2,>1afe,>3e02
       DATA >1b16,>0e0f,>ffb4,>fcfc,>fcff,>feff,>b4fd,>1e00,>d575,>67f2,>ea06,>060f,>07c6,>7ac2,>02da,>3e3c
       DATA >0baf,>a7ef,>4f5f,>6850,>50d0,>ffe0,>604f,>7c40,>d8e8,>f0f0,>fff1,>793d,>3d3d,>fd39,>39bf,>7878
       DATA >abaf,>e74f,>4f5f,>6850,>d0d0,>ff60,>605f,>7c3c,>d8e8,>f0f0,>fff1,>793d,>3d3d,>fd39,>39bf,>7800
       DATA >0304,>1e29,>5352,>82c7,>8f90,>5040,>2018,>0601,>c0b0,>0808,>1406,>0606,>86c6,>464c,>4c78,>e0c0
       DATA >0102,>0c14,>1e3a,>2141,>6161,>6161,>3316,>0c03,>e020,>3838,>1c1c,>1e1e,>9ea6,>8284,>0808,>90e0
       DATA >3c0b,>0556,>6164,>6764,>f1b0,>786f,>333c,>7f7c,>3cd0,>a068,>8426,>e727,>8f0f,>1ffa,>e41e,>fe00
       DATA >0702,>0f1e,>3e3f,>3838,>7170,>0079,>e71c,>3f3f,>e018,>2432,>020b,>8d91,>c2e2,>14fc,>f0e0,>1c7c
       DATA >42a6,>9a95,>1695,>9590,>27ac,>a82f,>d04c,>2318  ; 52: Vsymmetry
       DATA >8141,>6160,>e062,>6260,>c043,>47c0,>0000,>0000  ; 53: Vsymmetry
       DATA >42a6,>9a92,>0a8a,>8a8a,>0888,>9222,>d24e,>2318  ; 54: Vsymmetry
       DATA >8141,>6161,>f171,>7171,>f575,>61c1,>0101,>0000  ; 55: Vsymmetry
       DATA >1b16,>0e0f,>fcb5,>fdfd,>fdfc,>fdfc,>b5fd,>1e1e,>d075,>75f7,>1afa,>fef9,>f139,>823e,>e6da,>3e02
       DATA >1b16,>0e0f,>fcb5,>fdfd,>fdfc,>fdfc,>b5fd,>1e00,>d575,>77f2,>1afa,>f9f1,>f93e,>823e,>fee6,>1a3c
       DATA >0000,>0000,>0000,>0000  ; 58: HVcenter
       ; 59: Hflip-1
       ; 60: Hflip-1
       ; 61: Hflip-1
       ; 62: Hflip-1
       ; 63: Hflip-1
