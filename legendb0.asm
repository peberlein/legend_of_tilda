*
* Legend of Tilda
* 
* Bank 0: initialization and main loop
*
       
       COPY 'legend.asm'
MAIN
       LIMI 0                 * Disable interrupts

       LI   R0,>01C2          * VDP Register 1: 16x16 Sprites, disable interrupt
       BL   @VDPREG
       LI   R0,>0500+(SPRLST/>80)  * VDP Register 5: Sprite List Table
       BL   @VDPREG
       LI   R0,>0600+(SPRPAT/>800)  * VDP Register 6: Sprite Pattern Table
       BL   @VDPREG
       LI   R0,>07F1          * VDP Register 7: White on Black
       BL   @VDPREG
       
       LI   R0,PATTAB         * Pattern table starting at char 0
       LI   R1,PAT0
       LI   R2,PAT255-PAT0
       BL   @VDPW
       
       LI   R0,CLRTAB         * Color table
       LI   R1,CLRSET
       LI   R2,32
       BL   @VDPW
       
       LI   R0,SPRPAT         * Sprite Pattern Table
       LI   R1,SPR0
       LI   R2,SPR47-SPR0
       BL   @VDPW

     
       
*                               Draw the screen
       CLR  R0                * Start at top left corner of the screen
       LI   R2,768            * Number of bytes to write
       LI   R1,MD0
       BL   @VDPW

      
       LI   R0,BANK1         * Music is in bank 1
       LI   R1,HDREND        * First function in bank 1
       CLR  R2               * Overworld song is 0
       BL   @BANKSW

       LI   R0,>7700         * Initial map location is 7,7
       MOVB R0,@MAPLOC
       
       LI   R0,BANK2         * Overworld is in bank 2
       LI   R1,HDREND        * First function in bank 1
       CLR  R2               * Use wipe from center 0
       BL   @BANKSW

       LI   R0,SPRLST         * Sprite List Table
       LI   R1,SPRL0
       LI   R2,12
       BL   @VDPW
       
       LIMI 2                 * Enable interrupts
       
       CLR  R0
       MOVB R0,@RUPEES
       MOVB R0,@KEYS
       MOVB R0,@BOMBS
       MOV R0,@FLAGS0
       MOV R0,@MOVE12

       LI R13,>7078        * Link Y X position in pixels
INFLP

DRAW

       LIMI 0                 * Disable interrupts
       
       AI R13,>FF00
       LI R0,SPRLST
       LI R1,WRKSP+(R13*2)
       LI R2,2
       BL @VDPW

       LI R0,SPRLST+4
       LI R1,WRKSP+(R13*2)
       LI R2,2
       BL @VDPW
       AI R13,>0100

*       LI   R0,>07F1          * VDP Register 7: White on Black
*       BL   @VDPREG
       
       LIMI 2                 * Enable interrupts

       
       BL @VSYNC

       BL @MUSIC



*	CLR R1
*	LI R12, >0024
*	LDCR R1,3            * Turn on Keyboard Col 0
*	LI R12, >0006
*	SETO R2
*	STCR R2,8            * Read Row bits


* Up/down movement has priority over left/right, unless there is an obstruction
       
       LI R1,>0100
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 1
       LI R12, >0006
       TB 5                 * Key W
       JNE MOVEDN
       TB 6                 * Key S
       JNE MOVEUP
       TB 4                 * Key 2
       JEQ !
       BL @SCRLDN
!

       LI R1,>0300
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 3
       LI R12, >0006
       TB 4                 * Key 4
       JEQ !
       BL @SCRLLT
!

       LI R1,>0400
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 4
       LI R12, >0006
       TB 3                 * Key 6
       JEQ !
       BL @SCRLRT
!


       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 6 (Joystick 1)
       LI R12, >0006
       TB 3                 * JS1 DOWN
       JNE MOVEDN
       TB 4                 * JS1 UP
       JNE MOVEUP

HKEYS
       LI R1,>0600
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 6 (Joystick 1)
       LI R12, >0006
       TB 2                 * JS1 RIGHT
       JNE MOVERT
       TB 1                 * JS1 LEFT
       JNE MOVELT

       LI R1,>0200
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 2
       LI R12, >0006
       TB 5                 * Key D
       JNE MOVERT
       TB 3                 * Key 8
       JEQ !
       BL @SCRLUP
!

       LI R1,>0500
       LI R12, >0024
       LDCR R1,3            * Turn on Keyboard Col 5
       LI R12, >0006
       TB 5                 * Key A
       JNE MOVELT
       
       JMP  INFLP             * Infinite loop

      
MOVEDN
       CI R13,(192-16)*256   * Check at bottom edge of screen
       JL !
       BL @SCRLDN

!      MOV R13,R0
       AI R0,>1004    * 16 pixels down, 4 right
       LI R2,HKEYS
       BL @TESTCH
       MOV R13,R0
       AI R0,>100C    * 16 pixels down, 12 right
       BL @TESTCH

       MOV R13,R0     * Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVED2
       ANDI R0,>0004
       JEQ MOVEL2
       JMP MOVER2

MOVEUP
       CI R13,25*256  * Check at top edge of screen
       JHE !
       BL @SCRLUP

!      MOV R13,R0
       AI R0,>0704    * 7 pixels down, 4 right
       LI R2,HKEYS
       BL @TESTCH
       MOV R13,R0
       AI R0,>070C    * 7 pixels down, 12 right
       BL @TESTCH

       MOV R13,R0     * Make X coord 8-aligned
       ANDI R0,>0007
       JEQ MOVEU2
       ANDI R0,>0004
       JEQ MOVEL2
       JMP MOVER2

MOVERT
       MOV R13,R0     * Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ !
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2
       
!      MOV R13,R0     * Check at right edge of screen
       ANDI R0,>00FF
       CI R0,256-16
       JNE !
       BL @SCRLRT

!      MOV R13,R0
       AI R0,>0810    * 8 pixels down, 16 right
       LI R2,!
       BL @TESTCH

MOVER2 INC R13        * Move X coordinate right
       INV @MOVE12
       JEQ !          * Check if additional movement needed
       MOV R13,R1
       ANDI R1,>0007  * Check if 8-pixel aligned
       JEQ !
       INC R13        * Add additional movement if not aligned
!      MOV R13, R1
       SWPB R1
       ANDI R1,>0800  * Set sprite animation based on coordinate
       AI R1,>3000

       JMP MOVE2      * Update the sprite animation


MOVELT
       MOV R13,R0    * Make Y coord 8-aligned
       ANDI R0,>0700
       JEQ !
       ANDI R0,>0400
       JEQ MOVEU2
       JMP MOVED2

!      MOV R13,R0     * Check at left edge of screen
       ANDI R0,>00FF
       JNE !
       BL @SCRLLT

!      MOV R13,R0
       AI R0,>07FF  * 8 pixels down, 1 left
       LI R2,!
       BL @TESTCH
       
MOVEL2 DEC R13        * Move X coordinate left
       INV @MOVE12        * Check if additional movement needed
       JEQ !
       MOV R13,R1
       ANDI R1,>0007  * Check if 8-pixel aligned
       JEQ !
       DEC R13        * Add additional movement if not aligned
!      MOV R13, R1
       SWPB R1
       ANDI R1,>0800  * Set sprite animation based on coordinate
       AI R1,>2000


MOVE2  LI R0,SPRLST+2  * Update the sprite animation
       BL @VDPWB
       LI R0,SPRLST+6
       AI R1,>0400
       BL @VDPWB
       B @DRAW

MOVED2 AI R13,>0100   * Move Y coordinate down
       INV @MOVE12     * Check if additional movement needed
       JEQ !
       MOV R13,R1     
       ANDI R1,>0700  * Check if 8-pixel aligned
       JEQ !
       AI R13,>0100   * Add additional movement if not aligned
!      MOV R13,R1
       ANDI R1,>0800  * Set sprite animation based on coordinate
       JMP MOVE2      * Update the sprite animation

MOVEU2 AI R13,>FF00   * Move Y coordinate up
       INV @MOVE12     * Check if additional movement needed
       JEQ !
       MOV R13,R1
       ANDI R1,>0700  * Check if 8-pixel aligned
       JEQ !
       AI R13,>FF00   * Add additional movement if not aligned
!      MOV R13,R1
       ANDI R1,>0800  * Set sprite animation based on coordinate
       AI R1,>1000
       JMP MOVE2      * Update the sprite animation

SCRLRT LI   R0,>0100           * Add 1 to MAPLOC X
       AI   R13,->00F0
       LI   R2,4             * Use scroll right 4
       JMP !

SCRLLT LI   R0,>FF00           * Add -1 to MAPLOC X
       AI   R13,>00F0
       LI   R2,3             * Use scroll left 3
       JMP !

SCRLDN LI   R0,>1000           * Add 1 to MAPLOC Y
       AI   R13,-19*8*256
       LI   R2,2             * Use scroll down 2
       JMP !

SCRLUP LI   R0,>F000           * Add -1 to MAPLOC Y
       AI   R13,19*8*256
       LI   R2,1             * Use scroll up 1

!      AB   R0,@MAPLOC
       LI   R0,BANK2         * Overworld is in bank 2
       LI   R1,HDREND        * First function in bank 1
       B    @BANKSW
       

* Look at character at pixel coordinate in R0, and jump to R2 if solid
TESTCH
* Convert pixel coordinate YYYYYYYY XXXXXXXX 
* to character coordinate        YY YYYXXXXX
       ANDI R0,>F8F8
       MOV R0,R1
       SRL R1,3
       MOVB R1,R0
       SRL R0,3
       MOV R11,R10   * Save return address
       BL @VDPRB
       CI R1,>7F00
       JH !
       B *R10        * Jump saved return address
!      B *R2





SPRL0  BYTE 120-8
       BYTE 128-8
       BYTE 0
       BYTE 3
SPRL1  BYTE 120-8
       BYTE 128-8
       BYTE 4
       BYTE 1
SPRL2  BYTE >D0
       BYTE >D0
       BYTE 0
       BYTE 1

       COPY 'overworld.asm'

       
SLAST  END  MAIN
