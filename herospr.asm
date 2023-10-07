
*  LNKSPR  load hero sprites, walk and attack (R3 = direction)
*  LNKATK  load hero sprite attack stance (R3 = direction)
*  MSKLFT  load hero sprites masked LEFT (R3 = direction, R4=count)
*  MSKRGT  load hero sprites masked RIGHT (R3 = direction, R4=count)
*  MSKBOT  load hero sprites masked BOTTOM (R3 = direction, R4=count)
*  MSKTOP  load hero sprites masked TOP (R3 = direction, R4=count)
*  LNKITM  load hero sprites holding item

LNKADR ; Calculate sprites source address
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       SRA R1,1
       AI R1,SPR0

       CI R3,DIR_UP
       JEQ !          ; No shield sprite for facing up
       LI R0,MAGSHD
       CZC @HFLAGS,R0  ; Got magic shield?
       JEQ !
       AI R1,32*16     ; Copy magic shield walking sprites to sprites pattern table

!      LI R0,SPRPAT+VDPWM   ; Copy walking+attack+rod sprites to sprites pattern table
       MOVB @R0LB,*R14
       MOVB R0,*R14
       RT

LNKDIR ; set direction flags and load sprites
       MOV @FLAGS,R0
       ANDI R0,~DIR_XX
       SOC R3,R0
       MOV R0,@FLAGS
LNKSPR
       MOV R11,R13    ; Save return address
       BL @LNKADR     ; Get sprites address in R1
       LI R2,32*4
!      MOVB *R1+,*R15
       DEC R2
       JNE -!
       JMP BANK0         ; Return to saved address

LNKATK
       MOV R11,R13    ; Save return address
       MOV R3,R1      ; Adjust R1 to point to correct offset within sprite patterns
       SRA R1,1
       AI R1,SPR28
       LI R0,SPRPAT
       LI R2,32*3
       BL @VDPW
       JMP BANK0         ; Return to saved address



MSKALL   ; All clear mask
       LI R2,32*4
!      MOVB R2,*R15   ; Copy zeroes
       DEC R2
       JNE -!
       JMP BANK0      ; Return to saved address


* Masked copy bottom R4 lines of R3 sprites to VDP
* R4 lines zerod, rest copied
MSKTOP
       MOV R11,R13    ; Save return address
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2       ; Copy 4 sprites
MSKTO2
       MOV R4,R2
       A R2,R1
!      MOVB R2,*R15    ; Copy R2 zeroes
       DEC R2
       JNE -!

       LI R2,16
       S R4,R2
!      MOVB *R1+,*R15      ; Copy 16-R2 bytes
       DEC R2
       JNE -!

       DEC R8
       JNE MSKTO2
       JMP BANK0

* Copy sprite at R1 to VDP (address already programmed)
* R2 lines copied, rest zeros
* R2 must be preserved
MSKBOT
       MOV R11,R13    ; Save return address
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2       ; Copy 4 sprites
MSKBO2
       LI R2,16
       S R4,R2
!      MOVB *R1+,*R15     ; Copy 16-R2 bytes
       DEC R2
       JNE -!

       MOV R4,R2
       A R2,R1
!      MOVB R2,*R15    ; Copy R2 zeroes
       DEC R2
       JNE -!

       DEC R8
       JNE MSKBO2
       JMP BANK0


MSKLFT
       MOV R11,R13    ; Save return address
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2

       LI R0,16
       S R4,R0
       JLE MSKALL
       SETO R7
       SLA R7,R0
MSKLF2
       LI R2,16       ; Copy left half or right half of sprite, alternating
!      MOVB *R1+,R0
       SZCB R7,R0
       MOVB R0,*R15
       DEC R2
       JNE -!

       SWPB R7        ; Alternate pixel mask

       DEC R8
       JNE MSKLF2
       JMP BANK0

MSKRGT
       MOV R11,R13    ; Save return address
       BL @LNKADR
       CI R4,16
       JHE MSKALL
       LI R8,4*2

       LI R0,16
       S R4,R0
       JLE MSKALL
       SETO R7
       SRL R7,R0
       JMP MSKLF2  ; Same copy loop, different R7 mask

LNKITM ; Load sprites link holding item
       MOV R11,R13    ; Save return address
       LI R0,SPRPAT   ; Copy link holding item sprites to sprites pattern table
       LI R1,SPR7
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+32
       LI R1,SPR19
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+64
       LI R1,SPR31
       LI R2,32
       BL @VDPW

       LI R0,SPRPAT+96
       LI R1,SPR43
       LI R2,32
       BL @VDPW

       B @BANK0

SPR0   DATA >0F37,>6AEC,>AE26,>030C    ; Color 3
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FC,>F0F0    ;
       DATA >C464,>E0C0,>00E0,>0000    ;
SPR1   DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F0,>2002,>0202    ;
       DATA >3A9A,>1A22,>E200,>0080    ;
SPR2   DATA >000F,>376A,>ECAE,>2603    ; Color 3
       DATA >1823,>0140,>613E,>1F00    ;
       DATA >0080,>0000,>00D0,>FCF0    ;
       DATA >F0C8,>A860,>C010,>E000    ;
SPR3   DATA >0000,>0815,>1311,>191C    ; Color 1
       DATA >071C,>3E3F,>1EC1,>E070    ;
       DATA >0000,>F0F8,>F020,>0004    ;
       DATA >0434,>5494,>24E4,>1870    ;
SPR4   DATA >0100,>0000,>0B3F,>0F0F    ; Color 3
       DATA >2326,>0703,>0007,>0000    ;
       DATA >F0EC,>5637,>7564,>C030    ;
       DATA >18E0,>6080,>64FE,>0000    ;
SPR5   DATA >000F,>1F0F,>0440,>4040    ; Color 1
       DATA >5C59,>5844,>4700,>0001    ;
       DATA >0010,>A8C8,>8898,>38C0    ;
       DATA >E41E,>9E7E,>9800,>E0E0    ;
SPR6   DATA >0001,>0000,>000B,>3F0F    ; Color 3
       DATA >0F13,>1506,>0308,>0700    ;
       DATA >00F0,>EC56,>3775,>64C0    ;
       DATA >18C4,>8002,>867C,>F800    ;
SPR7   DATA >0000,>0F1F,>0F04,>0020    ; Color 1
       DATA >202C,>2A29,>2427,>180E    ;
       DATA >0000,>10A8,>C888,>9838    ;
       DATA >E038,>7CFC,>7883,>070E    ;
SPR8   DATA >072F,>2830,>351F,>0603    ; Color 3
       DATA >2071,>2021,>0003,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
SPR9   DATA >0000,>070F,>0A00,>097C    ; Color 1
       DATA >DF8E,>DFDE,>FFFC,>7E0E    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CC12,>92FA,>8C00,>7000    ;
SPR10  DATA >072F,>2830,>351F,>0603    ; Color 3
       DATA >1038,>1010,>0000,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
SPR11  DATA >0000,>070F,>0A00,>093C    ; Color 1
       DATA >6F47,>6F6F,>7F7F,>3E00    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
SPR12  DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0727,>2718,>1F07,>0000    ;
       DATA >C0E0,>F4F4,>E4CC,>8810    ;
       DATA >F0F0,>E018,>F8C0,>0000    ;
SPR13  DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3858,>5827,>0008,>0600    ;
       DATA >0000,>0008,>1830,>70E8    ;
       DATA >0C0C,>1CE0,>0038,>7830    ;
SPR14  DATA >0307,>2F2F,>2733,>1108    ; Color 3
       DATA >0F0F,>0718,>1F03,>0000    ;
       DATA >C0E0,>F4F4,>E4CC,>8810    ;
       DATA >E0E4,>E418,>F8E0,>0000    ;
SPR15  DATA >0000,>0010,>180C,>0E17    ; Color 1
       DATA >3030,>3807,>001C,>1E0C    ;
       DATA >0000,>0008,>1830,>70E8    ;
       DATA >1C1A,>1AE4,>0010,>6000    ;
SPR16  DATA >0F37,>6AEC,>AE26,>030C    ; Color 8
       DATA >1807,>0601,>267F,>0000    ;
       DATA >8000,>0000,>D0FD,>F1F1    ;
       DATA >C565,>E1C1,>01E0,>0000    ;
SPR17  DATA >0008,>1513,>1119,>1C03    ; Color 1
       DATA >2778,>797E,>1900,>0707    ;
       DATA >00F0,>F8F3,>2302,>0202    ;
       DATA >3A9A,>1A22,>E203,>0380    ;
SPR18  DATA >000F,>376A,>ECAE,>2603    ; Color 8
       DATA >1823,>0140,>613E,>1F00    ;
       DATA >0080,>0000,>00D0,>FAF2    ;
       DATA >F2CA,>AA62,>C212,>E000    ;
SPR19  DATA >0000,>0815,>1311,>191C    ; Color 1
       DATA >071C,>3E3F,>1EC1,>E070    ;
       DATA >0000,>F0F8,>F626,>0404    ;
       DATA >0434,>5494,>24E4,>1E76    ;
SPR20  DATA >0100,>0000,>0BBF,>8F8F    ; Color 8
       DATA >A3A6,>8783,>8007,>0000    ;
       DATA >F0EC,>5637,>7564,>C030    ;
       DATA >18E0,>6080,>64FE,>0000    ;
SPR21  DATA >000F,>1FCF,>C440,>4040    ; Color 1
       DATA >5C59,>5844,>47C0,>C001    ;
       DATA >0010,>A8C8,>8898,>38C0    ;
       DATA >E41E,>9E7E,>9800,>E0E0    ;
SPR22  DATA >0001,>0000,>000B,>5F4F    ; Color 8
       DATA >4F53,>5546,>4348,>0700    ;
       DATA >00F0,>EC56,>3775,>64C0    ;
       DATA >18C4,>8002,>867C,>F800    ;
SPR23  DATA >0000,>0F1F,>6F64,>2020    ; Color 1
       DATA >202C,>2A29,>2427,>786E    ;
       DATA >0000,>10A8,>C888,>9838    ;
       DATA >E038,>7CFC,>7883,>070E    ;
SPR24  DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60C0    ;
       DATA >30EC,>6C04,>70F0,>0000    ;
SPR25  DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9038    ;
       DATA >CE12,>92FA,>8C00,>7000    ;
SPR26  DATA >072F,>2830,>351F,>0018    ; Color 5
       DATA >187E,>7E18,>1818,>0000    ;
       DATA >E0F4,>140C,>ACF8,>60D0    ;
       DATA >38F8,>3088,>30E0,>0000    ;
SPR27  DATA >0000,>070F,>0A00,>FFE7    ; Color 1
       DATA >E781,>81E7,>E7E7,>7E3C    ;
       DATA >0000,>E0F0,>5000,>9028    ;
       DATA >C404,>CC74,>C010,>7070    ;
SPR28  DATA >0003,>0B15,>1637,>7341    ; Color 3
       DATA >0F18,>1030,>783F,>1F00    ;
       DATA >00C0,>8000,>0068,>7EF0    ;
       DATA >EE1E,>1A10,>E000,>F000    ;
SPR29  DATA >0000,>040A,>0908,>0C0E    ; Color 1
       DATA >0007,>0F0F,>07C0,>E070    ;
       DATA >0000,>78FC,>F890,>8008    ;
       DATA >10F0,>F0E0,>18F8,>0C1E    ;
SPR30  DATA >0000,>0000,>0000,>0000    ; Color 4
       DATA >FFFF,>0000,>0000,>0000    ;
       DATA >0000,>0000,>0000,>0056    ;
       DATA >ABAF,>5600,>0000,>0000    ;
SPR31  DATA >6374,>0815,>1F0E,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >C62E,>10A8,>F870,>60C0    ;
       DATA >30F0,>3880,>38F8,>0000    ;
SPR32  DATA >0003,>0100,>0016,>7E0F    ; Color 3
       DATA >7778,>5808,>0700,>0F00    ;
       DATA >00C0,>D0A8,>68EC,>CE82    ;
       DATA >F018,>080C,>1EFC,>F800    ;
SPR33  DATA >0000,>1E3F,>1F09,>0110    ; Color 1
       DATA >080F,>0F07,>181F,>3078    ;
       DATA >0000,>2050,>9010,>3070    ;
       DATA >00E0,>F0F0,>E003,>070E    ;
SPR34  DATA >0000,>0000,>0000,>006A    ; Color 4
       DATA >B5F5,>6A00,>0000,>0000    ;
       DATA >0000,>0000,>0000,>0000    ;
       DATA >FFFF,>0000,>0000,>0000    ;
SPR35  DATA >0003,>676A,>6031,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >00C0,>E656,>068C,>9C3C    ;
       DATA >C808,>C078,>C000,>7070    ;
SPR36  DATA >0317,>1C38,>3597,>4E26    ; Color 3
       DATA >1807,>0A0C,>0602,>0100    ;
       DATA >E0F0,>180A,>AEEC,>7860    ;
       DATA >00C0,>0484,>6CE8,>E000    ;
SPR37  DATA >1828,>63C7,>CA68,>3119    ; Color 1
       DATA >0708,>0503,>1939,>0000    ;
       DATA >0000,>E0F0,>5010,>8098    ;
       DATA >FC3C,>F878,>9217,>0F00    ;
SPR38  DATA >0101,>0101,>0101,>0101    ; Color 4
       DATA >0102,>0102,>0102,>0301    ;
       DATA >8080,>8080,>8080,>8080    ;
       DATA >8040,>8040,>80C0,>C080    ;
SPR39  DATA >6374,>0815,>1F0D,>0603    ; Color 3
       DATA >0C0F,>1C01,>1C1F,>0000    ;
       DATA >E0F0,>1404,>ACEC,>78C0    ;
       DATA >3CFC,>3088,>38E0,>0000    ;
SPR40  DATA >0F5F,>5F7F,>2F27,>1218    ; Color 3
       DATA >1F1F,>2F30,>3F01,>0000    ;
       DATA >80C0,>E0E8,>D811,>3244    ;
       DATA >C8D0,>A010,>F8E0,>0000    ;
SPR41  DATA >1000,>2000,>5058,>6D67    ; Color 1
       DATA >2020,>104F,>C0E0,>0000    ;
       DATA >0000,>0000,>20E0,>C1BB    ;
       DATA >372F,>5EEC,>0018,>3C3C    ;
SPR42  DATA >0102,>0301,>0201,>0201    ; Color 4
       DATA >0101,>0101,>0101,>0101    ;
       DATA >80C0,>C080,>4080,>4080    ;
       DATA >8080,>8080,>8080,>8080    ;
SPR43  DATA >0003,>676A,>6032,>393C    ; Color 1
       DATA >1310,>031E,>0300,>0E0E    ;
       DATA >0000,>E0F0,>5010,>843C    ;
       DATA >C000,>C870,>C010,>7070    ;
