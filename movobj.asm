* moving objects/sprites handling  (bank 5)

* TODO remove references to ECOLOR (use VDP save area for spr idx + color)

IDLEID EQU >0040 ; Idle object, jumps to OBNEXT but nonzero so it can't be reused
BSWDID EQU >0005 ; Beam Sword ID
MAGCID EQU >0006 ; Magic ID
BPOPID EQU >0040 ; Beam Sword/Magic Pop ID (SOC on BSWDID or MAGCID)
BSPLID EQU >0807 ; Beam Sword Splash ID with initial counter
BOMBID EQU >4C08 ; Bomb ID with initial counter
BMRGID EQU >0009 ; Boomerang ID
ARRWID EQU >000A ; Arrow ID
SPRKID EQU >00CB ; Spark ID with initial counter=3
SPOFID EQU >000B ; Sprite off (Spark ID with initial counter=0)
FLAMID EQU >5D0C ; Flame ID with initial counter
BMFMID EQU >BF0C ; Book of Magic Flame ID with initial counter
ROCKID EQU >800D ; Rock ID and initial counter
ARMOID EQU >FC0E ; Armos ID and initial counter
DEADID EQU >120F ; Dead Enemy Pop ID w/ counter=18
LAKEID EQU >0010 ; Lake ID and initial counter
TORNID EQU >0011 ; Tornado ID
ITEMID EQU >0012 ; Normal item ID
CITMID EQU >0013 ; Collectable item ID (sets bit so it can't be collected again)
STRSID EQU >0014 ; Stairs spawner

; FIXME below are not updated yet
SOFFID EQU >0118 ; turn off sprite immediately
RUPYID EQU >5000 ; Rupee ID with initial counter
BRPYID EQU >5000 ; Blue Rupee ID with initial counter
HARTID EQU >5000 ; Heart ID with initial counter
FARYID EQU >5023 ; Fairy ID with initial counter
ZORAID EQU >0010 ; Zora ID
ZBULID EQU >8011 ; Zora bullet ID with initial counter
CAVEID EQU >001F ; Cave NPC ID
TEXTID EQU >0024 ; Cave Message Texter ID
BULLID EQU >001C ; Octorok bullet ID
FRY2ID EQU >0029 ; Fairy at pond ID
HRT2ID EQU >0013 ; Heart that spins around fairy ID
GHINID EQU >000C ; Ghini ID
FLICID EQU >0028 ; Flicker ID

;   function called with data in registers:
;   R4   data from object array (function idx, counter, etc)
;   R5   YYXX word sprite location (Y is adjusted down 1 line)
;   R6   SI.C sprite index, early clock bit, and color

;   (direction could be encoded in sprite index if done carefully, or sprite function index)
; TODO 6 bits in R6 are not used:
;  lowest 2 bits of sprite index are ignored in 16x16 sprite mode
;  4 bits between sprite index and early clock bit are not used


* Object function pointer table, functions called with data in R4,
* sprite YYXX in R5, idx color in R6, must return by B @OBNEXT
OBJTAB DATA ESLOT1,ESLOT2,ESLOT3   ; 1-3
       DATA ESLOT4,BSWORD,MAGIC,BSPLSH    ; 4-7
       DATA BOMB,BMRNG,ARROW,ASPARK    ; 8-B
       DATA FLAME,ROCK,ARMOS,DEAD  ; C-F

       DATA LAKE,TORNAD,ITEM,CITEM  ; 10-13
       DATA STAIRS,BAD,BAD,BAD    ; 14-17
       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD

       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD

       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD
       DATA BAD,BAD,BAD,BAD

       ;,PEAHAT,TKTITE,TKTITE  ; 0-3 - - Red Blue
       ;DATA OCTORK,OCTORK,OCTRKF,OCTRKF  ; 4-7 Red Blue Red Blue
       ;DATA MOBLIN,MOBLIN,LYNEL, LYNEL   ; 8-B Red Blue Red Blue
       ;DATA GHINI, BOULDR,LEEVER,LEEVER  ; C-F - - Red Blue
       ;DATA ZORA, ZORABL, FLAME, HEART2  ; 10-13
       ;DATA BSWORD,MAGIC,BSPLSH,ARMOS    ; 14-17
       ;DATA DEAD, BOMB, BMRNG, CAVITM    ; 18-1B
       ;DATA BULLET,ARROW,ASPARK,CAVNPC   ; 1C-1F
       ;DATA RUPEE, BRUPEE,HEART,AFAIRY   ; 20-23
       ;DATA TEXTER,ROCK,LAKE,TORNAD      ; 24-27
       ;DATA FLICKR,FAIRY,CLOUD,STALFO ; 28-2B
       ; 2C-2F
       ; 30-33
       ; 34-37
       ; 38-3B
       ; 3C-3F

BAD
       DATA 0

* Enemy group selected ENEGRP - 4 enemy functions per group
GROUP1 DATA OBNEXT,OBNEXT,OBNEXT,OBNEXT ;
GROUP2

MOVOBJ ; do moving objects
       LI R1,7*2         ; Process sprites starting with flying sword (7)
       JMP !
OBNEXT
       MOV @OBJPTR,R1       ; Get sprite index
       MOV R4,@OBJECT(R1)   ; Save data
       A R1,R1
       MOV R5,@SPRLST(R1)   ; Save sprite pos
       MOV R6,@SPRLST+2(R1) ; Save sprite id & color
       SRL R1,1
OBLOOP INCT R1             ; Next index
       CI R1,64            ; Stop after last sprite
       JNE !

       LI R13,x#MOVOBX      ; Fixed return address
       JMP BANK0            ; Return to bank 0 saved address R13

!      MOV R1,@OBJPTR      ; Save pointer
       MOV @OBJECT(R1),R4  ; Get func index and data

       MOV R4,R3
       ANDI R3,OBJMSK ; Get sprite function index
       JEQ OBLOOP    ; skip OBNEXT dispatch

       A R1,R1
       MOV @SPRLST(R1),R5  ; Get sprite location
       MOV @SPRLST+2(R1),R6  ; Get sprite color

       A R3,R3
       MOV @OBJTAB-2(R3),R9  ; Table index is 1-based
       B *R9       ; Jump to sprite function



ESLOT1
       MOV @ENEGRP,R3  ; Get group table
       MOV *R3,R9      ; Get first entry
       B *R9     ; Jump to sprite function
ESLOT2
       MOV @ENEGRP,R3  ; Get group table
       MOV @2(R3),R9   ; Get second entry
       B *R9     ; Jump to sprite function
ESLOT3
       MOV @ENEGRP,R3  ; Get group table
       MOV @4(R3),R9   ; Get third entry
       B *R9     ; Jump to sprite function
ESLOT4
       MOV @ENEGRP,R3  ; Get group table
       MOV @6(R3),R9   ; Get fourth entry
       B *R9     ; Jump to sprite function




BSWJMP DATA BSWDRT,BSWDLT,BSWDDN,BSWDUP
BSWRDD DATA >0003,>FFFD,>0300,>FD00     ; Beam sword direction (move by 3)
BSWRDC BYTE >07,>0F,>06,>09             ; Beam sword colors: cyan, white, dark red, light red
BSPLSD DATA >FEFF,>FF01,>00FF,>0101     ; Beam splash direction data NW,NE,SW,SE
REVMSK ; Reverse direction mask, same as DATA >0002
MAGICD DATA >0002,>FFFE,>0200,>FE00     ; Magic beam direction (move by 2)
MAGICC BYTE >07,>04,>06,>01             ; Magic colors: cyan, dark blue, dark red, black

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
       JHE BSWNXT
DEAD2  JMP SPROFF

BOUNDS
       SWPB R5
       CI R5,>1000          ; Check left edge of screen
       JL SPROFF
       CI R5,>E000         ; Check right edge of screen
       JH SPROFF
       SWPB R5
       CI R5,>2800         ; Check top edge of screen
       JL SPROFF
       CI R5,>A000          ; Check bottom edge of screen
       JH SPROFF
       RT

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
       CI R5,>1800         ; Check top edge of screen
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
       ANDI R1,OBJMSK       ; Get object idx
       CI R1,MAGCID
       JNE !
       MOV @HFLAG2,R0
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
       BL @!OBSLOT
       LI R4,BSPLID+>40    ; Create splash NE
       LI R6,>840F         ; Sprite
       BL @!OBSLOT
       LI R4,BSPLID+>80    ; Create splash SW
       LI R6,>880F         ; Sprite
       BL @!OBSLOT
       LI R4,BSPLID+>C0    ; Create splash SE
       LI R6,>8C0F         ; Sprite
       BL @!OBSLOT
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



ASPARK ; Arrow spark
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





FLAMXY DATA >00F0,>0000,>B800,>1800

FLMDOR LI R2,FLMDO2  ; Flame overlapped secret door location
       MOV @DOOR,R5
       MOV R5,R0
       BL @!TESTCH    ; Get character under secret door location
FLMDO2 CI R1,>9000  ; Green bush
       JNE !
       LI R1,>7879  ; Green stairs
       LI R2,>7A7B
       JMP !!
!      CI R1,>9800  ; Red bush
       JNE FLAME0
       LI R1,>7071  ; Red stairs
       LI R2,>7273
!      BL @!STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @!SETBIT   ; Set bit R0 in VDP at R1

       LI R0,x#TSF191   ; Secret sound effect
       MOV R0,@SOUND2

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

       BL @BANK2X          ; map.asm
       DATA x#LITCDL       ; Light up via candle (Modifies R0..R10,R12,R13)

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

       LI R0,x#TSF62   ; Bomb explode sound effect
       MOV R0,@SOUND3
       LI R0,x#TSF63
       MOV R0,@SOUND4

       LI R6,CLOUD1   ; cloud 1, white

       MOV R5,R7

       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JNE DUNBOM

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
       BL @!OBSLOT
       AI R4,->80     ; Lower left poof - toggles by 16
       AI R5,(16*256)+8
       BL @!OBSLOT
       AI R4,>40      ; Upper right poof - toggles by 16
       AI R5,(-32*256)+16
       BL @!OBSLOT
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
       BL @!TESTCH    ; Get character under secret door location
BOMDO2 CI R1,>8000  ; Green brick
       JEQ !
       CI R1,>A000  ; Red brick
       JNE !!
!      LI R1,>7F7F
       LI R2,>2020
       BL @!STORCH   ; Draw doorway

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @!SETBIT   ; Set bit R0 in VDP at R1

       LI R0,x#TSF191   ; Secret
       MOV R0,@SOUND2

!      MOV R7,R5
       JMP BOMB0

DUNBOM
       BL @BANK2X     ; map.asm
       DATA x#DNBOMB  ; dungeon bomb make hole in wall?

       JMP BOMB0


* Peahat animation loop: 2 2 1 2 1  (01011011)
* And moves by 1 only when animation changes
* Peahat Direction data
PEAHAD DATA >0001,>0101,>0100,>00FF  ; 0 Right, 1 downright, 2 down, 3 downleft
       DATA >FFFF,>FEFF,>FF00,>FF01  ; 4 Left,  5 upleft,    6 up,   7 upright
PEAHAA DATA >DAAA,>AAAA,>AA4A,>4A4A,>4911,>1111,>1080,>8080 ; animation
GHINSP BYTE >24,>24,>20,>20,>20,>28,>2C,>2C





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


!
       MOV @COUNTR,R0
       ANDI R0,>3000
       JNE BMRNXT     ; Animate every 6th frame

       MOV R6,R1
       SRL R1,10
       ANDI R1,3
       MOVB @BMRNGS(R1),R6

       SRL R1,2
       JOC BMRNXT

       LI R0,x#TSF52     ; Boomerang sound effect
       MOV R0,@SOUND3
       LI R0,x#TSF53     ; Boomerang sound effect
       MOV R0,@SOUND4

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
       LI R4,(BMRGID&OBJMSK)+>0600  ; spark for 3 frames
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


* Compare YYXX in R3 and R5 for overlap, jump to R2 if collision
* Modifies R3
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
       MOVB @HURTC,R0     ; Can't get hurt again if still flashing
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
       ANDI R1,OBJMSK    ; Get enemy type

       ; TODO Enemy reverse direction, or bullet disappear
       CI R1,BULLID
       JEQ LNKHI4

       CI R1,ARRWID
       JEQ LNKHI4

       CI R1,ZBULID&OBJMSK
       JEQ !
       CI R1,BSWDID
       JNE LNKHI5
!
       MOV @HFLAGS,R3
       ANDI R3,MAGSHD      ; Beam sword and zora bullet can only be blocked with magic shield
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

       CI R1,ZBULID&OBJMSK
       JEQ ZBHIT      ; zora bullet hit?

       SRL R3,7
       XOR @REVMSK,R3
       C R2,R3   ; check reverse direction
       JNE ARRHIT

       ; successful block
       MOV @BOUNCD(R2),R4  ; change to beam splash id
LNKBLK
       LI R0,x#TSF240    ; Tink sound
       MOV R0,@SOUND1

       RT                 ; return with no damage

BOUNCD DATA BSPLID,BSPLID+>40,BSPLID+>40,BSPLID+>80  ; Reflected bounce NW,NE,NE,SW

ARRHIT ; Arrow disappear (same as SPROFF)
       CLR R4
       LI R5,>D200
LNKHI5

       AI R0,48*>0400      ; add 48<<10 frames hurt counter
       MOVB R0,@HURTC

       LI R0,x#TSF302    ; Link hurt sound
       MOV R0,@SOUND3
       LI R0,x#TSF303    ; Link hurt sound
       MOV R0,@SOUND4

       ;FIXME SB @EDAMAG(R1),@HP  ; Subtract enemy attack damage
       LI R0,1 ;FIXME
       SB R0,@HP ;FIXME
       JGT !

       CLR R1         ; Set HP to zero in case of underflow
       MOVB R1,@HP
       ; fall thru (zero hp is in bank0)
!      B @STATUS

ZBHIT  ; zora bullet, check for block
       LI R5,>D200

       SWPB R3
       CLR R2
       MOVB @ZBHITA(R3),R2
       JLT !
       ; test sign bit = 0
       CZC R2,R4
       JNE ARRHIT
       CLR R4
       JMP LNKBLK
!      ; test sign bit = 1
       CZC R2,R4
       JEQ ARRHIT
       CLR R4
       JMP LNKBLK
ZBHITA BYTE >82,>02,>84,>04      ; rt lt dn up


OBNXT3 B @OBNEXT      ; TODO put this somewhere else

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

       CI R2,->0100    ; hero pushing from the side
       JLT !
       CI R2,>0100    ; hero pushing from the side
       JGT !
       CI R2,->0010
       JLT !!
       CI R2,>0010
       JGT !!
!
       CI R2,>1000
       JGT !          ; hero overlapping rock?
       CI R2,->0800
       JLT !
       S R1,@HEROSP  ; push back hero
       S R1,@HEROSP+4  ; push back hero
!
       SLA R0,6      ; C = bottom counter bit
       JNC OBNXT3    ; move every other frame
       A R1,R5       ; move rock
       JMP OBNXT3
ROCK2
       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !
       ; dungeon block
       LI R1,>8486
       LI R2,>8587
       BL @!STORCH    ; draw block
       BL @BANK2X     ; map.asm
       DATA x#DUNBLK

       JMP ROCKFX     ; Secret & SPROFF

!      ; overworld rock
       CI R6,>1C06   ; red rock?
       JNE !
       LI R1,>9C9E   ; red rock
       LI R2,>9D9F
       BL @!STORCH
       LI R1,>7071   ; red stairs
       LI R2,>7273
       JMP !!!
!      LI R1,>9496   ; green rock
       LI R2,>9597
       CI R6,>1C01   ; gravestone?
       JNE !
       LI R1,>F4F6   ; grave
       LI R2,>F5F7
!
       BL @!STORCH
       LI R1,>7879   ; green stairs
       LI R2,>7A7B
!
       MOV @DOOR,R5
       BL @!STORCH    ; draw door

       CI R6,>1C01   ; gravestone?  don't store cave bit
       JEQ ROCKFX

       MOVB @MAPLOC,R0
       SRL R0,8
       LI R1,SDCAVE ; Save data - opened secret caves
       BL @-!SETBIT   ; Set bit R0 in VDP at R1
ROCKFX
       LI R0,x#TSF191   ; Secret
       MOV R0,@SOUND2

       B @SPROFF


BMRHIT
       LI R0,TSF70         ; Bump sound
       MOV R0,@SOUND1

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

HITES2 AI R7,4      ; Next object
       JNE HITES1

       MOV R4,R0
       SRC R0,7   ; Get hurt/stun bit in carry flag
       JNC !  ; Stun bit doesn't return to object movement
       B  @OBNEXT
!
       B  @LNKHIT  ; Test enemy hitting hero

* test if sword is hitting enemy, and if enemy is hitting hero (LNKHIT)
* this is kinda spaghetti gotos
* modifies R0-R3 R7 R8
HITEST
       ; currently getting knocked back or stunned?
       MOV R4,R0
       SRC R0,7   ; Get hurt/stun bit in carry flag
       JNC HITES0
       JMP HSBIT

STBIT  ; Stun counter is nonzero

       ORI R1,VDPWM     ; Set stun/HP write address in VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @R2LB,*R15  ; Save decremented counter
       JNE !   ; counter nonzero
       ANDI R4,~>0040  ; Clear stun bit
!

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
       JNE SUBHP
       LI R0,BPOPID         ; Beam Sword Pop ID
       SOC R0,@BSWDOB       ; Set sword beam to sword pop

SUBHP  ; subtract damage from enemy HP
       MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       CLR R2
       MOVB @VDPRD,R2       ; Enemy HP in R2

       ; TODO adjust damamge based on weapon
       MOV @HFLAGS,R0       ;
       ANDI R0,WSWORD+MSWORD ; Get sword bits
       AI  R0,>0100         ; R0 = >100,>200,>400 based on sword power
       S   R0,R2            ; Subtract sword damage from enemy hp
       JEQ ENEHP0           ; enemy HP is zero
       JLT ENEHP0           ; or negative

HURT   ; Enemy hit by sword or beam
       ORI R1,VDPWM
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB R2,*R15         ; Store updated HP in VDP

       AI R1,ENEMSC-ENEMHP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOVB @R6LB,*R15     ; Store sprite color in VDP

       LI R0,TSF70         ; Bump sound
       MOV R0,@SOUND1

       ORI R4,>0040         ; Set hurt/stun bit

       MOV @LASTSP+2(R7),R2   ; Get sword sprite index in R2
       ANDI R2,>0C00        ; Mask direction bits
       SLA R2,4
       ORI R2,>2000         ; Get new direction bits and hurt counter = 32

       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       JMP HURT2

* Modifies R1,R2 R0,R3(if hurt)
HSBIT   ; Enemy is hurt or stunned
       MOV @OBJPTR,R1       ; Get object idx
       AI R1,ENEMHS         ; Get counters from VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP                  ; Delay required for read
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
       SB R0,R0   ;ANDI R0,>00FF        ; Clear direction and counter

       AI R1,(ENEMSC*2)-ENEMHS-VDPWM
       SRL R1,1
       MOVB @R1LB,*R14
       MOVB R1,*R14
       NOP                  ; Delay required for read
       MOVB @VDPRD,@R6LB    ; Restore sprite color from VDP

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

HITES3 RT

ENEHP0 ; enemy HP is zero

       LI R0,TSF111         ; Enemy poof sound
       MOV R0,@SOUND2

       ; TODO get enemy drop table

       BL @!RANDOM
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
* Spawn item
SPITEM
       MOV R4,R6
       ANDI R6,>003F
       A R6,R6
       ;MOV @ECOLOR(R6),R6               ; Set color and sprite index
       BL @!OBSLOT

!

       ; TODO get enemy type and decrement enemy screen count

       ; decrement enemy counter
       LI R2,>1000    ; add 1 to nibble
       MOVB @MAPLOC,R0
       SRL R0,9
       JNC !
       SRL R2,4       ; R2=>0100
!
       AI R0,SDENEM         ; use overworld enemy counts
       MOV @FLAGS,R1
       ANDI R1,DUNLVL
       JEQ !
       AI R0,DNENEM-SDENEM   ; use dungeon enemy counts
!
       BL @VDPRB
       S R2,R1
       BL @VDPWB

       LI R4,DEADID          ; Change object type to DEAD, counter to 19
       CLR R6                ; Clear sprite and color transparent

       B @OBNEXT



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
       ;MOV @ECOLOR(R3),R6    ; Set sprite and color
       MOV R11,R10          ; Save return address
SPAWN2 BL @!RANDOM           ; Get a random screen location
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
       BL @!TESTCH
       MOV R5,R0
       AI R0,>0808
       BL @!TESTCH

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
       BL @!RANDOM
       ANDI R0,>1800  ; Face random direction
       XOR R0,R6

       MOV R0,R1
       SRL R1,10      ; Make sure direction is clear
       MOV @EMOVEA(R1),R0  ; Check for walls
       A R5,R0
       BL @!TESTCH
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

       LI R0,TSF191   ; Secret sound effect
       MOV R0,@SOUND2

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
       LI R1,>1414           ; yellow background
       MOV R1,R2
!
       BL @!STORCH



       ; store armos HP
       MOV @OBJPTR,R1       ; Get object idx
       SRL R1,1
       AI R1,ENEMHP+VDPWM   ; Use HP array in VDP
       MOVB @R1LB,*R14
       MOVB R1,*R14
       LI R0,>0300       ; Armos has 3 HP
       MOVB R0,*R15      ; Store HP

       BL @!RANDOM
       ANDI R0,>0380  ; get only 3 bits
       SOC R0,R4

       AI R6,9-15  ; change to bright red from white

ARMOS2
       BL @ANIM6     ; Animate - R0 contains counter

       BL @HITEST

       ANDI R6,>F7FF  ; use down-facing sprite
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
       JMP LEMOV2


* Enemy movement (octorok, moblin, lynels)
* Modifies R0-R3,R10
EMOVE
       LI R10,OBNEXT    ; Return to R10
       MOV R5,R0
       AI R0,>0800
       ANDI R0,>0F0F    ; Aligned to 16 pixels?
       JNE EMOVE3       ; No? Keep moving

       BL @!RANDOM
       MOV R0,R1
       ANDI R0,7        ; 1 in 8 chance to change direction
       JNE EMOVE3

       ; TODO shoot projectile
       ANDI R1,>0003
       JNE EMOVE2       ; 1 in 4 chance to shoot

       AI R4,49*>100    ; set counter for projectile launch

EMOVE2 BL @!RANDOM       ; Change direction
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
       BL @!TESTCH
       MOV @EMOVEB(R3),R0
       A R5,R0
       BL @!TESTCH

EMOVE5 A @EMOVED(R3),R5     ; Perform movement
       B *R10               ; Jump to saved return address

* Leever random direction
LERAND
       BL @!RANDOM
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

       BL @!RANDOM
       ANDI R0,7        ; 1 in 8 chance to change direction
       JEQ LERAND

       JMP EMOVE4


* Knockback, until hitting wall or edge of screen
* R3 = direction 0=Down 2=Left 4=Right 6=Up
* Modifies R0-R2
KNOCKB
       MOV R11,R10           ; Save return address in R10
       JMP EMOVE4




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


* Changing lake colors every 8 frames
LAKE   MOV R4,R1
       ANDI R1,>01C0
       JNE !
       MOV R4,R1
       SRL R1,9
       MOVB @LAKEC(R1),R1
       LI R0,CLRTAB+28   ; water palette
       BL @VDPWB
       MOVB R1,*R15
       CI R4,LAKEID+>1200
       JEQ !!
!
       AI R4,>0040
       JMP TORNXT   ; goto OBNEXT
!
       ; draw dry pond
       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       AI R0,SCR1TB+(9*32)+10+VDPWM
       LI R7,LAKECH
       LI R2,8
!      MOVB *R7+,R1
       BL @VDPWB
       LI R3,10
!      MOVB *R7,*R15
       DEC R3
       JNE -!
       INC R7
       MOVB *R7+,*R15

       AI R0,32
       DEC R2
       JNE -!!

       ; draw red stairs
       LI R5,>6860
       LI R1,>7071   ; red stairs
       LI R2,>7273
       BL @!STORCH   ; Draw doorway

       LI R0,x#TSF191   ; Secret sound effect
       MOV R0,@SOUND2

       B @SPROFF

       ; flute-lake animation colors for color table
LAKEC  BYTE >4B,>5B,>7B,>EB,>DB,>6B,>8B,>9B,>AB,>4B
       ; chars to replace lake chars after animation (left, mid, right)
LAKECH BYTE >68,>69,>6D
       BYTE >6A,>16,>6E
       BYTE >6A,>16,>6E
       BYTE >6A,>17,>6E
       BYTE >6A,>16,>6E
       BYTE >6A,>17,>6E
       BYTE >6A,>17,>6E
       BYTE >6B,>6C,>6F


TORNAD ; tornado
       CI R4,>0C00+TORNID
       JH TORNA1
       AI R4,>0100

       CI R4,>0200+TORNID
       JNE !
       LI R6,CLOUD2
!      CI R4,>0700+TORNID
       JNE !
       LI R6,CLOUD3
!      CI R4,>0C00+TORNID
       JNE !
       LI R6,>F804  ; tornado sprite
!
TORNXT
       B @OBNEXT
TORNA1 INCT R5
       MOV R5,R0
       SB R0,R0   ;ANDI R0,>00FF
       CI R0,>00F0
       JNE -!
       B @SPROFF

; A cave or dungeon item
; Set a data bit that prevents getting the item again
ITEM


CITEM ; collectible item
       MOV @HEROSP,R3   ; Sprite off if collision with hero
       LI R2,GETITM
       BL @COLIDE
       B @OBNEXT
GETITM ; collect item
       BL @SETITM

       MOV R4,R1
       SRL R1,7   ; assumes bit 7 is also 0
       MOV @ITFUNC(R1),R1
       B *R1      ; run get item func

SETHF2 ; set hero flag2
       SOC R0,@HFLAG2

       ; TODO hold certain items above hero for a moment
       ; TODO getting ti-force will exit dungeon
!
       B @SPROFF

ITFUNC ; item functions
       DATA SPROFF,GETCMP,GETMAP,GETTIF    ; nothing, compass, map, tiforce
       DATA GETKEY,GETBOM,GET_HC,GETHRT    ; key, bombs, heart container, heart
       DATA GETRUP,GETBRP                  ; rupee, blue rupee

GETCMP ; get compass
       LI R0,COMPAS
       JMP SETHF2
GETMAP ; get minimap
       LI R0,MINMAP
       SOC R0,@HFLAG2

       BL @BANK2X
       DATA x#MM_GET

       JMP -!
GETTIF ; get tiforce
       B @SPROFF
GETKEY ; get key
       B @SPROFF
GETBOM ; get 4 bombs
       B @SPROFF
GET_HC ; get heart container
       B @SPROFF
GETHRT ; get heart
       B @SPROFF
GETRUP ; get rupee
       B @SPROFF
GETBRP ; get blue rupee (5)
       B @SPROFF


;* When enemy count hits zero, check for dungeon secrets in bank 2
;EZERO
;       BL @BANK2X
;       DATA x#DNITEM
;       RT



STAIRS  ; dungeon stairs appearing
       MOV R5,@DOOR
       LI R1,>7475    ; stairs upper
       LI R2,>7677    ; stairs lower
       BL @!STORCH
       B @SPROFF




* Get random number in R0 (modifies R1)
* RAND16 must be seeded with nonzero, Period is 65535
!RANDOM
       MOV @RAND16,R0    ; Get initial seed
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









* Store characters R1,R2 at R5 in name table
* Modifies R0,R1,R3
!STORCH
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
!OBSLOT
       LI R1,MOVEOB      ; Start at slot 13
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

* Look at character at pixel coordinate in R0, and jump to R2 if solid (character is in R1)
* Modifies R0,R1
!TESTCH
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


* Set cave item bit for current location
* Modifies R0-R2
SETITM
       LI R1,SDITEM ; Save data - cave items collected
       MOV @FLAGS,R0
       ANDI R0,DUNLVL
       JEQ !
       LI R1,SDDUNG ; Save data - dungeon items collected
!      MOVB @MAPLOC,R0
       SRL R0,8
       ; fall thru (and return from there)

* Set bit R0 in VDP at address R1
* Modifies R0-R2
!SETBIT MOV R0,R2
       SRL R2,3
       A R2,R1    ; R1 += (bit >> 3)
       LI R2,>8000
       ANDI R0,7
       JEQ !
       SRL R2,R0  ; R3 = 0x80 >> (bit & 7)
!
       MOVB @R1LB,*R14
       MOVB R1,*R14
       MOV R1,R0   ; Save address for VDPWB
       MOVB @VDPRD,R1
       SOC R2,R1   ; R1 |= R3
       B @VDPWB


