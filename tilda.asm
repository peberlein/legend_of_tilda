;
; tilda.asm
; Copyright (c) 2017 Pete Eberlein

; Cartridge header and common functions


VDPWD  EQU  >8C00             ; VDP write data
VDPWA  EQU  >8C02             ; VDP set read/write address
VDPRD  EQU  >8800             ; VDP read data (don't forget NOP after address)
VDPSTA EQU  >8802             ; VDP status
VDPWM  EQU  >4000             ; VDP address write mask
VDPRM  EQU  >8000             ; VDP address register mask

SNDREG EQU  >8400             ; Sound register address

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
; 0000:031F Screen Table A (32*25 = 320)
; 0320:033F Save area scratchpad/sprite list
; 0340:035F Color Table (32 bytes = 20)
; 0360:037F MapSav(1),LadPos(2)
; 0380:03FF Sprite List Table (32*4 bytes = 80)
; 0400:071F Screen Table B (32*25 = 320)
; 0720:073F
; 0740:075F Bright Color Table (32 bytes = 20)
; 0760:077F
; 0780:079F Menu Color Table (32 bytes = 20)
; 07A0:07DF Enemy Hurt/Stun Counters interleaved (64 bytes = 40)
; 07E0:07FF Enemy HP (32 bytes = 20)
; 0800:0FFF Overworld/Dungeon Pattern Descriptor Table (256*8 = 800)
; 1000:1B7F Sprite Pattern Table (64*32 + 28*32 bytes = B80)
; 1B80:137F Enemy sprite patterns (64*32 bytes = 800)
; 2380:263F Level Screen Table (32*22 chars = 2C0)
; 2640:28DF Menu Screen Table (32*21 chars = 2A0)
; 28E0:2B5F Menu pattern table backup (20*32 bytes = 280)
; 2B60:     Cave texts

; 3000:3fff Music Sound List (would it be better in banked ROM?)

; TODO  Dark dungeon pattern backup (128*8 bytes = 400)

; TODO Enemy Status Bytes (32 bytes = 20)
;  Drop table type
;  Stunnable by boomerang
;  Killable by boomerang



SCR1TB EQU  >0000    ; Name Table 32*24 bytes (double-buffered)
SCHSAV EQU  >0320    ; Save area for SCRTCH scratchpad/screen list
CLRTAB EQU  >0340    ; Color Table address in VDP RAM - 32 bytes
MAPSAV EQU  >0360    ; Overworld map saved location when in dungeon
LADPOS EQU  >3601    ; Ladder Position YYXX, and backup chars
SPRTAB EQU  >0380    ; Sprite List Table address in VDP RAM - 32*4 bytes
SCR2TB EQU  >0400    ; Name Table 32*24 bytes (double-buffered)
BCLRTB EQU  >0740    ; Bright Color Table address in VDP RAM - 32 bytes
MCLRTB EQU  >0780    ; Menu Color Table address in VDP RAM - 32 bytes
PATTAB EQU  >0800    ; Pattern Table address in VDP RAM - 256*8 bytes
SPRPAT EQU  >1000    ; Sprite Pattern Table address in VDP RAM - 256*8 bytes
ENESPR EQU  >1B80    ; Enemy sprite patterns (up to 64)
LEVELA EQU  >2380    ; Name table for level A (copied to SCR1TB or SCR2TB)
MENUSC EQU  >2640    ; Name table for menu screen
PATSAV EQU  >28E0    ; Pattern table backup for menu screen 32*20 bytes
CAVTXT EQU  >2B60    ; Cave text
SDATA  EQU  >2E00    ; Save Data
SDCAVE EQU  SDATA    ; Save Data - opened secret caves, 128 bits = 16 bytes
SDITEM EQU  SDATA+16 ; Save Data - cave items collected, 128 bits = 16 bytes
SDOPEN EQU  SDATA+32 ; Save Data - dungeon doors unlocked or walls bombed, 256 bits = 32 bytes
SDDUNG EQU  SDATA+64 ; Save Data - dungeon items collected, 256 bits = 32 bytes

MUSICV EQU  >3000    ; Music Base Address in VDP RAM (4k space)

ENEMDT EQU  >0760    ; Enemy drop table, status flags
ENEMHS EQU  >07A0    ; Enemy hurt/stun counters interleaved:
                     ; stun: count=6bits
                     ; hurt: direction=2bits count=6bits
ENEMHP EQU  >07E0    ; Enemy HP

CNDLUS EQU  >0008    ; TODO Candle used, once per screen (blue candle only, locate at Flame HP)
MAZEST EQU  >0000    ; TODO Maze state (Forest Maze, Mountain)


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


TRACK1 EQU WRKSP+32
SOUND1 EQU WRKSP+34

TRACK2 EQU WRKSP+36
SOUND2 EQU WRKSP+38

TRACK3 EQU WRKSP+40
SOUND3 EQU WRKSP+42

TRACK4 EQU WRKSP+44
SOUND4 EQU WRKSP+46


MOVE12 EQU  WRKSP+48        ; Movement by 1 or 2


HFLAGS EQU  WRKSP+50        ; Hero Flags (part of save data)
SELITM EQU  >0007            ; Selected item 0-7

MAGSHD EQU  >0008            ; Magic Shield
SWORDA EQU  >0010            ; Wood  Sword 1x damage (brown)
WSWORD EQU  >0020            ; White Sword 2x damage (white)
MSWORD EQU  >0040            ; Magic Sword 4x damage (white slanted)
BOW    EQU  >0080            ; Bow (brown)

LADDER EQU  >0100            ; Ladder (brown)
RAFT   EQU  >0200            ; Raft (brown)
MAGKEY EQU  >0400            ; Magic Key (opens all doors, appears as A in key count)
BMRANG EQU  >0800            ; Boomerang (brown)
ARROWS EQU  >1000            ; Arrows (brown)
FLUTE  EQU  >2000            ; Flute (brown)
SARROW EQU  >4000            ; Silver arrows (appear blue, double damage)
MAGBMR EQU  >8000            ; Magic Boomerang (blue)

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

BLUCLR EQU  >0700            ; Color of sprite with blue ring
REDCLR EQU  >0800            ; Color of sprite with red ring

HFLAG2 EQU  WRKSP+52         ; More hero flags (part of save data)
BOMBSA EQU  >0001            ; Bombs available > 0
BCANDL EQU  >0002            ; Blue candle (once per screen)
LETTER EQU  >0003            ; Letter from old man (give to woman allows buying potions)
BLUPOT EQU  >0004            ; Blue potion (refills hearts, turns into letter when used)
MAGROD EQU  >0010            ; Magic Rod (blue)
BLURNG EQU  >0020            ; Blue Ring (take 1/2 damage)
REDRNG EQU  >0040            ; Red Ring (take 1/4 damage)
REDPOT EQU  >0080            ; Red potion (refills hearts, turns into blue potion when used)
BAIT   EQU  >0100            ; Bait (lures monsters or give to grumble grumble)
RCANDL EQU  >0200            ; Red candle (unlimited)
PBRACE EQU  >0400            ; Power Bracelet (red)
BOOKMG EQU  >0800            ; Book of Magic (adds flames to magic rod)
LETPOT EQU  >1000            ; Gave the letter to old woman, potions available
COMPAS EQU  >2000            ; Compass (for current dungeon)
MINMAP EQU  >4000            ; Dungeon map (current dungeon)

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
CAVTYP EQU  WRKSP+62        ; Cave type (NPC / dungeon)

* RAM   00     01     02     03     04     05     06     07
* 8320  TRACK1        SOUND1        TRACK2        SOUND2
* 8328  TRACK3        SOUND3        TRACK4        SOUND4
* 8330  MOVE12        HFLAGS        HFLAG2        KEY_FL
* 8338  OBJPTR        COUNTR        RAND16        CAVTYP ______
* 8340  HURTC  ______ MAPLOC RUPEES KEYS   BOMBS  HP     HEARTS
* 8348  DOOR          FLAGS         SWRDOB        BSWDOB
* 8350  ARRWOB        BMRGOB        FLAMOB        BOMBOB
* 8358  enemies
*  ...
* 8380  sprite list

OBJECT EQU  WRKSP+64        ; 64 bytes: sprite function index (6 bits) hurt/stun (1 bit) and data (9 bits)
HURTC  EQU  OBJECT+0        ; Link hurt animation counter (8 frames knockback, 40 more frames invincible)

MAPLOC EQU  OBJECT+2        ; Map location YX 16x8
HEARTS EQU  OBJECT+3        ; Max hearts - 1 (min 2, max 15)
HP     EQU  OBJECT+4        ; Hit points (max 2x hearts, 4x hearts, 8x hearts, depending on ring)
RUPEES EQU  OBJECT+5        ; Rupee count (max 255)
KEYS   EQU  OBJECT+6        ; Key count max 9 or (or A for magic key)
BOMBS  EQU  OBJECT+7        ; Bomb count (max 8,12,16)

DOOR   EQU  OBJECT+8        ; YYXX position of doorway or secret

FLAGS  EQU  OBJECT+10       ; Various Flags
INCAVE EQU  >0001            ; Inside cave
FULLHP EQU  >0002            ; Full hearts, able to use beam sword
DARKRM EQU  >0004            ; TODO Dungeon room darkened
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



SWRDOB EQU  OBJECT+12       ; Sword animation counter
BSWDOB EQU  OBJECT+14       ; Beam sword/Magic counter
ARRWOB EQU  OBJECT+16       ; Arrow counter
BMRGOB EQU  OBJECT+18       ; Boomerang counter
FLAMOB EQU  OBJECT+20       ; Flame counter
BOMBOB EQU  OBJECT+22       ; Bomb counter
LASTOB EQU  OBJECT+24

SPRLST EQU  WRKSP+128       ; 127 bytes sprite list, copied to VDP by SPRUPD
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





;SOUNDP EQU  WRKSP+192       ; Sound effect list pointer (zero when not playing)
;SOUNDC EQU  WRKSP+194       ; Sound effect counter
;SOUND0 EQU  WRKSP+196       ; Backup register for music sound generator 0 vzxy
;SOUND1 EQU  WRKSP+196       ; Backup register for music sound generator 1 vzxy
;SOUND2 EQU  WRKSP+196       ; Backup register for music sound generator 2 vzxy
;SOUND3 EQU  WRKSP+196       ; Backup register for music sound generator 3 vn





; Sprite function array (64 bytes), for each sprite:
;   index byte of sprite function to call: 6 bits, flags hurt and stun: 1 bits
;   other byte of data (counter, direction, etc)
  
;   function called with data in registers:
;   R4   data from sprite function array (function idx, counter, etc)
;   R5   YYXX word sprite location (Y is adjusted down 1 line)
;   R6   IDCL sprite index, color and early bit
  
;   (direction could be encoded in sprite index if done carefully, or sprite function index)


; TODO attack animation & Magic Rod could be shared in 0x with walking animation
; Sprite patterns (16x16 pixels, total of 64) (four per line, 4*8 bytes per sprite)
; 0x Link (fg and outline, 2 frame animation)  (replaced when changing direction)
; 1x Link Attack (fg and outline)   Wand (same direction), Ladder/Raft(as needed)
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
; Fx Flame (1 frame pattern-animated) Fairy (1 frame pattern-animated), empty, empty
;    Flame2, Fairy2, tornado 1, tornado 2,
;    Raft, Book, Magic Rod, Ladder
;    Magic Key, Power Bracelet, Arrow&Bow, Flute
;    Heart, Key, Letter, Potion
;    Ring, Bait, Candle, Magic Shield
;    Old Woman 1&2, Merchant 1&2
;    Old Man 1&2, Magic Sword, Item Selector
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
MRODC  EQU >1804    ; Magic Rod sprite, blue
ARMOSC EQU >6000    ; Armos, transparent
PULSE  EQU >280A    ; Pulsing sprite, dark yellow
RAFTSC EQU >1C0A    ; Raft sprite index, dark yellow


BSWDID EQU >0014 ; Beam Sword ID
MAGCID EQU >0015 ; Magic ID
BPOPID EQU >0040 ; Beam Sword/Magic Pop ID (SOC on BSWDID or MAGCID)
BSPLID EQU >0816 ; Beam Sword Splash ID with initial counter
DEADID EQU >1218 ; Dead Enemy Pop ID w/ counter=18
RUPYID EQU >5020 ; Rupee ID with initial counter
BRPYID EQU >5021 ; Blue Rupee ID with initial counter
HARTID EQU >5022 ; Heart ID with initial counter
FARYID EQU >5023 ; Fairy ID with initial counter
ZORAID EQU >0010 ; Zora ID
BOMBID EQU >4C19 ; Bomb ID with initial counter
FLAMID EQU >5D11 ; Flame ID with initial counter
BMFMID EQU >BF11 ; Book of Magic Flame ID with initial counter
BMRGID EQU >001A ; Boomerang ID
ARRWID EQU >001D ; Arrow ID
SPRKID EQU >00DE ; Spark ID with initial counter=3
CAVEID EQU >001F ; Cave NPC ID
ITEMID EQU >001B ; Cave item ID
TEXTID EQU >0024 ; Cave Message Texter ID
BULLID EQU >001C ; Octorok bullet ID
FRY2ID EQU >0012 ; Fairy at pond ID
HRT2ID EQU >0013 ; Heart that spins around fairy ID
SPOFID EQU >001E ; Sprite off (Spark ID with initial counter=0)
IDLEID EQU >0040 ; Idle object, jumps to OBNEXT but nonzero so it can't be reused
ARMOID EQU >FC17 ; Armos ID and initial counter
ROCKID EQU >8025 ; Rock ID and initial counter




       AORG >6000         ; Cartridge header in all banks
HEADER
       BYTE >AA     ; Standard header
       BYTE >01     ; Version number 1
       BYTE >01     ; Number of programs (optional)
       BYTE >00     ; Reserved (for FG99 this can be G,R,or X)
       DATA >0000   ; Pointer to power-up list
       DATA PRGLST  ; Pointer to program list
       DATA >0000   ; Pointer to DSR list
       ;DATA >0000   ; Pointer to subprogram list  (this doubles as next program list entry)

PRGLST DATA >0000   ; Next program list entry
       DATA START   ; Program address
       BYTE CRTNME-CRTNM       ; Length of name
CRTNM  TEXT 'LEGEND OF TILDA'
CRTNME
       EVEN

BANK0  EQU  >6000
BANK1  EQU  >6002
BANK2  EQU  >6004
BANK3  EQU  >6006
BANK4  EQU  >6008
BANK5  EQU  >600A
BANK6  EQU  >600C
BANK7  EQU  >600E

START
       LWPI WRKSP             ; Load the workspace pointer to fast RAM
       LI R0,BANK0            ; Switch to bank 0
       LI R1,MAIN             ; and go to MAIN

; Select bank in R0 (not inverted) and jump to R1
BANKSW CLR *R0
       B *R1

; Copy R2 bytes from R1 to VDP address R0
VDPW   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
!      MOVB *R1+,*R15       ; Write byte to VDP RAM
       DEC  R2              ; Byte counter
       JNE  -!              ; Check if done
       RT

; Write one byte from R1 to VDP address R0
VDPWB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       RT

; Read one byte to R1 from VDP address R0 (R0 is preserved)
VDPRB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       CLR R1               ; Very important delay for 9918A prefetch, otherwise glitches can occur
       MOVB @VDPRD,R1
       RT

; Read R2 bytes to R1 from VDP address R0 (R0 is preserved)
VDPR   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       NOP                  ; Very important for 9918A prefetch, otherwise glitches can occur
!      MOVB @VDPRD,*R1+
       DEC R2
       JNE -!
       RT


; Write VDP register R0HB data R0LB
VDPREG MOVB @R0LB,*R14      ; Send low byte of VDP Register Data
       ORI  R0,VDPRM          ; Set register access bit
       MOVB R0,*R14         ; Send high byte of VDP Register Number
       RT

; Note: The interrupt is disabled in VDP Reg 1 so we can poll it here
; There could be a race condition where the interrupt flag could be cleared before we read it,
; resulting it a missed vsync interrupt, and polling the status register increases that chance.
; VSYNC  MOVB @VDPSTA,R0     ; Note: VDP Interrupt flag is now cleared after reading it
;        ANDI R0, >8000
;        JEQ VSYNC
;        RT

; Reading the VDP INT bit from the CRU doesn't clear the status register, so it should be safe to poll.
; The CRU bit appears to get updated even with interrupts disabled (LIMI 0)
; Modifies R0
VSYNCM
       MOV R12,R0            ; Save R12 since we use it
       MOVB @VDPSTA,R12      ; Clear interrupt first so we catch the edge
       CLR R12
!      TB 2                  ; CRU Address bit 0002 - VDP INT
       JEQ -!                ; Loop until set
       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU
       MOV R0,R12            ;
       ; fall thru

; Play some music!
;
; Modifies R0,R1
MUSIC
       DEC @MUSICC         ; Decrement music counter (once per frame)
       JNE MUSIC3
MUSIC0
       MOV @MUSICP,R0      ; Program the Music Pointer in VRAM
       MOVB @R0LB,*R14     ; Send low byte of VDP RAM write address
       MOVB R0,*R14        ; Send high byte of VDP RAM write address
       CLR R1
MUSIC1
       MOVB @VDPRD,R1      ; Read sound list byte from VRAM
       INC @MUSICP         ; Increment music pointer

       CI R1,>8000         ; Is it a music counter byte?
       JL MUSIC2
       CI R1,>E000         ; Is it a noise channel byte?
       JHE !
       MOV R1,R0
       ANDI R0,>1000       ; Is it the upper nibble even? (freq byte, otherwise vol byte)
       JNE !
; Bytes with upper nibble >8_, >A_, >C_ are two bytes
       MOVB R1,@SNDREG     ; Write the byte the sound chip
       MOVB @VDPRD,R1      ; Read the next byte from VRAM
       INC @MUSICP         ; Increment music pointer

!      MOVB R1,@SNDREG     ; Write the byte the sound chip
       JMP MUSIC1
MUSIC2 SWPB R1
       MOV R1, @MUSICC     ; Store the music counter
       JNE MUSIC3
       INC @MUSICC         ; Set Music counter = 1
       MOVB @VDPRD,R0      ; Get loop offset low byte
       SWPB R0
       MOVB @VDPRD,R0      ; Get loop offset high byte
       AI R0, MUSICV       ; Add music base pointer
       MOV R0,@MUSICP
       JMP MUSIC0
MUSIC3
       RT


HDREND

