%%%%%%%%%%%%%%%%%%%%%%%
% The Legend of Tilda %
%%%%%%%%%%%%%%%%%%%%%%%

An action adventure for the TI 99/4A

Written in TMS9900 assembly language for 32K ROM cartridge.

http://atariage.com/forums/topic/265033-the-legend-of-tilda/







NOTES--------------------------------------------------------------

http://anonymous-function.com/zelda-canvas/  (not a good emulation)

https://www.spriters-resource.com/nes/legendofzelda/
http://www.nesmaps.com/maps/Zelda/sprites/ZeldaSprites.html
http://www.finalfantasykingdom.net/z1worldmap.php

http://troygilbert.com/deconstructing-zelda/movement-mechanics/
(not sure, this might be referring to ALTTP instead)
LOZ always aligns to 8 pixels before turning

Playthroughs
https://www.youtube.com/watch?v=4bt5VHG3Jpw
https://www.youtube.com/watch?v=hhb3LqLtTBM

Music:
http://rainwarrior.ca/projects/nes/nsfimport.html
http://www.unige.ch/medecine/nouspikel/ti99/tms9919.htm
http://forums.famitracker.com/viewtopic.php?t=1399#p11179
https://www.seventhstring.com/resources/notefrequencies.html


Name: "Legend of Tilda"  (Princess Matilda)
Idea: TIforce instead of triforce (shape of texas instead of triangle)

Start of game, black screen, wipe in (from center to left/right) (after which link just appears in the center)
Going through an overworld door, Link sinks down with walking animation, cut to black
Cave fades in from black, items appear in smoke, message appears one letter at a time
Item collected is held up
Leaving cave is cut to black, link rises up in doorway with walking animation
Moving from one overworld screen to another scrolls in that direction
The left, right, and bottom -most 8 pixels of the screen are not displayed 
 (bushes are cut in half in overwold, bricks are not displayed in dungeon)
Some enemies appear from offscreen 
Enemies disappear during scrolling
Enemies appearing on-screen appear in a puff of smoke (enemies cannot be harmed during smoke)
Some enemies appear from beneath the surface of the ground (leever)
Clock powerup freezes enemies onscreen
Bombs produce screen flash and smoke (bombs cannot be selected when zero)
     () ()
  ()[]   []()   []=bomb location
   ()     ()
 (attack anim for 8 frames, 40 frames detonate,
  clouds toggle V formation 2 frames,
  palette change all grey, 4 frames
  clouds toggle V formation, 1 frame
  palette change all grey, 4 frames
  clouds toggle V formation, 13 frames
  dissolve toggle V formation, 12 frames
  
Old man disappears when item is selected (2 fires stay, even when cave is reentered)
Cave with rupees (It's a secret to everyone) prints the number below the rupees
 (Link doesn't hold up anything) (Rupee counter continues counting up after leaving cave)
Can use candle once per screen (lights up room if dark, burns down trees to find secret passage)
Blue ring 250 rupees, makes clothes grey, take half damage
Entering dungeon, black screen, fade in from center to the left and right
Some enemies can carry keys, dropping when killed (what happens to key if enemy killed and leave screen - key spawns on ground when reentering room)
Going down dungeon stairs, fade to black
Fack from black, and gravity keeps link on the floor (invisible blocks?)
Bosses drop a heart container
Collecting triforce does a few screen flashes, then wipe to black (from left/right to center)
  (link is still visible holding triforce, blinking yellow and light blue)
After dungeon, black screen, then cut to overworld, Link rises from entrance
When link gets hurt, he blinks blue/white between green/brown
Heart pickups blink red/blue (2 frames on/off for 24 frames, 8 frames red/blue)
1 Rupee pickups blink yellow/lightblue (color change every 8 frames, 2 frame flicker when appearing 8 blinks)
5 Rupee pickups solid lightblue
Before moving in a new direction, Link will align to 8-pixel grid
Walking animation changes every 6 frames (10Hz) (Fire also)


Functions:
wipe in from center to left/right
wipe out from left/right
bright flash (palette: black becomes gray, others become white)
draw sprite bitmap on character map
scroll map up/down/left/right
sprite sink/down rise/up (while animating) (use solid higher-priority sprite over it, won't work for dithered ground though)
update hearts (use sprite for half-heart)
potions fill hearts to full (slowly, half-heart each time) (red potion turns to blue when used)


Use black, dark blue, dark green, dark red for tile foreground color
So that sprite->character map drawing will look OK-ish
Only use sprite-character map as needed (5+ sprites on a line)

in cave, use sprites for fire, old man and sword, with 2nd color in bg chars
Cave enter
427 tiles appear
428 link appears, walking upward
433 finish walking
436 center poof
437 center poof dissapate1 (delay 1), 2 fire poofs
439 left fire poof dissapate1 (delay 1)
440 right fire poof dissapate1 (delay 2)
443 center poof dissapate2 (delay 6)
445 left fire poof dissapate2 (delay 6)
446 right fire poof dissapate2 (delay 6)
449 old man and sword appear (delay 6)
451 left fire appears (delay 6)
452 right fire appears (delay 6)
454 I
460 T
466 '
472 S
478 space
484 D
...
562 G
568 O
574 next line A
...
670 .
671 link can move

359 tiles appear
360 link appears, walking upward
365 finish walking
368 center poof
369 center poof dissapate1, 2 fire poofs
371 left fire poof dissapate1
372 right fire poof dissapate1
375 center poof dissapate2
377 left fire poof dissapate2
378 right fire poof dissapate2
381 shopkeeper and items appear
383 left fire appears
384 right fire appears

185 get sword, holding it up, words disappear
186 tile sword disappears
188 old man off
189 old man on
...
251 old man off  (64 frames blinked)
312 sword disappears
313 standing normal (62 frames later, 128 total)


943 tiles appear
360 link appears, walking upward
365 finish walking
952 center poof
953 center poof dissapate1, 2 fire poofs
955 left fire poof dissapate1
956 right fire poof dissapate1
959 center poof dissapate2
961 left fire poof dissapate2
962 right fire poof dissapate2
981 shopkeeper and items appear
383 left fire appears
384 right fire appears


Menu screen - selector changes blue/red 8 frames

Investigate 3-color sprites (flipping two sprite priority every field)
This should work great for fire (flickering is fine!)
Link 3 colors: light green, dark red (mixed to brown?)
Blue ring: grey, yellow (mixed to brown?)
Red ring: red, yellow (mix to brown?)


Overworld rooms are 16x11 or 176 metatiles
Overworld map is 16x8 rooms, 128 in total, total memory 22k!!

> The Zelda 1 overworld is made of 16x8 screens, each made of 16x176 pixel "columns".
> http://forums.nesdev.com/viewtopic.php?t=5122
> https://forums.nesdev.com/viewtopic.php?f=2&t=9245
> http://userpages.monmouth.com/~colonel/videogames/zelda/moonmap.html
> https://shockingvideogamesecrets.files.wordpress.com/2011/12/ouqjc.gif

1 word xy location for secret exit (cave, bomb hole, stairs, etc)
4 side transitions (some are not consistent, such as puzzle mazes)
2 enemy types, flag if zora present

Cave contains message, character and items (always 2 fires)
Cave data, 3 bytes?
  events: old man giving item (wood sword, white sword, magic sword, letter)
          old man giving red potion or heart container "TAKE ANY ONE YOU WANT."
          money making game
          old woman selling potions (needs letter)
          merchant selling various items
            magic shield 160  key 100  blue candle 60
            magic shield 130  bombs 20  arrows 80
            magic shield 90  monster bait 100  heart 10
            key 80  blue ring 250  monster bait 60
          moblin giving money "IT'S A SECRET TO EVERYBODY."
          old woman with message "PAY ME AND I'LL TALK"

          



Input Priority
Sword, Up/Down (unless wall), Right/Left

Sword is attack sprite for 4 frames, then add sword for 8 frames
Then walk sprite, and sword retract in 2 frames
Note: can change direction while attacking!
Can fire sword beam, arrow, boomerang, flame at same time (only one of each though)

Bombs take 40 frames to detonate (http://tasvideos.org/2091S.html)

Link hurt, knockback last 8 frames, then invincibility 40 more frames
Can attack while being knocked back (but not turn or move)
When link is flashing, enemies can't hurt him (invincibility frames)
When enemies are flashing or stunned, they can't hurt link
hurt palette: 2 frames each
  dark blue, white
  green, black  (normal colors)
  black, red
  red, white
Dead, Face South, 30-ish frames flashing
(animation continues to 1016 if walking when died)
878 1 hearts gone
879 32 face down, enemies disappeared, hurt blinking
911 26 finished blinking, normal colors
937 2 brown on yellow palette
939 2 brown on dark red palette
941 5 face right
946 5 face up
951 5 face left
956 5 face down
961 5 face right
966 5 face up
971 5 face left
976 5 face down
981 5 face right
986 5 face up
991 5 face left
996 5 face down
1001 5 face right
1006 5 face up
1011 5 face left
1016 2 face down
1018 10 brown on lightred palette
1028 10 dark brown on darkred palette
1038 10 black on darkred palette
1048 1 all black palette
1049 24 link gray (sword too)
1073 10 small star (white/blue)
1083 4 big star (white/blue)
1087 46 disappear
1133 96 GAME OVER (G below X's) centered vertically
1229 3 black screen, status bar disappears
1232
    * CONTINUE   (* red heart)


      SAVE


      RETRY
selection blinks red and white 4 frames each, total 63 frames
3976 red
3980 white
...
4039 black screen
4050 status bar appears
4051 loading level wipe starts

Boomerang moves by 3 thrown, 2 when returning
8 frame animation changes every other frame, rotates counter-clockwise
Spark for 2 frames when hits edge of screen, returns rotating same way

Magic Rod
4 frames attack
8 frames wand out (retract 2)
1 frame
magic appears (moves by 3 and 2 alternating)
colors: dark blue, dark red, black, cyan

Arrow item by itself cannot be selected, nor can the bow
Bow and Arrow can be selected even with 0 rupees
Arrow appears 1 frame after attack animation, costs 1 rupee
Moves by 3, brown tip, light blue or grey shaft, red feathers
Moblin arrows move by 2, brown tip, red shaft, white feathers
Spark for 3 frames at edge of screen

Zora bullet: red black lightblue(or grey) darkblue
Zora pulse: 2 11 11 8
Zora appears: 19
Bullet appears: 16, then bullet shoots
Zora disappears after 30 more frames
Zora pulse: 11 11 11 11 11 11 11 11 8
Disappears for 1 frame

969 2 disappear
970 32 pulsing
1002 19 appears
1021 16 bullet appears
1037 30 bullet shoots
1067 96 pulsing
1163 2 disappear
1165 32 pulsing
1197    appear

Rocks animate 6 frames
moving left or right 1 pixel per frame
moves down 2 pixels per frame
bounce freezes for 1 frame (sometimes changing direction)
appears stationary for 8 to 32 frames then
up -2 -2 -2 -1 -1 -1 0 0 1 1 1 2 2 2



Destroy animation: small 6 big 6 small 6
Destroy colors: red red red2 red2 white white white2 white2
Tektite animation 17 frames
Enemy knockback 17 frames then flash/move for 16 more frames?
Enemy hurt colors: 2 frames each: green black orange blue


Leever pulsing 8 frames 
Red Leever coming up 8 frames
Leever spin 5 frames
Red Leever going down 8 frames, 3 frames pulse, 8 frames pulse, 5 vanish
Blue Leever going down 8 11 11 11 11 11 11 11 8 
Moving by 6 then 7 etc when under, by 2 when normal
Blue Leever going up 4 11 11 7 (15 frames half-up)
Multiple Blue Leever appearance delayed by 16 frames

1045 31 enemies appear
1076 6 leever pulse 1
1082 11 leever pulse 2
1093 11 leever pulse 1
1104 4 leever pulse 2
1108 15 leever half up
1123 5 leever 1
1128 5 leever 2
1133 5 leever 1
1138 5 leever 2
1143 5 leever 1
1148 5 leever 2
1153 5 leever 1
1158 5 leever 2
1378 16 leever half down
1394 11 leever pulse 1
1406 11 leever pulse 2
1416 11 leever pulse 1
1427 11 leever pulse 2
1439 11 leever pulse 1
1449 11 leever pulse 2
1460 11 leever pulse 1
1471 11 leever pulse 2
1482 8 leever pulse 1
1490 129 disappear
1619 3 leever pulse 1
1621   leever pulse 2




Peahat Moving by 2 2 1 2 1
Peahat spin up 8 8 8 5 4 4 4 4 4 4 4 3 3 3 2 3 3 2 3 3 2 3 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 2 1 2 1
Peahat sits for 73 frames

Octorok enemy appearing in cloud/puff:
Full cloud: 1 frame  (octoroks 32+16*N frames)
Half cloud: 6 frames  
Low cloud: 6 frames (enemy appears underneath on last frame)
Delay before next half cloud: 6 frames 
Lynel clouds appear simultaneously

1660 clouds appear
1692 cloud 1 frame 2 (delay 32 : 32 + 16*0)
1698 cloud 1 frame 3 (delay 6)
1704 cloud 1 octorok appears (delay 6)
1708 cloud 2 frame 2 (delay 48 : 32 + 16*1)
1714 cloud 2 frame 3 (delay 6)
1720 cloud 2 octorok appears (delay 6)
1724 cloud 3 frame 2 (delay 64 : 32 + 16*2)
1730 cloud 3 frame 3 (delay 6)
1736 cloud 3 octorok appears (delay 6)
1740 cloud 4 frame 2 (delay 80 : 32 + 16*3)
1746 cloud 4 frame 3 (delay 6)
1752 cloud 4 octorok appears (delay 6)

483 screen scrolls in
493 clouds appear frame 1
494 cloud 1 frame 2 (delay 1)
496 cloud 2 frame 2 (delay 3)
498 cloud 3 frame 2 (delay 5)
499 cloud 4 frame 2 (delay 6)
500 cloud 1 frame 3 (delay 6)
502 cloud 2 frame 3 (delay 6)
504 cloud 3 frame 3 (delay 6)
505 cloud 1 moblin appears, cloud 4 frame 3 (delay 6)
506 cloud 1 gone (delay 6)
507 cloud 2 moblin appears
508 cloud 2 gone (delay 6)
509 cloud 3 moblin appears
510 cloud 4 moblin appears, cloud 3 gone (delay 6)
511 cloud 4 gone (delay 6)

541 cloud 5 frame 2  (delay 48)
547 cloud 5 frame 3  (delay 6)
554 cloud 5 gone, octorok appears  (delay 7)
573 cloud 6 frame 2  (delay 80)
579 cloud 6 frame 3  (delay 6)
585 cloud 6 gone, octorok appears  (delay 7)


106 screen scrolls in
151 first edge octorok appears
201 2nd edge octorok appears
221 3rd edge octorok appears
261 4th edge octorok appears


Armos, touch to activate
8062 blink on/off every frame
8125 solid, background tiles disappear
     slow moves 1 then 0 alternating
     fast moves 1 then 2 alternating



Monster flags: hurt/stun=1bit
Hurt state: 2 bits direction, 6 bits counter (stored in VDP)
Stun state: 6 bits counter (stored in VDP)
(can be hurt or stunned independently: stun can wear off during hurt, etc)
HP (stored in VDP)


Enemy	Damage	Hits-to-kill	Drops
Armos	1	3/2/1
Ghini	1	9/5/3
LeeverR	.5	2/1/1		rupees
LeeverB	1	4/2/1
LynelR	1	4/2/1
LynelB	2	6/3/2		bombs
 beam sword 4
MoblinR	.5	2/1/1
MoblinB	.5	3/2/1		bombs
 arrow  .5
OctorokR .5	1
OctorokB .5	2/1/1		bombs
 bullet .5
Peahat	.5	2/1/1
Rock	.5
TektiteR .5	1
TektiteB .5	1
Zola	.5	2/1/1

Aquamentus  .5  6/3/2
BubbleW   none    (takes away sword temporarily)
BubbleR   none    (takes away sword until touch blue or triforce)
BubbleB   none    (restores sword)
DarknutR   1    4/2/1  (only vuln to sword or bombs)
DarknutB   2    8/4/2  (only vuln to sword or bombs)
Digdogger  1    8/4/2  (flute to split, 1 or 3 mini digdoggers)
Dodongo    1    2 bombs to mouth, 1 bomb to back and hit with sword (always gives bombs this way)
Flame      1    1/1/1  (block access to princess)
Ganon      2    16/8/4 (silver arrow to finish off)
 projectile 1
Gel        .5   1/1/1  (can be killed by boomerang)
Gibdo      2    7/4/2  (mummy)
Gleeok     1    8/4/2  (L4 2 heads, L6 3 heads, L8 4 heads)
 projectile 1
GohmaR     1     (1 arrow to eye)
GohmaB     1     (3 arrows to eye)
 projectile 1
GoriyaR    .5   3/2/1  (boomerangs can be blocked with any shield)
GoriyaB    1    5/3/2
Keese      .5   1/1/1  (can be killed by boomerang)
LanmolaR   2    4/2/1  (centipedes, fast)
LanmolaB   2    8/4/2  (really fast)
Likelike   1    9/5/3  (swallow hero, eats magic shield)
Manhandla  1    4/2/1 per hand
 projectile 1
Moldorm    .5   2/1/1  (slow orange dots)
Patra      2    outer eyes 8/4/2  middle 9/6/3
Pols Voice 2    9/5/3 or 1 arrow (arrow pass thru) (drops lots of rupees)
RopeR/B    .5   1/1/1
Stalfos    .5   2/1/1
Stone statue .5    (projectile can be blocked by magic shield)
Trap       1
Vire       1    2/1/1 (spawns 2 keese, unless killed w/ magic sword)
Wall master .5  2/1/1  (if catches you, go to level start)
WizzrobeR  1    4/2/1  (boomerang has no effect)
  projectile 4         (can be blocked by magic shield)
WizzrobeB  2    9/6/3  (boomerang has no effect)
Zol       1     1/1/1  (splits into 2 gels if hit with wooden sword)



Item drops chart and forced item drops:
http://www.zeldaspeedruns.com/loz/generalknowledge/item-drops-chart
http://www.zeldaspeedruns.com/loz/tech/forced-item-drops
https://kb.speeddemosarchive.com/The_Legend_of_Zelda



Weapon Damage [http://zelda.gamepedia.com/Weapon_Strength#The_Legend_of_Zelda]
Wooden Sword    1
White Sword     2
Magical Sword   4
Arrow	        2
Silver Arrow    4
Candle          1
Boomerang       1
Bomb            4
Magic Rod       2
Book of Magic Fire  2


Candle animate 4  move by 1 every other frame
662 36 flame appears
664    move
665    animate
698 57 stop moving
755    disappear


Menu screen - 3 rows of sprites and colors
Raft (brown) Book (red/blue) Ring (blue/red) Ladder (brown) Dungeon Key (brown) Power Bracelet (red)
Boomerang (brown/blue) Bomb (blue) Bow/Arrow (brown/?) Candle (red/blue)
Flute (brown) Meat (red) Scroll(brown)/Potion(red/blue) Magic Rod (blue)


Title Screen
Waterfall toggle - 8 frames (toggle on 2nd frame of first row)
3 rows of waterfall sprites
First row, 4 frames, 4 frames,
Bottom 2 rows, 8 frames  (move down 2 pixels each frame)
Tiforce - yellow x12, orange 6, red 6, red 16, orange 6,


Startup frames
0 black
1,2 gray
3-33 peach
34 graphics in

34 triforce orange    6
40 triforce yellow    12
52 triforce orange    6
58 triforce red       6
64 triforce dark red  12
76 triforce red       16

92 triforce orange    6
98 triforce yellow    12
110 triforce orange   6
116 triforce red      6
122 triforce dark red 12
134 triforce red      16

150 triforce orange   6
156 triforce yellow   12
168 triforce orange   6
174 triforce red
...
553 bg light green
561 bg light blue
567 bg cyan
572 bg light green, sword grey
576 bg med blue
579 bg dark cyan
581 bg dark blue
583 bg darker blue, sword dark grey, zelda purple
585 bg black, rocks dark grey, zelda dark blue, foliage dark blue, waterfall gray on dark blue
777 waterfall darker
783 rocks black, zelda black, waterfall bg black
787 all black
1030 scrolling text

THE LEGEND OF TILDA
LONG AGO, GANROM, PRINCE
OF DORKINESS, STOLE THE
TIFORCE OF POWER.
PRINCESS TILDA OF TYRULE
BROKE THE TIFORCE OF
WISDOM INTO EIGHT PIECES
AND HID THEM FROM GANROM
BEFORE SHE WAS KIDNAPPED
BY GANROM'S MINIONS.
HERO, YOU MUST FIND THE
PIECES AND SAVE  TILDA.

GANROM & 'S - red
PRINCESS & TILDA - blue
HERO - green
other text - white
Updated cave text from 2003 release:
https://tcrf.net/The_Legend_of_Zelda/Console_Differences
http://legendsoflocalization.com/the-legend-of-zelda/first-quest/
http://computerarcheology.com/NES/Zelda/

https://www.zeldadungeon.net/zelda-screenshots.php

Saved Data
1 Max hearts - 1
1 Rupees 0..255
1 keys
1 bombs(5 bits) / max bombs(3 bits)
4 flags (items collected)

16 overworld secrets opened (128 bits)
16 overworld items collected (128 bits) (TODO reduce if cave/armos has no item)
32 dungeon map rooms visited (256 bits)
32 dungeon items collected (256 bits) (TODO Reduce if room has no item)
64 dungeon walls unlocked/bombed (2 per room?, 512 bits) (TODO reduce)
64 overworld enemies count (4 bits per screen, 0-15 enemies, 512 bits)
1 tiforce collected (1 per dungeon up to 8)
4 map/compass collected (1 each per dungeon up to 9, 32 bits)
232 total bytes


Dungeon door types:
Wall
Open
Bombable
Locked
Shutters (one-way, kill enemies, push block, kill enemies & push block)

Dungeon bosses do not respawn when defeated (TODO verify)


TODO: High priority
Edge spawning for octorok/moblin/lynel
Animate going up/down cave (animate in bank 3) (move up/down 1 pixel every 4 frames, animate every 6 frames)
Add Armos (activation and AI, moves by 1&0 or 1&2)
Push rock to open secret cave (14 frames to start moving, moves every other frame)
Push locked door in dungeon to open (uses 1 key)
Bomb counter decrement
Enemy collision with Arrow, Boomerang, Candle, Bomb
Magic Rod (damage amount)
Caves and stores
Fix flickering when item is collected
Hold up item when bought in store / acquired in cave
 TODO which items are one or two-handed
 2handed: bigheart, triforce, raft, ladder
 1handed: all else
 0handed: rupees


TODO:
Fairy pond - filling hearts (circle movement)
Tektite AI
Add Zora bullet (blocked by magic shield, at either angle diagonal)
Enemy stun (requires boomerang or clock)
Title screen music
Smooth scrolling text after title screen
Rewrite sound player
  Sound effect playback
  Pattern music 4 channel compression
Drops: bombs(4), fairy(3 hearts), clock(stun all enemies)
  Drop table and forced item drops
Heart container item
Ladder
Raft
Flute (Tornado)
Flute (open level 7)
Enemy respawn (8 screen LRU)
Save enemy count per screen
Implement forest maze and up up mountain
Show letter to old woman for potions
Dungeons & music
Dungeon enemies and bosses
 Bats use peahat AI
Dungeon palette changes for darkness (use candle)

Continue/save/retry screen
Character selection / enter your name
FG99 saving
Disk save/load
Press joystick 1 up to start
Free up 14 bytes in CPU RAM for unrolled VDP copy (or 8 bytes without unroll)
!    MOV *R1+,*R15
     MOV *R1+,*R15
     MOV *R1+,*R15
     MOV *R1+,*R15
     DEC R2
     JNE -!
     RT
Peahat should not hurt link while flashing and not on ground
Link sword retract
Red Leevers should be more aggressive


DONE:
Status bar - gems,keys,bombs + hearts
Enemy hurt animation
Enemy HP decrement
Menu screen
Sprite flickering
Fix sprite screen edge transitions (early start bit) (sword beam splash only)
Title screen
Hide secrets in overworld.txt
Hero hurt animation
Hero HP decrement
Hero game over animation
Game over screen
Sword beam only works at full hearts
Drops: hearts, gems, gemsX5
Leevers
Peahats
Zora
Sprite compression
Menu screen items and selection
Bomb + screen flash
Move hero sprites to slot 4-5, status bar sprites to 0-3
Boomerang collects items
Flame hurts hero
Magic shield sprite for purchase in shop
Pattern table and screen table compression (LZW? Huffman coding? LZ77)
Rocks AI
Dungeon tileset
Bomb open secrets
Candle open secrets
Sprite masking (walking thru dungeon doors)
Arrows (hero)
Cloud spawning for octorok/moblin/lynel/tektite
Add octorok bullets (stationary 24 frames before shooting, blocked by tiles, moves by 3)
Add moblin arrows (move by 2, go through tiles, spark at screen edge)
Add lynel swords (same as sword beam, move by 3, no splash, blocked by magic shield)
Bullets/arrows/swords bounce off shield (except when attacking)
