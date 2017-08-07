;
; legend.asm
;

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
R10LB  EQU  WRKSP+21          ; Register 10 low byte address
R13LB  EQU  WRKSP+27          ; Register 13 low byte address


; VDP Map
; 0000:031F Screen Table A (32*25 = 320)
; 0340:035F Color Table (32 bytes = 20)
; 0360:037F Bright Color Table (32 bytes = 20)
; 0380:03FF Sprite List Table (32*4 bytes = 80)
; 0400:071F Screen Table B (32*25 = 320)
; 0720:073F Enemy HP (32 bytes = 20)
; 0740:077F Enemy Hurt/Stun Counters interleaved (64 bytes = 40)
; 0780:079F Save area scratchpad/sprite list
; 07A0:07FF
; 0800:0FFF Pattern Descriptor Table
; 1000:17FF Sprite Pattern Table
; 1800:1ABF Level Screen Table (32*22 chars = 2C0)
; 1AC0:1D5F Menu Screen Table (32*21 chars = 2A0)
; 1D60:255F Enemy sprite patterns (64*32 bytes = 800)

; 3000:3fff Music Sound List (would it be better in banked ROM?)

SCR1TB EQU  >0000           ; Name Table 32*24 bytes (double-buffered)
CLRTAB EQU  >0340           ; Color Table address in VDP RAM - 32 bytes
BCLRTB EQU  >0360           ; Bright Color Table address in VDP RAM - 32 bytes
SPRTAB EQU  >0380           ; Sprite List Table address in VDP RAM - 32*4 bytes
SCR2TB EQU  >0400           ; Name Table 32*24 bytes (double-buffered)
SCHSAV EQU  >0780           ; Save area for SCRTCH scratchpad/screen list
PATTAB EQU  >0800           ; Pattern Table address in VDP RAM - 256*8 bytes
SPRPAT EQU  >1000           ; Sprite Pattern Table address in VDP RAM - 256*8 bytes
LEVELA EQU  >1800           ; Name table for level A (copied to SCRTB1 or 2)
MENUSC EQU  >1AC0           ; Name table for menu screen
ENESPR EQU  >1D60           ; Enemy sprite patterns (up to 64)

MUSICV EQU  >3000           ; Music Base Address in VDP RAM (4k space)

ENEMHP EQU  >0720    ; Enemy HP
ENEMHS EQU  >0740    ; Enemy hurt/stun counters interleaved:
                     ; stun: count=6bits
                     ; hurt: direction=2bits count=6bits

; CPU RAM layout
;   0:  32 bytes - workspace
;  32:  32 bytes - global variables
;  64: 128 bytes - sprite list
; 192:  64 bytes - moving object index and data
; 224:  32 bytes - scratchpad (overlaps object table)       

; 00: workspace
; 10: workspace
; 20: globals
; 30: globals
; 40: sprites 0-3    (could be unused - in VDP RAM only)
; 50: sprites 4-7
; 60: sprites 8-11
; 70: sprites 12-15
; 80: sprites 16-19
; 90: sprites 20-23
; A0: sprites 24-27
; B0: sprites 28-31
; C0: objects 0-7    (0-6 are unused)
; D0: objects 8-15
; E0: objects 16-23  (scratchpad)
; F0: objects 24-31  (scratchpad)

MUSICP EQU  WRKSP+32        ; Music Pointer
MUSICC EQU  WRKSP+34        ; Music Counter

MAPLOC EQU  WRKSP+36        ; Map location XY 16x8
RUPEES EQU  WRKSP+37        ; Rupee count (max 255)
KEYS   EQU  WRKSP+38        ; Key count
BOMBS  EQU  WRKSP+39        ; Bomb count (max 8,12,16)
HP     EQU  WRKSP+40        ; Hit points (max 2x hearts, 4x hearts, 8x hearts, depending on ring)
HEARTS EQU  WRKSP+41        ; Max hearts - 1 (min 2, max 15)
MOVE12 EQU  WRKSP+42        ; Movement by 1 or 2
SPRLSP EQU  WRKSP+44        ; Sprite List Pointer in VDP RAM (32*4 bytes)
DOOR   EQU  WRKSP+46        ; YYXX position of doorway or secret
FLAGS  EQU  WRKSP+48        ; Screen pointer in VRAM for page flipping
INCAVE EQU  >0001            ; Inside cave
FULLHP EQU  >0002            ; Full hearts, able to use beam sword
ENEDGE EQU  >0004            ; Enemies load from edge of screen
SCRFLG EQU  >0400           ; NOTE must be equal to SCR2TB
;TODO Facing bits in here

HFLAGS EQU  WRKSP+50        ; Hero Flags
BLURNG EQU  >0001            ; Blue Ring (take 1/2 damage)
REDRNG EQU  >0002            ; Red Ring (take 1/4 damage)
MAGSHD EQU  >0004            ; Magic Shield
BCANDL EQU  >0008            ; Blue candle (once per screen)
RCANDL EQU  >0010            ; Red candle (unlimited)
BMRANG EQU  >0020            ; Boomerang (brown)
MAGBMR EQU  >0040            ; Magic Boomerang (blue)
ASWORD EQU  >0080            ; Wood  Sword 1x damage (brown)
WSWORD EQU  >0100            ; White Sword 2x damage (white)
MSWORD EQU  >0200            ; Magic Sword 4x damage (white slanted)
ARROWS EQU  >0400            ; Arrows (brown)
BOW    EQU  >0800            ; Bow (brown)
FLUTE  EQU  >1000            ; Flute (brown)
PBRACE EQU  >2000            ; Power Bracelet (red)
LADDER EQU  >4000            ; Ladder (brown)
RAFT   EQU  >8000            ; Raft (brown)

HFLAG2 EQU  WRKSP+52         ; More hero flags
MAGROD EQU  >0001            ; Magic Rod (blue)
BOOKMG EQU  >0002            ; Book of Magic (adds flames to magic rod)
MAGKEY EQU  >0004            ; Magic Key (opens all doors, appears as XA)
REDPOT EQU  >0008            ; Red potion (refills hearts, turns into blue potion when used)
BLUPOT EQU  >0010            ; Blue potion (refills hearts, turns into letter when used)
LETTER EQU  >0020            ; Letter from old man (give to woman allows buying potions)
LETPOT EQU  >0040            ; Gave the letter to old woman, potions available
BAIT   EQU  >0080            ; Bait (lures monsters or give to grumble grumble)
SARROW EQU  >0100            ; Silver arrows (appear blue, double damage)

SELITM EQU  >E000            ; Selected item 0-7

KEY_FL EQU WRKSP+54         ; key press flags
KEY_UP EQU  >0002           ; J1 Up / W
KEY_DN EQU  >0005           ; J1 Down / S
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

SPRLST EQU  WRKSP+64
HEROSP EQU  SPRLST          ; Address of hero sprites (color and outline)
SCRTCH EQU  SPRLST+96       ; 32 bytes scratchpad for screen scrolling (overlaps sprite list)

OBJECT EQU  WRKSP+192       ; 64 bytes sprite function index (6 bits) hurt/stun (1 bit) and data (9 bits)
SWORDC EQU  OBJECT+12       ; Sword animation counter
HURTC  EQU  OBJECT+0        ; Link hurt animation counter (8 frames knockback, 40 more frames invincible)
FACING EQU  OBJECT+2        ; Pointer to facing direction sprites
FACEDN EQU  >0000
FACELT EQU  >0100
FACERT EQU  >0200
FACEUP EQU  >0300



;SOUNDP EQU  WRKSP+192       ; Sound effect list pointer (zero when not playing)
;SOUNDC EQU  WRKSP+194       ; Sound effect counter
;SOUND0 EQU  WRKSP+196       ; Backup register for music sound generator 0 vzxy
;SOUND1 EQU  WRKSP+196       ; Backup register for music sound generator 1 vzxy
;SOUND2 EQU  WRKSP+196       ; Backup register for music sound generator 2 vzxy
;SOUND3 EQU  WRKSP+196       ; Backup register for music sound generator 3 vn





; Sprite function array (64 bytes), for each sprite:
;   index byte of sprite function to call: 6 bits, flags hurt and stun: 2 bits
;   other byte of data (counter, direction, etc)
  
;   function called with data in registers:
;   R4   data from sprite function array (function idx, counter, etc)
;   R5   YYXX word sprite location (Y is adjusted)
;   R6   IDCL sprite index, color and early bit
  
;   (direction could be encoded in sprite index if done carefully, or sprite function index)

; Sprite patterns (16x16 pixels, total of 64) (four per line, 4*8 bytes per sprite)
; 0x Link (fg and outline, 2 frame animation)  (replaced when changing direction)
; 1x Link Attack (fg and outline)   Wand (same direction), Ladder/Raft(as needed)
; 2x reserved for enemies (moblin 1-4, pulsing ground 1-2, peahat 1-2, ghini 1-4
; 3x reserved for enemies (moblin 5-8, leever 1-3, tektite 1-2, rock 1-2
; 4x reserved for enemies (octorok 1-4, lynel 1-4,
; 5x reserved for enemies (octorok 5-8, lynel 5-8,
; 6x reserved for enemies (octorok bullet, zora 1-2, zora bullet, armos 1-4
; 7x Sword N,S,E,W
; 8x Sword projectile pop
; 9x Boomerang N,S,E,W
; Ax Arrow N,S,E,W
; Bx Magic N,S,E,W
; Cx rupee, bomb, heart, key
; Dx cloud puff (3 frames), spark (arrow hitting edge of screen)
; Ex map dot, half-heart (status bar), disappearing enemy (2 frames)
; Fx Flame (1 frame pattern-animated) Fairy (1 frame pattern-animated), secondary item, clock

; TODO: Compass, clock, magic book, rings, magic key, power bracelet,
;       candles, whistle, bait, letter and medicine

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
; rocks zora

; Sprite list layout
; 0-1  Link, outline
; 2-5  Mapdot, item, sword, half-heart
; TODO  0-3  Mapdot, item, sword, half-heart  (keep in VDP RAM only)
; TODO  4-5  Link, outline
; 6    Sword/wand
; 7    Flying sword
; 8    Arrow
; 9    Boomerang
; 10   Magic
; 11   Flame
; 12   Bomb
; 13+  all other objects



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

; Game saved as password (36 values per character A-Z 0-9, or 32 without 01IO)
; slightly obfuscated to prevent value hacking






BANK0  EQU  >6000
BANK1  EQU  >6002
BANK2  EQU  >6004
BANK3  EQU  >6006

       AORG >6000         ; Cartridge header in all banks
HEADER
       BYTE >AA     ; Standard header
       BYTE >01     ; Version number 1
       BYTE >01     ; Number of programs (optional)
       BYTE >00     ; Reserved (for FG99 this can be G,R,or X)
       DATA >0000   ; Pointer to power-up list
       DATA PRGLST  ; Pointer to program list
       DATA >0000   ; Pointer to DSR list
       DATA >0000   ; Pointer to subprogram list

PRGLST DATA >0000   ; Next program list entry
       DATA START   ; Program address
       BYTE CRTNME-CRTNM       ; Length of name
CRTNM  TEXT 'LEGEND OF TILDA'
CRTNME
       EVEN

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
       NOP                  ; Very important for 9918A prefetch, otherwise glitches can occur
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
VSYNC  MOV R12,R0            ; Save R12 since we use it
       MOVB @VDPSTA,R12      ; Clear interrupt first so we catch the edge
       CLR R12
!      TB 2                  ; CRU Address bit 0002 - VDP INT
       JEQ -!                ; Loop until set
       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU
       MOV R0,R12            ;
       RT

;
; Play some music!
;
; Modifies R0,R1,R2
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
       MOV R1,R2
       ANDI R2,>1000       ; Is it the upper nibble even? (freq byte, otherwise vol byte)
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

