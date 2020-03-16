;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 1: compressed sprites



       COPY 'tilda.asm'

       
; R2=sprite index to load
; R2LB=count

; TODO load enemy objects/sprites
;  save enemy count (and if zero, put in zeroenemy fifo)
;  load enemies
;  load enemy sprites (in this bank)
;  set enemy number to saved count, or none if in zeroenemy fifo
;

; R2=100 animate fire/fairy sprites
; R2=10 Load enemies (called from bank2, return to bank 0)

; TODO make it possible to load ranges of sprites, from bank4
; modifies R0-R10,R12-R13
MAIN
       MOV  R11,@OBJPTR      ; Save our return address
       CI R2,100
       JEQ FFANIM             ; Flame/Fairy animation

       CI R2,10
       JNE !
       B @LENEMY             ; Load enemies
!

       LI R3,SPRITE            ; Pointer to compressed sprites
       LI R4,SPRPAT+(28*32)    ; Start output at item sprites
       LI R7,MODES
       CLR R8
       LI R9,112
DECOM0
       BL @DECOM2            ; Decompress sprites

DONE
       LI   R0,BANK0         ; Load bank 0
       MOV  @OBJPTR,R1       ; Jump to our return address
       JMP    BANKSW



; Flame and fairy animation
FFANIM
       LI R3,FFSPR1            ; Pointer to compressed sprites
       MOV @COUNTR,R0
       ANDI R0,>0004
       JNE !
       LI R3,FFSPR2            ; Pointer to compressed sprites
!
       LI R4,SPRPAT+(60*32)    ; Start output at flame sprite
       LI R7,MODEND
       LI R8,>01C0             ; Normal, H-center
       LI R9,2                 ; 2 sprites
       JMP DECOM0

LDUNG0
       CLR @MOVE12
       B @DONE

LDUNGE ; Load dungeon enemies  R0=FLAGS R1=MAPLOC R9=LASTOB
       ANDI R0,INCAVE
       ;JNE LDCAVE  ; TODO

       LI R0,SPRLST+(6*4)      ; Clear sprite list [6..31]
       LI R2,(32-6)*2          ; (including scratch)
!      CLR *R0+
       DEC R2
       JNE -!


       ; get enemy group index
       MOV R1,R0
       AI R0,SDENEM*2   ; R0 = save data overworld enemies counts
       MOV R1,R2
       A R2,R2
       AI R2,OENEMY    ; R2 = overworld enemy table

       MOV @FLAGS,R1
       ANDI R1,DUNLVL  ; test for dungeon or overworld
       JEQ !           ; overworld
       AI R0,(DNENEM*2)-(SDENEM*2)   ; dungeon enemies counts
       AI R2,DENEMY-OENEMY
!

       MOV *R2,R4   ; R4 = xyy   x=enemy count, yy=enemy index or group & flags
       JEQ LDUNG0   ; zero enemies

       ; get saved count
       SRL R0,1      ; R0 = save data enemy counts + map offset
       JOC !         ; odd, use lower nibble
       BL @VDPRB     ; R1 = saved count nibbles
       SRL R1,4      ; even, use upper nibble
       JMP !!
!
       BL @VDPRB     ; R1 = saved count nibbles
!      ANDI R1,>0F00   ; R1 = saved enemy count
       JNE !!

       ; zero count, check for recent list
       LI R0,RECLOC
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       LI R0,8              ; number of recent location slots
!      CB @MAPLOC,@VDPRD    ; is current map location on list?
       JEQ LDUNG0           ; visited recently, so no enemies
       DEC R0
       JNE -!
       JMP !!

!      ; count is nonzero
       C R1,R4     ; sanity check
       JH !        ; skip if saved count is greater than expected

       ; replace R4 with saved count
       ANDI R4,>00FF
       SOC R1,R4
!
       ; R2 = pointer to entry in OENEMY or DENEMY
       ; R4 = current count and enemy type/group
       ; TODO R2 should be adjusted if group

       MOV R2,@MOVE12 ; save for loading sprites
       ANDI R4,>0F00
       MOV R4,@HURTC  ; save for loading sprites

       LI R3,LASTOB   ; R3 = start filling enemies here
!
       MOV *R2+,R6     ; get enemy count and enemy type

       MOV R6,R7
       ANDI R7,>0F00   ; R7 = count
       SZC R7,R6       ; enemy type
       SLA R6,3        ; table entries are 8 bytes
       AI R6,ENDATA    ; array of data 8 bytes each
!
       MOV R3,R0
       MOV R3,R1
       MOV *R6+,*R3+    ; copy enemy type
       AI R1,((SPRLST+2)/2)-OBJECT  ; point to sprite and color
       SLA R1,1
       MOV *R6+,*R1    ; copy enemy sprite

       ; next *R1 bytes are damage(4) drop(4) hp(8) stun(8) hurt(8)
       AI R0,(ENEMDT*2)-OBJECT
       MOVB *R6+,R1
       BL @VDPWB
       AI R0,ENEMHP-ENEMDT-VDPWM
       MOVB *R6+,R1
       BL @VDPWB
       AI R0,(ENEMHS/2)-ENEMHP-VDPWM
       SLA R0,1
       MOVB *R6+,R1
       BL @VDPWB
       MOVB *R6+,*R15

       AI R6,-8      ; rewind table entry

       AI R4,->100    ; decrement enemy counter
       JEQ !          ; done if zero

       AI R7,->100    ; decrement group counter
       JNE -!         ; next in same group

       JMP -!!        ; next group

!
       MOV @MOVE12,R1
LOADSP ; load sprite patterns
       MOV *R1,R5      ; get enemy count and type
       ANDI R5,>00FF   ; enemy type
       SLA R5,3        ; table entries are 8 bytes
       MOV @ENDATA+8(R5),R4   ; src idx(8) dst(4) count(4)

       MOV R4,R2
       SRL R2,8        ; R2 = src idx

       MOV R4,R9
       ANDI R9,>000F    ; R9 = count
       JEQ !!            ; sanity check

       ANDI R4,>00F0
       SLA R4,1
       AI R4,SPRPAT+(8*32)   ; R4 = (dest index+8)*32

       ; decompress overworld enemy sprites
       LI R3,SPR64 ; overworld mob sprites start at 64
       LI R7,MODES+32

       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !        ; not in dungeon

       ; decompress dungeon enemy sprites
       LI R3,SPR128 ; dungeon mob sprites start at 128
       LI R7,MODES+64
!
       ; R2 = sprite index, R3 = SPRXXX, R4 = VDP address, R7 = mode, R9 = count
       BL @DECOMX       ; decompress sprites
!
       MOV @MOVE12,R1
       INCT @MOVE12
       MOV *R1,R2   ; get next group byte
       ANDI R2,>0F00
       S R2,@HURTC
       JLT LOADSP   ; enemy count zero

       CLR @MOVE12
       CLR @HURTC
       B @DONE




       ; Load dungeon cave or tunnel
LDCAVE

CAVDAT DATA >D05F,>5848,>0000 ; Flame object id, location, sprite
       DATA >D05F,>58A8,>0000 ; Flame object id, location, sprite
       DATA >C0DF,>5878,>D00F ; Old man object id, location, sprite

LCAVE  ; load cave

       LI R8,LASTSP
!      CLR *R8+
       CI R8,WRKSP+256        ; Clear sprite table
       JNE -!


;       LI R5,SPRPAT+(76*32)   ; copy cave item sprites
;       LI R9,SPRPAT+(8*32)    ; into enemies spots
;       LI R4,14               ; copy 14 sprite patterns
;!      MOV R5,R0
;       BL @READ32
;       MOV R9,R0
;       BL @PUTSCR
;       AI R5,32
;       AI R9,32
;       DEC R4
;       JNE -!
;
;       LI R0,ENESPR+(20*32)   ; Copy Moblin sprite
;       BL @READ32
;       MOV R9,R0
;       BL @PUTSCR

       LI R2,48             ; copy cave item sprites
       LI R4,SPRPAT+(8*32)  ; into enemies spots
       LI R9,14             ; copy 14 sprites
       BL @DECOM1

       LI R2,20          ; Copy Moblin sprite
       LI R9,1
       BL @DECOMO

       LI R2,3            ; 2 fires and 1 npc

       LI R4,LASTOB       ; object list
       LI R5,LASTSP       ; sprite list
       LI R7,CAVDAT
!
       MOV *R7+,*R4+      ; Object ID
       MOV *R7+,*R5+      ; Object pos
       MOV *R7+,*R5+      ; Object sprite
       DEC R2
       JNE -!

       ; Don't spawn NPC if item bit is set
       LI R1,SDITEM    ; use cave items
       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !
       LI R1,SDDUNG    ; use dungeon items
!      MOVB @MAPLOC,R0
       SRL R0,8
       BL @GETBIT
       JNC !            ; NPC should appear
       CLR @-2(R4)      ; clear object
       AI R5,-4         ; clear sprites

       ; Clear remaining sprite table
!      CLR *R5+
       CI R5,WRKSP+256
       JNE -!
CAVERT
       MOV @HEROSP,R5        ; Get hero YYXX
       B @DONE




       ; Load overwold enemies
LENEMY
       MOVB @MAPLOC,R1         ; Get map location
       SRL R1,8

       LI R9,LASTOB        ; Start filling the object list at last index

       MOV @FLAGS,R0
       MOV R0,R7
       ANDI R7,DUNLVL
       JEQ !
       B @LDUNGE           ; Load dungeon enemies
!
       ANDI R0,INCAVE
       JNE LCAVE            ; Load overworld cave items instead

       MOVB @ENEMYS(R1),R0     ; Get enemy group index at map location
       SRL R0,8

       LI R7,ENEMYG           ; Pointer to enemy groups

       MOV  R0,R5
       LI R4,4              ; 4 Armos sprites
       LI R8, ENESPR+(>2C*32)   ; Armos sprite source address index >2C
       LI R10,SPRPAT+(>18*32)   ; Destination sprite address index >60
       ANDI R0,>0080        ; Test zora bit
       JEQ LENEM2
       LI R0,ZORAID         ; Zora enemy type
       MOV R0,*R9+          ; Store it
       INC R4 	     	    ; 5 Zora sprites
       LI R8,ENESPR+(>20*32)    ; Zora sprite source address index >20
       AI R10,32            ; Destination sprite address index >61

LENEM2 MOV R8,R0            ; Copy Zora or Armos sprite
       AI R8,32
       BL @READ32           ; Read sprite into scratchpad

       MOV R10,R0
       AI R10,32
       BL @PUTSCR           ; Copy it back to the sprite pattern table

       CI R8,ENESPR+(>23*32)   ; After zora (pulsing ground)
       JNE !
       LI R10,SPRPAT+(>0A*32)   ; Pulsing ground dest address index >28

!      DEC R4
       JNE LENEM2


       MOV R5,R1               ; R5 = enemy group index
       MOV R5,R0
       ANDI R0,>0040           ; Test edge loading bit
       ; TODO

       ANDI R1,>003F          ; Mask off zora and loading behavior bits to get group index
       JNE LENEM3
       JMP LENEM6                ; No enemies on this screen

!      CLR R3
       MOVB *R7+,R3
       CI R3,>8000             ; Keep reading until the end of the group (upper bit not set)
       JHE -!
LENEM3 DEC R1                  ; Decrement counter until we locate the enemy group
       JNE -!


LENEM4 MOVB *R7+,R3            ; Load the number and type of enemies

       MOV R3,R4
       SRL R4,12
       ANDI R4,>0007           ; Get the count of enemies
       JEQ LENEM5

       MOV R3,R8
       ANDI R8,>0F00           ; Get only the enemy type
       SWPB R8
       JNE !
       LI R8,FRY2ID           ; Fairy pond special case
!      MOV R8,*R9+            ; Store enemy type in objects array
       DEC R4
       JNE -!

       A R8,R8                 ; Load the sprites for this enemy
       MOV @ENEMYP(R8),R4      ; Get Enemy pattern (XXYZ -> XX = source pattern offset, Y = dest index + 20, Z = sprite count)
       JEQ LENEM5

       MOV R4,R8
       ANDI R8,>FF00
       SRL  R8,3
       AI   R8,ENESPR          ; Get source offset in R8 = XX * 32 + ENESPR

       MOV R4,R10
       ANDI R10,>00F0
       SLA  R10,2
       AI  R10,SPRPAT+>0100     ; Calculate dest offset into sprite pattern table (Y * 64 + >20 * 8)

       ANDI R4,>000F       ; The number of sprites to copy
!      MOV R8,R0
       BL @READ32          ; Read sprite into scratchpad
       AI R8,32

       MOV R10,R0
       BL @PUTSCR          ; Copy it back to the sprite pattern table
       AI R10,32

       DEC R4
       JNE -!

LENEM5 A R3,R3             ; Keep reading until the end of the group (upper bit not set)
       JOC LENEM4

       LI R0,ENEMHP+12+VDPWM      ; Fill enemy HP
       MOVB @R0LB,*R14
       MOVB R0,*R14

       LI R9,LASTOB      ; Read objects
       LI R4,(SPRLST-LASTOB)/2 ; 32-12
!      MOV *R9+,R1
       ANDI R1,>003F
       MOVB @INITHP(R1),*R15 ; Copy initial HP
       DEC R4
       JNE -!

LENEM6
       ;BL @RECENT              ; update recent entries

       LI R0,SPRLST+(6*4)      ; Clear sprite list [6..31]
       LI R2,(32-6)*2          ; (including scratchpad)
!      CLR *R0+
       DEC R2
       JNE -!

       B @CAVERT



RECENT ; keep track of recent map locations visited
       ; read the most recent 8 map locs
       LI R0,RECLOC
       LI R1,SCRTCH
       LI R2,8
       BL @VDPR

       LI R0,RECLOC
       MOVB @MAPLOC,R1
       BL @VDPWB       ; write the current location first

       LI R0,SCRTCH
       LI R2,7
!      CB *R0+,R1
       JEQ -!           ; skip writing current maploc (already written first)
       DEC R0
       MOVB *R0+,@VDPWD
       DEC R2
       JNE -!
       RT




* R3 = pointer to compressed sprites data
* R4 = sprite pattern address in VDP
* R7 = pointer to next compression type nibbles
* R8 = current compression type nibble word
* R9 = count of sprites to decompress



****************************************
* Enemy pattern indexes (XXYZ -> XX = source pattern offset, Y = dest index*4+20, Z = count)
* Y table 0:20 1:28 2:30 3:38 4:40 5:48 6:50 7:58 8:60 9:68
****************************************
ENEMYP DATA >0000  ; 0 Fairy
       DATA >0002  ; 1 Peahat              (both vertical symmetry)
       DATA >0222  ; 2 Red Tektite         (both vertical symmetry)
       DATA >0222  ; 3 Blue Tektite        (both vertical symmetry)
       DATA >0449  ; 4 Red Octorok         (both vertical symmetry, both horizontal symmetry, flips + bullet)
       DATA >0449  ; 5 Blue Octorok        (both vertical symmetry, both horizontal symmetry, flips + rotations + bullet)
       DATA >0449  ; 6 Fast Red Octorok
       DATA >0449  ; 7 Fast Blue Octorok
       DATA >1008  ; 8 Red Moblin          (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1008  ; 9 Blue Moblin         (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1848  ; A Red Lynel           (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >1848  ; B Blue Lynel          (1 sprite flipped, 2 sprites both flipped, 1 sprite flipped)
       DATA >2804  ; C Ghini               (1 sprite flipped, 1 sprite flipped)
       DATA >0E22  ; D Rock                (2 sprites)
       DATA >2315  ; E Red Leever          (5 sprites, all vertical symmetry)
       DATA >2315  ; F Blue Leever         (5 sprites, all vertical symmetry)

       ; D1: keese, stalfos, trap, zol, goriya, wallmaster, aquamentus
       ; D2: keese, rope, goriya, B goriya, trap, zol, statues, moldorm, dodongo
       ; D3: keese, darknut, trap, gel/zol, bubble, manhandla
       ; D4: keese, vire, trap, gel/zol, likelike, bubble, manhandla, gleeok
       ; D5: keese, gibdo, darknut, B darknut, gel/zol, polsvoice, statues, dodongo, digdogger
       ; D6: keese, trap, gel/zol, wizzrobe, B wizzrobe, vire, likelike, gleeok, bubble, gohma
       ; D7: keese, stalfos, rope, trap, goriya, B goriya, dodongo, digdogger, moldorm, aquamentas, wallmaster, bubble
       ; D8: keese, gibdo, bubble, darknut, B darknut, pols voice, statues, manhandla, gohma, gleeok
       ; D9: keeze, patra, trap, likelike, wizzrobe, B wizzrobe, bubble, gel/zol, moldorm, statue, vire,


; 00-03  Keese, Trap, Zol, Gel
; 04-07  Rope, Vire, Bubble, Gibdo
; 08-0B  LikeLike, Pols Voice, Darknut, Blue Darknut
; 0C-0F  Stalfos, Wallmaster, Goriya, Blue Goriya
; 10-13  Wizzrobe, Blue Wizzrobe, Aquamentas, Aquamentas2
; 14-17  Dodongo, Digdogger, Gleeok2, Gleeok3
; 18-1B  Gleeok4, Gohma-1, Gohma-3, Manhandla
; 1C-1F  Moldorm, Lanmola, Patra,



DENEMP DATA >0002  ; 0 Keese      12345678
       DATA >0000  ; 1 Trap       1234 67 9
       DATA >0000  ; 2 Zol        1 3456  9
       DATA >0000  ; 3 Gel          3456  9
       DATA >0000  ; 4 Rope        2    7
       DATA >0000  ; 5 Vire          4 6  9
       DATA >0000  ; 6 Bubble       34 6  9
       DATA >0000  ; 7 Darknut      3 5  8
       DATA >0000  ; 8 Likelike      4 6  9
       DATA >0000  ; 9 Pols Voice     5  8
       DATA >0000  ; A Statues     2  5  89
       DATA >0000  ; B

       ; 1,2,7
       DATA >0222  ; C Stalfos    1,7
       DATA >0000  ; D Wallmaster 1,7
       DATA >0000  ; E Goriya     1,2,7
       DATA >0000  ; F B Goriya   2,7

       ; 5,6,8,9
       DATA >0000  ; D Gibdo      5,8
       DATA >0000  ; C B Darknut  5,8
       DATA >0000  ; E Wizzrobe   6,9
       DATA >0000  ; F B Wizzrobe 6,9

DBOSSP DATA >0000  ; 0 none
       DATA >0000  ; 1 Aquamentas1 1,7
       DATA >0000  ; 2 Dodongo     2,7
       DATA >0000  ; 3 Dodongo x3  2,7
       DATA >0000  ; 4 Digdogger   5,7
       DATA >0000  ; 5 Gleeok-2    4
       DATA >0000  ; 6 Gleeok-3    6
       DATA >0000  ; 7 Gleeok-4    8
       DATA >0000  ; 8 Gohma-1     6
       DATA >0000  ; 9 Gohma-3     8
       DATA >0000  ; A Manhandla   3,4,8
       DATA >0000  ; B Moldorm x2  2,7
       DATA >0000  ; C Lanmola-1   9
       DATA >0000  ; D Lanmola-2   9
       DATA >0000  ; E Patra       9
       DATA >0000  ; F Old man/grumble grumble























       ; initial HP for enemies
INITHP BYTE 0,2,1,1     ; Armos Peahat RedTektite BlueTektite
       BYTE 1,2,1,2     ; RedOctorok BlueOctorok FastRedOctorok FastBlueOctorok
       BYTE 2,3,4,6     ; RedMoblin BlueMoblin RedLynel BlueLynel
       BYTE 9,0,2,4     ; Ghini Rock RedLeever BlueLeever
       BYTE 2           ; Zora

       ; initial drop table for enemies
INITDT BYTE 0,4,1,3     ; Armos Peahat RedTektite BlueTektite
       BYTE 1,2,1,2     ; RedOctorok BlueOctorok FastRedOctorok FastBlueOctorok
       BYTE 1,2,4,2     ; RedMoblin BlueMoblin RedLynel BlueLynel
       BYTE 3,0,3,1     ; Ghini Rock RedLeever BlueLeever
       BYTE 4           ; Zora

* Group 1     2     3     4     0=nothing
* 0   Rupee Bomb  Rupee Heart
* 1   Heart Rupee Heart Fairy
* 2   Rupee Clock Rupee Rupee
* 3   Fairy Rupee BlRup Heart
* 4   Rupee Heart Heart Fairy
* 5   Heart Bomb  Clock Heart
* 6   Heart Rupee Rupee Heart
* 7   Rupee Bomb  Rupee Heart
* 8   Rupee Heart Rupee Rupee
* 9   Heart Heart BlRup Heart
*
* 1 - OctorokR, TektiteR, MoblinR, LeeverB, WizzrobeB
* 2 - OctorokB, MoblinB, LynelB, GoriyaR, Gibdo, Vire, DarknutR, WizzrobeR
* 3 - TektiteB, LeeverR, Stalfos, Gel, Ghini, RopeR/B, WallMaster, PolsVoice, LanmolaB
* 4 - Peahat, Zora, LynelR, GoriyaB, DarknutB, Moldorm, Aquamentus
*       Dodongo, Digdogger, Patra, Gleeok, Gohma, LanmolaR
*
* Kill counter (reset to zero if link is hit)
* 10 - killed w/ bomb, drops bomb, else 5 rupee
* 16 - drops fairy
* 26, 36, 46, etc. - killed w/ bomb, drops bomb, else 5 rupee


****************************************
* Enemy groups  (XY -> Y = Enemy pattern index  X = Count or Count + 8 if more enemies in group)
****************************************
ENEMYG BYTE >4A     ; 01  4 red lynel
       BYTE >4D     ; 02  4 rocks
       BYTE >6B     ; 03  6 blue lynel
       BYTE >AB,>AA,>9E,>1F    ; 04  2 blue lynel 2 red lynel 1 red leveer 1 blue leveer
       BYTE >AB,>AA,>21 ; 05  2 blue lynel 2 red lynel 2 peahat
       BYTE >1A     ; 06  1 red lynel
       BYTE >1B     ; 07  1 blue lynel
       BYTE >1E     ; 08  1 red leever
       BYTE >62     ; 09  6 red tektite
       BYTE >4B     ; 0A  4 blue lynel
       BYTE >AB,>2A ; 0B  2 blue lynel 2 red lynel
       BYTE >61     ; 0C  6 peahat
       BYTE >41     ; 0D  4 peahat
       BYTE >4E     ; 0E  4 red leever
       BYTE >6F     ; 0F  6 blue leever
       BYTE >AF,>9E,>31 ; 10  2 blue leever 1 red leveer 3 peahat
       BYTE >42     ; 11  4 red tektite
       BYTE >B6,>25 ; 12  3 fast red octorok 2 blue octorok
       BYTE >45     ; 13  4 blue octorok
       BYTE >4F     ; 14  4 blue leever
       BYTE >14     ; 15  1 red octorok
       BYTE >C6,>15 ; 16  5 fast red octorok 1 blue octorok
       BYTE >10     ; 17  fairy
       BYTE >15     ; 18  1 blue octorok
       BYTE >49     ; 19  4 blue moblin
       BYTE >48     ; 1A  4 red moblin
       BYTE >B9,>18 ; 1B  3 blue moblin 1 red moblin
       BYTE >42     ; 1C  4 red tektite
       BYTE >53     ; 1D  5 blue tektite
       BYTE >43     ; 1E  4 blue tektite
       BYTE >6E     ; 1F  6 red leever
       BYTE >18     ; 20  1 red moblin
       BYTE >44     ; 21  4 red octorok
       BYTE >11     ; 22  1 peahat
       BYTE >63     ; 23  6 blue tektite
       BYTE >78     ; 24  7 red moblin
       BYTE >5A     ; 25  5 red lynel
       BYTE >59     ; 26  5 blue moblin
       BYTE >A9,>28 ; 27  2 blue moblin 2 red moblin
       BYTE >B9,>28 ; 28  3 blue moblin 2 red moblin
       BYTE >99,>B8,>27 ; 29  1 blue moblin 3 red moblin 2 fast blue octorok
       BYTE >1C     ; 2a  1 ghini
       BYTE >A4,>26 ; 2b  2 red octorok, 2 fast red octorok
       BYTE >B4,>27 ; 2c  3 red octorok 2 fast blue octorok
       BYTE >12     ; 2d  1 red tektite

       ; +40 enemies enter from sides of screen (otherwise appear in puffs of smoke)
       ; +80 zora (otherwise armos sprites are loaded)

ENEMYS BYTE >00,>01,>01,>02,>03,>04,>05,>06,>02,>00,>87,>08,>09,>09,>00,>00
       BYTE >0A,>05,>03,>0B,>01,>05,>02,>82,>82,>82,>89,>00,>00,>0C,>89,>0C
       BYTE >2a,>2a,>06,>01,>00,>0D,>8C,>8C,>8C,>0E,>0F,>10,>11,>92,>93,>00
       BYTE >2a,>2a,>05,>00,>14,>80,>80,>15,>96,>17,>10,>14,>18,>19,>92,>98
       BYTE >2a,>2a,>20,>17,>A1,>22,>80,>80,>8E,>16,>23,>24,>12,>19,>19,>AC
       BYTE >25,>26,>27,>28,>A1,>95,>A1,>2B,>2B,>8D,>A1,>27,>19,>19,>26,>92
       BYTE >05,>26,>26,>29,>12,>AB,>2B,>21,>21,>A1,>A1,>29,>1A,>1A,>29,>96
       BYTE >0D,>26,>1B,>19,>2D,>90,>11,>00,>21,>1D,>1E,>9F,>9F,>93,>A1,>98


       ; New group idea
       ; count(2 bits) 1..4  index(5 bits)

       ; group index (7 bits)

       ; Dungeon enemy groups XY -> Y=pattern index, X=count-1 / +8 if group, or Y=bosstype X=0
DENEMG BYTE >20    ;01 3 keese
       BYTE >50    ;02 6 keese
       BYTE >60    ;03 7 keese
       BYTE >70    ;04 8 keese
       BYTE >A0,>A0,>90  ;05 3 keese, 3 bubble, 2 gel

       BYTE >21    ;06 3 stalfos/gibdo
       BYTE >41    ;07 5 stalfos/gibdo
       BYTE >51    ;08 6 stalfos/gibdo
       BYTE >51    ;09 7 stalfos/gibdo
       BYTE >A0,>90,>80,>10 ;0A 3 stalfos/gibdo, 2 darknut, 1 B darknut, 2 bubble
       BYTE >90,>90,>90 ;0B 2 keese, 2 stalfos/gibdo, 2 pols voice

       BYTE >24    ;0C 3 zols
       BYTE >34    ;0D 4 zols
       BYTE >44    ;0E 5 zols
       BYTE >54    ;0F 6 zols
       BYTE >64    ;10 7 zols
       BYTE >74    ;11 8 zols
       BYTE >20    ;12 3 gels
       BYTE >40    ;13 5 gels
       BYTE >50    ;14 6 gels

       BYTE >34    ;15 4 traps
       BYTE >B4,>30    ;16 4 traps, 4 keese
       BYTE >B4,>10    ;17 4 traps, 2 gel
       BYTE >54    ;18 6 traps

       BYTE >20    ;19 3 vire
       BYTE >40    ;1A 5 vire
       BYTE >50    ;1B 6 vire
       BYTE >A0,>10 ;1C 3 vire, 2 bubble

       BYTE >20    ;1D 3 darknuts
       BYTE >40    ;1E 5 darknuts
       BYTE >60    ;1F 7 darknuts

       BYTE >00,>20 ;20 5 wallmasters/B darknut, 3 bubble
       BYTE >40    ;21 5 wallmasters/B darknuts
       BYTE >50    ;22 6 wallmasters/B darknuts
       BYTE >90,>90,>10 ;23 2 pols voice, 2 darknut, 2 B darknut

       BYTE >30    ;24 4 polsvoice
       BYTE >40    ;25 5 polsvoice
       BYTE >60    ;26 7 polsvoice

       BYTE >90,>90,>10   ;27 2 keese, 2 pols voice, 2 stalfo/gibdo

       BYTE >22    ;28 3 rope
       BYTE >42    ;29 5 rope
       BYTE >52    ;2A 6 rope
       BYTE >62    ;2B 7 rope

       BYTE >10    ;2C 2 wizzrobes/goriya
       BYTE >20    ;2D 3 wizzrobes/goriya
       BYTE >30    ;2E 4 wizzrobes/goriya
       BYTE >40    ;2F 5 wizzrobes/goriya
       BYTE >50    ;30 6 wizzrobes/goriya

       BYTE >80,>10  ;31 1 wizzrobes/goriya, 2 B wizzrobes/B goriya
       BYTE >80,>A0,>20  ;32 1 wizzrobes/goriya, 3 B wizzrobes/B goriya, 3 bubble
       BYTE >90,>10  ;33 2 wizzrobes/goriya, 2 B wizzrobes/B goriya
       BYTE >90,>90,>34  ;34 2 wizzrobes/goriya, 2 B wizzrobes/B goriya, 4 trap
       BYTE >90,>90,>90,>10  ;35 2 wizzrobes, 2 B wizzrobes, 2 bubble, 2 likelike
       BYTE >90,>90,>80,>20  ;36 2 wizzrobes, 2 B wizzrobes, 1 bubble, 3 likelike
       BYTE >90,>20  ;37 2 wizzrobes/goriya, 3 B wizzrobes/B goriya
       BYTE >90,>A0,>20  ;38 2 wizzrobes/goriya, 3 B wizzrobes/B goriya, 3 bubble
       BYTE >90,>B0,>20  ;39 2 wizzrobes/goriya, 4 B wizzrobes/B goriya, 3 bubble
       BYTE >A0,>20  ;3A 3 wizzrobes/goriya, 3 B wizzrobes/B goriya

       BYTE >90,>80,>20  ;3B 2 B wizzrobes, 1 bubble, 3 likelike
       BYTE >A0,>90  ;3C 3 B wizzrobes/B goriya, 2 bubble
       BYTE >A0      ;3D 3 B wizzrobes/B goriya
       BYTE >40      ;3E 5 B wizzrobes/B goriya
       BYTE >50      ;3F 6 B wizzrobes/B goriya

       BYTE >10      ;40 2 likelike
       BYTE >50      ;41 6 likelike
       BYTE >90,>10  ;42 2 likelike, 2 bubble
       BYTE >A0,>30  ;43 4 likelike, 4 trap
       BYTE >90,>90,>10  ;44 2 likelike, 2 bubble, 2 gel

       ;TODO boss types

; enemy types:
; overworld: 16
       ; Blue Lynel, Red Lynel, Blue Moblin, Red Moblin
       ; Red Octorok, Red Octorok Fast, Blue Octorok, Blue Octorok Fast
       ; Blue Tektite, Red Tektite, Blue Leever, Red Leever
       ; Peahat, Rock, Ghini, Lake Fairy

; dungeon enemies 24
       ; Blue Goriya, Red Goriya, Red Darknut, Blue Darknut
       ; Vire, Zol, Gel1, Gel2
       ; Pols Voice, LikeLike, Gibdo, Trap
       ; Blue Keese, Red Keese, Dark Keese,
       ; Bubble, Blue Bubble, Red Bubble,
       ; Blue Wizzrobe, Red Wizzrobe, Patra Big, Patra Small
; dungeon bosses 24
       ; Dodongo, Manhandla, Aquamentus, Ganon
       ; Blue Gohma, Red Gohma, Digdogger 3, Digdogger 1
       ; Red Lanmola, Blue Lanmola, Moldorm,
       ; Gleeok 1, Gleeok 2, Gleeok 3, Gleeok 4
       ; Zelda, Flame1, Flame2,
       ; Old mans, Hungry Goriya




OENEMY ; overworld enemy table
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000

DENEMY ; 3 bits enemy count, 1 bit statue projectiles, 1 bit group flag, 6 bits enemy type/group
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>411,>320,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>31E,>000,>124,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>00F,>313,>513,>320,>81F,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>610,>51E,>810,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>31E,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>310,>000,>51E,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000

       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000
       DATA >000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000,>000


       ; enemy table
       ; ID (16), sprite(16), damage(4), drop(4), HP(8), src pat(8), dst pat(4), count(4)
ENDATA DATA FARYID,FARYSC,>0000, >0000  ; Fairy?
       DATA >0001, >0000, >0402, >0002  ; 01 Peahat
       DATA >0002, >0000, >0101, >0222  ; 02 Red Tektite
       DATA >0003, >0000, >0301, >0222  ; 03 Blue Tektite
       DATA >0004, >0000, >0101, >0449  ; 04 Red Octorok
       DATA >0005, >0000, >0202, >0449  ; 05 Blue Octorok
       DATA >0006, >0000, >0101, >0449  ; 06 Fast Red Octorok
       DATA >0007, >0000, >0202, >0449  ; 07 Fast Blue Octorok
       DATA >0008, >0000, >0102, >1008  ; 08 Red Moblin
       DATA >0009, >0000, >0203, >1008  ; 09 Blue Moblin
       DATA >000A, >0000, >0404, >1848  ; 0A Red Lynel
       DATA >000B, >0000, >0206, >1848  ; 0B Blue Lynel
       DATA GHINID,>0000, >0309, >2804  ; 0C Ghini
       DATA ROCKID,>0000, >0000, >0E22  ; 0D Rock
       DATA >000E, >0000, >0302, >2315  ; 0E Red Leever
       DATA >000F, >0000, >0104, >2315  ; 0F Blue Leever
       
       DATA >0000, >0000, >0001, >0202  ; 10 Keese
       DATA >0000, >0000, >0000, >1701  ; 11 Trap
       DATA >0000, >0000, >0301, >3404  ; 12 Zol (big)
       DATA >0000, >0000, >0001, >3402  ; 13 Gel (little)
       DATA >0000, >0000, >0301, >1C04  ; 14 Rope
       DATA >0000, >0000, >0202, >0206  ; 15 Vire
       DATA >0000, >0000, >0000, >0000  ; 16 Bubble
       DATA >0000, >0000, >0000, >0000  ; 17 Bubble Blue
       DATA >0000, >0000, >0000, >0000  ; 18 Bubble Red
       DATA >0000, >0000, >0207, >2402  ; 19 Gibdo
       DATA >0000, >0000, >0009, >1403  ; 1A Likelike
       DATA >0000, >0000, >0309, >2602  ; 1B Pols Voice
       DATA >0000, >0000, >0204, >3808  ; 1C Darknut
       DATA >0000, >0000, >0308, >3808  ; 1D Blue Darknut
       DATA >0008, >0000, >0302, >0002  ; 1E Stalfos
       DATA >0000, >0000, >0302, >3002  ; 1F Wallmaster
       DATA >0000, >0000, >0203, >2808  ; 20 Goriya
       DATA >0000, >0000, >0405, >2808  ; 21 Blue Goriya
       DATA >0000, >0000, >0204, >1806  ; 22 Wizzrobe
       DATA >0000, >0000, >0109, >1806  ; 23 Blue Wizzrobe
       DATA >0000, >0000, >0406, >0000  ; 24 Aquamentas
       DATA >0000, >0000, >0402, >0000  ; 25 Dodongo
       DATA >0000, >0000, >0408, >0000  ; 26 Digdogger
       DATA >0000, >0000, >0408, >0000  ; 27 Gleeok 1
       DATA >0000, >0000, >0408, >0000  ; 28 Gleeok 2
       DATA >0000, >0000, >0408, >0000  ; 29 Gleeok 3
       DATA >0000, >0000, >0408, >0000  ; 2A Gleeok 4
       DATA >0000, >0000, >0401, >0000  ; 2B Gohma 1
       DATA >0000, >0000, >0403, >0000  ; 2C Gohma 3
       DATA >0000, >0000, >0404, >0000  ; 2D Manhandla
       DATA >0000, >0000, >0402, >0000  ; 2E Moldorm
       DATA >0000, >0000, >0404, >0000  ; 2F Red Lanmola
       DATA >0000, >0000, >0408, >0000  ; 30 Blue Lanmola
       DATA >0000, >0000, >0409, >1004  ; 31 Patra
       DATA >0000, >0000, >0010, >0000  ; 32 Ganon
       DATA >0000, >0000, >0000, >0000  ; 33 Zelda
       DATA >0000, >0000, >0000, >3202  ; 34 Old Man
       DATA >0000, >0000, >0000, >0000  ; 35 Hungry Goriya
       
       


* Get bit R0 in VDP at address R1, returns bit in C
* modifies R0-R2
GETBIT
       MOV R0,R2
       ANDI R0,7  ; R0 = lower 3 bits
       SRL R2,3
       A R2,R1    ; R1 = adjusted VDP address
       MOVB @R1LB,*R14
       MOVB R1,*R14
       INC R0       ; delaying instruction before read
       MOVB @VDPRD,R1
       SLA R1,R0   ; shift the bit into carry
       RT

* Copy scratchpad to the screen at R0
* Modifies R0,R1,R2
PUTSCR
       ORI R0,VDPWM
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       LI R1,SCRTCH        ; Source pointer to scratchpad ram
       LI R2,8             ; Write 32 bytes from scratchpad
!      MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       MOVB *R1+,*R15
       DEC R2
       JNE -!
       RT

* Copy screen at R0 into scratchpad 32 bytes
* Modifies R1,R2
READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH        ; Dest pointer to scratchpad ram
       LI R2,8             ; Read 32 bytes to scratchpad
       LI R15,VDPRD        ; Keep VDPRD address in R15
!      MOVB *R15,*R1+
READ3  MOVB *R15,*R1+
       MOVB *R15,*R1+
       MOVB *R15,*R1+
       DEC R2
       JNE -!
       LI R15,VDPWD        ; Restore VDPWD address in R15
       RT




DECOMO ; decompress overworld enemy sprites
       LI R3,SPR64 ; overworld mob sprites start at 64
       LI R7,MODES+32
       JMP DECOMX

* Sprite decompression entry point
* R2 = sprite index
* R4 = sprite pattern address in VDP
* R9 = count of sprites to decompress
DECOM1 ; decompress sprites
       LI R3,SPR0
       LI R7,MODES

DECOMX
       MOV R11,R10      ; sprite decompressor returns to R10


       ; R3 = pointer to compressed sprites data
       ; R7 = pointer to next compression type nibbles
       ; R8 = current compression type nibble word

       CLR R8
       MOV R2,R2  ;  if R2 is zero, start decompression immediately
       JEQ !!!

!      SLA R8,4        ; Get next code from R8
       JNE !
       MOV *R7+,R8     ; Refill R8 if empty
!      MOV R8,R1
       ANDI R1,>F000   ; Get offset into jump table
       SRL R1,12
       CLR R0
       MOVB @SIZTBL(R1),R0
       SWPB R0
       A R0,R3         ; offset to next sprite

       DEC R2
       JNE -!!

!
       LI R5,NEXTDC   ; SETVDP will branch to R5
       JMP SETVDP

* Decompression sizes in sprite compressor (spritec.c)
SIZTBL BYTE 0,32,0,0, 0,0,0, 0,0,0, 8,8,16,16,16,16

* Decompression jump table
JMPTBL DATA DONE,NORMAL,HFLIP1,VFLIP1,HFLIP2,VFLIP2,VFLIP3,CLKWS1
       DATA CLKWS2,CLKWS4,HVCENT,HVSYMM,HCENT,VCENT,HSYMM,VSYMM


* Reverse the 16-bit word in R0
* Modifies R1
REVB16
       SWPB R0      ; Reverse groups of 8 bits
REVB8
       MOV R0,R1    ; Reverse even and odd bits
       SRL R1,1
       ANDI R1,>5555
       ANDI R0,>5555
       SLA R0,1
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 2 bits
       SRL R1,2
       ANDI R1,>3333
       ANDI R0,>3333
       SLA R0,2
       SOC R1,R0

       MOV R0,R1    ; Reverse groups of 4 bits
       SRL R1,4
       ANDI R1,>0F0F
       ANDI R0,>0F0F
       SLA R0,4
       SOC R1,R0

       RT

HFLIP1
       MOV R4,R0
       AI R0,-32
       JMP HFLIP

HFLIP2
       MOV R4,R0
       AI R0,-64
       JMP HFLIP

VFLIP1
       MOV R4,R0
       AI R0,-32
       JMP VFLIP

VFLIP2
       MOV R4,R0
       AI R0,-64
       JMP VFLIP

VFLIP3
       MOV R4,R0
       AI R0,-96
       JMP VFLIP

CLKWS1
       MOV R4,R0
       AI R0,-32
       JMP CLKWIS

CLKWS2
       MOV R4,R0
       AI R0,-64
       JMP CLKWIS

CLKWS4
       MOV R4,R0
       AI R0,-128
       JMP CLKWIS


* Copy R2 bytes from R3 to VDP, reversing the bits
* Modifies R0-R2,R5
CPREVB MOV R11,R5   ; Save return address
!      MOVB *R3+,R0  ; read a byte from the right column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       B *R5        ; Return to saved address


NORMAL LI R11,NEXTSP
       LI R2,32
       JMP COPY
COPY16 LI R2,16
       JMP COPY
COPY8
       LI R2,8
* Copy R2 bytes from *R3 to *R15
COPY
!      MOVB *R3+,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

UPCPY8 LI R2,8
       JMP !
UPCP16 LI R2,16
!      A R2,R3
* Copy R2 bytes from *R3 to *R15, moving backward
UPCOPY
!      DEC R3
       MOVB *R3,*R15 ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT


* Read sprite from VDP at R0 in scratch, then set R4 VDP write address
* Saves R3 to R13
* Modifies R0-R3,R5
GETSPR
       MOV R11,R5   ; Save return address
       MOV R3,R13    ; Save R3
       LI R1,SCRTCH
       MOV R1,R3
       LI R2,32
       BL @VDPR      ; Read sprite to flip from VDP
SETVDP ; When branched from elsewhere, set R5 to return address
       MOV R4,R0      ; Set VDP write address
       ORI R0,VDPWM
       MOVB @R0LB,*R14
       MOVB R0,*R14
       B *R5        ; Return to saved address


* source in R3, dest VDP address in R4 (already loaded)
HFLIP
       BL @GETSPR    ; Get sprite from R0 to scratch

       LI R2,16      ; Copy 16 bytes
       A R2,R3       ; Start reading from right column
       BL @CPREVB    ; Copy bytes reversing the bits
       LI R2,16      ; Copy 16 bytes
       AI R3,-32     ; Start reading from left column
       BL @CPREVB    ; Copy bytes reversing the bits
       MOV R13,R3    ; Restore R3
       JMP NEXTSP


* source in R3, dest VDP address in R4 (already loaded)
VFLIP
       BL @GETSPR    ; Get sprite from R0 to scratch

       BL @UPCP16    ; Start reading from the bottom
       AI R3,16      ; Start reading from bottom of next column
       BL @UPCP16
       MOV R13,R3    ; Restore R3
       JMP NEXTSP

CLKWIS
       BL @GETSPR    ; Get sprite from R0 to scratch

       LI R2,32      ; Copy 32 bytes
       AI R3,8       ; Start from lower left
CLKWI2
       CI R2,24
       JEQ !
       CI R2,8
       JNE CLKWI3
!      AI R3,16      ; Get next offset
       JMP !
CLKWI3 CI R2,16
       JNE !
       AI R3,-24     ; Get next offset
!      MOV R2,R0
       NEG R0
       ANDI R0,7     ; Get shift amount
       INC R0

       LI R6,8       ; Copy 8 bits
CLKWI4
       SRL R1,1
       MOVB *R3+,R5
       SLA R5,R0     ; Shift pixel into carry status
       JNC !
       ORI R1,>8000  ; Set a pixel
!      DEC R6
       JNE CLKWI4
       MOVB R1,*R15

       AI R3,-8

       DEC R2
       JNE CLKWI2
       MOV R13,R3    ; Restore R3

       JMP NEXTSP

CPZER4 LI R2,4
       JMP CPZERO
CPZER8 LI R2,8

* Copy R2 zeros to *R15
CPZERO CLR R0
!      MOVB R0,*R15  ; Copy zero to VDP
       DEC R2
       JNE -!
       RT

* Copy R2 bytes from *R3 to *R15, shifting right by 4
CPSR4
!      MOVB *R3+,R1
       SRL R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT
CPSL4  CLR R1
!      MOVB *R3+,R1
       SLA R1,4      ; Shift it
       MOVB R1,*R15  ; Copy byte to VDP data
       DEC R2
       JNE -!
       RT

HVCENT
       BL @CPZER4    ; Copy 4 zero bytes
       LI R2,8       ; Copy 8 shifted bytes
       BL @CPSR4
       BL @CPZER8    ; Copy 8 zero bytes
       LI R2,8       ; Copy 8 bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       BL @CPZER4    ; Copy 4 zero bytes
       JMP NEXTSP


* Sprite decompression entry point
* R3 = pointer to compressed sprites data
* R4 = sprite pattern address in VDP
* R7 = pointer to next compression type nibbles
* R8 = current compression type nibble word
* R9 = count of sprites to decompress
DECOM2
       MOV R11,R10
       LI R5,!
       JMP SETVDP      ; This will return to R5
NEXTSP
       AI R4,32        ; next vdp sprite
       DEC R9          ; decrement sprite count
       JNE !
       B *R10          ; Return to saved address

!
NEXTDC
       SLA R8,4        ; Get next code from R8
       JNE !
       MOV *R7+,R8     ; Refill R8 if empty
!
       MOV R8,R1
       ANDI R1,>F000   ; Get offset into jump table
       SRL R1,11
       MOV @JMPTBL(R1),R1      ; Get jump table entry
       B *R1


HCENT
       LI R2,16      ; Copy 16 shifted bytes
       BL @CPSR4
       LI R2,16      ; Copy 16 shifted bytes
       S R2,R3       ; Start from top again
       BL @CPSL4
       JMP NEXTSP

VCENT
       BL @CPZER4    ; Copy 4 zero bytes
       BL @COPY8     ; Copy 8 bytes
       BL @CPZER8    ; Copy 8 zero bytes
       BL @COPY8     ; Copy 8 bytes
       BL @CPZER4    ; Copy 4 zero bytes
       JMP NEXTSP

HVSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes upward
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
       BL @CPREVB    ; Copy bytes reversing the bits
       LI R2,8       ; Copy 8 bytes
!      DEC R3
       MOVB *R3,R0   ; read a byte from the left column
       BL @REVB8     ; reverse the bits
       MOVB R0,*R15  ; write VDP data
       DEC R2
       JNE -!
       AI R3,8
       JMP NEXTSP

* source in R3, dest VDP address in R4 (already loaded)
VSYMM
       BL @COPY16    ; Copy 16 bytes
       LI R2,16      ; Copy 16 bytes
       S R2,R3       ; Start reading from left column
       BL @CPREVB    ; Copy bytes reversing the bits
       JMP NEXTSP

HSYMM
       BL @COPY8     ; Copy 8 bytes
       LI R2,8       ; Copy 8 bytes reverse
       BL @UPCOPY
       LI R2,8       ; Copy 8 bytes
       A R2,R3
       BL @COPY
       LI R2,8       ; Copy 8 bytes
       BL @UPCOPY
       AI R3,8
       JMP NEXTSP

       COPY 'sprites.asm'

FFSPR1 EQU SPRITE+>E8
FFSPR2 EQU SPRITE+>148

       COPY 'tilda_common.asm'


;MODES  DATA >d283,>c252,>a283,>d283,>e283,>ccaf,>fffa,>aabb,>1ca2,>1c12,>fccb,>cccc,>fccc,>cccc,>ffff,>ffcb
;       DATA >ffff,>ee44,>9955,>ca11,>1144,>1212,>1144,>1212,>bfff,>ffff,>1212,>1111,>1111,>ffff,>11a2,>2222
;MODEND DATA >0000
;
;SPRITE
;       DATA >0018,>08af,>afaf,>0818,>0000,>00fe,>fffe,>0000  ; 0: Vcenter
;       ; 1: Hflip-1
;       ; 2: Clockwise-2
;       ; 3: Vflip-1
;       DATA >0000,>0000,>0000,>78fc,>fce6,>c3db,>c860,>7030  ; 4: Hcenter
;       ; 5: Hflip-1
;       ; 6: Vflip-2
;       ; 7: Hflip-1
;       DATA >381c,>0e0e,>0e0e,>1c38  ; 8: HVcenter
;       ; 9: Hflip-1
;       ; 10: Clockwise-2
;       ; 11: Vflip-1
;       DATA >00a8,>54ff,>54a8,>0000,>0000,>06fb,>0600,>0000  ; 12: Vcenter
;       ; 13: Hflip-1
;       ; 14: Clockwise-2
;       ; 15: Vflip-1
;       DATA >0003,>1188,>4c64,>2636,>2018,>8cce,>c6e7,>6767  ; 16: Hsymmetry
;       ; 17: Hflip-1
;       ; 18: Clockwise-2
;       ; 19: Vflip-1
;       DATA >080c,>0e55,>3b3b,>3b3b,>3b3b,>3b5b,>e57e,>3c18  ; 20: Hcenter
;       DATA >0004,>0402,>0101,>023c,>4ebf,>bfff,>ff7e,>3c00  ; 21: Hcenter
;       DATA >6cfe,>fefe,>7c38,>1000  ; 22: HVcenter
;       DATA >0707,>0107,>0d18,>1034,>2231,>2030,>1018,>0d07  ; 23: Vsymmetry
;       DATA >070f,>3f77,>6f6f,>eff7,>ffdf,>5f5b,>293c,>1f0e  ; 24: Vsymmetry
;       DATA >030e,>2923,>1130,>7694,>a829,>236b,>3118,>170a  ; 25: Vsymmetry
;       DATA >0200,>0820,>0310,>200a,>8009,>2001,>2004,>0106  ; 26: Vsymmetry
;       DATA >442d,>be7c,>387c,>9008  ; 27: HVcenter
;       DATA >0000,>0000,>003c,>3c3c  ; 28: HVcenter
;       DATA >60f0,>e0f0,>e070,>2010  ; 29: HVcenter
;       DATA >0000,>0010,>0104,>010a  ; 30: HVsymmetry
;       DATA >0140,>0111,>0805,>02b5  ; 31: HVsymmetry
;FFSPR1 DATA >0014,>292b,>0f6f,>7f7f,>7fbf,>fefa,>7c7c,>3f07,>4484,>a0e4,>e8da,>fefd,>fdff,>ffbe,>1e3c,>fcf0
;       DATA >4428,>0438,>7991,>bbd6,>4683,>283c,>3020,>2020  ; 33: Hcenter
;       DATA >0000,>0000,>0000,>0000  ; 34: HVcenter
;       ; 35: Hflip-1
;FFSPR2 DATA >2221,>0527,>175b,>7fbf,>bfff,>ff7d,>783c,>3f0f,>0028,>94d4,>f0f6,>fefe,>fefd,>7f5f,>3e3e,>fce0
;       DATA >4428,>85b9,>b952,>3ad4,>6cc6,>283c,>3020,>2020  ; 37: Hcenter
;       DATA >0000,>0780,>b00c,>0350,>2e10,>0c01,>3608,>0003,>f806,>110d,>000c,>3204,>8224,>c02c,>9028,>d020
;       ; 39: Hflip-1
;       DATA >317b,>7b7b,>403b,>7b7f,>7b7b,>403b,>7b7f,>4a31  ; 40: Vsymmetry
;       DATA >feab,>55ab,>7fff,>41ff,>55ff,>7ff7,>63f7,>7f7e  ; 41: Hcenter
;       DATA >182c,>3c18,>2418,>2418,>1818,>1818,>1818,>1818  ; 42: Hcenter
;       DATA >e0ff,>ffe0,>e0ff,>ffe0  ; 43: HVsymmetry
;       DATA >041f,>2e2f,>ffef,>0f7e,>0808,>0808,>7808,>7808  ; 44: Hcenter
;       DATA >0014,>3a0b,>73f0,>31d0,>d031,>f073,>0b3a,>1400  ; 45: Hcenter
;       DATA >e098,>8c86,>8683,>8383,>8383,>8386,>868c,>98e0  ; 46: Hcenter
;       DATA >3828,>3828,>3828,>3828,>3828,>3838,>1038,>2838  ; 47: Hcenter
;       DATA >0000,>1c3e,>7f7f,>7f7f,>3f3f,>1f0f,>0703,>0100  ; 48: Vsymmetry
;       DATA >3c7e,>e7c3,>c3ff,>ff18,>1818,>1878,>7838,>7818  ; 49: Hcenter
;       DATA >dbff,>ffcb,>7fd7,>ffaf,>ffff,>fefe,>ae7e,>fcfc  ; 50: Hcenter
;       DATA >3c18,>243c,>2424,>6681,>81ff,>fbdf,>f7bd,>c37e  ; 51: Hcenter
;       DATA >0000,>003c,>5eff,>ff7e,>c181,>c27c,>0000,>0000  ; 52: Hcenter
;       DATA >2c18,>183c,>7eab,>7fef,>5ffd,>563c,>1818,>1834  ; 53: Hcenter
;       DATA >083c,>746e,>2400,>3c3c,>3c3d,>3d3d,>3d3d,>ff7e  ; 54: Hcenter
;       DATA >0000,>ffff,>e7e7,>8181,>e7e7,>e7e7,>7e3c,>0000  ; 55: Hcenter
;       DATA >0000,>0003,>0507,>0502,>0121,>2000,>0000,>000e  ; 56: Vsymmetry
;       DATA >070c,>1810,>1010,>3034,>7656,>5f5e,>566f,>2f21  ; 57: Vsymmetry
;       DATA >0000,>0515,>131b,>0000,>0030,>3870,>6000,>0000  ; 58: Vsymmetry
;       DATA >0000,>0000,>0000,>1018,>0f0f,>0600,>1e07,>0000  ; 59: Vsymmetry
;       DATA >0705,>0d0d,>0300,>0000,>8080,>8000,>0000,>0006  ; 60: Vsymmetry
;       DATA >0000,>0000,>0810,>3064,>6c7c,>7677,>772f,>0f19  ; 61: Vsymmetry
;       DATA >80c0,>e0e0,>7070,>343a,>1a5f,>4e2e,>1e15,>0303  ; 62: Hcenter
;       DATA >e080,>8000,>0000,>0000  ; 63: HVsymmetry
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

; Enemies compressed
;       DATA >0103,>037e,>fe7d,>092b,>6b0b,>2d36,>0718,>0302  ; 0: Vsymmetry
;       DATA >0038,>7d3e,>0207,>1f3d,>3d7b,>0f17,>3708,>0d01  ; 1: Vsymmetry
;       DATA >0000,>0000,>63b5,>8fbf,>b71f,>79b9,>8c87,>8280  ; 2: Vsymmetry
;       DATA >0305,>1f3f,>375f,>5999,>3477,>4240,>4040,>4080  ; 3: Vsymmetry
;       DATA >2436,>3f6c,>78bb,>edfc,>00c0,>80f0,>31a1,>df1f  ; 4: Hsymmetry
;       DATA >486d,>3f6c,>78bb,>edfc,>8080,>90f0,>24ac,>dc1c  ; 5: Hsymmetry
;       ; 6: Hflip-2
;       ; 7: Hflip-2
;       ; 8: Clockwise-4
;       ; 9: Clockwise-4
;       ; 10: Vflip-2
;       ; 11: Vflip-2
;       DATA >0000,>0000,>3864,>a68e,>a595,>8fce,>7e18,>0000  ; 12: Hcenter
;       DATA >0000,>0000,>0000,>0000  ; 13: HVcenter
;       DATA >0307,>192e,>5d5d,>fdf8,>f0ef,>6f7f,>3f1f,>0701,>c0b0,>c8e8,>e4d2,>fafa,>7a3a,>b2b4,>a498,>20c0
;       DATA >0103,>0f1b,>1125,>3e7e,>5e5e,>5e5e,>2c19,>0f03,>e020,>d8c8,>e4e4,>e2e2,>625a,>7e7c,>f8f8,>70e0
;       DATA >0301,>0e11,>2120,>6747,>3e4f,>7f26,>e01c,>3f3f,>e0f8,>ece6,>fef5,>736f,>3e3e,>fc0c,>1010,>9c7c
;       DATA >0003,>010e,>1121,>2066,>4737,>434f,>20c3,>3f07,>00e0,>f8ec,>e6fe,>f573,>6fbe,>fcff,>ec90,>e0e0
;       ; 18: Hflip-2
;       ; 19: Hflip-2
;       DATA >3c0f,>0b49,>7edb,>d8db,>eeaf,>4750,>4c37,>7b7c,>3cf0,>d090,>78de,>1ada,>76f7,>ef0f,>1ae4,>de00
;       ; 21: Hflip-1
;       DATA >3c1f,>0728,>3060,>6040,>4040,>5847,>2019,>3f3c,>3cf8,>e012,>0a0c,>0e0e,>0e06,>34c2,>0214,>ee00
;       ; 23: Hflip-1
;       DATA >1f05,>0c02,>0682,>c4fe,>7f7f,>3f7f,>ff70,>2000,>f0f0,>a888,>103e,>213e,>f0f0,>f8fc,>fc38,>1000
;       DATA >000f,>0206,>0103,>0186,>ffff,>7f3f,>3f1f,>1d1d,>00f8,>f854,>4408,>3e21,>3ef8,>f8f8,>f8f0,>f0e0
;       ; 26: Hflip-2
;       ; 27: Hflip-2
;       DATA >0b0f,>0f05,>041d,>2245,>447b,>4f2f,>2f2f,>2e30,>e8f8,>f850,>1cd2,>22cf,>096a,>fafa,>fafe,>3c38
;       ; 29: Hflip-1
;       DATA >0b0f,>0f07,>071a,>2044,>4549,>3e1f,>1f1f,>0e00,>e8f8,>f8f0,>fc22,>0282,>d4d8,>bcfc,>fcfc,>3c38
;       ; 31: Hflip-1
;       DATA >0000,>0003,>0706,>0c0d  ; 32: HVsymmetry
;       DATA >8141,>776b,>e96a,>6a6f,>d853,>57d0,>2f33,>1c07  ; 33: Vsymmetry
;       DATA >8141,>656d,>f575,>7575,>f777,>6ddd,>2d31,>1c07  ; 34: Vsymmetry
;       DATA >0000,>0000,>0000,>0000,>0003,>0d37,>0e00,>0000  ; 35: Vsymmetry
;       DATA >0000,>0000,>0000,>0000,>0305,>0f1a,>0700,>0000  ; 36: Vsymmetry
;       DATA >0406,>090b,>0d0e,>0e06,>0e1b,>1e2f,>3b5e,>7712  ; 37: Vsymmetry
;       DATA >0121,>2235,>3919,>1909,>0d36,>3d6f,>bef7,>1d09  ; 38: Vsymmetry
;       DATA >0000,>0000,>0406,>090b,>0d0e,>0e16,>16da,>3d07  ; 39: Vsymmetry
;       DATA >0798,>aec0,>ff5c,>4040,>5c3f,>1f0f,>0300,>0000,>e0f8,>733e,>fcf8,>7830,>30f0,>f8f8,>fc3e,>0000
;       ; 41: Hflip-1
;       DATA >0f1f,>ffef,>773f,>3f1f,>1f0f,>0f07,>0300,>0000,>c0f0,>fbf6,>f6fc,>fcf8,>f8fc,>fcfe,>fe7f,>0000
;       ; 43: Hflip-1
;       DATA >1b16,>0e0f,>ffb4,>fcfc,>fcff,>feff,>b4fd,>1e1e,>d075,>65f7,>ea06,>0207,>0fc7,>7ac2,>1afe,>3e02
;       DATA >1b16,>0e0f,>ffb4,>fcfc,>fcff,>feff,>b4fd,>1e00,>d575,>67f2,>ea06,>060f,>07c6,>7ac2,>02da,>3e3c
;       DATA >0baf,>a7ef,>4f5f,>6850,>50d0,>ffe0,>604f,>7c40,>d8e8,>f0f0,>fff1,>793d,>3d3d,>fd39,>39bf,>7878
;       DATA >abaf,>e74f,>4f5f,>6850,>d0d0,>ff60,>605f,>7c3c,>d8e8,>f0f0,>fff1,>793d,>3d3d,>fd39,>39bf,>7800
;       DATA >0304,>1e29,>5352,>82c7,>8f90,>5040,>2018,>0601,>c0b0,>0808,>1406,>0606,>86c6,>464c,>4c78,>e0c0
;       DATA >0102,>0c14,>1e3a,>2141,>6161,>6161,>3316,>0c03,>e020,>3838,>1c1c,>1e1e,>9ea6,>8284,>0808,>90e0
;       DATA >3c0b,>0556,>6164,>6764,>f1b0,>786f,>333c,>7f7c,>3cd0,>a068,>8426,>e727,>8f0f,>1ffa,>e41e,>fe00
;       DATA >0702,>0f1e,>3e3f,>3838,>7170,>0079,>e71c,>3f3f,>e018,>2432,>020b,>8d91,>c2e2,>14fc,>f0e0,>1c7c
;       DATA >42a6,>9a95,>1695,>9590,>27ac,>a82f,>d04c,>2318  ; 52: Vsymmetry
;       DATA >8141,>6160,>e062,>6260,>c043,>47c0,>0000,>0000  ; 53: Vsymmetry
;       DATA >42a6,>9a92,>0a8a,>8a8a,>0888,>9222,>d24e,>2318  ; 54: Vsymmetry
;       DATA >8141,>6161,>f171,>7171,>f575,>61c1,>0101,>0000  ; 55: Vsymmetry
;       DATA >1b16,>0e0f,>fcb5,>fdfd,>fdfc,>fdfc,>b5fd,>1e1e,>d075,>75f7,>1afa,>fef9,>f139,>823e,>e6da,>3e02
;       DATA >1b16,>0e0f,>fcb5,>fdfd,>fdfc,>fdfc,>b5fd,>1e00,>d575,>77f2,>1afa,>f9f1,>f93e,>823e,>fee6,>1a3c
;       DATA >0000,>0000,>0000,>0000  ; 58: HVcenter
;       ; 59: Hflip-1
;       ; 60: Hflip-1
;       ; 61: Hflip-1
;       ; 62: Hflip-1
;       ; 63: Hflip-1

