; This is in bank 1

LDUNG0
       B @BANK0   ; return to saved address R13 in bank 0

LDUNGE ; Load dungeon enemies  R0=FLAGS R1=MAPLOC R9=LASTOB
       ANDI R0,INCAVE
       ;JNE LDCAVE  ; TODO

       LI R0,SPRLST+(6*4)      ; Clear sprite list [6..31]
       LI R2,(32-6)*2          ; (including scratch)
!      CLR *R0+
       DEC R2
       JNE -!

       JMP LDUNG0  ; FIXME temporarily disabled

       ; get enemy group index
       MOV R1,R0
       AI R0,SDENEM*2   ; R0 = save data overworld enemies counts
       MOV R1,R2
       A R2,R2
*       AI R2,OENEMY    ; R2 = overworld enemy table

       MOV @FLAGS,R1
       ANDI R1,DUNLVL  ; test for dungeon or overworld
       JEQ !           ; overworld
       AI R0,(DNENEM*2)-(SDENEM*2)   ; dungeon enemies counts
*       AI R2,DENEMY-OENEMY
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
       SB R4,R4   ;ANDI R4,>00FF
       SOC R1,R4
!
       ; R2 = pointer to entry in OENEMY or DENEMY
       ; R4 = current count and enemy type/group
       ; TODO R2 should be adjusted if group

*       MOV R2,@TEMPRT ; save for loading sprites
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

       ; next *R1 bytes are damage(4) drop(4) color(8) stun(8) hurt(8) hp(8)
       AI R0,(ENEMDT*2)-OBJECT
       MOVB *R6+,R1
       BL @VDPWB       ; write damage
       AI R0,ENEMHP-ENEMDT-VDPWM
       MOVB *R6+,R1
       BL @VDPWB       ; write hp
       ;AI R0,ENEMSC-ENEMHP-VDPWM
       ;MOVB *R6+,R1
       ;BL @VDPWB       ; write color
       AI R0,(ENEMHS/2)-ENEMHP-VDPWM
       SLA R0,1
       MOVB *R6+,R1
       BL @VDPWB       ; write stun
       MOVB *R6+,*R15  ; write hurt

       AI R6,-8      ; rewind table entry

       AI R4,->100    ; decrement enemy counter
       JEQ !          ; done if zero

       AI R7,->100    ; decrement group counter
       JNE -!         ; next in same group

       JMP -!!        ; next group

!
       MOV @TEMPRT,R1
LDSPR ; load sprite patterns
       MOV *R1,R5      ; get enemy count and type
       SB R5,R5   ;ANDI R5,>00FF   ; enemy type
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
       LI R3,SPR_64 ; overworld mob sprites start at 64
       LI R7,MODES+32

       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !        ; not in dungeon

       ; decompress dungeon enemy sprites
       LI R3,SPR_128 ; dungeon mob sprites start at 128
       LI R7,MODES+64
!
       ; R2 = sprite index, R3 = SPRXXX, R4 = VDP address, R7 = mode, R9 = count
       BL @DECOMX       ; decompress sprites
!
       MOV @TEMPRT,R1
       INCT @TEMPRT
       MOV *R1,R2   ; get next group byte
       ANDI R2,>0F00
       S R2,@HURTC
       JLT LDSPR   ; enemy count zero

       CLR @TEMPRT
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
       BL @!GETBIT
       JNC !            ; NPC should appear
       CLR @-2(R4)      ; clear object
       AI R5,-4         ; clear sprites

       ; Clear remaining sprite table
!      CLR *R5+
       CI R5,WRKSP+256
       JNE -!
CAVERT
       ;MOV @TEMPRT,R13   ; Restore return address
       B @BANK0




* Load enemies
LENEMY  ; called from bank1
       MOV R11,R13       ; save return address

       MOVB @MAPLOC,R1         ; Get map location
       SRL R1,8

*       LI R9,LASTOB        ; Start filling the object list at last index

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
       LI R4,SPRPAT+(4*32)  ; VDP address = >1x 4 Armos sprites
       LI R2,44             ; index = Armos Sprites
       LI R9,4              ; count = 4 Armos sprites
       BL @DECOMO

       JMP CAVERT  ; FIXME temporarily disabled

*       LI R8,ENESPR+(>2C*32)   ; Armos sprite source address index >2C
       LI R10,SPRPAT+(>18*32)   ; Destination sprite address index >60
       ANDI R0,>0080        ; Test zora bit
       JEQ LENEM2
       LI R0,ZORAID         ; Zora enemy type
       MOV R0,*R9+          ; Store it
       INC R4               ; 5 Zora sprites
*       LI R8,ENESPR+(>20*32)    ; Zora sprite source address index >20
       AI R10,32            ; Destination sprite address index >61

LENEM2 MOV R8,R0            ; Copy Zora or Armos sprite
       AI R8,32
       BL @READ32           ; Read sprite into scratchpad

       MOV R10,R0
       AI R10,32
       BL @!PUTSCR           ; Copy it back to the sprite pattern table

*       CI R8,ENESPR+(>23*32)   ; After zora (pulsing ground)
       JNE !
       LI R10,SPRPAT+(>0A*32)   ; Pulsing ground dest address index >28

!      DEC R4
       JNE LENEM2


       MOV R5,R1               ; R5 = enemy group index
       MOV R5,R0
       ANDI R0,>0040           ; Test edge loading bit
       ; TODO

       ANDI R1,OBJMSK          ; Mask off zora and loading behavior bits to get group index
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
*       AI   R8,ENESPR          ; Get source offset in R8 = XX * 32 + ENESPR

       MOV R4,R10
       ANDI R10,>00F0
       SLA  R10,2
       AI  R10,SPRPAT+>0100     ; Calculate dest offset into sprite pattern table (Y * 64 + >20 * 8)

       ANDI R4,>000F       ; The number of sprites to copy
!      MOV R8,R0
       BL @READ32          ; Read sprite into scratchpad
       AI R8,32

       MOV R10,R0
       BL @!PUTSCR          ; Copy it back to the sprite pattern table
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
       ANDI R1,OBJMSK
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

; GROUP1 fast octorok, octorok, moblin,
; GROUP2 lynel, red leever, blue leever, peahat
; GROUP3 ghini, rocks, fairy,


****************************************
* Enemy groups  (XY -> Y = Enemy pattern index  X = Count or Count + 8 if more enemies in group)
****************************************
ENEMYG BYTE >4A     ; 01  4 red lynel
       BYTE >4D     ; 02  4 rocks
       BYTE >6B     ; 03  6 blue lynel
       BYTE >AB,>AA,>9E,>1F    ; 04  2 blue lynel 2 red lynel 1 red leever 1 blue leever
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
       BYTE >2A,>2A,>06,>01,>00,>0D,>8C,>8C,>8C,>0E,>0F,>10,>11,>92,>93,>00
       BYTE >2A,>2A,>05,>00,>14,>80,>80,>15,>96,>17,>10,>14,>18,>19,>92,>98
       BYTE >2A,>2A,>20,>17,>A1,>22,>80,>80,>8E,>16,>23,>24,>12,>19,>19,>AC
       BYTE >25,>26,>27,>28,>A1,>95,>A1,>2B,>2B,>8D,>A1,>27,>19,>19,>26,>92
       BYTE >05,>26,>26,>29,>12,>AB,>2B,>21,>21,>A1,>A1,>29,>1A,>1A,>29,>96
       BYTE >0D,>26,>1B,>19,>2D,>90,>11,>00,>21,>1D,>1E,>9F,>9F,>93,>A1,>98


       ; New group idea
       ; count(2 bits) 1..4  group index(5 bits)
       ; followed by count enemies: type(8 bits) number(4 bits)

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


       ; GROUP1: moblin, octorok, fast octorok, tektite
       ; GROUP2: lynel, red leever, blue leever, peahat
       ; GROUP3: ghini, rock, fairy


       ; enemy table
       ; ID (16), sprite(16), damage(4), drop(4), HP(8), src pat(8), dst pat(4), count(4)
ENDATA DATA >0003, FARYSC,>0000, >0000  ; Fairy?
       DATA >0004, >0000, >0402, >0002  ; 01 Peahat
       DATA >0004, >0000, >0101, >0222  ; 02 Red Tektite
       DATA >0004, >0000, >0301, >0222  ; 03 Blue Tektite
       DATA >0004, >0000, >0101, >0449  ; 04 Red Octorok
       DATA >0004, >0000, >0202, >0449  ; 05 Blue Octorok
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
!GETBIT
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
!PUTSCR
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
!READ32
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM read address
       MOVB R0,*R14         ; Send high byte of VDP RAM read address
       LI R1,SCRTCH        ; Dest pointer to scratchpad ram
       LI R2,8             ; Read 32 bytes to scratchpad
       LI R15,VDPRD        ; Keep VDPRD address in R15
!      MOVB *R15,*R1+
!READ3  MOVB *R15,*R1+
       MOVB *R15,*R1+
       MOVB *R15,*R1+
       DEC R2
       JNE -!
       LI R15,VDPWD        ; Restore VDPWD address in R15
       RT
