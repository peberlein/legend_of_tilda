;
; Legend of Tilda
; Copyright (c) 2017 Pete Eberlein
;
; Bank 5: moving objects (enemies, projecties) and collision detection
;

       COPY 'tilda.asm'

       
; Use function in R2
;      0=do moving objects
;      1=draw status
; Modifies R0-R13,R15
MAIN
       MOV R11,R12          ; Save return address for later
       A R2,R2
       MOV @JMPTBL(R2),R2
       B *R2

JMPTBL DATA OBSTRT,STATS



* Object function pointer table, functions called with data in R4,
* sprite YYXX in R5, idx color in R6, must return by B @OBNEXT
OBJTAB DATA OBNEXT,PEAHAT,TKTITE,TKTITE  ; 0-3 - - Red Blue
       DATA OCTORK,OCTORK,OCTRKF,OCTRKF  ; 4-7 Red Blue Red Blue
       DATA MOBLIN,MOBLIN,LYNEL, LYNEL   ; 8-B Red Blue Red Blue
       DATA GHINI, BOULDR,LEEVER,LEEVER  ; C-F - - Red Blue
       DATA ZORA, FLAME, FAIRY, HEART2   ; 10-13
       DATA BSWORD,MAGIC,BSPLSH,ARMOS    ; 14-17
       DATA DEAD, BOMB, BMRNG, CAVITM    ; 18-1B
       DATA BULLET,ARROW,ASPARK,CAVNPC   ; 1C-1F
       DATA RUPEE, BRUPEE,HEART,AFAIRY   ; 20-23
       DATA TEXTER,ROCK                  ; 24-27
       ; 28-2B
       ; 2C-2F
       ; 30-33
       ; 34-37
       ; 38-3B
       ; 3C-3F

       ; TODO combine RUPEE,BRUPEE,HEART,FAIRY, other collectible items


* Damage enemies do to attack hero
*         no ring     blue ring   red ring
* 1 dmg = 1/2 heart   1/4 heart   1/8 heart
EDAMAG BYTE >00,>01  ; None, Peahat
       BYTE >01,>01  ; Red/Blue Tektite
       BYTE >01,>01  ; Octorok
       BYTE >01,>01  ; Fast Octorok
       BYTE >01,>01  ; Moblin
       BYTE >02,>04  ; Lynel
       BYTE >02,>01  ; Ghini, Rock
       BYTE >01,>02  ; Red/Blue Leevers
       BYTE >01,>01  ; Zora, Flame
       BYTE >00,>00  ;
       BYTE >04,>04  ; Beam Sword, Magic
       BYTE >00,>02  ; Beam splash, Armos
       BYTE >00,>00  ; Dead
       BYTE >00,>00  ;
       BYTE >01,>01  ; Bullet,arrow
       BYTE >00,>00  ;

* Enemy sprite index and color
ECOLOR DATA >0000,>2009  ; None, Peahat
       DATA >3009,>3005  ; Red Tektite, Blue Tektite
       DATA >4008,>4004  ; Octorok sprites
       DATA >4008,>4004  ; Fast Octorok Sprites
       DATA >2006,>2004  ; Moblin Sprites
       DATA >4006,>4004  ; Lynel Sprites
       DATA >200F,>2009  ; Ghini, Rock
       DATA >3006,>3004  ; Leever Sprites
       DATA >680D,>0000  ; Zora, Fire
       DATA >0000,>0000  ;
       DATA >0000,>0000  ; Beam Sword, Magic
       DATA >0000,>6005  ; Beam splash, Armos
       DATA >0000,>0000  ; Dead
       DATA >0000,>0000  ;
       DATA >0000,>0000  ; Bullet,arrow
       DATA >0000,>0000  ;
       DATA >C004,>C004  ; Rupee, Blue rupee
       DATA >C800,>F400  ; Heart, Fairy



OBNEXT
       MOV @OBJPTR,R1       ; Get sprite index
       MOV R4,@OBJECT(R1)   ; Save data
       A R1,R1
       MOV R5,@SPRLST(R1)   ; Save sprite pos
       MOV R6,@SPRLST+2(R1) ; Save sprite id & color
       SRL R1,1
       JMP OBLOOP
OBSTRT
       LI R1,7*2-2         ; Process sprites starting with flying sword (7)
OBLOOP INCT R1
       CI R1,64            ; Stop after last sprite
       JEQ DONE

       MOV R1,@OBJPTR      ; Save pointer
       MOV @OBJECT(R1),R4  ; Get func index and data
       A R1,R1
       MOV @SPRLST(R1),R5  ; Get sprite location
       MOV @SPRLST+2(R1),R6  ; Get sprite color

       SRL R1,1
       MOV R4,R3
       ANDI R3,>003F ; Get sprite function index
       JEQ OBLOOP

       A R3,R3
       MOV @OBJTAB(R3),R1
       B *R1       ; Jump to sprite function



* Update map dot location, and load enemies thru bank4
DONE
       LI   R0,BANK0         ; Load bank 0
       MOV  R12,R1           ; Jump to our return address
       B    @BANKSW











* Draw the byte number in R1 as (right-justified) [space][space]n or [space]nn or nnn
* Used for price underneath items in caves
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBRJ
       MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1,>6400      ; R1 >= 100 decimal ?
       JHE NUMBE2
       LI R0,>2000
       MOVB R0,*R15     ; Write a space
       CI R1,>0A00      ; R1 < 10 decimal ?
       JL NUMBE4
       LI R0,>3000      ; 0 ascii
       JMP NUMBE3

* Draw the byte number in R1 as Xn[space] or Xnn or nnn
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBER MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1, >6400  ; 100 decimal
       JHE NUMBE2
       LI R0, >5800           ; X ascii
       MOVB R0,*R15        ; Write X
       LI R0, >3000             ; 0 ascii
       CI R1, >A00   ; 10 decimal
       JHE NUMBE3
       A R0,R1
       MOVB R1,*R15        ; Write second digit
       LI R1, >2000
       MOVB R1,*R15           ; Write a space
       RT

NUMBE2 LI R0, >3100           ; 1 ascii
       AI R1, ->6400    ; R1 -= 100
       CI R1, >6400     ; R1 < 100 ?
       JL !
       AI R1, ->6400
       LI R0, >3200           ; 2 ascii
!      MOVB R0,*R15           ; Write first digit
       LI R0, >3000           ; 0 ascii
       JMP NUMBE3
!      AI R0,>100
       AI R1, ->A00        ; R1 -= 10
NUMBE3 CI R1, >A00         ; 10 decimal
       JHE -!
NUMBE4 MOVB R0,*R15        ; Write second digit
       AI R1, >3000        ; 0 ascii
       MOVB R1,*R15        ; Write final digit
       RT

* Modifies R0-R4,R7-R11,R13
STATS  ; status called from another bank
       BL @STATUS
       B @DONE

* Draw number of rupees, keys, bombs and hearts
* Modifies R0-R3,R7-R11,R13
STATUS MOV R11,R10         ; save return address
       CLR R1
       MOVB @RUPEES,R1
       MOV @FLAGS,R3
       ANDI R3,SCRFLG
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*0)+12  ; Write mask + screen offset + row 0 col 12
       BL @NUMBER             ; Write rupee count

       MOVB @KEYS,R1
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*1)+12  ; Write mask + screen offset + row 1 col 12
       BL @NUMBER             ; Write keys count

       MOVB @BOMBS,R1
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*2)+12  ; Write mask + screen offset + row 2 col 12
       BL @NUMBER             ; Write bombs count

       MOV R10,R11        ; restore return address

       AI R3,VDPWM+SCR1TB+(32*2)+22  ; Write mask + screen offset + row 2 col 22
       ; R3 = lower left heart position
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       AI R3,-32              ; R3 = upper left heart position

       CLR R9
       MOVB @HEARTS,R9        ; R9 = max hearts - 1
       AI   R9,>100
       MOV  @HFLAGS,R0
       LI   R10,1             ; R10 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R9,R9             ; double max hp
       INC  R10               ; R10 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R9,R9             ; double max hp again
       INCT R10               ; R10 = 4 hp per half-heart
!
       A    R9,R9             ; double max hp for half-hearts
       SWPB R10
       ;  write hearts and move half-heart sprite
       CLR R2
       LI R0,>1F01            ; Full heart / empty heart
       LI R13,8               ; Countdown to move up
       LI R7,>0CAC            ; Half-heart sprite coordinates
       LI R8,>E400            ; Half-heart sprite index and color (invisible)
       MOVB @HP,R1            ; R1 = hit points
       JEQ HALFH
       C R1,R9
       JL FILLH
       MOV R9,R1              ; Set HP to max HP
       MOVB R1,@HP
FILLH
       A   R10,R2
       CB  R2,R1              ; Compare counter to HP
       JL !
       LI  R8,>E406           ; Half-heart sprite index and color (red)
       S   R10,R2
       JMP HALFH
!      A   R10,R2
       AI  R7,>0008
       MOVB R0,*R15           ; Draw heart
       DEC R13
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       LI R7,>04AC            ; Half-heart sprite coordinates
!      CB  R2,R1              ; Compare counter to HP
       JL FILLH
HALFH  MOV R7,@HARTSP         ; Save sprite coordinates
       MOV R8,@HARTSP+2       ; Save sprite index and color
       SWPB R0                ; Switch hearts
       LI R7,FULLHP
       C R2,R9                ; Compare to max hearts
       JL EMPTYH
       SOC R7,@FLAGS          ; Set full hp flag
       JMP STDONE
EMPTYH
       A   R10,R2
       A   R10,R2
       MOVB R0,*R15           ; Draw heart
       DEC R13
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
!      C R2,R9                ; Compare counter to max hearts
       JL EMPTYH
       SZC R7,@FLAGS          ; Clear full hp flag
STDONE
       RT




* Store characters R1,R2 at R5 in name table
* Modifies R0,R1,R3
STORCH
       MOV R5,R0
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
       ANDI R0,>F8F8
       MOV R0,R3
       SRL R3,3
       MOVB R3,R0
       SRL R0,3
       MOV @FLAGS,R3
       ANDI R3,SCRFLG
       A R3,R0

       ORI R0,VDPWM
       LI R3,2
!
       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address

       MOVB R1,*R15
       MOVB @R1LB,*R15

       AI R0,32
       MOV R2,R1

       DEC R3
       JNE -!

       RT

* Scan objects for empty slot: store R4 index & data, R5 in location, R6 in sprite index and color
* Modifies R0,R1
OBSLOT
       LI R1,LASTOB      ; Start at slot 13
!      MOV *R1,R0
       JEQ !
       INCT R1
       CI R1,SPRLST
       JNE -!
       RT            ; Unable to find empty slot
!      MOV R4,*R1
       AI R1,-OBJECT+(SPRLST/2)
       A R1,R1
       MOV R5,*R1+
       MOV R6,*R1
       RT








CAVLOC DATA >7078,>7058,>7098  ; Center, left, right, leftmost  (merchant)
STAIRS DATA >8878,>8848,>88A8  ; Center, left, right   (stairs)

* Cave sprite table: index and color SSSSSSuu uuuuCCCC S=sprite index C=color
* u=6 bit index into price table, or
*     indicator of npc sprites and background tiles, or
*     indicator of fire sprites and background tiles, or
*     indicator of background tiles


OLDMAN EQU >0000 ; Old man NPC
CAVMOB EQU >4000 ; Cave moblin NPC
OLDWOM EQU >8000 ; Old woman NPC
MERCH  EQU >C000 ; Merchant NPC

* Cave npc type and text offsets (numbers are printed during cave string generation: ./tools/txt)
CAVDAT DATA OLDMAN+0         ; 1 IT'S DANGEROUS TO GO\ALONE! TAKE THIS.
       DATA OLDMAN+40        ; 2 MASTER USING IT AND\YOU CAN HAVE THIS.
       DATA OLDMAN+40        ; 3 MASTER USING IT AND\YOU CAN HAVE THIS.
       DATA OLDMAN+80        ; 4 SHOW THIS TO THE\OLD WOMAN.
       DATA OLDMAN+109       ; 5 PAY ME FOR THE DOOR\REPAIR CHARGE.
       DATA OLDMAN+145       ; 6 LET'S PLAY MONEY\MAKING GAME.
       DATA OLDMAN+176       ; 7 SECRET IS IN THE TREE\AT THE DEAD-END.
       DATA OLDMAN+216       ; 8 TAKE ANY ONE YOU WANT.
       DATA OLDMAN+240       ; 9 TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; A TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; B TAKE ANY ROAD YOU WANT.
       DATA OLDMAN+240       ; C TAKE ANY ROAD YOU WANT.
       DATA CAVMOB+265       ; D IT'S A SECRET\TO EVERYBODY.
       DATA CAVMOB+265       ; E IT'S A SECRET\TO EVERYBODY.
       DATA CAVMOB+265       ; F IT'S A SECRET\TO EVERYBODY.
       DATA OLDWOM+294       ; 10 BUY MEDICINE BEFORE\YOU GO.
       DATA OLDWOM+323       ; 11 PAY ME AND I'LL TALK.
       DATA OLDWOM+323       ; 12 PAY ME AND I'LL TALK.
       ;DATA 346       ; THIS AIN'T ENOUGH TO TALK.
       ;DATA 374       ; GO NORTH,WEST,SOUTH,\WEST TO THE FOREST\OF MAZE.
       ;DATA 424       ; BOY, YOU'RE RICH!
       ;DATA 443       ; GO UP,UP THE MOUNTAIN AHEAD.
       DATA OLDWOM+474       ; 13 MEET THE OLD MAN\AT THE GRAVE.
       DATA MERCH+506       ; 14 BOY, THIS IS\REALLY EXPENSIVE!
       DATA MERCH+506       ; 15 BOY, THIS IS\REALLY EXPENSIVE!
       DATA MERCH+538       ; 16 BUY SOMETHIN' WILL YA!
       DATA MERCH+538       ; 17 BUY SOMETHIN' WILL YA!

NPCSPR ;    SPR1  SPR2  BGCH1 BGCH2
       DATA >500A,>5406,>2324,>2829  ; 2 Old man skin, robe
       DATA >5806,>0000,>2020,>2020  ; Moblin "IT'S A SECRET\TO EVERYBODY."
       DATA >400A,>4406,>5C5D,>2829  ; Old woman sprites
       DATA >480A,>4C02,>BCBD,>BEBF  ; Merchant sprites
*FIRECH DATA >2020,>5E5F  ; Fire background chars
*       DATA >7879,>7A7B  ; Warp Stairs background chars

CAVTBL ; SSSSSSGx PPPPCCCC  S=sprite index G=group bit P=price index C=color
       DATA >7E08      ; 1 Wood sword "IT'S DANGEROUS TO GO\ALONE! TAKE THIS."
       DATA >7E0F      ; 2 White sword "MASTER USING IT AND\YOU CAN HAVE THIS." (5h)
       DATA >5609      ; 3 Magic sword "MASTER USING IT AND\YOU CAN HAVE THIS." (12h)
       DATA >2A04      ; 4 Letter "SHOW THIS TO THE\OLD WOMAN."
       DATA >C20A      ; 5 -20 rupees TODO door repair charge

       DATA >C20A,>C00A,>C00A  ; 6 Rupees "LET'S PLAY MONEY\MAKING GAME."
       DATA >0200      ; 7 "SECRET IS IN THE TREE\AT THE DEAD-END." TODO
       DATA >0200,>2C06,>2006 ; 8 red potion, heart container "TAKE ANY ONE YOU WANT."
       DATA >0200,>0000,>0000 ; 9 warp stairs 1 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; A warp stairs 2 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; B warp stairs 3 "TAKE ANY ROAD YOU WANT."
       DATA >0200,>0000,>0000 ; C warp stairs 4 "TAKE ANY ROAD YOU WANT."

       DATA >C20A    ; D: 10 rupees
       DATA >C20A    ; E: 30 rupees
       DATA >C20A    ; F: 100 rupees

       DATA >0200,>2C54,>2C86  ; 10: Blue potion(40), red potion(68) "BUY MEDICINE BEFORE\YOU GO." (2nd line left aligned)
       DATA >C24A,>C02A,>C06A  ; 11: 10 30 50 "THIS AIN'T ENOUGH TO TALK" "GO NORTH WEST SOUTH WEST" "BOY,YOU'RE RICH"
       DATA >C22A,>C01A,>C03A  ; 12: 5 10 20 "THIS AIN'T ENOUGH TO TALK" "THIS AIN'T ENOUGH TO TALK" "GO UP,UP THE MOUNTAIN AHEAD"
       DATA >0200      ; 13: "MEET THE OLD MAN\AT THE GRAVE" TODO

       DATA >36B9,>3CA9,>C826  ; 14: Shield(90) bait(100) heart(10) "BOY, THIS IS\REALLY EXPENSIVE!"
       DATA >32E4,>249B,>3476  ; 15: Key(80) bluering(250) bait(60) "BOY, THIS IS\REALLY EXPENSIVE!"
       DATA >C634,>3CC9,>AC9B  ; 16: Shield(130) bomb(20) arrow(80) "BUY SOMETHIN' WILL YA!"
       DATA >26BB,>3CD9,>3874  ; 17: Shield(160) key(100) candle(60) "BUY SOMETHIN' WILL YA!"

       DATA >0200 ; Terminating group bit

* cave item prices (stored in object hp)
*           0 1 2  3  4  5  6  7  8  9  A  B   C   D   E
IPRICE BYTE 0,5,10,20,30,40,50,60,68,80,90,100,130,160,250
       EVEN







* Look at character at pixel coordinate in R0, and jump to R2 if solid (character is in R1)
* Modifies R0,R1
TESTCH
       ; Convert pixel coordinate YYYYYYYY XXXXXXXX
       ; to character coordinate        YY YYYXXXXX
       ANDI R0,>F8F8
       MOV R0,R1
       SRL R1,3
       MOVB R1,R0
       SRL R0,3
       MOV @FLAGS,R1
       ANDI R1,SCRFLG
       A R1,R0

       MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       CLR R1
       MOVB @VDPRD,R1

       CI R1,>7E00  ; Characters >7E and higher are solid
       JHE !
       RT
!      B *R2        ; Jump alternate return address













BSWJMP DATA BSWDRT,BSWDLT,BSWDDN,BSWDUP
BSWRDD DATA >0003,>FFFD,>0300,>FD00     ; Beam sword direction (move by 3)
BSWRDC BYTE >07,>0F,>06,>09             ; Beam sword colors: cyan, white, dark red, light red
BSPLSD DATA >FEFF,>FF01,>00FF,>0101     ; Beam splash direction data NW,NE,SW,SE
REVMSK ; Reverse direction mask, same as DATA >0002
MAGICD DATA >0002,>FFFE,>0200,>FE00     ; Magic beam direction (move by 2)
MAGICC BYTE >07,>04,>06,>01             ; Magic colors: cyan, dark blue, dark red, black

* Beam sword shoots when link is at full hearts, cycle colors white,cyan,red,brown
* R4[9..8] = color bits
* R4[6] = pop bit
BSWORD
       AI R4,>4000              ; Cycle colors
       MOV R4,R1
       SRL R1,14
       MOVB @BSWRDC(R1),@R6LB

BSWRD2
       MOV R6,R2
       ANDI R2,>0F00       ; Get facing from sprite index
       SRL  R2,9
       A @BSWRDD(R2),R5    ; Add movement from table
BSWRD3
       MOV R4,R1
       SLA R1,10           ; Check for hitting enemy
       JOC BSWPOP

       MOV R5,R0
       SWPB R0
       MOV @BSWJMP(R2),R1   ; Jump table for checking screen edge
       B *R1
BSWDLT
       CI R0,>0800          ; Check left edge of screen
       JH !
       JMP BSWPOP
BSWDRT
       CI R0,>E800         ; Check right edge of screen
       JL !
       JMP BSWPOP
BSWDUP
       CI R5,>1800         ; Check left edge of screen
       JH !
       JMP BSWPOP
BSWDDN
       CI R5,>B000          ; Check bottom edge of screen
       JHE BSWPOP
!
       MOV @OBJPTR,R0
       CI R0,LASTOB-OBJECT ; Is it the player beam sword?
       JL BSWNXT
       BL @LNKHIT         ; hit player if not player weapon
       JMP BSWNXT

BSWPOP
       MOV R4,R1
       ANDI R1,>003F       ; Get object idx
       CI R1,MAGCID
       JNE !
       MOV @FLAGS,R0
       ANDI R0,BOOKMG      ; Have Book of Magic?
       JEQ BSPOFF

       LI R0,BMFMID        ; Book of Magic Flame ID
       MOV R0,@FLAMOB      ; Flame object id
       MOV R5,@FLAMSP      ; Flame position
       LI R6,>F008         ; Flame sprite and color
       MOV R6,@FLAMSP+2

       JMP BSPOFF
!      CI R1,ARRWID
       JNE !

       ; TODO arrow spark at edge of screen
       ;CLR @ARRWOB       ; Clear arrow so it can be fired again
       LI R6,SPARK
       LI R4,SPRKID
       JMP BSWNXT

!      MOV @OBJPTR,R0
       CI R0,BSWDOB-OBJECT ; Is it the hero's beam sword?
       JNE SPROFF

       LI R4,BSPLID        ; Create splash NW
       LI R6,>800F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>40    ; Create splash NE
       LI R6,>840F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>80    ; Create splash SW
       LI R6,>880F         ; Sprite
       BL @OBSLOT
       LI R4,BSPLID+>C0    ; Create splash SE
       LI R6,>8C0F         ; Sprite
       BL @OBSLOT
       LI R4,IDLEID        ; sword off but can't fire again
       JMP !
BSPOFF ; Beam splash off (from below)
       CLR @BSWDOB       ; Clear sword so it can be fired again
SPROFF
       CLR R4
!      LI R5,>D200        ; Disappear (offscreen)
BSWNXT B @OBNEXT


ARROW
       MOV @OBJPTR,R0
       CI R0,ARRWOB-OBJECT
       JEQ BSWRD2         ; Hero arrow just moves like beam sword (by 3)
       ; Enemy arrow hit test will happen at BSWRD3
       JMP MAGIC2  ; Move by 2 (magic)

MAGIC
       ; TODO enemy magic hero hit test and colors

       AI R4,>4000         ; Cycle colors
       MOV R4,R1
       SRL R1,14
       MOVB @MAGICC(R1),@R6LB

       MOV @COUNTR,R0
       SLA R0,4            ; Use low bit from counter6 nibble
       JNC BSWRD2          ; Move by 3 or 2 alternating frames
MAGIC2
       MOV R6,R2
       ANDI R2,>0C00       ; Get facing from sprite index
       SRL  R2,9
       A @MAGICD(R2),R5    ; Add movement from table
       JMP BSWRD3


       ; Arrow spark
ASPARK
       LI R0,>0040
       C R0,R4
       JH SPROFF
       S R0,R4
       JMP BSWNXT


* Beam sword splash, or reflected bullet/arrow/sword
* R4[15..8] = countdown
*   [7..6] = direction (not from sprite since also used for bullet reflect)
BSPLSH
       MOV R4,R1
       ANDI R1,>00C0       ; Get facing from object index
       SRL  R1,5

       MOV R5,R0
       A @BSPLSD(R1),R5    ; Add movement from table (NW,NE,SW,SE)
       XOR R5,R0
       ;ANDI R0,>0080       ; Check if X wrapped
       ;JEQ !
       SRC R0,8            ; Check if X wrapped
       JNC !
       ORI R6,>0080        ; Set early clock bit
       AI R5,>0020         ; Add early clock offset 32px

!
       AI R4,>0100         ; Decrement TTL
       MOV R4,R1
       ANDI R1,>1F00
       JEQ BSPOFF          ; Turn off

       MOV R6,R0
       ANDI R0,>F000       ; Get sprite index (upper nibble)
       CI R0,>7000         ; sword sprite?
       JEQ !
       CI R0,>8000         ; beam sword pop sprite?
       JNE BSWNXT          ; nope - done
!
       SWPB R1             ; Cycle colors
       ANDI R1,>0003
       ANDI R6,>FFF8        ; Mask off color
       AB @BSWRDC(R1),@R6LB ; Get cycled color

       JMP BSWNXT


RUPEE
BRUPEE
HEART
       LI R0,>0100
       C  R4,R0          ; Test counter for zero
       JHE !
       AI R4,>5000       ; Initialize counter
       MOV @ECOLOR(R3),R6 ; Initialize sprite and color
!      MOV @COUNTR,R1
       ANDI R1,>000F     ; Use only 16-counter
       MOV R1,R2
       ANDI R6,>FFF0     ; Mask off color
       SRL R1,3
       A R1,R3
       AB @RUPEEC->40(R3),@R6LB

       CI R4,>2000
       JLE !
       S  R0,R4          ; Decrement counter
       SLA R2,15
       JOC BSWNXT
       ANDI R6,>FFF0     ; Mask off color
       JMP BSWNXT

!      MOV  R2,R2
       JNE !
       S  R0,R4          ; Decrement counter
       C  R4,R0          ; Test counter for zero
       JL SPROFF

!      LI R2,GETITM
       MOV @HEROSP,R3    ; Get hero pos in R3
       BL @COLIDE
       MOV @SWRDSP,R3    ; Get sword pos in R3
       BL @COLIDE
       MOV @BMRGSP,R3    ; Get boomerang pos in R3
       BL @COLIDE
       JMP BSWNXT
GETITM
       ANDI R4,3
       JNE !
       LI R0,>0100       ; Get 1 rupee
       JMP GETRUP
!      DEC R4
       JNE !
       LI R0,>0500       ; Get 5 rupees
       JMP GETRUP
!      DEC R4
       JNE !
       MOV @HFLAGS,R0
       ANDI R0,BLURNG+REDRNG
       INC R0
       SLA R0,9
       AB R0,@HP         ; Get heart
!
DOSTAT BL @STATUS
       B @SPROFF
GETRUP AB R0,@RUPEES   ; Add R0 to rupees
       JNC DOSTAT      ; Overflow?
       SETO R0         ; Reset rupess to 255
       MOVB R0,@RUPEES
       JMP DOSTAT

       ; Rupee yellow, blue; 5 rupee blue blue; heart blue red
RUPEEC BYTE >0A,>05,>05,>05,>04,>06



FLAMXY DATA >00F0,>0000,>B800,>1800

FLMDOR LI R2,FLMDO2  ; Flame overlapped secret door location
       MOV @DOOR,R5
       MOV R5,R0
       BL @TESTCH    ; Get character under secret door location
FLMDO2 CI R1,>9000  ; Green bush
       JNE !
       LI R1,>7879  ; Green stairs
       LI R2,>7A7B
       JMP !!
!      CI R1,>9800  ; Red bush
       JNE FLAME0
       LI R1,>7071  ; Red stairs
       LI R2,>7273
!      BL @STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @SETBIT   ; Set bit R0 in VDP at R1

       JMP FLAME0

FLAME4
       ; FIXME this should be right when the flame stops moving
       MOV @FLAGS,R0
       ANDI R0,DARKRM
       JEQ !!      ; in a darkened room?

       ; save sprite data because dan2 decompress will overwrite it
       MOV @OBJPTR,R1       ; Get sprite index
       MOV R4,@OBJECT(R1)   ; Save data
       A R1,R1
       MOV R5,@SPRLST(R1)   ; Save sprite pos
       MOV R6,@SPRLST+2(R1) ; Save sprite id & color

       ; save R12
       LI R0,MAPSAV+1
       MOV R12,R1
       BL @VDPWB
       MOVB @R12LB,*R15

       LI R0,BANK2
       LI R1,MAIN
       LI R2,2         ; Light up via candle
       BL @BANKSW

       ; restore R12
       LI R0,MAPSAV+1
       BL @VDPRB
       MOVB R1,R12
       MOVB @VDPRD,@R12LB

       MOV @OBJPTR,R1       ; Get sprite index
       B @OBLOOP

FLAME  CI R4,>FF00
       JHE FLAME3
       LI R0,>0100
       S  R0,R4
       C  R4,R0      ; Decrement counter
       JHE !
FLAME2
       ; FIXME don't do this in dungeon
       MOV @DOOR,R3    ; Check for door collision
       LI R2,FLMDOR
       BL @COLIDE

FLAME0
       B @SPROFF
!
       CI R4,FLAMID
       JEQ FLAME2    ; Book of Magic flame?
       JH !
       CI R4,>3900   ; Stop moving after 36 frames
       JLE FLAME4
       LI R0,>0100   ; Move every other frame
       CZC R0,R4
       JNE !
       MOV R4,R1
       ANDI R1,>00C0
       SRL R1,5        ; R1 = direction
       MOV R5,R0
       SZC @EMOVEC(R1),R0  ; Mask XX or YY
       C R0,@FLAMXY(R1)    ; Check screen edge
       JEQ !
       A @EMOVED(R1),R5 ; Move
!      BL @LNKHIT
FLAME3 JMP BOMNXT



* Bomb jump  0  1   2  3
BOMBJ  BYTE -16,16,-32,32


BOMB   LI R0,>0100
       S  R0,R4
       C  R4,R0      ; Decrement counter
       JHE !
       B @SPROFF
!
       MOV R4,R0      ; Get counter in R0
       SRL R0,8
       CI R0,36       ; Bomb explode
       JNE !!!
       LI R6,CLOUD1   ; cloud 1, white

       MOV R5,R7

       MOV @DOOR,R3    ; Check for door collision
       LI R2,BOMDOR
       BL @COLIDE
BOMB0

       SWPB R7
       CI R7,>1000    ; At left edge?
       JHE !
       AI R5,>0020    ; Adjust right 32 pixels
       AI R6,>0080    ; Set early bit for left edge
!
       AI R4,>80      ; Middle left poof - toggles by 32
       AI R5,-16
       BL @OBSLOT
       AI R4,->80     ; Lower left poof - toggles by 16
       AI R5,(16*256)+8
       BL @OBSLOT
       AI R4,>40      ; Upper right poof - toggles by 16
       AI R5,(-32*256)+16
       BL @OBSLOT
       AI R5,(16*256)-8

       CI R7,>1000    ; At left edge?
       JHE !
       AI R5,->0020   ; Adjust left 32 pixels
       AI R6,->0080   ; Clear early bit
!

       JMP BOMB1
!
       CI R0,12
       JNE !
       AI R6,>0400       ; Poof dissapates slightly
!
BOMB1
       MOV @OBJPTR,R1
       CI R1,BOMBOB-OBJECT
       JEQ !             ; Primary bomb poof doesn't move

       LI R1,>0040       ; Wiggle back and forth
       XOR R1,R4
       MOV R4,R1
       ANDI R1,>00C0
       SRL R1,6
       AB @BOMBJ(R1),@R5LB

       JMP BOMNXT

!      CI R0,34         ; Bright colorset
       JEQ BOMB2
       CI R0,30         ; Normal colorset
       JEQ BOMB3
       CI R0,29         ; Bright colorset
       JEQ BOMB2
       CI R0,25         ; Normal colorset
       JNE BOMNXT
BOMB3
       LI R0,>0300+(CLRTAB/>40) ; VDP Register 3: Color Table
       LI R1,>07F1          ; VDP Register 7: White on Black
       JMP !
BOMB2
       LI R0,>0300+(BCLRTB/>40) ; VDP Register 3: Color Table
       LI R1,>07FE          ; VDP Register 7: White on Grey
!      BL @VDPREG
       MOV R1,R0
       BL @VDPREG
BOMNXT B @OBNEXT

BOMDOR LI R2,BOMDO2
       MOV @DOOR,R5
       MOV R5,R0
       BL @TESTCH    ; Get character under secret door location
BOMDO2 CI R1,>8000  ; Green brick
       JEQ !
       CI R1,>A000  ; Red brick
       JNE !!
!      LI R1,>7F7F
       LI R2,>2020
       BL @STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @SETBIT   ; Set bit R0 in VDP at R1

!      MOV R7,R5
       JMP BOMB0

       ; Set bit R0 in VDP at address R1
       ; Modifies R0-R3
SETBIT MOV R0,R2
       LI R3,>8000
       ANDI R0,7
       JEQ !
       SRL R3,R0  ; R3 = 0x80 >> (bit & 7)
!
       SRL R2,3
       A R2,R1    ; R1 += (bit >> 3)
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOV R1,R0   ; Save address for VDPWB
       MOVB @VDPRD,R1
       SOC R3,R1   ; R1 |= R3
       B @VDPWB




* bits right,left,down,up (screen edge tests, index by 3-bit direction)
BMRNGF BYTE >8,>A,>2,>6   ; Right, downright, down, downleft
       BYTE >4,>5,>1,>9   ; Left,  upleft,    up,   upright

* Boomerang
* R4[15-9]= counter 0=returning 1-2=spark 3-7f=countdown
* R4[8-6] = direction (peahat style)

* 45 move by 3x15
* 30 move by 2 2
* 28 move by 1 0 1 0 1 0 1 0 1 0 1 0
* 16 move by 0 0
* 14 move by 1 0 1 0 1 0
* 8 move by 1 1 1 1 1 1 1 1
* 0 move by 2
BMRNG
       CI R4,16*>0200
       JL BMRNG2  ; Returning

       MOV R4,R3
       SRL R3,6
       ANDI R3,>0007  ; Get direction in R3

       MOV R5,R7      ; R5=YYXX
       SWPB R7        ; R7=XXYY

       MOVB @BMRNGF(R3),R0  ; Get screen edge test flags in R0 right,left,down,up
       SLA R0,5       ; Get right test bit in carry
       JNC !
       CI R7,>F000    ; Test right screen edge
       JHE BMRNG7
!      SLA R0,1       ; Get left test bit in carry
       JNC !
       CI R7,>0300    ; Test left screen edge
       JLE BMRNG7
!      SLA R0,1       ; Get down test bit in carry
       JNC !
       CI R5,>B400    ; Test bottom screen edge
       JHE BMRNG7
!      SLA R0,1       ; Get up test bit in carry
       JNC !
       CI R5,>1800    ; Test top screen edge
       JLE BMRNG7
!
       A R3,R3
       MOV @PEAHAD(R3),R3  ; R3=peahat-style movement by 1
BMRNG1
       MOV R4,R0
       SRL R0,9        ; R0=counter
       JEQ BMOVE2      ; counter=0? Move by 2

       AI R4,->200     ; Decrement counter

       CI R6,SPARK
       JEQ BMRNG8

       CI R0,8
       JLE BMOVE1      ; Move by 1
       CI R0,28
       JH !
       ANDI R0,1       ; Move by 0 or 1
       JNE BMOVE1
       JMP BMOVE0
!      CI R0,30
       JLE BMOVE2      ; Move by 2

BMOVE3 A R3,R5
BMOVE2 A R3,R5
BMOVE1 A R3,R5
BMOVE0

       MOV @COUNTR,R0
       ANDI R0,3
       JNE BMRNXT     ; Animate every 4th frame

       MOV R6,R1
       SRL R1,10
       ANDI R1,3
       MOVB @BMRNGS(R1),R6

       JMP BMRNXT
BMRNG2
       MOV @HEROSP,R3   ; Sprite off if collision with hero
       LI R2,SPROFF
       BL @COLIDE

       CLR R3
       CB R5,@HEROSP    ; Move toward the hero
       JL  BMRNG3
       JH  BMRNG4
!      CB @R5LB,@HEROSP+1
       JL  BMRNG5
       JH  BMRNG6
       JMP BMRNG1
BMRNG3
       AI R3,>0100
       JMP -!
BMRNG4
       AI R3,>FF00
       JMP -!
BMRNG5
       AI R3,>0001
       JMP BMRNG1
BMRNG6
       AI R3,>FFFF
       JMP BMRNG1
BMRNG7 ; Screen edge hit
       LI R4,(BMRGID&>003F)+>0600  ; spark for 3 frames
       LI R6,SPARK
       JMP BMRNXT
BMRNG8 ; wait for spark countdown to 0
       CI R4,>0100
       JHE BMRNXT
       LI R6,BOOMSC   ; normal boomerang color
       MOV @HFLAGS,R0
       SLA R0,1
       JNC BMRNXT
       LI R6,MBOMSC  ; magic boomerang color
BMRNXT B @OBNEXT


* Boomerang next sprite table (indexed by current sprite)
BMRNGS BYTE >9C,>98,>90,>94

       ; Compare YYXX in R3 and R5 for overlap, jump to R2 if collision
       ; Modifies R3
COLIDE
       S   R5,R3            ; subtract sprite pos from sword pos
       ABS R3
       CI R3,>0D00
       JH !
       SWPB R3
       ABS R3
       CI R3,>0D00
       JH !
       B *R2              ; collided
!      RT                 ; no collision


* Hit test R5 with our hero
* Enemy direction in R2: 0=right 2=left 4=down 6=up
* Modifies R0,R3
LNKHIT
       MOV @HURTC,R0     ; Can't get hurt again if still flashing
       JNE -!

       MOV @HEROSP,R3    ; Get hero pos in R3
       MOV R3,R0           ; Save hero pos for later
       S   R5,R3           ; subtract enemy pos from hero pos
       ABS R3
       CI R3,>0A00
       JH -!       ; no collision RT
       SWPB R3
       ABS R3
       CI R3,>0A00
       JH -!        ; no collision RT

       ; calculate knockback direction
       ANDI R0,>0707
       JNE !
       ; horizontally and vertically aligned
       CB R3,@R3LB
       JL LNKHI2

!      ANDI R0,>0700
       JNE LNKHI2
       ; horizontally aligned
       CB @R5LB,@HEROSP+1
       JHE !
       CLR R0          ; right
       JMP LNKHI3
!      LI R0,DIR_LT    ; left
       JMP LNKHI3
LNKHI2
       ; vertically aligned
       CB R5,@HEROSP
       JHE !
       LI R0,DIR_DN    ; down
       JMP LNKHI3
!      LI R0,DIR_UP    ; up

LNKHI3
       ; don't change R0 until setting HURTC

       MOV R4,R1
       ANDI R1,>003F    ; Get enemy type

       ; TODO Enemy reverse direction, or bullet disappear
       CI R1,BULLID
       JEQ LNKHI4

       CI R1,ARRWID
       JEQ LNKHI4

       CI R1,BSWDID
       JNE !

       MOV @HFLAGS,R3
       ANDI R3,MAGSHD      ; Beam sword can only be blocked with magic shield
       JEQ ARRHIT

LNKHI4

       ; check sprite for action, can't block if hero attacking
       MOV @HEROSP+2,R3    ; Get hero sprite offset and color
       ANDI R3,>F000       ; Get sprite upper nibble
       JNE ARRHIT          ; Is zero? (hero walking sprites)


       ; bullets bounce off if facing the right way (and have magic shield in some cases)

       ; enemy arrow
       MOV @FLAGS,R3
       ANDI R3,DIR_XX     ; R3 = hero direction >0300
       SRL R3,7
       XOR @REVMSK,R3
       C R2,R3   ; check reverse direction
       JNE ARRHIT

       ; successful block
       MOV @BOUNCD(R2),R4  ; change to beam splash id
       RT                 ; return with no damage

BOUNCD DATA BSPLID,BSPLID+>40,BSPLID+>40,BSPLID+>80  ; Reflected bounce NW,NE,NE,SW

ARRHIT ; Arrow disappear (same as SPROFF)
       CLR R4
       LI R5,>D200
!

       AI R0,>C000      ; add 48<<10 frames hurt counter
       MOV R0,@HURTC

       SB @EDAMAG(R1),@HP  ; Subtract enemy attack damage
       JGT !

       CLR R1         ; Set HP to zero in case of underflow
       MOVB R1,@HP
       ; fall thru (zero hp is in bank0)
!      B @STATUS

AFAIRY
BADNXT JMP BADNXT



* Rupee blink
RUPEEB
       CI R6,>C00A
       JEQ !
       CI R6,>C005
       JNE !!
!      MOV @COUNTR,R0
       ANDI R0,>0007
       JNE !
       LI R0,(>C00A^>C005)
       XOR R0,R6
!      RT

* Cave item object, check hero collision, enough money, already have it
* R4: object id
* R5: location
* R6: sprite and color
CAVITM
       BL @RUPEEB
       MOV @HEROSP,R0
       C R0,R5
       JNE TEXTRT
       MOV @OBJPTR,R0
       SRL R0,1      ; Get object byte offset
       AI R0,ENEMHP
       BL @VDPRB     ; R1 = item price
       CB R1,@RUPEES
       JH TEXTRT     ; Not enough rupees?

       ;TODO already have it?

       SB R1,@RUPEES ; Subtract price from rupees
       BL @STATUS    ; Update status

       ; TODO hold up item  (TODO this needs to be in bank 0)
       LI R0,BANK4
       LI R1,MAIN
       LI R2,9
       BL @BANKSW

       ; Put sprites in VDP in order
       LI R0,SPRTAB
       LI R1,SPRLST
       LI R2,32*4
       BL @VDPW


       ; TODO this should be in bank0

       LI R9,32
!      BL @VSYNCM
       ;BL @COUNT
       LI R0,SPRTAB+(14*4)
       LI R1,>5700
       BL @VDPWB

       BL @VSYNCM
       ;BL @COUNT
       LI R0,SPRTAB+(14*4)
       LI R1,>D000
       BL @VDPWB

       DEC R9
       JNE -!

       LI R9,64
!      BL @VSYNCM
       ;BL @COUNT

       DEC R9
       JNE -!

       ; Back to normal sprites
       LI R0,BANK4
       LI R1,MAIN
       LI R2,2
       MOV @FLAGS,R3
       ANDI R3,DIR_XX
       BL @BANKSW       ; TODO this needs to be in bank 0


       ; TODO NPC disappears
       ; TODO set bit for collected item
       B @SPROFF

* Text writer object, writes one char every 6 frames
* R4[15:6] counter
* R5[7:0] screen offset
* R6[13:0] pointer to text in VDP RAM
TEXTER
       MOV @COUNTR,R0
       CI R0,>2000     ; Only update every 6 frames, when COUNTR is 1xxx
       JHE TEXTRT
       CLR R1       ; Initial offset zero
!      A R1,R5      ; Add offset (1-31)
       MOV R6,R0
       INC R6         ; Next character
       BL @VDPRB
       CI R1,>2000
       JHE !
       SRL R1,8
       JNE -!
       B @SPROFF    ; Zero byte - end of text
!      MOV @FLAGS,R2
       ANDI R2,SCRFLG   ; Get current screen ptr
       MOV R5,R0
       ANDI R0,>00FF    ; Get screen offset
       AI R0,8*32+4     ; Add text offset in cave 8,4
       A R2,R0
       BL @VDPWB
       INC R5
FARYRT
TEXTRT B @OBNEXT



* Fairy in pond (restore half-heart every 22 frames) (spawn heart every 11 frames)
* R4[15..8] = counter
*  0 = needs init
*  1 = waiting for hero to trigger
*  46..2 = countdown by 2  R4[8..6] = spawned heart counter
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
FAIRY
       MOV R4,R0
       ANDI R0,>FF00
       JNE !
       ; initialize fairy position and sprite
       LI R5,>5378  ; Position
       LI R6,FARYSC ; Fairy Sprite and color

       BL @SAVESP   ; Save sprite, start with cloud animation
       ORI R4,>4FC0
       JMP FARYRT

!      CI R0,51*>100
       JL !
       B @OCTOR4     ; Do cloud animation
!
       CI R0,>100
       JEQ FAIRYX   ; not triggered

       AI R4,>200   ; increment counter

       ANDI R0,>FE00
       CI R0,12*>200
       JEQ !

       CI R0,23*>200
       JL FARYRT
       AI R4,-22*>200
!
       MOV R4,R1
       ANDI R1,>01C0 ; remaining spinning hearts to spawn
       JEQ FAIRY6    ; restore player half-heart

       AI R4,->0040  ; decrement remaining spinning hearts
       JMP FAIRY5  ; Spawn a heart

FAIRYX
       LI R2,FAIRY4   ; jump here on collision
       LI R5,>7378    ; location to collide to hero
       MOV @HEROSP,R3
       BL @COLIDE
FAIRY3
       LI R5,>5378  ; Restore fairy location
       JMP FARYRT

FAIRY4 ; start spawning hearts
       LI R4,FRY2ID+>05C0
FAIRY5 ; spawn a heart
       MOV R4,R7
       LI R4,HRT2ID
       LI R6,HRT2SC
       BL @OBSLOT
       MOV R7,R4
       LI R6,FARYSC
       JMP FAIRY3

FAIRY6 ; filling hero hearts mode
       CI R0,23*>200
       JNE FARYRT      ; only every 22 frames

       CLR R9
       MOVB @HEARTS,R9        ; R9 = max hearts - 1
       AI   R9,>100
       MOV  @HFLAGS,R0
       LI   R10,1             ; R10 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R9,R9             ; double max hp
       INC  R10               ; R10 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R9,R9             ; double max hp again
       INCT R10               ; R10 = 4 hp per half-heart
!      A R9,R9                ; R9 = max hp
       SWPB R10
       A R10,@HP              ; add a half-heart
       CB   @HP,R9
       JHE FAIRY8             ; hp full

FAIRY7
       BL @STATUS

       ; if hero hearts are full, turn off all spinning hearts, otherwise add 1 half-heart
       JMP FARYRT
FAIRY8
       MOVB R9,@HP            ; set hearts to max
       LI R4,IDLEID            ; set to idle object

       ; turn off all spinning hearts
       LI R1,LASTOB
!
       CI R1,OBJECT+64
       JEQ FAIRY7

       MOV *R1+,R0       ; get object data
       ANDI R0,>003F     ; mask object type
       CI R0,HRT2ID      ; spinning heart?
       JNE -!
       LI R0,SPOFID      ; Set object to turn off sprite
       MOV R0,@-2(R1)

       JMP -!


* Add sine of R1 to R5
* R1 = 0..44..88 ~ 0..pi..2pi
AR5SIN
       CI R1,44
       JHE NEGSIN
       CI R1,23
       JL !
       NEG R1
       AI R1,44
!      AB @SINTBL(R1),R5
       RT
NEGSIN
       CI R1,67
       JL !
       NEG R1
       AI R1,88+44
!      SB @SINTBL-44(R1),R5
       RT

SINTBL ; sine table - 23 bytes to pi/2, scaled to 53
       BYTE >00,>04,>08,>0B,>0F,>13,>16,>19,>1D,>20,>23
       BYTE >25,>28,>2A,>2D,>2F,>30,>32,>33,>34,>34,>35,>35
       EVEN

* Hearts that spin around fairy in pond (counterclockwise)
* R4[15..8] = countdown 0..88
HEART2
       LI R0,>100
       C R4,R0
       JHE !
       AI R4,88*>100
!      S R0,R4

       MOV R4,R1    ; Get rotation from R4
       SRL R1,8

       LI R5,>786A  ; Center Position (byte swapped)

       BL @AR5SIN   ; Add sine to X

       MOV R4,R1    ; Get rotation from R4
       SRL R1,8
       AI R1,-22    ; Subtract 1/4 to get cosine
       JOC !        ; overflow?
       AI R1,88     ; wrap around
!
       SWPB R5
       BL @AR5SIN   ; Add cosine to Y
       JMP PEAHRT



* Store the current sprite in object HP and set to cloud
SAVESP
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS+VDPWM   ; Use HP/stun counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R6,*R15      ; Save sprite and facing
       MOVB @R6LB,*R15   ; Save color

       LI R6,CLOUD1  ; poof, white
       RT


* Boulder AI
* R4: 0 init
*     1-18  y+=2
*     19-21 y+=1
*     22-23 y+=0
*     24-26 y-=1
*     27-29 y-=2
*     30+   y+=0 x+=0
BOULDR LI R3,>0100
       C R3,R4
       JLE !
BOULDI BL @RANDOM
       MOV R0,R1
       ANDI R1,>3F80
       AI R1,>2000
       A R1,R4      ; R4+=(32+RND*16)*256

       ANDI R0,>00FF
       AI R0,>1800
       MOV R0,R5
       LI R6,>3009

!      BL @ANIM6
       CI R4,30*>100
       JL !
       BL @RANDOM
       ANDI R0,>0080
       XOR R0,R4      ; Change direction randomly
       JMP BOULD3

!      CI R4,27*>100
       JL !
       AI R5,->0200    ; Move up 2
       JMP BOULD2

!      CI R4,24*>100
       JL !
       S R3,R5        ; Move up 1
       JMP BOULD2

!      CI R4,22*>100
       JHE BOULD2
       CI R4,19*>100
       JL !
       A R3,R5       ; Move down 1
       JMP BOULD2

!      AI R5,>0200
       CI R5,>D000   ; Reinit at bottom of screen
       JHE BOULDI
BOULD2
       MOV R4,R0
       SLA R0,9
       JOC !
       INC R5        ; Move right
       JMP BOULD3
!      DEC R5        ; Move left

BOULD3 S R3,R4       ; Decrement counter
       C R3,R4
       JL !
       AI R4,30*>100   ; Bounce
!
       BL @LNKHIT
       JMP PEAHRT




* Peahat animation loop: 2 2 1 2 1  (01011011)
* And moves by 1 only when animation changes
* Peahat Direction data
PEAHAD DATA >0001,>0101,>0100,>00FF  ; 0 Right, 1 downright, 2 down, 3 downleft
       DATA >FFFF,>FEFF,>FF00,>FF01  ; 4 Left,  5 upleft,    6 up,   7 upright
PEAHAA DATA >DAAA,>AAAA,>AA4A,>4A4A,>4911,>1111,>1080,>8080 ; animation
* R4:  6 bits animation counter
*      3 bits direction
*      1 bits hurt/stun flag
*      6 bits object id
*  descending: 128 frames, counter=27..42
*  landed: 72 frames, counter=18..26
*  ascending: 128 frames, counter=2..17   init=17
*  flying: 8 frames, count=1
PEAHAT
       MOV R4,R1
       MOV @COUNTR,R2  ; R2=counter
       INV R2          ; counting down by default
       SRL R1,10      ; Get counter bits
       JEQ PEAHA3    ; If zero do setup
       CI R1,1
       JNE !         ; flying normally?
       MOV R2,R1
       ANDI R1,7     ; use 3 bits from counter
       JMP PEAHA2

!      CI R1,17      ; ascending?
       JH !
       ANDI R2,7     ; use 3 bits from counter
       JMP PEAHA1

!      CI R1,26      ; landed?
       JH PEAHA0
       ANDI R2,7     ; use 3 bits from counter
       JNE !
       AI R4,->0400  ; Decrement landed counter
!      BL @HITEST    ; can only be hit while landed
PEAHRT
       JMP OBNXT

PEAHA0 NEG R1        ; descending
       AI R1,27+17   ; reverse descending counter 27..42 -> 17..2
       INV R2
       ANDI R2,7     ; use 3 bits from counter
       CI R2,7
PEAHA1 JNE !
       AI R4,->0400  ; Decrement ascending/descending counter
!      DECT R1
       SLA R1,3
       A R2,R1       ; add them to counter

       LI R0,>0040   ; Test for hurt bit
       COC R0,R4
       JNE PEAHA2
       BL @HSBIT

PEAHA2
       BL @LNKHIT    ; Modifies R0,R3

       MOV R1,R0
       SRL R1,4
       A  R1,R1
       MOV @PEAHAA(R1),R1  ; Get animation bits
       ANDI R0,>000F
       INC R0
       SLA R1,R0      ; Put animation bit in carry status
       JNC OBNXT      ; Don't animate or move if bit not set

       LI R1,>0400
       XOR R1,R6      ; Toggle animation
       MOV R4,R1
       ANDI R1,>0380  ; Get direction bits (8 directions)
       SRL R1,6
       MOV R5,R2          ; Save old position
       A @PEAHAD(R1),R5   ; Move based on direction

       MOV R5,R0         ; Test edges of screen
       CI R0,>2800       ; Top edge
       JLE PEAHAR
       CI R0,>A800       ; Bottom edge
       JHE PEAHAR
       SWPB R0
       CI R0,>1000       ; Left side
       JLE PEAHAR
       CI R0,>E000       ; Right side
       JHE PEAHAR

       ANDI R0,>0707    ; Don't change direction unless 8-pixel aligned
       JNE OBNXT

       BL @RANDOM
       ANDI R0,>001F
       JNE !            ; 1 in 32 chance to land
       CI R4,>0800
       JHE !            ; flying normally?
       ANDI R4,>03FF    ; Clear counter bits
       ORI R4,42*>0400  ; Set counter=42
       JMP OBNXT
!
       MOV R4,R1
       ANDI R1,>0380    ; R1 = direction bits
       ANDI R0,7        ; 2 in 8 chance to change direction
       JEQ !            ; Turn right
       DEC R0
       JNE OBNXT
       AI R1,>FF80      ; Turn left
PEAHAL ANDI R1,>0380    ; Mask off direction overflow
       ANDI R4,>FC7F    ; Mask off old direction
       SOC R1,R4        ; Store new direction
       JMP OBNXT
!      AI R1,>0080      ; Turn right
       JMP PEAHAL
PEAHAR LI R0,>0200      ; Reverse direction
       XOR R0,R4
       MOV R2,R5        ; Restore old position
       JMP OBNXT
PEAHA3
       BL @SPAWN
       LI R6,>2009    ; Set sprite and color (ECOLOR+2)
       ORI R4,(17*>0400)+(6*>0080)   ; Set initial counter=17 and direction to spin-up=6
       JMP OBNXT



* Tektite
* R4[15-8] = counter
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
TKTITE
       MOV R4,R0
       SRL R0,8       ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       MOV @ECOLOR(R3),R6 ; Reload sprite and color
       JMP OCTOR1     ; use octorok to init cloud
!
       CI R4,51*>100  ; cloud animation?
       JHE OCTOR4

       AI R4,->0100   ; decrement counter
       DEC R0         ; decrement counter
       JNE !          ; toggle animation when counter hits zero
       AI R4,>1100    ; counter += 17
       LI R1,>0400
       XOR R1,R6      ; Toggle animation
!      BL @HITEST
       JMP OBNXT

OBNXT  B @OBNEXT

* Octorok, Moblin and Lynel AI
* R4[15..8] = counter
*  0 = needs init
*  1 = normal movement
*  2..50 = stationary for projectile
*  26 = projectile launch
*  51..56 = low cloud
*  57..62 = mid cloud
*  63..  = high cloud
LYNEL
MOBLIN
OCTORK
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE OCTOR2    ; If zero do setup
OCTORI
       BL @SPAWN     ; Setup octorok
OCTOR1
       BL @SAVESP    ; Save sprite and facing to HP, change to cloud sprite

       AI R1,-(ENEMHS+VDPWM+>18)  ; R1=0,2,4,...
       SLA R1,11     ; R1 upper byte: 0,8,16

       CI R4,>0008   ; Moblin ID?
       JL !          ; less than moblin means octorok or tektite (longest delay)
       SRL R1,2      ; divide delay by 4  R1=0,2,4
       CI R4,>000A   ; Lynel ID?
       JL !          ; less than lynel means moblin
       CLR R1        ; Lynels all appear at the same time

!      AI R4,>4800   ;
       A R1,R4       ; delay cloud based on enemy index

OCTOR2
       CI R4,51*>100  ; cloud animation?
       JHE OCTOR4

       BL @ANIM6     ; Animate - R0 contains counter

       BL @HITEST

       MOV @COUNTR,R0
       SLA R0,8
       JOC OBNXT     ; Move every other frame (unless it's fast octorok)

OCTOR3
       ; check if shooting a bullet
       CI R4,>0200
       JL EMOVE      ; Not shooting, just move
       AI R4,->100   ; Decrement counter

       MOV R4,R1
       SRL R1,8      ; R1=counter 50..2
       CI R1,25      ; Shoot projectile at count=25
       JNE OBNXT

       ; shoot a bullet
       MOV R4,R7     ; Save object id
       MOV R6,R8     ; Save sprite

       MOV R6,R4
       ANDI R4,>1800
       SRL R4,5      ; R4= direction mask >00C0
       ORI R4,BULLID
       LI R6,BULLSC

       MOV R7,R0
       ANDI R0,>003F ; Get ID
       CI R0,>0008   ; Moblin ID?
       JL !          ; less than moblin means octorok or tektite (longest delay)

       ; moblin - shoot arrow
       MOV R8,R6
       ANDI R6,>1800 ; R6=direction
       SRL R6,1
       ORI R6,>A001  ; arrow sprite, black
       LI R4,ARRWID

       CI R0,>000A   ; Lynel ID?
       JL !          ; less than lynel means moblin

       ; lynel - shoot sword
       AI R6,>700F->A001  ; change arrow to sword
       LI R4,BSWDID
!
       BL @OBSLOT
       MOV R7,R4     ; Restore object id
       MOV R8,R6     ; Restore sprite

       JMP OBNXT

       ; Fast octorok
OCTRKF
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JEQ OCTORI    ; If zero do setup

       CI R4,51*>100 ; cloud animation?
       JHE OCTOR4

       BL @ANIM6

       BL @HITEST
       JMP OCTOR3    ; Move every frame

OCTOR4 ; cloud animation
       AI R4,->100
       MOV R4,R0
       SRL R0,8
       CI R0,62
       JEQ !
       CI R0,56
       JEQ !
       CI R0,50
       JNE OBNXT

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Use HP/stun counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP
       MOVB @VDPRD,R6      ; Load sprite and facing
       MOVB @VDPRD,@R6LB   ; Load color
       AI R4,-49*>100      ; Set R4HB to 1
       JMP OBNXT

!      AI R6,>0400
       JMP OBNXT2


GHINI
       MOV R4,R0
       SRL R0,8      ; Get initial counter
       JNE !          ; If zero do setup
       BL @SPAWN
       LI R6,>200F    ; Ghini sprite white
       AI R4,>0100
!
OBNXT2
       B @OBNEXT




* Enemy movement (octorok, moblin, lynels)
* Modifies R0-R3,R10
EMOVE
       LI R10,OBNEXT    ; Return to R10
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE3       ; No? Keep moving

       BL @RANDOM
       MOV R0,R1
       ANDI R0,7        ; 1 in 8 chance to change direction
       JNE EMOVE3

       ; TODO shoot projectile
       ANDI R1,>0003
       JNE EMOVE2       ; 1 in 4 chance to shoot

       AI R4,49*>100    ; set counter for projectile launch

EMOVE2 BL @RANDOM       ; Change direction
       ANDI R0,>1800
       XOR R0,R6

EMOVE3
       MOV R6,R3        ; Get enemy facing
       SRL R3,10
       ANDI R3,>0006         ; Mask only direction bits

       LI R2,EMOVE2     ; Change direction if wall or screen edge
* Enemy movement subroutine, goto R2 if solid, goto R10 otherwise
* R3 = direction 0=Down 2=Left 4=Right 6=Up
* Modifies R0,R1
EMOVE4
       MOV R5,R0
       SZC @EMOVEM(R3),R0    ; Aligned to 8 pixels?
       JNE EMOVE5            ; Not aligned, move and return
       MOV R5,R0
       SZC @EMOVEC(R3),R0    ; For edge test
       C @EMOVEE(R3),R0      ; At edge of screen?
       JNE !                 ; At edge, return
       B *R2                 ; Return to R2 address
!
       ; Check for walls, will return to R2 if solid
       MOV @EMOVEA(R3),R0
       A R5,R0
       BL @TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @TESTCH

EMOVE5 A @EMOVED(R3),R5     ; Perform movement
       B *R10               ; Jump to saved return address

* Leever random direction
LERAND
       BL @RANDOM
       ANDI R0,>0180
       XOR R0,R4          ; Get random direction
* Lever move
LEMOVE
       LI R10,OBNEXT     ; EMOVE4 will return to R10
LEMOV2
       LI R2,LERAND      ; EMOVE4 will go to R2 if solid

       MOV R4,R3         ; Get direction in R3
       SRL R3,6
       ANDI R3,>0006

       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE5       ; No? Keep moving

       BL @RANDOM
       ANDI R0,7        ; 1 in 8 chance to change direction
       JEQ LERAND

       JMP EMOVE4


* Knockback, until hitting wall or edge of screen
* R3 = direction 0=Down 2=Left 4=Right 6=Up
* Modifies R0-R2
KNOCKB
       MOV R11,R10           ; Save return address in R10
       JMP EMOVE4


* Octorok Bullet
* R4[7..6] = direction
BULLET
       MOV R4,R2
       ANDI R2,>00C0
       SRL R2,5         ; Get bullet direction R2: 0=Down 2=Left 4=Right 6=Up
       BL @LNKHIT       ; hit test on hero
       MOV R4,R4        ; test R4 for zero?  (did bullet hit hero)
       JEQ OBNXT2
       MOV R2,R3
       LI R2,SPROFF     ; Goto SPROFF if wall or screen edge
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       JMP OBNXT2



LEVERP DATA >3806,>3804  ; Leever half-up sprite

* R4:  7 bits animation counter
*      2 bits direction
*      1 bits hurt/stun flag
*      6 bits object id
* _______________frames___animation___counter
*   half-down:     16                  35
*   pulsing:       96       11         29..34
*   underground:  129                  20..28
*   pulsing:       32       11         18..19
*   half-up:       15                  17
*   normal:       255        5         1..16
LEEVER
       MOV R4,R1
       SRL R1,9
       JNE !
       BL @SPAWN
       LI R6,>0000
       MOV @OBJPTR,R1
       SWPB R1
       ANDI R1,>0E00
       A R1,R4            ; Initial counter + object pointer
       AI R4,21*>0200     ; Initial counter + 21
       BL @RANDOM
       ANDI R0,>0180
       XOR R0,R4          ; Get random direction
       CLR R6
       B @OBNEXT

!      MOV @COUNTR,R0
       ANDI R0,>000F
       JNE LEEVR2
       AI R4,->0200    ; Decrement counter every 16 frames

       ; Set colors based on new counter
       DEC R1         ; Half-down?
       JNE !
       AI R4,35*>0200  ; Change counter to pulsing (down)
       LI R1,35
       ANDI R4,~>0040  ; Clear hurt/stun bit
       JMP LHALF

!      CI R1,16
       JNE !
       MOV @ECOLOR(R3),R6 ; Normal sprite
       JMP LEEVR2

!      CI R1,17        ; Half-up?
       JNE !
LHALF  MOV @LEVERP-28(R3),R6 ; Half-up/down sprite
       JMP LEEVR2

* Lever move every 6 frames (TODO should be 6 then 7)
LEMOV6
       MOV @COUNTR,R0
       SRL R0,12
       DEC R0
       JEQ LEMOVE
       JMP OBNXT3

!      CI R1,19        ; Pulsing?
       JEQ LPULSE

       CI R1,28        ; Underground?
       JNE !
       CLR R6          ; Transparent sprite
       JMP LEEVR2

!      CI R1,34        ; Pulsing?
       JNE LEEVR2

LPULSE LI R6,PULSE     ; Pulsing sprite

LEEVR2
       CI R1,16        ; Normal?
       JH !
       BL @ANIM5
       BL @HITEST
       MOV @COUNTR,R0
       ANDI R0,1
       JEQ LEMOVE      ; Move every other frame
       JMP OBNXT3
!
       MOV R4,R0
       ANDI R0,>0040
       JEQ !
       BL @HSBIT       ; Do knockback or blinking
!
       CI R1,17        ; Half-up?
       JLE LEMOV6

       CI R1,19        ; Pulsing?
       JLE LPULS2

       CI R1,28        ; Underground?
       JLE LEMOV6

       CI R1,34
       JH LEMOV6       ; Half-down

LPULS2 BL @ANIM11      ; Pulsing?
       JMP LEMOV6



* R4: 8 bits counter
*     1 bits reserved
*     1 bits hurt/stun flag
*     6 bits object id
* init                             counter=0
* pulsing  32 frames   anim 11     counter=10..11
* normal   48 frames               counter=7..9
*   bullet appears after 19 frames, then shoots after 16
* pulsing  96 frames   anim 11     counter=1..6
* disappear 2 frames
ZORA   CI R4,>0100
       JHE !

ZORA1  LI R2,ZORA3
ZORA2  BL @RANDOM      ; Get a random coordinate
       ANDI R0,>70F0   ; Align to 16 pixels
       AI R0,>2800     ; Moved down by 5 lines
       ; TODO fix respawning in same location
       MOV R0,R5       ; Save location if it's good
       BL @TESTCH
       JMP ZORA2
ZORA3  ANDI R1,>F000
       CI R1,>E000     ; Is it water?
       JNE ZORA2

       AI R4,>0C00     ; Set counter to 11
       JMP ZORA4
!
       MOV @COUNTR,R0
       ANDI R0,>000F   ; Get 16 counter
       JNE ZORA5
       AI R4,->100
       CI R4,>0100
       JL ZORA1       ; Reset counter
       CI R4,>0900+ZORAID
       JNE !
       LI R6,>680D     ; Zora sprite
       C R5,@HEROSP    ; Hero above or below zora?
       JL ZORA5
       AI R6,>0400     ; Zora face down toward hero
       JMP ZORA5
!      CI R4,>0600+ZORAID
       JNE ZORA5
ZORA4
       LI R6,>2805     ; Pulsing sprite

ZORA5
       CI R4,>0700
       JL !            ; Pulsing
       CI R4,>0A00
       JHE !           ; Pulsing
       BL @HITEST
       JMP OBNXT3

!      BL @ANIM11

       JMP OBNXT3


OBNXT3 B @OBNEXT






* dead - little 6 big 6 little 6
* R4[15..8] = counter, initially 18
DEAD   MOV R4,R1
       SRL R1,8
       LI R6,>E800   ; little star
       AI R1,-8
       CI R1,6
       JHE !
       LI R6,>EC00   ; big star
!      SRL  R1,1
       ANDI R1,>0003   ; animate colors
       MOVB @DEADC(R1),@R6LB
       AI R4,->0100
       CI R4,>0100
       JHE OBNXT3
DEAD2  B @SPROFF


* pushing rock sprite, moves up or down
* R4[15..10] = countdown, initially 32
* R4[9..8] = direction  DIR_UP or DIR_DN
ROCK
       MOV R4,R0
       ANDI R0,>FC00 ; get counter
       JEQ ROCK2     ; stop if zero
       AI R4,->0400

       MOV R4,R1
       ANDI R1,DIR_XX ; get direction
       SRL R1,7     ; get direction index
       MOV @EMOVED(R1),R1

       MOV R5,R2
       S @HEROSP,R2
       CI R2,>1000
       JGT !          ; hero overlapping rock?
       CI R2,->0800
       JLT !
       S R1,@HEROSP  ; push back hero
!
       SLA R0,6      ; C = bottom counter bit
       JNC OBNXT3    ; move every other frame
       A R1,R5       ; move rock
       JMP OBNXT3
ROCK2
       CI R6,>1C06   ; red rock?
       JNE !
       LI R1,>9C9E   ; red rock
       LI R2,>9D9F
       BL @STORCH
       LI R1,>7071   ; red stairs
       LI R2,>7273
       JMP !!
!
       LI R1,>9496   ; green rock
       LI R2,>9597
       BL @STORCH
       LI R1,>7879   ; green stairs
       LI R2,>7A7B
!
       MOV @DOOR,R5
       BL @STORCH    ; draw door

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @SETBIT   ; Set bit R0 in VDP at R1

       JMP DEAD2    ; SPROFF



* test if sword is hitting enemy, and if enemy is hitting hero (LNKHIT)
* modifies R0-R3 R7 R8
HITEST
       ; currently getting knocked back or stunned?
       MOV R4,R0
       SRC R0,7   ; Get hurt/stun bit in carry flag
       JOC HSBIT

HITES0
       ; get position of sword sprite
       LI R7,-(LASTSP-SWRDSP)
HITES1
       MOV @LASTSP(R7),R3   ; Get sword pos in R3

       S   R5,R3            ; subtract sprite pos from sword pos
       ABS R3               ; absolute difference
       CI R3,>0E00          ; Y diff <= 13 ?
       JH HITES2
       SWPB R3              ; swap to compare X
       ABS R3               ; absolute difference
       CI R3,>0E00          ; X diff <= 13 ?
       JH HITES2

       CI R7,-(LASTSP-BMRGSP)
       JEQ BMRHIT           ; Boomerang hit
       CI R7,-(LASTSP-BSWDSP)
       JNE !
       LI R0,BPOPID         ; Beam Sword Pop ID
       SOC R0,@BSWDOB       ; Set sword beam to sword pop

!      MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       CLR R2
       MOVB @VDPRD,R2       ; Enemy HP in R2

       MOV @HFLAGS,R0       ;
       ANDI R0,WSWORD+MSWORD ; Get sword bits
       AI  R0,>0100         ; R0 = >100,>200,>400 based on sword power
       S   R0,R2            ; Subtract sword damage from enemy hp
       JGT HURT             ; Jump if hp is greater than zero

!

       BL @RANDOM
       ANDI R0,>0007
       JNE !

       LI R4,RUPYID         ; Rupee spawn
       JMP SPITEM

!      DEC R0
       JNE !

       LI R4,BRPYID         ; 5 Rupee spawn
       JMP SPITEM

!      DEC R0
       JNE !

       LI R4,HARTID         ; Heart spawn
       JMP SPITEM

!
       LI R4,DEADID          ; Change object type to DEAD, counter to 19
       CLR R6                ; Clear sprite and color transparent
OBNXT4
       B @OBNEXT

* Spawn item
SPITEM
       MOV R4,R6
       ANDI R6,>003F
       A R6,R6
       MOV @ECOLOR(R6),R6               ; Set color and sprite index
       BL @OBSLOT
       JMP -!

BMRHIT
       CLR R0
       MOVB R0,@BMRGOB       ; Set boomerang state to returning

       ; Set stun counter to stun duration
       LI R2,157*>100          ; Initial stun counter 157

       ORI R4,>0040     ; Set hurt/stun bit

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS+VDPWM   ; Put counter to VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Enemy stun counter in R2
       MOVB R0,*R15         ; Clear Enemy hurt counter

       JMP HITES2


HITES2 AI R7,4      ; Next object
       JNE HITES1

       MOV R4,R0
       SRC R0,7   ; Get hurt/stun bit in carry flag
       JOC OBNXT4  ; Stun bit doesn't return to object movement

       B  @LNKHIT  ; Test enemy hitting hero

HITES3 RT


HURT   ; Enemy hit by sword or beam
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Store updated HP in VDP

       ORI R4,>0040         ; Set hurt/stun bit

       MOV @LASTSP+2(R7),R2   ; Get sword sprite index in R2
       ANDI R2,>0C00        ; Mask direction bits
       SLA R2,4
       ORI R2,>2000         ; Get new direction bits and hurt counter = 32

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       JMP HURT2

HSBIT   ; Enemy is hurt or stunned
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP
       MOVB @VDPRD,R2       ; Enemy stun counter in R2
       SWPB R2              ; doesn't modify status flags
       JEQ !
       DEC R2               ; Decrement stun counter if nonzero
!      MOVB @VDPRD,R2       ; Enemy hurt counter in R2
       JEQ STBIT

       ; R2[15:14] direction of movement
       ; R2[13:8]  hurt countdown
       ; R2[7:0]   stun countdown

HURT2  AI R2,-256           ; Decrement counter
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @R2LB,*R15      ; Store updated stun counter in VDP
       MOVB R2,*R15         ; Store updated Hurt counter in VDP

       MOV R2,R3
       ANDI R3,>0600        ; Get color counter, 2 frames each
       SRL R3,9
       MOVB @HRTCOL(R3),@R6LB

       MOV R2,R0
       ANDI R0,>3F00        ; Mask counter
       JNE !
       ANDI R0,>00FF        ; Clear direction and counter
       MOV R4,R3
       ANDI R3,>003F        ; Get object index
       A R3,R3
       MOVB @ECOLOR+1(R3),@R6LB  ; Reset sprite color
       ANDI R4,>FFBF        ; Clear hit/stun bit
!      CI R0,>1000
       JL HITES3

       MOV R4,R0
       ANDI R0,>003F
       CI R0,ZORAID
       JEQ HITES3           ; Zora cannot be knocked back

       MOV R2,R3
       ANDI R3,>C000        ; Mask direction bits
       SRL R3,13            ; R3 = direction bits * 2
       LI R2,OBNEXT
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       BL @KNOCKB
       B @OBNEXT



STBIT  ; Stun counter is nonzero

       ORI R1,VDPWM     ; Set stun/HP write address in VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @R2LB,*R15  ; Save decremented counter
       JNE !   ; counter nonzero
       ANDI R4,~>0040  ; Clear stun bit
!      B @HITES0




* Enemy edge test, jump to R2 if at edge of screen
* R3 = direction 0=Down 1=Left 2=Right 3=Up
* Modifies R0,R1
TSTEDG
       MOV R5,R0
       SWPB R0
       MOV @TSTJMP(R3),R1
       B *R1
TESTLT
       CI R0,>1000          ; Check left edge of screen
       JLE !
       RT
TESTRT
       CI R0,>E000         ; Check right edge of screen
       JHE !
       RT
TESTUP
       CI R5,>1800         ; Check top edge of screen
       JLE !
       RT
TESTDN
       CI R5,>B000          ; Check bottom edge of screen
       JHE !
       RT
!      B *R2


TSTJMP DATA TESTDN,TESTLT,TESTRT,TESTUP


* R4=data R5=YYXX R6=SSEC
* Sets R6 to random facing
SPAWN
       MOV @ECOLOR(R3),R6    ; Set sprite and color
       MOV R11,R10          ; Save return address
SPAWN2 BL @RANDOM           ; Get a random screen location
       ANDI R0,>70F0
       AI R0,>2800
       MOV R0,R2
       ANDI R2,>00F0
       CI R2,>0010     ; Don't spawn too far left
       JLE SPAWN2
       CI R2,>00E0     ; or right
       JHE SPAWN2

       MOV R0,R5       ; Don't spawn on solid ground
       LI R2,SPAWN2
       AI R0,>0800
       BL @TESTCH
       MOV R5,R0
       AI R0,>0808
       BL @TESTCH

       C @DOOR,R5      ; Don't spawn on a door
       JEQ SPAWN2

       MOV R5,R0       ; Don't spawn too close to the hero
       S @HEROSP,R0
       ABS R0
       CI R0,>2000
       JHE !
       SWPB R0
       ABS R0
       CI R0,>2000
       JLT SPAWN2
!
       BL @RANDOM
       ANDI R0,>1800  ; Face random direction
       XOR R0,R6

       MOV R0,R1
       SRL R1,10      ; Make sure direction is clear
       MOV @EMOVEA(R1),R0  ; Check for walls
       A R5,R0
       BL @TESTCH
       CLR R1

       B *R10


* Animation functions, toggle sprite every 5, 6 or 11 frames
* Modifies R0,R1,R2
ANIM5
       MOV @COUNTR,R0
       ANDI R0,>00E0
       SLA R0,3             ; get 3-bit 5 counter
       LI R2,>0500
       JMP !
ANIM6
       MOV @COUNTR,R0
       SRL R0,4             ; get uppper nibble 6 counter
       LI R2,>0600
       JMP !
ANIM11
       MOV @COUNTR,R0
       LI R2,>0B00
!      ANDI R0,>0F00        ; get lower nibble 11 counter
       MOV @OBJPTR,R1
       SWPB R1
!      C R1,R2
       JLE !
       S R2,R1
       JMP -!
!      C R1,R0
       JNE !
       LI R1,>0400
       XOR R1,R6     ; Toggle animation every 5, 6 or 11 frames
!      RT




* Armos AI
* R4:  6 bits animation counter
*      1 bit 0=slow 1=fast
*      2 bits direction
*      1 bits hurt/stun flag
*      6 bits object id
ARMOS
       LI R0,>0400    ; minimum counter
       C R4,R0
       JL ARMOS2
       LI R1,15       ; white
       XOR R1,R6      ; toggle color between transparent

       S R0,R4        ; decrement counter
       C R4,R0
       JHE ARMOS3     ; until zero


       ; Draw armos underneath
       C @DOOR,R5
       JNE !
       ; TODO bracelet
       ;LI R1,>7879    ; Green stairs
       ;LI R2,>7A7B    ; Green stairs
       LI R1,>7071    ; Red stairs
       LI R2,>7273    ; Red stairs

       JMP !!!
!
       ; ground, either yellow or gray
       LI R0,CLRTAB+27  ; Get palette entry for Armos chars
       BL @VDPRB
       CI R1,>4E00      ; black on gray
       JNE !
       LI R1,>0808      ; gray background
       MOV R1,R2
       JMP !!
!
       CLR R1           ; yellow background
       CLR R2
!
       BL @STORCH



       ; store armos HP
       MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP+VDPWM   ; Use HP array in VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       LI R0,>0300       ; Armos has 3 HP
       MOVB R0,*R15      ; Store HP

       BL @RANDOM
       ANDI R0,>0380  ; get only 3 bits
       SOC R0,R4

       MOV @ECOLOR+>2E,R6  ; change to light blue from white

ARMOS2
       BL @ANIM6     ; Animate - R0 contains counter

       BL @HITEST

       ANDI R6,>67FF  ; use down-facing sprite
       MOV R4,R0
       ANDI R0,>0180  ; get direction bits
       CI R0,>0180    ; up?
       JNE !
       ORI R6,>0800   ; use up-facing sprite
!


       MOV @COUNTR,R0
       SLA R0,8
       JOC !
       BL @LEMOVE    ; move 1
ARMOS3
       B @OBNEXT
!
       MOV R4,R0
       SLA R0,7      ; C = fast/slow bit
       JNC ARMOS3
       ; move twice
       LI R10,LEMOVE  ; LEMOVE2 will return to LEMOVE, which returns to OBNEXT
       B @LEMOV2


* Cave item
* bits[15..12] counter
* bits[11..6] item number, 6 bits
* bits[5..0] object id
* item number:
*   0 fire
*   1 npc
*
* counter:
*   16..13 poof
*   12..7 dissolve 1
*   6..1 dissolve 2
*   0 item appearing
CAVNPC
       MOV R4,R0
       SRL R0,12
       JNE !
       BL @RUPEEB  ; Rupee blink
       JMP CAVNP2

!      AI R4,->1000

       CI R0,13
       JNE !
       LI R6,CLOUD1   ; poof, white
!
       CI R0,12
       JNE !
       AI R6,>0400   ; dissolve 1
!
       CI R0,6
       JNE !
       AI R6,>0400   ; dissolve 2
!
       DEC R0
       JNE CAVNP2

       CI R5,>5878    ; NPC position? otherwise flame
       JEQ !

       LI R6,>F008    ; Fire sprite
       LI R1,>2020    ; Fire background chars
       LI R2,>5E5F    ; Fire background chars
       BL @STORCH     ; Store characters R1,R2 at R5 in name table
CAVNP2 B @OBNEXT

!      ; Load NPC, text and items

       MOVB @CAVTYP,R3
       SRL R3,8          ; R3 = cave type
       MOV R3,R10        ; R10 = item index

       DEC R3
       A R3,R3

       MOV R5,R7      ; Save NPC pos
       MOV @CAVDAT(R3),R9 ; Get NPC type and text offset

       MOV R9,R2
       SRL R2,11
       AI R2,NPCSPR
       MOV *R2+,R8       ; Get primary sprite
       MOV *R2+,R6       ; Get secondary sprite
       BL @OBSLOT        ; Spawn secondary sprite
       MOV *R2+,R1       ; Get background chars
       MOV *R2+,R2       ; Get background chars
       BL @STORCH        ; Draw background characters

       ; TODO case >10, letter must be shown to old woman


       LI R4,TEXTID   ; Cave message texter
       LI R5,>D200    ; Counter
       MOV R9,R6
       ANDI R6,>03FF
       AI R6,CAVTXT   ; Cave text in VDP RAM
       BL @OBSLOT

       ; load items
       LI R3,CAVTBL   ; Table of item groups
!      MOV *R3+,R6
       MOV R6,R9
       SLA R9,7      ; Get group bit in carry
       JNC -!
       DEC R10        ; Decrement item index until zero
       JNE -!

       LI R2,CAVLOC   ; Spawn cave items
!      CLR R4
       MOV *R2+,R5    ; Sprite location
       JEQ !
       ANDI R6,>FC0F  ; Get sprite
       LI R4,ITEMID   ; Object ID
       BL @OBSLOT     ; Note: returns object offset in R1

       MOV R1,R0
       SRL R0,2       ; Convert double-word offset to byte offset
       AI R0,ENEMHP   ; R0 = Object HP address

       SRL R9,11      ; Get item price index
       MOVB @IPRICE(R9),R1 ; R1 = item price
       BL @VDPWB      ; Store item price in object HP

       MOVB R1,R4
       JEQ !          ; Don't draw if zero

       ; Convert pixel coordinate YYYYYYYY XXXXXXXX R5
       ; to character coordinate        YY YYYXXXXX R0
       ANDI R5,>F8F8
       MOV R5,R0
       SRL R0,3
       MOVB R0,R5
       SRL R5,3
       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       A R5,R0

       AI R0,VDPWM+(3*32)-1  ; Adjust position to 3 lines down and 1 left
       BL @NUMBRJ     ; Display item price R1 right-justified at R0

!      MOV *R3+,R6
       MOV R6,R9
       SLA R9,7      ; Get group bit in carry
       JNC -!!

       MOVB R4,R4
       JEQ !         ; Draw rupee and X
       LI R4,CAVEID
       LI R5,>8430  ; Rupee loc
       LI R6,>C00A   ; Rupee sprite
       BL @OBSLOT

       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       AI R0,32*17+8
       LI R1,'X'*256
       BL @VDPWB

!
       LI R4,CAVEID   ; Restore object id
       MOV R7,R5      ; Restore position
       MOV R8,R6      ; Restore sprite

       JMP CAVNP2


* Enemy hurt colors: 2 frames each
HRTCOL BYTE >0C,>01,>08,>04  ; green black orange blue

*DEADC  BYTE >08,>06,>0F,>0E  ; dark red, red, cyan, white
DEADC  BYTE >09,>06,>0F,>07  ; red, dark red, red, white, cyan


* Facing     Right Left  Down  Up
EMOVED DATA >0001,>FFFF,>0100,>FF00     ; Direction data
EMOVEM DATA >FFF8,>FFF8,>F8FF,>F8FF     ; Mask alignment to 8 pixels (inverted for SZC)
EMOVEA DATA >0010,>FFFF,>1000,>FF00     ; Test char offset 1
EMOVEB DATA >0F10,>0EFF,>100F,>FF0F     ; Test char offset 2
EMOVEC DATA >FF00,>FF00,>00FF,>00FF     ; Screen edge mask (inverted for SZC)
EMOVEE DATA >00E0,>0010,>A800,>2800     ; Screen edge value


* Get random number in R0 (modifies R1)
* RAND16 must be seeded with nonzero, Period is 65535
RANDOM MOV @RAND16,R0    ; Get initial seed
       MOV R0,R1
       A   R1,R1
       XOR R1,R0         ; R0 ^= R0 << 1
       MOV R0,R1
       SRL R1,7
       XOR R1,R0         ; R0 ^= R0 >> 7
       MOV R0,R1
       SLA R1,4
       XOR R1,R0         ; R0 ^= R0 << 4
       MOV R0,@RAND16    ; Save new seed
       RT
