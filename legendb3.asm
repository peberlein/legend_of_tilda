*
* Legend of Tilda
* 
* Bank 3: dungeon map
*

       COPY 'legend.asm'

       
* Load a map into VRAM
MAIN


       LI R0,BANK0          * Load bank 0
       MOV R11,R1           * Jump to our return address
       B @BANKSW
       