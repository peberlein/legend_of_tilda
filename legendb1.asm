*
* Legend of Tilda
* 
* Bank 1: music
*


       COPY 'legend.asm'

       
* Load a song into VRAM, R2 indicates song 0=overworld 1=dungeon
MAIN
       MOV  R11,R3           * Save our return address
       MOV  R2,R0
       JNE  !
       LI   R1,SNDLST        * Music Address in ROM
       LI   R2,SNDEND-SNDLST  * Music Length in bytes
       B    @SND2

!      LI   R1,SNDLS2        * Music Address in ROM
       LI   R2,SNDEN2-SNDLS2  * Music Length in bytes
SND2
       LI   R0,MUSICV        * Music Address in VRAM
       BL   @VDPW            * Copy to VRAM
       
       LI   R0,1             * Music counter = 1
       MOV  R0,@MUSICC
       LI   R15,MUSICV       * Music pointer in VRAM
       
       LI   R0,BANK0         * Load bank 0
       MOV  R3,R1            * Jump to our return address
       B    @BANKSW
       
SNDLST BCOPY "music.snd"
SNDEND

SNDLS2 BCOPY "dungeon.snd"
SNDEN2