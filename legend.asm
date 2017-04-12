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

WRKSP  EQU  >8300             * Workspace memory in fast RAM
R0LB   EQU  WRKSP+1           * Register zero low byte address

CLRTAB EQU  >0380             * Color Table address in VDP RAM - 32 bytes
PATTAB EQU  >0800             * Pattern Table address in VDP RAM - 256*8 bytes
SPRPAT EQU  >1000             * Sprite Pattern Table address in VDP RAM - 256*8 bytes
SPRLST EQU  >0300             * Sprite List Table address in VDP RAM - 32*4 bytes
LEVELA EQU  >1800
LEVELB EQU  >1AC0

MUSICV EQU  >3000           * Music Pointer in VDP RAM (4k space)
MUSICC EQU  WRKSP+34        * Music Counter

MAPLOC EQU  WRKSP+36        * Map location 16x8
RUPEES EQU  WRKSP+37        * Rupee count
KEYS   EQU  WRKSP+38        * Key count
BOMBS  EQU  WRKSP+39        * Bomb count
HEARTS EQU  WRKSP+40        * Hearts
HEARTX EQU  WRKSP+41        * Max hearts
MOVE12 EQU  WRKSP+42        * Movement by 1 or 2
LEVELP EQU  WRKSP+44        * Level Pointer in VDP RAM (768 bytes)
FLAGS  EQU  WRKSP+46        * Flags

* Flags:
*  Blue ring (take 1/2 damage)
*  Red ring (take 1/4 damage)
*  Page flipping A or B



* VDP Map
* 0000:02ff Screen Table
* 0300:037f Sprite List
* 0380:039f Color Table
* 0380:07ff
* 0800:0fff Pattern Table
* 1000:17ff Sprite Pattern Table
* 1800:1abf Level A Screen Table
* 1ac0:1d7f Level B Screen Table

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

