***************************************************************
* The Legend of Tilda
* alternate title: Tilda - A 99/4A Fantasy
* Copyright 2022 Pete Eberlein
***************************************************************

WRKSP  EQU  >8300             ; Workspace memory in fast RAM, 16 registers, 32 bytes
R0LB   EQU  WRKSP+1           ; Register zero low byte address
R1LB   EQU  WRKSP+3           ; Register one low byte address
R2LB   EQU  WRKSP+5           ; Register two low byte address
R3LB   EQU  WRKSP+7           ; Register three low byte address
R4LB   EQU  WRKSP+9           ; Register four low byte address
R5LB   EQU  WRKSP+11          ; Register five low byte address
R6LB   EQU  WRKSP+13          ; Register six low byte address
R7LB   EQU  WRKSP+15          ; Register 7 low byte address
R8LB   EQU  WRKSP+17          ; Register 8 low byte address
R9LB   EQU  WRKSP+19          ; Register 9 low byte address
R10LB  EQU  WRKSP+21          ; Register 10 low byte address
R12LB  EQU  WRKSP+25          ; Register 12 low byte address
R13LB  EQU  WRKSP+27          ; Register 13 low byte address

VDPWD  EQU  >8C00             ; VDP write data
VDPWA  EQU  >8C02             ; VDP set read/write address
VDPRD  EQU  >8800             ; VDP read data (don't forget NOP after address)
VDPSTA EQU  >8802             ; VDP status
VDPWM  EQU  >4000             ; VDP address write mask
VDPRM  EQU  >8000             ; VDP address register mask
SNDREG EQU  >8400             ; Sound register address

* VDP Map
* 0000:031F Screen Table A (32*25 = >320)
* 0320:033F Save area scratchpad/sprite list (>20)
* 0340:035F Color Table (32 bytes = >20)
* 0360:037F Music Save pointers (8 bytes) MapSav(1),Ecount(1),R12SAV(2),LadPos(6)
*           Recent map locations (8 bytes)
* 0380:03FF Sprite List Table (32*4 bytes = >80)
* 0400:071F Screen Table B (32*25 = >320)
* 0720:073F
* 0740:075F Bright Color Table (32 bytes = >20)
* 0760:077F Enemy Drop table index and status flags (32 bytes = >20)
* 0780:079F Menu Color Table (32 bytes = >20)
* 07A0:07DF Enemy Hurt/Stun Counters interleaved (64 bytes = >40)
* 07E0:07FF Enemy HP (32 bytes = >20)
* 0800:0FFF Overworld/Dungeon Pattern Descriptor Table (256*8 = >800)
* 1000:17FF Dark Overworld/Dungeon Pattern Descriptor Table (256*8 = >800)
* 1800:1FFF Sprite Pattern Table (64*32 = >800)
* OBSOLETE 1000:1B7F Sprite Pattern Table (64*32 + 28*32 bytes = >B80)
* OBSOLETE 1B80:137F Enemy sprite patterns (64*32 bytes = >800)
* XX00:XXFF Menu Pattern Descriptor Table (256*8 = >800)
* 2380:263F Level Screen Table (32*22 chars = >2C0)
* 2640:28DF Menu Screen Table (32*21 chars = >2A0)
* 28E0:2B5F Menu pattern table backup (20*32 bytes = >280)
* 2B60:     Cave texts

* TODO  Dark dungeon pattern table (256*8 bytes = 800)
* TODO HUD/menu Sprite Pattern Table
* Map dot, items B, Swords, Half-heart, menu cursor
* TODO HUD/menu Sprite List Table
* Map dot, Item B, Sword, Half-Heart, 5th sprites
* TODO HUD/menu Pattern Table (maybe)
* Map background, item border, heart, ti-force pieces, menu items

SCR1TB EQU  >0000    ; Name Table 32*25 bytes (double-buffered)
SCHSAV EQU  >0320    ; Save area for SCRTCH scratchpad/screen list
CLRTAB EQU  >0340    ; Color Table address in VDP RAM - 32 bytes

MUS1RT EQU  >0360    ; Music 1 subpattern return address
MAPSAV EQU  >0362    ; Overworld map saved location when in dungeon
ECOUNT EQU  >0363    ; Count of enemies on screen
MUS2RT EQU  >0364    ; Music 2 subpattern return address
UNUSED EQU  >0366    ; TODO Unused
MUS3RT EQU  >0368    ; Music 3 subpattern return address
KCOUNT EQU  >036A    ; Enemy kill counter (reset to zero if link hurt)
MAZEST EQU  >036B    ; Maze state (0 to 3)
MUS4RT EQU  >036C    ; Music 4 subpattern return address
LADPOS EQU  >036E    ; Ladder Position YYXX, and backup chars - 6 bytes
RECLOC EQU  >0374    ; Recent map locations - 8 bytes

SPRTAB EQU  >0380    ; Sprite List Table address in VDP RAM - 32*4 bytes
MPDTST EQU  SPRTAB    ;  map dot
HARTST EQU  SPRTAB+4  ;  half-heart
ITEMST EQU  SPRTAB+8  ;  selected item
ASWDST EQU  SPRTAB+12 ;  active sword  [menu selector]
HEROST EQU  SPRTAB+16 ;  hero sprites  [menu map, compass]
SWRDST EQU  SPRTAB+24 ;  sword sprite

SCR2TB EQU  >0400    ; Name Table 32*25 bytes (double-buffered)
BCLRTB EQU  >0740    ; Bright Color Table address in VDP RAM - 32 bytes
MCLRTB EQU  >0780    ; Menu Color Table address in VDP RAM - 32 bytes
PATTAB EQU  >0800    ; Pattern Table address in VDP RAM - 256*8 bytes
DRKTAB EQU  >1000    ; Dark Pattern Table for dark dungeons
SPRPAT EQU  >1800    ; Sprite Pattern Table address in VDP RAM - 256*8 bytes
;ENESPR EQU  >1B80    ; Enemy sprite patterns (up to 64) TODO remove

MENTAB EQU  >2000    ; Menu Pattern Table address in VDP RAM - 256*8 bytes
LEVELA EQU  >2800    ; Name table for level A 32*22 (copied to SCR1TB or SCR2TB) TODO move to >2000
MENUSC EQU  >2AC0    ; Name table for menu screen 32*21
PATSAV EQU  >2D60    ; Pattern table backup for menu screen 32*22 bytes
CAVTXT EQU  >3020    ; Cave text

SDATA  EQU  >3300    ; Save Data
SDNAME EQU  SDATA    ; Save Data - save file name, 8 bytes
SDSLOT EQU  SDATA+8  ; Save Data - slot index 0..2
SDHART EQU  SDATA+9  ; Save Data - max hearts 1 byte
SDRUPE EQU  SDATA+10 ; Save Data - rupees 1 byte
SDKEYS EQU  SDATA+11 ; Save Data - keys   1 byte
SDBOMB EQU  SDATA+12 ; Save Data - bombs 5 bits / max bombs 3 bits = 1 byte
SDFLAG EQU  SDATA+13 ; Save Data - item flags (HFLAGS,HFLAG2), 32 bits = 4 bytes
SDCOMP EQU  SDATA+17 ; Save Data - compasses collected, 9 bits = 2 bytes
SDMAPS EQU  SDATA+19 ; Save Data - maps collected, 9 bits = 2 bytes
SDTIFO EQU  SDATA+21 ; Save Data - TiForces collected, 8 bits = 1 byte

SDCAVE EQU  SDATA+24 ; Save Data - opened secret caves, 128 bits = 16 bytes
SDITEM EQU  SDATA+40 ; Save Data - cave items collected, 128 bits = 16 bytes
SDROOM EQU  SDATA+56 ; Save Data - dungeon rooms visited, 256 bits = 32 bytes
SDDUNG EQU  SDATA+88 ; Save Data - dungeon items collected, 256 bits = 32 bytes
SDOPEN EQU  SDATA+120 ; Save Data - dungeon doors unlocked or walls bombed, 512 bits = 64 bytes
SDENEM EQU  SDATA+184 ; Save Data - overworld enemy counts, 4 bits * 128 = 64 bytes
SDEND  EQU  SDATA+248

DNENEM EQU  >3400    ; Dungeon enemy counts, 4 bits * 256 = 128 bytes (cleared when entering dungeon)

ENEMDT EQU  >0760    ; Enemy damage done to hero, enemy drop table (8 bits total)
ENEMSC EQU  >0780    ; Enemy sprite color, saved during hurt animation (8 bits)
ENEMHS EQU  >07A0    ; Enemy hurt/stun counters interleaved:
       ; stun: count=6bits
       ; hurt: direction=2bits count=6bits
ENEMHP EQU  >07E0    ; Enemy HP (8 bits)





* Fast RAM layout
       DORG WRKSP+>20
MUSIC1 DATA 0    ; Music Track 1 duration and pointer
SOUND1 DATA 0    ; Sound Track 1 duration and pointer
MUSIC2 DATA 0    ; Music Track 2 duration and pointer
SOUND2 DATA 0    ; Sound Track 2 duration and pointer
MUSIC3 DATA 0    ; Music Track 3 duration and pointer
SOUND3 DATA 0    ; Sound Track 3 duration and pointer
MUSIC4 DATA 0    ; Music Track 4 duration and pointer
SOUND4 DATA 0    ; Sound Track 4 duration and pointer

HFLAGS DATA 0    ; Hero Flags (part of save data)
SELITM EQU  >0007  ; Selected item mask 0-7

MAGSHD EQU  >0008  ; Magic Shield
ASWORD EQU  >0010  ; Wood  Sword 1x damage (brown)
WSWORD EQU  >0020  ; White Sword 2x damage (white)
MSWORD EQU  >0040  ; Master Sword 4x damage (white slanted)

BOW    EQU  >0080  ; Bow (brown)
ARROWS EQU  >0100  ; Arrows (brown)
LADDER EQU  >0200  ; Ladder (brown)
RAFT   EQU  >0400  ; Raft (brown)
MAGKEY EQU  >0800  ; Magic Key (opens all doors, appears as A in key count)
BMRANG EQU  >1000  ; Boomerang (brown)
FLUTE  EQU  >2000  ; Flute (brown)
BOWARR EQU  >4000  ; Combined bow and arrows
SARROW EQU  >8000  ; Silver arrows (appear blue, double damage)

* order of items that get copied to pattern table
* 80  ladder  raft   brown
* 88  magkey boomer  brown
* 90  arrows flute   brown
* 98  silver boomer  blue
* A0  bombs  candle  blue
* A8  letter potion  blue
* B0  magrod ring    blue
* B8  ring   book    red
* C0  powerb candle  red
* C8  meat   potion  red


*Raft (brown) Book (red) Ring (blue/red) Ladder (brown) Dungeon Key (brown) Power Bracelet (red)
*Boomerang (brown/blue) Bomb (blue) Bow/Arrow (brown/?) Candle (red/blue)
*Flute (brown) Meat (red) Scroll(brown)/Potion(red/blue) Magic Rod (blue)

* Raft  Book  Ring(B/R)  Ladder  MagicKey  PowerBracelet
* Boomerang(Br/Bl)  Bombs  Bow/Arrow  Candle(B/R)
* Flute  Meat  Letter/Potion(B/R)  MagicRod

GRNCLR EQU  >0300  ; Color of hero sprite with no rings
BLUCLR EQU  >0700  ; Color of hero sprite with blue ring
REDCLR EQU  >0800  ; Color of hero sprite with red ring

HFLAG2 DATA 0    ; More hero flags (part of save data)
BOMBSA EQU  >0001  ; Bombs available > 0
MAGBMR EQU  >0002  ; Magic Boomerang (blue)
BCANDL EQU  >0004  ; Blue candle (once per screen)
LETTER EQU  >0008  ; Letter from old man (give to woman allows buying potions)
BLUPOT EQU  >0010  ; Blue potion (refills hearts, turns into letter when used)
MAGROD EQU  >0020  ; Magic Rod (blue)
BLURNG EQU  >0040  ; Blue Ring (take 1/2 damage)
REDRNG EQU  >0080  ; Red Ring (take 1/4 damage)
BOOKMG EQU  >0100  ; Book of Magic (adds flames to magic rod)
PBRACE EQU  >0200  ; Power Bracelet (red)
RCANDL EQU  >0400  ; Red candle (unlimited)
BAIT   EQU  >0800  ; Bait (lures monsters or give to grumble grumble)
REDPOT EQU  >1000  ; Red potion (refills hearts, turns into blue potion when used)
LETPOT EQU  >2000  ; Gave the letter to old woman, potions available
COMPAS EQU  >4000  ; Compass (for current dungeon)
MINMAP EQU  >8000  ; Dungeon map (current dungeon)

KEY_FL DATA 0    ; key press flags
KEY_UP EQU  >0002  ; J1 Up / W
KEY_DN EQU  >0004  ; J1 Down / S
KEY_LT EQU  >0008  ; J1 Left / A
KEY_RT EQU  >0010  ; J1 Right / D
KEY_A  EQU  >0020  ; J1 Fire / J2 Left / Enter
KEY_B  EQU  >0040  ; J2 Fire / J2 Down / Semicolon / E
KEY_C  EQU  >0080  ; J2 Right/ J2 Up / Slash / Q
EDG_UP EQU  KEY_UP*256
EDG_DN EQU  KEY_DN*256
EDG_LT EQU  KEY_LT*256
EDG_RT EQU  KEY_RT*256
EDG_A  EQU  KEY_A*256
EDG_B  EQU  KEY_B*256
EDG_C  EQU  KEY_C*256


TEMPRT DATA 0  ; Temporary saved return address
OBJPTR DATA 0  ; Object pointer for processing sprites
COUNTR DATA 0  ; Counters in bits 6:[15..12] 11:[11..8] 5:[7..5] 16:[4..0]
RAND16 DATA 0  ; Random state
RUPEES DATA 0  ; Rupees to add, can be negative (every other frame) (saved?)

* RAM   00     01     02     03     04     05     06     07
* 8320  TRACK1        SOUND1        TRACK2        SOUND2
* 8328  TRACK3        SOUND3        TRACK4        SOUND4
* 8330  HFLAGS        HFLAG2        KEY_FL        TEMPRT
* 8338  OBJPTR        COUNTR        RAND16        RUPEES
* 8340  MAPLOC HP     CAVTYP ______ ENEGRP        PSHBLK
* 8348  FLAGS         DOOR          SWRDOB        BSWDOB
* 8350  ARRWOB        BMRGOB        FLAMOB        BOMBOB
* 8358   20 enemies +
*  ...
* 8380  sprite list

; Sprite function array (64 bytes), for each sprite:
;   index byte of sprite function to call: 6 bits, flags hurt and stun: 1 bit
;   other byte of data (counter, direction, etc)

       DORG WRKSP+>40
OBJECT EQU  $  ; 64 bytes: sprite function index (6 bits) hurt/stun (1 bit) and data (9 bits)
MAPLOC BYTE 0  ; Map location YX 16x8 or 16x16(dungeon)
HP     BYTE 0  ; Hit points (max 2x hearts, 4x hearts, 8x hearts, depending on ring)
CAVTYP BYTE 0  ; Cave type (NPC / dungeon)

RESERVED BYTE 0   ; FIXME fill or remove  (maybe MAZEST)
ENEGRP DATA 0  ; Enemy group table: GROUPn from bank 5
PSHBLK DATA 0  ; Pushable block location YYXX

FLAGS  DATA 0  ; Various Flags
INCAVE EQU  >0001  ; Inside cave
FULLHP EQU  >0002  ; Full hearts, able to use beam sword
DARKRM EQU  >0004  ; Dungeon room darkened
SLOWMV EQU  >0008  ; Slow movement (on stairs)

PUSHC  EQU  >00F0  ; pushing block/keydoor counter 0..14

DIR_XX EQU  >0300  ; Facing bits DIR_XX
DIR_RT EQU  >0000
DIR_LT EQU  >0100
DIR_DN EQU  >0200
DIR_UP EQU  >0300
SCRFLG EQU  >0400  ; Double-buffered screen flag, NOTE: must be equal to SCR2TB
       ; TODO  make sure SCR1TB is selected all the time except during scrolling
       ; TODO then SCRFLAG won't need to be checked during TESTCH etc.
ENEDGE EQU  >0800  ; TODO Enemies load from edge of screen
DUNLVL EQU  >F000  ; Current dungeon level 1-9 (0=overworld)

DOOR   DATA 0  ; YYXX position of doorway or secret

* TODO enemy kill counter up to 10
* TODO additional bomb/fairy counter?
* TODO Bait active flag (draws enemies to it)
* TODO Clock active flag (keep enemies frozen in place, flashing state)

OBJMSK EQU >003F  ; 6 bits for object type
SWRDOB BYTE 0  ; Sword animation counter 0-12
HURTC  BYTE 0  ; Link hurt animation counter (8 frames knockback, 40 more frames invincible)
BSWDOB DATA 0  ; Beam sword/Magic counter
ARRWOB DATA 0  ; Arrow counter
BMRGOB DATA 0  ; Boomerang counter
FLAMOB DATA 0  ; Flame counter
BOMBOB DATA 0  ; Bomb counter
MOVEOB DATA 0,0,0,0,0,0,0,0,0,0  ; 20 slots for moving objects
       DATA 0,0,0,0,0,0,0,0,0,0
LASTOB

       .IFNE $, WRKSP+>80
       .ERROR 'Fast RAM data wrong size'
       .ENDIF

       DORG WRKSP+>80
SPRLST EQU  $  ; 128 bytes sprite list, copied to VDP by SPRUPD
       DATA 0,0  ; unused: was 0 Status bar sprites (mapdot, item, sword, half-heart)
       DATA 0,0  ; unused: was 1 Life bar half-heart sprite
       DATA 0,0  ; unused: was 2 Selected item
       DATA 0,0  ; unused: was 3 Active sword
HEROSP DATA 0,0,0,0  ; 4,5 Hero sprites (color and outline)
SWRDSP DATA 0,0  ; 6 Sword/Magic Rod
BSWDSP DATA 0,0  ; 7 Beam sword/Magic (Magic overrides beam sword)
ARRWSP DATA 0,0  ; 8 Arrow
BMRGSP DATA 0,0  ; 9 Boomerang
FLAMSP DATA 0,0  ; 10 Candle flame
BOMBSP DATA 0,0  ; 11 Bomb
LASTSP DATA 0,0, 0,0, 0,0, 0,0  ; 12-31 Movable Objects (20)
       DATA 0,0, 0,0, 0,0, 0,0
       DATA 0,0, 0,0, 0,0, 0,0
       DATA 0,0, 0,0, 0,0, 0,0
       DATA 0,0, 0,0, 0,0, 0,0

SCRTCH EQU  WRKSP+>E0       ; 32 bytes scratchpad for screen scrolling (overlaps sprite list)

       .IFNE $, WRKSP+>100
       .ERROR 'Fast RAM sprite data wrong size'
       .ENDIF

* Some sprites and color
CLOUD1 EQU >D00F    ; Cloud full
CLOUD2 EQU >D40F    ; Cloud mid
CLOUD3 EQU >D80F    ; Cloud sparse
BULLSC EQU >6006    ; Octorok bullet, red
FARYSC EQU >F409    ; Fairy
HRT2SC EQU >C806    ; Heart
SPARK  EQU >DC0F    ; Spark, white
BOOMSC EQU >900A    ; normal boomerang, brown
MBOMSC EQU >9004    ; magic boomerang, blue
MRODSC EQU >0804    ; Magic Rod sprite, blue
ARMOSC EQU >1000    ; Armos, transparent
PULSEC EQU >2809    ; Pulsing sprite, light red
RAFTSC EQU >1C0A    ; Raft sprite index, dark yellow
GHINIC EQU >200F    ; Ghini, white
RUPEEY EQU >C00A    ; Yellow Rupee
RUPEEB EQU >C005    ; Blue Rupee
ZBULSC EQU >6406    ; Zora Bullet Red
SHLDSC EQU >3C09    ; Shield
BAITSC EQU >3409    ; Bait
BLURSC EQU >3004    ; Blue ring
BOMBSC EQU >C404    ; Bomb is C4 lol
ARRWSC EQU >AC0B    ; Arrow
BCDLSC EQU >3804    ; Blue Candle
LTTRSC EQU >2804    ; Letter
BPTNSC EQU >2C04    ; Blue Potion
RPTNSC EQU >2C06    ; Red Potion
BOW_SC EQU >180B    ; Bow
KEY_SC EQU >680B    ; Key
MAP_SC EQU >680A    ; Map
COMPSC EQU >6809    ; Compass
TIFOSC EQU >680F    ; TiForce
HRTCSC EQU >6806    ; Heart Container

NSWORC EQU >7C00    ; No sword A-box sprite
ASWORC EQU >7C09    ; wood sword A-box sprite
WSWORC EQU >7C0F    ; white sword A-box sprite
MSWORC EQU >FC0F    ; master sword A-box sprite

ABOXYX EQU >0495    ; A-box sprite coordinates YYXX
BBOXYX EQU >047C    ; B-box sprite coordinates YYXX


* Cartridge memory space
CARTAD EQU >6000             ; Cartridge address space
CARTED EQU CARTAD+>1FFF      ; Cartridge space end
BANK0W EQU CARTAD             ; Bank 0 write address
BANK1W EQU CARTAD+2           ; Bank 1 write address
BANK2W EQU CARTAD+4           ; Bank 2 write address
BANK3W EQU CARTAD+6           ; Bank 3 write address
BANK4W EQU CARTAD+8           ; Bank 4 write address
BANK5W EQU CARTAD+10          ; Bank 5 write address
BANK6W EQU CARTAD+12          ; Bank 6 write address
BANK7W EQU CARTAD+14          ; Bank 7 write address

       SAVE CARTAD,CARTAD+>2000  ; Assembler writes full 8K banks

       AORG CARTAD
***************************************************************
       BANK ALL
***************************************************************
       BYTE >AA     ; Standard header
       BYTE >00     ; Version number 1
       BYTE >01     ; Number of programs (optional)
       BYTE >00     ; Reserved (for FG99 this can be G,R,or X)
       DATA >0000   ; Pointer to power-up list
       DATA PRGLST  ; Pointer to program list
       DATA >0000   ; Pointer to DSR list
       ;DATA >0000   ; Pointer to subprogram list  (this doubles as next program list entry)

PRGLST DATA >0000   ; Next program list entry
       DATA START   ; Program start address
       STRI 'LEGEND OF TILDA'
       EVEN


START  CLR @BANK0W
       JMP x#MAIN

* Copy R2 bytes from R1 to VDP address R0
VDPW   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
!      MOVB *R1+,*R15       ; Write byte to VDP RAM
       DEC  R2              ; Byte counter
       JNE  -!              ; Check if done
       RT

* Write one byte from R1 to VDP address R0
VDPWB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       RT

* Read one byte to R1 from VDP address R0 (R0 is preserved, R1LB is zeroed)
VDPRB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       LI R1,VDPRD          ; Very important delay for 9918A prefetch, otherwise glitches can occur
       MOVB *R1,R1
       RT

* Read R2 bytes to R1 from VDP address R0 (R0 is preserved)
VDPR   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       NOP                  ; Very important delay for 9918A prefetch, otherwise glitches can occur
!      MOVB @VDPRD,*R1+
       DEC R2
       JNE -!
       RT


* Write VDP register R0HB data R0LB
VDPREG MOVB @R0LB,*R14      ; Send low byte of VDP Register Data
       ORI  R0,VDPRM        ; Set register access bit
       MOVB R0,*R14         ; Send high byte of VDP Register Number
       RT


; Note: BANKnX must be followed by DATA target address in new bank
; Return address R11 is modified to return after DATA
; otherwise BANKn must be called with target address in R13
BANK1X MOV *R11+,R13
BANK1  CLR @BANK1W       ; sprload.asm, enemload.asm
       B *R13

BANK2X MOV *R11+,R13
BANK2  CLR @BANK2W       ; map.asm
       B *R13

BANK3X MOV *R11+,R13
BANK3  CLR @BANK3W       ; tiles.asm
       B *R13

BANK4X MOV *R11+,R13
BANK4  CLR @BANK4W       ; herospr.asm, keys.asm, gameover.asm
       B *R13

BANK5X MOV *R11+,R13
BANK5  CLR @BANK5W       ; movobj.asm, status.asm
       B *R13

BANK6X MOV *R11+,R13
BANK6  CLR @BANK6W
       B *R13

BANK7X MOV *R11+,R13
BANK7  CLR @BANK7W
       B *R13

* Bank 0 last, to take advantage of JMP for returning to bank 0
BANK0X MOV *R11+,R13
BANK0  CLR @BANK0W       ; main.asm, hero.asm, scroll.asm
       B *R13

***************************************************************
       BANK 0
***************************************************************

VDPINI
       BYTE >00          ; VDP Register 0: 00
       BYTE >E2          ; VDP Register 1: 16x16 Sprites
       BYTE >00          ; VDP Register 2: 00
       BYTE >00+(CLRTAB/>40)  ; VDP Register 3: Color Table
       BYTE >00+(PATTAB/>800) ; VDP Register 4: Pattern Table
       BYTE >00+(SPRTAB/>80)  ; VDP Register 5: Sprite List Table
       BYTE >00+(SPRPAT/>800) ; VDP Register 6: Sprite Pattern Table
       BYTE >F1          ; VDP Register 7: White on Black

SPRINI ; initial sprite list entries
       DATA >D2D0,>E002  ; Map dot
       DATA >D2C8,>E406  ; Half-heart
       DATA BBOXYX,>F800  ; B item
       DATA ABOXYX,>7C00  ; Sword item
       DATA >7078         ; Hero YYXX
       DATA GRNCLR/256     ; Sprite 0, green
       DATA >0401          ; Sprite 1, black

MAIN
       LIMI 0      ; Interrupts off
       LWPI WRKSP  ; Set workspace pointer

       LI R14,VDPWA
       LI R15,VDPWD

       SETO @RAND16          ; random seed must be nonzero


       LI R1,VDPINI         ; Load initial VDP registers
       LI R0,VDPRM
!      MOVB *R1+,*R14       ; Send low byte of VDP Register Data
       MOVB R0,*R14         ; Send high byte of VDP Register Number
       AI R0,>0100
       CI R0,>0800+VDPRM
       JL -!

       BL @BANK3X
       DATA x#LTITLE       ; Load title tiles in bank3

       BL @BANK3X
       DATA x#OWTILE       ; Load overworld tiles in bank3

       LI R0,SDHART
       LI R1,SDDEFS        ; Load default save data
       LI R2,SDEND-SDHART
       BL @VDPW

RESTRT
       ; Load flags from save data
       LI R0,SDFLAG   ; saved data flags in VDP RAM
       LI R1,HFLAGS   ; hero flags in CPU RAM
       LI R2,4        ; both HFLAGS and HFLAG2
       BL @VDPR

       LI R0,SPRTAB   ; initialize the first four sprites
       LI R1,SPRINI
       LI R2,4*4      ; 4 32x32 sprites
       BL @VDPW

       MOV *R1,@HEROSP      ; initialize hero sprite
       MOV *R1+,@HEROSP+4
       MOV *R1+,@HEROSP+2
       MOV *R1+,@HEROSP+6

       LI R0,~DUNLVL
       SZC R0,@FLAGS     ; Reset flags (except dungeon)
       BL @LNKCLR        ; Reset hero color and hurt counter

       LI R0,DIR_UP        ; Set direction up
       SOC R0,@FLAGS

       ;LI   R1,>7700         ; Initial map location is 7,7 (5,3 is by fairy)(3,7 is D-1,)
       ;LI R1,>2100            ; Dungeons: 37, 3C, 74, 45, 0B, 22, 42, 6D, 05
       LI R1,>0500            ; temporary starting location
       MOVB R1,@MAPLOC


       LI R0,>0A00           ; Initial HP - 3 hearts
       MOV @HFLAG2,R1
       ANDI R1,REDRNG+BLURNG
       JEQ !
       A R0,R0               ; adjusted for blue ring
       ANDI R1,REDRNG
       JEQ !
       A R0,R0               ; adjusted for red ring
!
       MOVB R0,@HP

       CLR R2           ; R2=sprite index to load  R2LB=count
       BL @BANK1X
       DATA x#LOADSP    ; Load sprite patterns

       BL @GETSEL       ; Get currently selected item and sword sprites

       LI R9,32-6
       LI R1,SWRDOB     ; Clear object table, starting at sword
!      CLR *R1+
       DEC R9
       JNE -!

       LI R0,>D200
       LI R9,(32-6)*2
       LI R1,SWRDSP        ; Clear sprite list starting at sword
!      MOV R0,*R1+
       DEC R9
       JNE -!



       BL @BANK2X
       DATA x#LOADSC    ; Load map into screen at current position

       BL @BANK5X
       DATA x#STATS     ; Draw status bar information

       BL @BANK6X
       DATA x#LMUSIC     ; Load music for overworld/dungeon

       CLR @SOUND1       ; clear all sound effects
       CLR @SOUND2
       CLR @SOUND3
       CLR @SOUND4


       LI R0,>D200
       LI R9,16
       LI R1,SCRTCH        ; FIXME Fill scratch again
!      MOV R0,*R1+
       DEC R9
       JNE -!

       BL @WIPE           ; Wipe transition


       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       BL @BANK4X
       DATA x#LNKSPR      ; Load standing sprites R3=dir

       CLR @SWRDOB        ; Reset sword counter

       ; FIXME temporary code for testing dungeons
       ;LI R2,>2300
       ;B @GODUNG


MAINLP                  ; Main loop
       BL @!SPRUPD        ; Copy sprite list to VDP

       BL @BANK5X
       DATA x#MOVOBJ     ; Do moving objects (enemies and projectiles)
MOVOBX ; MOVOBJ returns here

       BL @VSYNCM        ; Wait for vertical sync and play music

       BL @BANK4X
       DATA x#DOKEY0      ; Read joystick/keys (return to bank 0)

       BL @COUNT          ; Increment counters (and animate fire/fairy, count up/down rupees)

       MOV @KEY_FL, R0
       SLA R0,1           ; Shift EDG_C bit into carry status
       JNC MENUX
       B @DOMENU        ; show menu item select screen
MENUX ; DOMENU returns here

       ; Hero actions
       COPY "hero.asm"
       ; NOTE: does not return, will branch to MAINLP elsewhere


* Update Sprite List to VDP Sprite Table (with flicker)
* Modifies R0-R3
!SPRUPD
       LI R0,HEROST+VDPWM  ; Copy to VDP Sprite Table starting at hero
       LI R1,HEROSP    ; from Sprite List in CPU starting at hero
       LI R2,2         ; Copy hero sprites first
       CLR R3          ; Direction 0=forward -8=backward
       MOVB @R0LB,*R14 ; VDP Write address
       MOVB R0,*R14    ; VDP Write address

!      MOVB *R1+,R0
       AI R0,->0100   ; adjust Y
       MOVB R0,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       A R3,R1      ; Move to next sprite (or previous)
       DEC R2
       JNE -!

       CI R1,SWRDSP   ; check for flickering at sword sprite
       JNE !        ; done?

       LI R2,32-6   ; Copy remaining sprites
       MOV @COUNTR,R0
       SRC R0,1
       JOC  -!      ; every other frame
       ; do in reverse order (flickering)
       LI R1,SPRLST+(4*31)
       LI R3,-8
       JMP -!
!      ; jumped to by TESTCH, below
       RT

* Look at character at pixel coordinate in R0, and jump to R2 if solid
* Modifies R0,R1 (returns character in R1)
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

       CI R1,>7E00  ; Characters >7E and higher are solid
       JL -!        ; nearest RT
       B *R2        ; Jump alternate return address

; TODO move this to bank 6
* Modifies R0-R3,R10,R12,R13
VSYNC0 ; vsync and music, called from bank 4 gameover
       MOV R11,R10     ; Save return address
       BL @VSYNCM
       ; return to bank4
       MOV R10,R13
       B @BANK4        ; Return to saved address in bank 4

* Modifies R0-R3, R12,R13
VSYNCM
       ; TODO move vsync to bank 6
       CLR R12               ; CRU Address bit 0002 - VDP INT
!      TB 2                  ; CRU bit 2 - VDP INT
       JEQ -!                ; Loop until set
       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU

       LI R13,x#MUSICP      ; play music in bank 6
       B @BANK6             ; return to R11 after bankswitch

* Modifies R0-R4,R10,R12,R13
DLAY10
       MOV R11,R10    ; Save return address
       LI R4,10
!      BL @VSYNCM
       DEC R4
       JNE -!
       B *R10


* Mute all the sound channels and clear the music pointers
* Modifies R0,R1
QUIET
       LI R0,MUTESB
       LI R1,SNDREG
       MOVB *R0+,*R1
       MOVB *R0+,*R1
       MOVB *R0+,*R1
       MOVB *R0+,*R1
       CLR @MUSIC1
       CLR @MUSIC2
       CLR @MUSIC3
       CLR @MUSIC4
       RT
MUTESB BYTE >9F,>BF,>DF,>FF  ; mute sound bytes

QUIET4   ; QUIET called from bank 4
       MOV R11,R13 ; save return address
       BL @QUIET
       B @BANK4    ; return to saved address in bank 4

       COPY "scroll.asm"     ; Scrolling - do screen wipe and scroll up/down/left/right
       COPY "counters.asm"   ; Counters and animate fire/fairy
       COPY "menu.asm"       ; Menu and item selection

       .PRINT "Bank 0 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 0 program too large'
       .ENDIF

SDDEFS ; Save data default values
       BYTE >05      ; Save Data - max hearts 1 byte
       BYTE >55      ; Save Data - rupees 1 byte
       BYTE >01      ; Save Data - keys   1 byte
       BYTE >0A      ; Save Data - bombs 5 bits / max bombs 3 bits = 1 byte
       DATA ASWORD+BOW+LADDER+RAFT+BMRANG+FLUTE  ; Save Data - item flags (HFLAGS,HFLAG2), 32 bits = 4 bytes
       DATA >0000+BOMBSA+BCANDL+MAGROD+BOOKMG+PBRACE+RCANDL+BAIT
       DATA >0000    ; Save Data - compasses collected, 9 bits = 2 bytes
       DATA >0000    ; Save Data - maps collected, 9 bits = 2 bytes
       BYTE >00      ; Save Data - TiForces collected, 8 bits = 1 byte

       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - opened secret caves, 128 bits = 16 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - cave items collected, 128 bits = 16 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - dungeon rooms visited, 256 bits = 32 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - dungeon items collected, 256 bits = 32 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - dungeon doors unlocked or walls bombed, 512 bits = 64 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000 ; Save Data - overworld enemy counts, 4 bits * 128 = 64 bytes
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000
       DATA >0000,>0000,>0000,>0000,>0000,>0000,>0000,>0000

***************************************************************
       BANK 1   ; Compressed sprites, load enemies
***************************************************************
       COPY "sprload.asm"
       COPY "enemload.asm"

       .PRINT "Bank 1 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 1 program too large'
       .ENDIF

***************************************************************
       BANK 2   ; overworld map, cave, dungeon map
***************************************************************
       COPY "map.asm"

       .PRINT "Bank 2 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 2 program too large'
       .ENDIF

***************************************************************
       BANK 3   ; compressed data: title screen, overworld tiles, dungeon tiles
***************************************************************
       COPY "tiles.asm"

       .PRINT "Bank 3 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 3 program too large'
       .ENDIF

***************************************************************
       BANK 4   ; title screen animation, game over animation, hero sprites
***************************************************************

       COPY "herospr.asm"
       COPY "keys.asm"
       COPY "gameover.asm"

DOKEY0
       MOV R11,R13   ; Save return address in bank0
       BL @DOKEYS
       B @BANK0

       .PRINT "Bank 4 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 4 program too large'
       .ENDIF

***************************************************************
       BANK 5  ; moving objects (enemies, projecties) and collision detection
***************************************************************

       COPY "movobj.asm"
       COPY "status.asm"

* Modifies R0-R3,R7-R12
STATS  ; status called from bank 0
       MOV R11,R13  ; Save return address in bank0
       BL @STATUS
       B @BANK0

       .PRINT "Bank 5 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 5 program too large'
       .ENDIF

***************************************************************
       BANK 6  ; overworld+dungeon music and sounds
***************************************************************

* Play music and sounds, returns to bank0
MUSICP
       MOV R11,R13   ; Save return address

       COPY "player.asm"

       B @BANK0      ; Return to saved address


* Load overword or dungeon music
* Modifies R0,R1
LMUSIC
       MOV R11,R13   ; Save return address

       LI R1,MUSICO  ; overworld
       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !
       LI R1,MUSICD  ; dungeon
       CI R0,>9000
       JNE !
       LI R1,MUSIC9  ; dungeon 9
!
       MOV *R1+,@MUSIC1
       MOV *R1+,@MUSIC2
       MOV *R1+,@MUSIC3
       MOV *R1+,@MUSIC4
       B @BANK0      ; Return to saved address

MUSICO DATA TSF00,TSF01,TSF02,TSF03  ; Overworld music pointers
MUSICD DATA TSF10,TSF11,TSF12,0      ; Dungeon music pointers
MUSIC9 DATA TSF20,TSF21,TSF22,0      ; Dungeon level 9 music pointers

       ; Music data for overworld and dungeon
       COPY "tilda_music2.asm"

       .PRINT "Bank 6 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 6 program too large'
       .ENDIF

***************************************************************
       BANK 7  ; title+finale music and sounds
***************************************************************

       ; Music data for title screen, ending, game over?
       ;COPY "tilda_music1.asm"

       .PRINT "Bank 7 size", $-CARTAD
       .IFGT $,CARTED
       .ERROR 'Bank 7 program too large'
       .ENDIF

