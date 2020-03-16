;
; tilda.asm
; Copyright (c) 2017 Pete Eberlein

; Cartridge header and common functions

; GENEVE EQU 1 ; Uncomment for GENEVE version

       .IFDEF GENEVE
VDPWD  EQU  >F100             ; VDP write data
VDPWA  EQU  >F102             ; VDP set read/write address
VDPRD  EQU  >F100             ; VDP read data (don't forget NOP after address)
VDPSTA EQU  >F102             ; VDP status
VDPWM  EQU  >4000             ; VDP address write mask
VDPRM  EQU  >8000             ; VDP address register mask

SNDREG EQU  >F120             ; Sound register address
       .ELSE
VDPWD  EQU  >8C00             ; VDP write data
VDPWA  EQU  >8C02             ; VDP set read/write address
VDPRD  EQU  >8800             ; VDP read data (don't forget NOP after address)
VDPSTA EQU  >8802             ; VDP status
VDPWM  EQU  >4000             ; VDP address write mask
VDPRM  EQU  >8000             ; VDP address register mask

SNDREG EQU  >8400             ; Sound register address
       .ENDIF

ISRCTL EQU  >83C2             ; Four flags: disable all, skip sprite, skip sound, skip QUIT
USRISR EQU  >83C4             ; Interrupt service routine hook address

WRKSP  EQU  >8300             ; Workspace memory in fast RAM
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


; VDP Map
; 0000:031F Screen Table A (32*25 = >320)
; 0320:033F Save area scratchpad/sprite list (>20)
; 0340:035F Color Table (32 bytes = >20)
; 0360:037F Music Save pointers (8 bytes) MapSav(1),Ecount(1),R12SAV(2),LadPos(6)
;           Recent map locations (8 bytes)
; 0380:03FF Sprite List Table (32*4 bytes = >80)
; 0400:071F Screen Table B (32*25 = >320)
; 0720:073F
; 0740:075F Bright Color Table (32 bytes = >20)
; 0760:077F Enemy Drop table index and status flags (32 bytes = >20)
; 0780:079F Menu Color Table (32 bytes = >20)
; 07A0:07DF Enemy Hurt/Stun Counters interleaved (64 bytes = >40)
; 07E0:07FF Enemy HP (32 bytes = >20)
; 0800:0FFF Overworld/Dungeon Pattern Descriptor Table (256*8 = >800)
; 1000:1B7F Sprite Pattern Table (64*32 + 28*32 bytes = >B80)
; 1B80:137F Enemy sprite patterns (64*32 bytes = >800)
; 2380:263F Level Screen Table (32*22 chars = >2C0)
; 2640:28DF Menu Screen Table (32*21 chars = >2A0)
; 28E0:2B5F Menu pattern table backup (20*32 bytes = >280)
; 2B60:     Cave texts

; TODO  Dark dungeon pattern table (256*8 bytes = 800)
; TODO HUD/menu Sprite Pattern Table
       ; Map dot, items B, Swords, Half-heart, menu cursor
; TODO HUD/menu Sprite List Table
       ; Map dot, Item B, Sword, Half-Heart, 5th sprites
; TODO HUD/menu Pattern Table (maybe)
       ; Map background, item border, heart, ti-force pieces

SCR1TB EQU  >0000    ; Name Table 32*25 bytes (double-buffered)
SCHSAV EQU  >0320    ; Save area for SCRTCH scratchpad/screen list
CLRTAB EQU  >0340    ; Color Table address in VDP RAM - 32 bytes

MUS1RT EQU  >0360    ; Music 1 subpattern return address 
MAPSAV EQU  >0362    ; Overworld map saved location when in dungeon
ECOUNT EQU  >0363    ; Count of enemies on screen
MUS2RT EQU  >0364    ; Music 2 subpattern return address 
R12SAV EQU  >0366    ; Saving R12 in bank 5
MUS3RT EQU  >0368    ; Music 3 subpattern return address
KCOUNT EQU  >036A    ; Enemy kill counter (reset to zero if link hurt)
MAZEST EQU  >036B    ; Maze state (0 to 3)
MUS4RT EQU  >036C    ; Music 4 subpattern return address
LADPOS EQU  >036E    ; Ladder Position YYXX, and backup chars - 6 bytes
RECLOC EQU  >0374    ; Recent map locations - 8 bytes

SPRTAB EQU  >0380    ; Sprite List Table address in VDP RAM - 32*4 bytes
SCR2TB EQU  >0400    ; Name Table 32*25 bytes (double-buffered)
BCLRTB EQU  >0740    ; Bright Color Table address in VDP RAM - 32 bytes
MCLRTB EQU  >0780    ; Menu Color Table address in VDP RAM - 32 bytes
PATTAB EQU  >0800    ; Pattern Table address in VDP RAM - 256*8 bytes
SPRPAT EQU  >1000    ; Sprite Pattern Table address in VDP RAM - 256*8 bytes
ENESPR EQU  >1B80    ; Enemy sprite patterns (up to 64) TODO remove
DARKPT EQU  >1800    ; TODO Dark Pattern Table for dark dungeons

LEVELA EQU  >2380    ; Name table for level A 32*25 (copied to SCR1TB or SCR2TB) TODO move to >2000
MENUSC EQU  >2640    ; Name table for menu screen
PATSAV EQU  >28E0    ; Pattern table backup for menu screen 32*22 bytes
CAVTXT EQU  >2BA0    ; Cave text

SDATA  EQU  >2E00    ; Save Data
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

DNENEM EQU  >2F00    ; Dungeon enemy counts, 4 bits * 256 = 128 bytes (cleared when entering dungeon)

ENEMDT EQU  >0760    ; Enemy damage done to here, enemy drop table (8 bits total)
ENEMHS EQU  >07A0    ; Enemy hurt/stun counters interleaved:
                     ; stun: count=6bits
                     ; hurt: direction=2bits count=6bits
ENEMHP EQU  >07E0    ; Enemy HP (8 bits)

CNDLUS EQU  >0008    ; TODO Candle used, once per screen (blue candle only, locate at Flame HP)


; CPU RAM layout
; 8300:  32 bytes - workspace
; 8320:  32 bytes - global variables
; 8340:  64 bytes - moving object index and data
; 8380: 128 bytes - sprite list
; 83E0:  32 bytes - scratchpad (overlaps sprite list)

; 00: workspace R0-R7
; 10: workspace R8-R15
; 20: globals
; 30: globals
; 40: objects 0-7    (0-6 are unused)
; 50: objects 8-15
; 60: objects 16-23
; 70: objects 24-31
; 80: sprites 0-3    (status sprites could be freed? - in VDP RAM only)
; 90: sprites 4-7
; A0: sprites 8-11
; B0: sprites 12-15
; C0: sprites 16-19
; D0: sprites 20-23
; E0: sprites 24-27  (scratchpad)
; F0: sprites 28-31  (scratchpad)

MUSICP EQU  WRKSP+32        ; Music Pointer
MUSICC EQU  WRKSP+34        ; Music Counter


MUSIC1 EQU WRKSP+32         ; Music Track 1 duration and pointer
SOUND1 EQU WRKSP+34         ; Sound Track 1 duration and pointer

MUSIC2 EQU WRKSP+36         ; Music Track 2 duration and pointer
SOUND2 EQU WRKSP+38         ; Sound Track 2 duration and pointer

MUSIC3 EQU WRKSP+40         ; Music Track 3 duration and pointer
SOUND3 EQU WRKSP+42         ; Sound Track 3 duration and pointer

MUSIC4 EQU WRKSP+44         ; Music Track 4 duration and pointer
SOUND4 EQU WRKSP+46         ; Sound Track 4 duration and pointer


MOVE12 EQU  WRKSP+48        ; Movement by 1 or 2


HFLAGS EQU  WRKSP+50        ; Hero Flags (part of save data)
SELITM EQU  >0007            ; Selected item mask 0-7

MAGSHD EQU  >0008            ; Magic Shield
ASWORD EQU  >0010            ; Wood  Sword 1x damage (brown)
WSWORD EQU  >0020            ; White Sword 2x damage (white)
MSWORD EQU  >0040            ; Master Sword 4x damage (white slanted)

BOW    EQU  >0080            ; Bow (brown)
ARROWS EQU  >0100            ; Arrows (brown)
LADDER EQU  >0200            ; Ladder (brown)
RAFT   EQU  >0400            ; Raft (brown)
MAGKEY EQU  >0800            ; Magic Key (opens all doors, appears as A in key count)
BMRANG EQU  >1000            ; Boomerang (brown)
FLUTE  EQU  >2000            ; Flute (brown)
BOWARR EQU  >4000            ; Combined bow and arrows
SARROW EQU  >8000            ; Silver arrows (appear blue, double damage)

; order of items that get copied to pattern table
; 80  ladder  raft   brown
; 88  magkey boomer  brown
; 90  arrows flute   brown
; 98  silver boomer  blue
; A0  bombs  candle  blue
; A8  letter potion  blue
; B0  magrod ring    blue
; B8  ring   book    red
; C0  powerb candle  red
; C8  meat   potion  red


;Raft (brown) Book (red) Ring (blue/red) Ladder (brown) Dungeon Key (brown) Power Bracelet (red)
;Boomerang (brown/blue) Bomb (blue) Bow/Arrow (brown/?) Candle (red/blue)
;Flute (brown) Meat (red) Scroll(brown)/Potion(red/blue) Magic Rod (blue)

; Raft  Book  Ring(B/R)  Ladder  MagicKey  PowerBracelet
; Boomerang(Br/Bl)  Bombs  Bow/Arrow  Candle(B/R)
; Flute  Meat  Letter/Potion(B/R)  MagicRod

GRNCLR EQU  >0300            ; Color of hero sprite with no rings
BLUCLR EQU  >0700            ; Color of hero sprite with blue ring
REDCLR EQU  >0800            ; Color of hero sprite with red ring

HFLAG2 EQU  WRKSP+52         ; More hero flags (part of save data)
BOMBSA EQU  >0001            ; Bombs available > 0
MAGBMR EQU  >0002            ; Magic Boomerang (blue)
BCANDL EQU  >0004            ; Blue candle (once per screen)
LETTER EQU  >0008            ; Letter from old man (give to woman allows buying potions)
BLUPOT EQU  >0010            ; Blue potion (refills hearts, turns into letter when used)
MAGROD EQU  >0020            ; Magic Rod (blue)
BLURNG EQU  >0040            ; Blue Ring (take 1/2 damage)
REDRNG EQU  >0080            ; Red Ring (take 1/4 damage)
BOOKMG EQU  >0100            ; Book of Magic (adds flames to magic rod)
PBRACE EQU  >0200            ; Power Bracelet (red)
RCANDL EQU  >0400            ; Red candle (unlimited)
BAIT   EQU  >0800            ; Bait (lures monsters or give to grumble grumble)
REDPOT EQU  >1000            ; Red potion (refills hearts, turns into blue potion when used)
LETPOT EQU  >2000            ; Gave the letter to old woman, potions available
COMPAS EQU  >4000            ; Compass (for current dungeon)
MINMAP EQU  >8000            ; Dungeon map (current dungeon)

KEY_FL EQU WRKSP+54         ; key press flags
KEY_UP EQU  >0002           ; J1 Up / W
KEY_DN EQU  >0004           ; J1 Down / S
KEY_LT EQU  >0008           ; J1 Left / A
KEY_RT EQU  >0010           ; J1 Right / D
KEY_A  EQU  >0020           ; J1 Fire / J2 Left / Enter
KEY_B  EQU  >0040           ; J2 Fire / J2 Down / Semicolon / E
KEY_C  EQU  >0080           ; J2 Right/ J2 Up / Slash / Q
EDG_UP EQU  KEY_UP*256
EDG_DN EQU  KEY_DN*256
EDG_LT EQU  KEY_LT*256
EDG_RT EQU  KEY_RT*256
EDG_A  EQU  KEY_A*256
EDG_B  EQU  KEY_B*256
EDG_C  EQU  KEY_C*256


OBJPTR EQU  WRKSP+56        ; Object pointer for processing sprites
COUNTR EQU  WRKSP+58        ; Counters in bits 6:[15..12] 11:[11..8] 5:[7..5] 16:[4..0]
RAND16 EQU  WRKSP+60        ; Random state
RUPEES EQU  WRKSP+62        ; Rupees to add, can be negative (every other frame) (saved?)

* RAM   00     01     02     03     04     05     06     07
* 8320  TRACK1        SOUND1        TRACK2        SOUND2
* 8328  TRACK3        SOUND3        TRACK4        SOUND4
* 8330  MOVE12        HFLAGS        HFLAG2        KEY_FL
* 8338  OBJPTR        COUNTR        RAND16        RUPEES
* 8340  HURTC         HP     MAPLOC CAVTYP ______ ______ ______
* 8348  DOOR          FLAGS         SWRDOB        BSWDOB
* 8350  ARRWOB        BMRGOB        FLAMOB        BOMBOB
* 8358  enemies
*  ...
* 8380  sprite list

OBJECT EQU  WRKSP+64        ; 64 bytes: sprite function index (6 bits) hurt/stun (1 bit) and data (9 bits)
HURTC  EQU  OBJECT+0        ; Link hurt animation counter (8 frames knockback, 40 more frames invincible)

HP     EQU  OBJECT+2        ; Hit points (max 2x hearts, 4x hearts, 8x hearts, depending on ring)
MAPLOC EQU  OBJECT+3        ; Map location YX 16x8
CAVTYP EQU  OBJECT+4        ; Cave type (NPC / dungeon)

DOOR   EQU  OBJECT+8        ; YYXX position of doorway or secret

FLAGS  EQU  OBJECT+10       ; Various Flags
INCAVE EQU  >0001            ; Inside cave
FULLHP EQU  >0002            ; Full hearts, able to use beam sword
DARKRM EQU  >0004            ; Dungeon room darkened
MOVEBY EQU  >0008            ; TODO Move player by 1 or 2

PUSHC  EQU  >00F0            ; pushing block/keydoor counter 0..14

DIR_XX EQU  >0300            ; Facing bits DIR_XX
DIR_RT EQU  >0000
DIR_LT EQU  >0100
DIR_DN EQU  >0200
DIR_UP EQU  >0300
SCRFLG EQU  >0400            ; Double-buffered screen flag, NOTE: must be equal to SCR2TB
ENEDGE EQU  >0800            ; TODO Enemies load from edge of screen
DUNLVL EQU  >F000            ; Current dungeon level 1-9 (0=overworld)

; TODO enemy kill counter up to 10
; TODO additional bomb/fairy counter?
; TODO Bait active flag (draws enemies to it)
; TODO Clock active flag (keep enemies frozen in place, flashing state)


SWRDOB EQU  OBJECT+12       ; Sword animation counter
BSWDOB EQU  OBJECT+14       ; Beam sword/Magic counter
ARRWOB EQU  OBJECT+16       ; Arrow counter
BMRGOB EQU  OBJECT+18       ; Boomerang counter
FLAMOB EQU  OBJECT+20       ; Flame counter
BOMBOB EQU  OBJECT+22       ; Bomb counter
LASTOB EQU  OBJECT+24

SPRLST EQU  WRKSP+128       ; 128 bytes sprite list, copied to VDP by SPRUPD
MPDTSP EQU  SPRLST          ; 0 Address of status bar sprites (mapdot, item, sword, half-heart)
HARTSP EQU  SPRLST+4        ; 1 Life bar half-heart sprite
ITEMSP EQU  SPRLST+8        ; 2 Selected item
ASWDSP EQU  SPRLST+12       ; 3 Active sword
HEROSP EQU  SPRLST+16       ; 4,5 Address of hero sprites (color and outline)
SWRDSP EQU  SPRLST+24       ; 6 Sword/Magic Rod
BSWDSP EQU  SPRLST+28       ; 7 Beam sword/Magic (Magic overrides beam sword)
ARRWSP EQU  SPRLST+32       ; 8 Arrow
BMRGSP EQU  SPRLST+36       ; 9 Boomerang
FLAMSP EQU  SPRLST+40       ; 10 Candle flame
BOMBSP EQU  SPRLST+44       ; 11 Bomb
LASTSP EQU  SPRLST+48

SCRTCH EQU  SPRLST+96       ; 32 bytes scratchpad for screen scrolling (overlaps sprite list)





; Sprite function array (64 bytes), for each sprite:
;   index byte of sprite function to call: 6 bits, flags hurt and stun: 1 bit
;   other byte of data (counter, direction, etc)
  
;   function called with data in registers:
;   R4   data from sprite function array (function idx, counter, etc)
;   R5   YYXX word sprite location (Y is adjusted down 1 line)
;   R6   SI.C sprite index, color and early clock bit
  
;   (direction could be encoded in sprite index if done carefully, or sprite function index)
; TODO 6 bits in R6 are not used:
;  lowest 2 bits of sprite index are ignored in 16x16 sprite mode
;  4 bits between sprite index and early clock bit are not used


; TODO attack animation & Magic Rod could be shared in 0x with walking animation
; Sprite patterns (16x16 pixels, total of 64) (four per line, 4*8 bytes per sprite)
; 0x Link (fg and outline, 2 frame animation)  (replaced when changing direction)
; 1x Link Attack (fg and outline)   MagicRod (same direction), Raft/Pushed block
; 2x reserved for enemies (moblin 1-4, pulsing ground 1-2, peahat 1-2, ghini 1-4
; 3x reserved for enemies (moblin 5-8, leever 1-3, tektite 1-2, rock 1-2
; 4x reserved for enemies (octorok 1-4, lynel 1-4,
; 5x reserved for enemies (octorok 5-8, lynel 5-8,
; 6x reserved for enemies (octorok bullet, zora 1-2, zora bullet, armos 1-4
; 7x Sword S,W,E,N
; 8x Sword projectile pop
; 9x Boomerang S,W,E,N
; Ax Arrow S,W,E,N
; Bx Magic S,W,E,N
; Cx Rupee, Bomb, Heart, Clock,
; Dx Cloud puff (3 frames), Spark (arrow or boomerang hitting edge of screen)
; Ex Map dot, Half-heart (status bar), Disappearing enemy (2 frames)
; Fx Flame (1 frame pattern-animated) Fairy (1 frame pattern-animated), B-item, magicsword
;    Flame2, Fairy2, tornado 1, tornado 2,
;    Raft, Book, Magic Rod, Ladder
;    Magic Key, Power Bracelet, Arrow&Bow, Flute
;    Heart, Key, Letter, Potion
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



; Screens cleared of enemies are stored in an 8-item cache, 
; When loading a level if it is not in the cache, then all enemies are loaded normally
; Each screen keeps a record of how many enemies were killed (when not all)
; Each screen has a list of enemies to load (only alive enemies are loaded from start of the list)


; Sprite patterns are limited, that's why only one link pattern
; per direction active at a time.
; New pattern uploaded upon changing direction
; Pattern takes into account magic shield or not



; level data
;  number and type of enemies (2 or 3 kinds)
;  special palette changes (white bricks, trees or dungeon)
;  door/secret location and trigger (bomb, candle, pushblock, etc)

; game keeps track of which secret locations are opened, and items obtained,
; number of rupees, keys and bombs, max hearts,
; and number of enemies remaining on each screen (reset at game start)

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
MRODSC EQU >1804    ; Magic Rod sprite, blue
ARMOSC EQU >6000    ; Armos, transparent
PULSEC EQU >2809    ; Pulsing sprite, light red
RAFTSC EQU >1C0A    ; Raft sprite index, dark yellow
GHINIC EQU >200F    ; Ghini, white
RUPEEY EQU >C00A    ; Yellow Rupee
RUPEEB EQU >C005    ; Blue Rupee
ZBULSC EQU >6406    ; Zora Bullet Red
SHLDSC EQU >3C09    ; Shield
BAITSC EQU >3409    ; Bait
KEY_SC EQU >240B    ; Key
BLURSC EQU >3004    ; Blue ring
BOMBSC EQU >C404    ; Bomb is C4
ARRWSC EQU >AC0B    ; Arrow
BCDLSC EQU >3804    ; Blue Candle
LTTRSC EQU >2804    ; Letter
BPTNSC EQU >2C04    ; Blue Potion
RPTNSC EQU >2C06    ; Red Potion
HRTCSC EQU >2006    ; Heart container
BOW_SC EQU >180B    ; Bow


NSWORC EQU >7C00    ; No sword A-box sprite
ASWORC EQU >7C09    ; wood sword A-box sprite
WSWORC EQU >7C0F    ; white sword A-box sprite
MSWORC EQU >FC0F    ; master sword A-box sprite

BSWDID EQU >0014 ; Beam Sword ID
MAGCID EQU >0015 ; Magic ID
BPOPID EQU >0040 ; Beam Sword/Magic Pop ID (SOC on BSWDID or MAGCID)
BSPLID EQU >0816 ; Beam Sword Splash ID with initial counter
DEADID EQU >1218 ; Dead Enemy Pop ID w/ counter=18
SOFFID EQU >0118 ; turn off sprite immediately
RUPYID EQU >5020 ; Rupee ID with initial counter
BRPYID EQU >5021 ; Blue Rupee ID with initial counter
HARTID EQU >5022 ; Heart ID with initial counter
FARYID EQU >5023 ; Fairy ID with initial counter
ZORAID EQU >0010 ; Zora ID
ZBULID EQU >8011 ; Zora bullet ID with initial counter
BOMBID EQU >4C19 ; Bomb ID with initial counter
FLAMID EQU >5D12 ; Flame ID with initial counter
BMFMID EQU >BF11 ; Book of Magic Flame ID with initial counter
BMRGID EQU >001A ; Boomerang ID
ARRWID EQU >001D ; Arrow ID
SPRKID EQU >00DE ; Spark ID with initial counter=3
CAVEID EQU >001F ; Cave NPC ID
ITEMID EQU >001B ; Cave item ID
TEXTID EQU >0024 ; Cave Message Texter ID
BULLID EQU >001C ; Octorok bullet ID
FRY2ID EQU >0029 ; Fairy at pond ID
HRT2ID EQU >0013 ; Heart that spins around fairy ID
SPOFID EQU >001E ; Sprite off (Spark ID with initial counter=0)
IDLEID EQU >0040 ; Idle object, jumps to OBNEXT but nonzero so it can't be reused
ARMOID EQU >FC17 ; Armos ID and initial counter
ROCKID EQU >8025 ; Rock ID and initial counter
LAKEID EQU >0026 ; Lake ID and initial counter
TORNID EQU >0027 ; Tornado ID
GHINID EQU >000C ; Ghini ID
FLICID EQU >0028 ; Flicker ID

CARTAD EQU >6000 ; Cartridge address in memory (TODO use >A000 for geneve)
       AORG CARTAD   ; Cartridge header in all banks
HEADER
       .IFDEF USE_GROM
       BYTE >AA     ; Standard header
       BYTE >00     ; Version number 1
       BYTE 0;>01     ; Number of programs (optional)
       BYTE 'G'     ; Reserved (for FG99 this can be G,R,or X)
       DATA >0000   ; Pointer to power-up list
       DATA 0;PRGLST  ; Pointer to program list
       DATA >0000   ; Pointer to DSR list
       DATA >0000   ; Pointer to subprogram list  (this doubles as next program list entry)
       .ELSE
       BYTE >AA     ; Standard header
       BYTE >00     ; Version number 1
       BYTE >01     ; Number of programs (optional)
       BYTE >00     ; Reserved (for FG99 this can be G,R,or X)
       DATA >0000   ; Pointer to power-up list
       DATA PRGLST  ; Pointer to program list
       DATA >0000   ; Pointer to DSR list
       DATA >0000   ; Pointer to subprogram list  (this doubles as next program list entry)

PRGLST DATA >0000   ; Next program list entry
       DATA START   ; Program address
       BYTE CRTNME-CRTNM       ; Length of name
CRTNM  TEXT 'LEGEND OF TILDA'
CRTNME
       .ENDIF
       EVEN

BANK0  EQU  CARTAD
BANK1  EQU  CARTAD+2
BANK2  EQU  CARTAD+4
BANK3  EQU  CARTAD+6
BANK4  EQU  CARTAD+8
BANK5  EQU  CARTAD+>A
BANK6  EQU  CARTAD+>C
BANK7  EQU  CARTAD+>E

START
       LWPI WRKSP             ; Load the workspace pointer to fast RAM
       LI R0,BANK3            ; Switch to bank 3 (title screen)
       LI R1,MAIN             ; and go to MAIN
       CLR R2                 ; do title screen

; Select bank in R0 (not inverted) and jump to R1
BANKSW CLR *R0
       B *R1

       DATA START     ; This is referenced by XML instruction in tilda_g.gpl



HDREND

