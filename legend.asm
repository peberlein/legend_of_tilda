*
* legend.asm
*

* Cartridge header and common functions


VDPWD  EQU  >8C00             * VDP write data
VDPWA  EQU  >8C02             * VDP set read/write address
VDPRD  EQU  >8800             * VDP read data
VDPSTA EQU  >8802             * VDP status
VDPWM  EQU  >4000             * VDP address write mask
VDPRM  EQU  >8000             * VDP address register mask

ISRCTL EQU  >83C2             * Four flags: disable all, skip sprite, skip sound, skip QUIT
USRISR EQU  >83C4             * Interrupt service routine hook address

WRKSP  EQU  >8300             * Workspace memory in fast RAM
R0LB   EQU  WRKSP+1           * Register zero low byte address

NAMTAB EQU  >0000             * Name Table
CLRTAB EQU  >0380             * Color Table address in VDP RAM - 32 bytes
PATTAB EQU  >0800             * Pattern Table address in VDP RAM - 256*8 bytes
SPRPAT EQU  >1000             * Sprite Pattern Table address in VDP RAM - 256*8 bytes
SPRLST EQU  >0400             * Sprite List Table address in VDP RAM - 32*4 bytes
SPRLS2 EQU  >0480             * Sprite List Table address in VDP RAM - 32*4 bytes
LEVELA EQU  >1800           * Name table for level A (copied to NAMTAB)

MUSICV EQU  >3000           * Music Pointer in VDP RAM (4k space)
MUSICC EQU  WRKSP+34        * Music Counter

MAPLOC EQU  WRKSP+36        * Map location XY 16x8
RUPEES EQU  WRKSP+37        * Rupee count
KEYS   EQU  WRKSP+38        * Key count
BOMBS  EQU  WRKSP+39        * Bomb count
HEARTS EQU  WRKSP+40        * Hearts
HEARTX EQU  WRKSP+41        * Max hearts
MOVE12 EQU  WRKSP+42        * Movement by 1 or 2
SPRLSP EQU  WRKSP+44        * Sprite List Pointer in VDP RAM (32*4 bytes)
DOOR   EQU  WRKSP+46        * YYXX position of doorway or secret
FLAGS  EQU  WRKSP+58        * Flags

SCRTCH EQU  WRKSP+64        * 32 bytes scratchpad for screen scrolling


* Flags:
*  Blue ring (take 1/2 damage)
*  Red ring (take 1/4 damage)
*  Page flipping A or B

* Sprite function array (64 bytes), for each sprite:
*   index byte of sprite function to call
*   other byte of data (counter, direction, hit points, etc)
  
*   function called with data in registers:
*        data from sprite function array (function idx, counter, etc)
*   YYXX word
*   IDCL sprite index, color and early bit
  
*   (direction could be encoded in sprite index if done carefully)

* Sprite patterns (total of 64)
* 16 (link fg and outline, 2 animations, four directions)
* 8 (link attack and outline, four directions)
* 4 (link holding item 1 or 2 hands, cave or triforce room only)
* 4 (sword)
* 4 (sword projectile pop)
* 2 (or 4, boomerang)
* 4 (arrow, four directions)
* 1 map dot (status bar)
* 1 half-heart (status bar)
* 1 bomb
* 1 rupee
* 1 heart
* 1 key
* 3 cloud puff / explosion
* 1 spark (arrow hitting bush)
* 2 disappearing enemy / pop


* enemy sprites loaded on demand per level


* level data
*  number and type of enemies (2 or 3 kinds)
*  special palette changes (white bricks, trees or dungeon)
*  door/secret location and trigger (bomb, candle, pushblock, etc)

* game keeps track of which secret locations are opened, and items obtained,
* and number of enemies remaining on each screen





* VDP Map
* 0000:031f Screen Table (32*25)
* 0320:037f
* 0380:039f Color Table
* 0400:047f Sprite List A (double buffered)
* 0480:04ff Sprite List B
* 0500:07ff
* 0800:0fff Pattern Table
* 1000:17ff Sprite Pattern Table
* 1800:1a77 Level A Screen Table (32*21 chars)


* 3000:3fff Music Sound List


BANK0  EQU  >6000
BANK1  EQU  >6002
BANK2  EQU  >6004
BANK3  EQU  >6006

       AORG >6000         * Cartridge header in all banks
HEADER
       BYTE >AA     * Standard header
       BYTE >01     * Version number 1
       BYTE >01     * Number of programs (optional)
       BYTE >00     * Reserved
       DATA >0000   * Pointer to power-up list
       DATA PRGLST  * Pointer to program list
       DATA >0000   * Pointer to DSR list
       DATA >0000   * Pointer to subprogram list

PRGLST DATA >0000   * Next program list entry
       DATA START   * Program address
       BYTE CRTNME-CRTNM       * Length of name
CRTNM TEXT 'LEGEND OF TILDA'
CRTNME
       EVEN

START
       LWPI WRKSP             * Load the workspace pointer to fast RAM
       LI R0,BANK0            * Switch to bank 0
       LI R1,MAIN             * and go to MAIN

* Select bank in R0 (not inverted) and jump to R1
BANKSW CLR *R0
       B *R1

* Copy R2 bytes from R1 to VDP address R0
VDPW   MOVB @R0LB,@VDPWA      * Send low byte of VDP RAM write address
       ORI  R0,>4000          * Set read/write bits 14 and 15 to write (01)
       MOVB R0,@VDPWA         * Send high byte of VDP RAM write address
       LI   R0,VDPWD
!      MOVB *R1+,*R0          * Write byte to VDP RAM
       DEC  R2                * Byte counter
       JNE  -!                * Check if done
       RT

* Write one byte from R1 to VDP address R0
VDPWB  MOVB @R0LB,@VDPWA      * Send low byte of VDP RAM write address
       ORI  R0,>4000          * Set read/write bits 14 and 15 to write (01)
       MOVB R0,@VDPWA         * Send high byte of VDP RAM write address
       MOVB R1,@VDPWD
       RT

* Read one byte to R1 from VDP address R0 (R0 is preserved)
VDPRB  MOVB @R0LB,@VDPWA      * Send low byte of VDP RAM write address
       MOVB R0,@VDPWA         * Send high byte of VDP RAM write address
       MOVB @VDPRD,R1
       RT

* Read R2 bytes to R1 from VDP address R0 (R0 is preserved)
VDPR   MOVB @R0LB,@VDPWA      * Send low byte of VDP RAM write address
       MOVB R0,@VDPWA         * Send high byte of VDP RAM write address
!      MOVB @VDPRD,*R1+
       DEC R2
       JNE -!
       RT
       
       
* Write VDP register R0HB data R0LB
VDPREG MOVB @R0LB,@VDPWA      * Send low byte of VDP Register Data
       ORI  R0,>8000          * Set register access bit
       MOVB R0,@VDPWA         * Send high byte of VDP Register Number
       RT

* Note: The interrupt is disabled in VDP Reg 1 so we can poll it here
VSYNC  MOVB @VDPSTA,R0
       ANDI R0, >8000
       JEQ VSYNC
       RT                   * Note: VDP Interrupt flag is now cleared after reading it

*
* Play some music!
*
MUSIC
       DEC @MUSICC          * Decrement music counter (once per frame)
       JNE MUSIC3
MUSIC0
       MOV R15,R0           * Program the Music Pointer in VRAM
       MOVB @R0LB,@VDPWA    * Send low byte of VDP RAM write address
       MOVB R0,@VDPWA       * Send high byte of VDP RAM write address
       CLR R1
       LI R0, >8400         * *R0 is where sound bytes go
MUSIC1
       MOVB @VDPRD,R1       * Read sound list byte from VRAM
       INC R15              * Increment music pointer

       CI R1,>8000          * Is it a music counter byte?
       JL MUSIC2
       CI R1,>E000          * Is it a noise channel byte?
       JHE !
       MOV R1,R2
       ANDI R2,>1000        * Is it the upper nibble even? (freq byte, otherwise vol byte)
       JNE !
* Bytes with upper nibble >8_, >A_, >C_ are two bytes
       MOVB R1,*R0          * Write the byte the sound chip
       MOVB @VDPRD,R1       * Read the next byte from VRAM
       INC R15              * Increment music pointer

!      MOVB R1,*R0          * Write the byte the sound chip
       JMP MUSIC1
MUSIC2 SWPB R1
       MOV R1, @MUSICC      * Store the music counter
       JNE MUSIC3
       INC @MUSICC          * Set Music counter = 1
       MOVB @VDPRD,R15      * Get loop offset low byte
       SWPB R15
       MOVB @VDPRD,R15      * Get loop offset high byte
       AI R15, MUSICV       * Add music base pointer
       JMP MUSIC0
MUSIC3
       RT

HDREND

