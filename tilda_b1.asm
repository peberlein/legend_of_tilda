;
; Legend of Tilda
; 
; Bank 1: music
;


       COPY 'tilda.asm'

       
; Load a song into VRAM, R2 indicates song 0=overworld 1=dungeon
MAIN
       MOV  R11,R3           ; Save our return address
       MOV  R2,R0
       JNE  !                ; is R2 nonzero? 
       
       LI R0,ENESPR          ; Enemy sprite patterns in VDP
       LI R1,SPR0
       LI R2,SPREND-SPR0
       BL   @VDPW
       
       LI   R1,SNDLST        ; Music Address in ROM
       LI   R2,SNDEND-SNDLST  ; Music Length in bytes
       JMP  SND2

!      LI   R1,SNDLS2        ; Music Address in ROM
       LI   R2,SNDEN2-SNDLS2  ; Music Length in bytes
SND2
       LI   R0,MUSICV        ; Music Address in VRAM
       BL   @VDPW            ; Copy to VRAM
       
       LI   R0,1             ; Music counter = 1
       MOV  R0,@MUSICC
       LI   R0,MUSICV
       MOV  R0,@MUSICP
       
       LI   R0,BANK0         ; Load bank 0
       MOV  R3,R1            ; Jump to our return address
       B    @BANKSW
       
SNDLST BCOPY "music.snd"
;SNDLST BCOPY "title.snd"
SNDEND

SNDLS2 BCOPY "dungeon.snd"
SNDEN2


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


****************************************
* Overworld Enemy Sprite Patterns                       
****************************************
SPR0   DATA >0103,>037E,>FE7D,>092B    ; Color 12
       DATA >6B0B,>2D36,>0718,>0302    ; 
       DATA >80C0,>C07E,>7FBE,>90D4    ; 
       DATA >D6D0,>B46C,>E018,>C040    ; 
SPR1   DATA >0038,>7D3E,>0207,>1F3D    ; Color 12
       DATA >3D7B,>0F17,>3708,>0D01    ; 
       DATA >001C,>BE7C,>40E0,>F8BC    ; 
       DATA >BCDE,>F0E8,>EC10,>B080    ; 
SPR2   DATA >0000,>0000,>63B5,>8FBF    ; Color 9
       DATA >B71F,>79B9,>8C87,>8280    ; 
       DATA >0000,>0000,>C6AD,>F1FD    ; 
       DATA >EDF8,>9E9D,>31E1,>4101    ; 
SPR3   DATA >0305,>1F3F,>375F,>5999    ; Color 9
       DATA >3477,>4240,>4040,>4080    ; 
       DATA >C0A0,>F8FC,>ECFA,>9A99    ; 
       DATA >2CEE,>4202,>0202,>0201    ; 
SPR4   DATA >2436,>3F6C,>78BB,>EDFC    ; Color 8
       DATA >FCED,>BB78,>6C3F,>3624    ; 
       DATA >00C0,>80F0,>31A1,>DF1F    ; 
       DATA >1FDF,>A131,>F080,>C000    ; 
SPR5   DATA >486D,>3F6C,>78BB,>EDFC    ; Color 8
       DATA >FCED,>BB78,>6C3F,>6D48    ; 
       DATA >8080,>90F0,>24AC,>DC1C    ; 
       DATA >1CDC,>AC24,>F090,>8080    ; 
SPR6   DATA >0003,>010F,>8C85,>FBF8    ; Color 8
       DATA >F8FB,>858C,>0F01,>0300    ; 
       DATA >246C,>FC36,>1EDD,>B73F    ; 
       DATA >3FB7,>DD1E,>36FC,>6C24    ; 
SPR7   DATA >0101,>090F,>2435,>3B38    ; Color 8
       DATA >383B,>3524,>0F09,>0101    ; 
       DATA >12B6,>FC36,>1EDD,>B73F    ; 
       DATA >3FB7,>DD1E,>36FC,>B612    ; 
SPR8   DATA >071B,>FF6D,>3FF3,>6426    ; Color 8
       DATA >7652,>1C1B,>0303,>030F    ; 
       DATA >E0D8,>FFB6,>FCCF,>2664    ; 
       DATA >6E4A,>38D8,>C0C0,>C0F0    ; 
SPR9   DATA >07DB,>7F2D,>FF73,>2466    ; Color 8
       DATA >F612,>1C33,>070F,>0000    ; 
       DATA >E0DB,>FEB4,>FFCE,>2466    ; 
       DATA >6F48,>38CC,>E0F0,>0000    ; 
SPR10  DATA >0F03,>0303,>1B1C,>5276    ; Color 8
       DATA >2664,>F33F,>6DFF,>1B07    ; 
       DATA >F0C0,>C0C0,>D838,>4A6E    ; 
       DATA >6426,>CFFC,>B6FF,>D8E0    ; 
SPR11  DATA >0000,>0F07,>331C,>12F6    ; Color 8
       DATA >6624,>73FF,>2D7F,>DB07    ; 
       DATA >0000,>F0E0,>CC38,>486F    ; 
       DATA >6624,>CEFF,>B4FE,>DBE0    ; 
SPR12  DATA >0000,>0000,>0306,>0A08    ; Color 6
       DATA >0A09,>080C,>0701,>0000    ; 
       DATA >0000,>0000,>8040,>60E0    ; 
       DATA >5050,>F0E0,>E080,>0000    ; 
SPR39  DATA >0000,>0000,>0000,>0000    ; Color 1
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>0000,>0000    ; 
SPR14  DATA >0307,>192E,>5D5D,>FDF8    ; Color 10
       DATA >F0EF,>6F7F,>3F1F,>0701    ; 
       DATA >C0B0,>C8E8,>E4D2,>FAFA    ; 
       DATA >7A3A,>B2B4,>A498,>20C0    ; 
SPR15  DATA >0103,>0F1B,>1125,>3E7E    ; Color 10
       DATA >5E5E,>5E5E,>2C19,>0F03    ; 
       DATA >E020,>D8C8,>E4E4,>E2E2    ; 
       DATA >625A,>7E7C,>F8F8,>70E0    ; 
SPR16  DATA >0301,>0E11,>2120,>6747    ; Color 6
       DATA >3E4F,>7F26,>E01C,>3F3F    ; 
       DATA >E0F8,>ECE6,>FEF5,>736F    ; 
       DATA >3E3E,>FC0C,>1010,>9C7C    ; 
SPR17  DATA >0003,>010E,>1121,>2066    ; Color 6
       DATA >4737,>434F,>20C3,>3F07    ; 
       DATA >00E0,>F8EC,>E6FE,>F573    ; 
       DATA >6FBE,>FCFF,>EC90,>E0E0    ; 
SPR18  DATA >071F,>3767,>7FAF,>CEF6    ; Color 6
       DATA >7C7C,>3F30,>0808,>393E    ; 
       DATA >C080,>7088,>8404,>E6E2    ; 
       DATA >7CF2,>FE64,>0738,>FCFC    ; 
SPR19  DATA >0007,>1F37,>677F,>AFCE    ; Color 6
       DATA >F67D,>3FFF,>3709,>0707    ; 
       DATA >00C0,>8070,>8884,>0466    ; 
       DATA >E2EC,>C2F2,>04C3,>FCE0    ; 
SPR20  DATA >3C0F,>0B49,>7EDB,>D8DB    ; Color 6
       DATA >EEAF,>4750,>4C37,>7B7C    ; 
       DATA >3CF0,>D090,>78DE,>1ADA    ; 
       DATA >76F7,>EF0F,>1AE4,>DE00    ; 
SPR21  DATA >3C0F,>0B09,>1E7B,>585B    ; Color 6
       DATA >6EEF,>F7F0,>5827,>7B00    ; 
       DATA >3CF0,>D092,>7EDB,>1BDB    ; 
       DATA >77F5,>E20A,>32EC,>DE3E    ; 
SPR22  DATA >3C1F,>0728,>3060,>6040    ; Color 6
       DATA >4040,>5847,>2019,>3F3C    ; 
       DATA >3CF8,>E012,>0A0C,>0E0E    ; 
       DATA >0E06,>34C2,>0214,>EE00    ; 
SPR23  DATA >3C1F,>0748,>5030,>7070    ; Color 6
       DATA >7060,>2C43,>4028,>7700    ; 
       DATA >3CF8,>E014,>0C06,>0602    ; 
       DATA >0202,>1AE2,>0498,>FC3C    ; 
SPR24  DATA >1F05,>0C02,>0682,>C4FE    ; Color 4
       DATA >7F7F,>3F7F,>FF70,>2000    ; 
       DATA >F0F0,>A888,>103E,>213E    ; 
       DATA >F0F0,>F8FC,>FC38,>1000    ; 
SPR25  DATA >000F,>0206,>0103,>0186    ; Color 4
       DATA >FFFF,>7F3F,>3F1F,>1D1D    ; 
       DATA >00F8,>F854,>4408,>3E21    ; 
       DATA >3EF8,>F8F8,>F8F0,>F0E0    ; 
SPR26  DATA >0F0F,>1511,>087C,>847C    ; Color 4
       DATA >0F0F,>1F3F,>3F1C,>0800    ; 
       DATA >F8A0,>3040,>6041,>237F    ; 
       DATA >FEFE,>FCFE,>FF0E,>0400    ; 
SPR27  DATA >001F,>1F2A,>2210,>7C84    ; Color 4
       DATA >7C1F,>1F1F,>1F0F,>0F07    ; 
       DATA >00F0,>4060,>80C0,>8061    ; 
       DATA >FFFF,>FEFC,>FCF8,>B8B8    ; 
SPR28  DATA >171F,>1F0A,>083B,>448B    ; Color 4
       DATA >88F6,>9F5F,>5F5F,>5C60    ; 
       DATA >D0F0,>F0A0,>38A4,>449E    ; 
       DATA >12D4,>F4F4,>F4FC,>7870    ; 
SPR29  DATA >171F,>1F0A,>384B,>44F3    ; Color 4
       DATA >9056,>5F5F,>5F7F,>3C1C    ; 
       DATA >D0F0,>F0A0,>20B8,>44A2    ; 
       DATA >22DE,>F2F4,>F4F4,>740C    ; 
SPR30  DATA >171F,>1F0F,>0F34,>4089    ; Color 4
       DATA >8B93,>7D3F,>3F3F,>1C00    ; 
       DATA >D0F0,>F0E0,>F844,>0404    ; 
       DATA >A8B0,>78F8,>F8F8,>7870    ; 
SPR31  DATA >171F,>1F0F,>3F44,>4041    ; Color 4
       DATA >2B1B,>3D3F,>3F3F,>3C1C    ; 
       DATA >D0F0,>F0E0,>E058,>0422    ; 
       DATA >A292,>7CF8,>F8F8,>7000    ; 
SPR13  DATA >0000,>0003,>0706,>0C0D    ; Color 8
       DATA >0D0C,>0607,>0300,>0000    ; 
       DATA >0000,>00C0,>E060,>30B0    ; 
       DATA >B030,>60E0,>C000,>0000    ; 
SPR32  DATA >8141,>756A,>E96A,>6A6F    ; Color 5
       DATA >D853,>57D0,>2F33,>1C07    ; 
       DATA >8182,>AE56,>9756,>56F6    ; 
       DATA >1BCA,>EA0B,>F4CC,>38E0    ; 
SPR33  DATA >8141,>656D,>F575,>7575    ; Color 5
       DATA >F777,>6DDD,>2D31,>1C07    ; 
       DATA >8182,>A6B6,>AFAE,>AEAE    ; 
       DATA >EFEE,>B6BB,>B48C,>38E0    ; 
SPR34  DATA >0000,>0000,>0000,>0000    ; Color 5
       DATA >0000,>0000,>030D,>370E    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>0000,>C0B0,>EC70    ; 
SPR35  DATA >0000,>0000,>0000,>0000    ; Color 5
       DATA >0000,>0003,>050F,>1A07    ; 
       DATA >0000,>0000,>0000,>0000    ; 
       DATA >0000,>00C0,>A0F0,>58E0    ; 
SPR36  DATA >0406,>090B,>0D0E,>0E06    ; Color 8
       DATA >0E1B,>1E2F,>3B5E,>7712    ; 
       DATA >2060,>90D0,>B070,>7060    ; 
       DATA >70D8,>78F4,>DC7A,>EE48    ; 
SPR37  DATA >0121,>2235,>3919,>1909    ; Color 8
       DATA >0D36,>3D6F,>BEF7,>1D09    ; 
       DATA >8084,>44AC,>9C98,>9890    ; 
       DATA >B06C,>BCF6,>7DEF,>B890    ; 
SPR38  DATA >0000,>0000,>0406,>090B    ; Color 8
       DATA >0D0D,>0D15,>15DA,>3D07    ; 
       DATA >0000,>0000,>2060,>90D0    ; 
       DATA >B0B0,>B0A8,>A85B,>BCE0    ; 
SPR40  DATA >0798,>AEC0,>FF5C,>4040    ; Color 15
       DATA >5C3F,>1F0F,>0300,>0000    ; 
       DATA >E0F8,>733E,>FCF8,>7830    ; 
       DATA >30F0,>F8F8,>FC3E,>0000    ; 
SPR41  DATA >071F,>CE7C,>3F1F,>1E0C    ; Color 15
       DATA >0C0F,>1F1F,>3F7C,>0000    ; 
       DATA >E019,>7503,>FF3A,>0202    ; 
       DATA >3AFC,>F8F0,>C000,>0000    ; 
SPR42  DATA >0F1F,>FFEF,>773F,>3F1F    ; Color 15
       DATA >1F0F,>0F07,>0300,>0000    ; 
       DATA >C0F0,>FBF6,>F6FC,>FCF8    ; 
       DATA >F8FC,>FCFE,>FE7F,>0000    ; 
SPR43  DATA >030F,>DF6F,>6F3F,>3F1F    ; Color 15
       DATA >1F3F,>3F7F,>7FFE,>0000    ; 
       DATA >F0F8,>FFF7,>EEFC,>FCF8    ; 
       DATA >F8F0,>F0E0,>C000,>0000    ; 
SPR44  DATA >1B16,>0E0F,>FFB4,>FCFC    ; Color 8
       DATA >FCFF,>FEFF,>B4FD,>1E1E    ; 
       DATA >D075,>65F7,>EA06,>0207    ; 
       DATA >0FC7,>7AC2,>1AFE,>3E02    ; 
SPR45  DATA >1B16,>0E0F,>FFB4,>FCFC    ; Color 8
       DATA >FCFF,>FEFF,>B4FD,>1E00    ; 
       DATA >D575,>67F2,>EA06,>060F    ; 
       DATA >07C6,>7AC2,>02DA,>3E3C    ; 
SPR46  DATA >0BAF,>A7EF,>4F5F,>6850    ; Color 8
       DATA >50D0,>FFE0,>604F,>7C40    ; 
       DATA >D8E8,>F0F0,>FFF1,>793D    ; 
       DATA >3D3D,>FD39,>39BF,>7878    ; 
SPR47  DATA >ABAF,>E74F,>4F5F,>6850    ; Color 8
       DATA >D0D0,>FF60,>605F,>7C3C    ; 
       DATA >D8E8,>F0F0,>FFF1,>793D    ; 
       DATA >3D3D,>FD39,>39BF,>7800    ; 
SPREND
