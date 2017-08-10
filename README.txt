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


http://www.piskelapp.com/

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
Bombs produce screen flash and smoke
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
Some enemies can carry keys, dropping when killed (what happens to key if enemy killed and leave screen)
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
          money making game
          old woman selling potions (needs letter)
          merchant selling various items
            magic shield 160  key 100  blue candle 60
            magic shield 130  bombs 20  arrows 80
            magic shield 90  monster bait 100  heart 10
            magic shield 130  bombs 20  arrows 80
            key 80  blue ring 250  monster bait 60
          goriya  (or moblin) giving money
          old woman with message
          



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

Zora bullet: red black lightblue(or grey) darkblue
Zora pulse: 2 11 11 8
Zora appears: 19
Bullet appears: 16, then bullet shoots
Zora disappears after 30 more frames
Zora pulse: 11 11 11 11 11 11 11 11 8
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
Full cloud: 1 frame  (octoroks 32,32+24,32+48,etc frames?)
Half cloud: 6 frames  
Low cloud: 6 frames (enemy appears underneath on last frame)
Delay before next half cloud: 6 frames 
Lynel clouds appear simultaneously

483 screen scrolls in
493 clouds appear frame 1
494 cloud 1 frame 2
496 cloud 2 frame 2
498 cloud 3 frame 2
499 cloud 4 frame 2
500 cloud 1 frame 3
502 cloud 2 frame 3
504 cloud 3 frame 3
505 cloud 1 moblin appears, cloud 4 frame 3
506 cloud 1 gone
507 cloud 2 moblin appears
508 cloud 2 gone
509 cloud 3 moblin appears
510 cloud 4 moblin appears, cloud 3 gone
511 cloud 4 gone

541 cloud 5 frame 2
547 cloud 5 frame 3
554 cloud 5 gone, octorok appears
573 cloud 6 frame 2
579 cloud 6 frame 3
585 cloud 6 gone, octorok appears

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
MoblinR	.5	2/1/1
MoblinB	.5	3/2/1		bombs
OctorokR .5	1
OctorokB .5	2/1/1		bombs
Peahat	.5	2/1/1
Rock	.5
TektiteR .5	1
TektiteB .5	1
Zola	.5	2/1/1

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
OF DARKNESS, STOLE THE
TIFORCE OF POWER.
PRINCESS TILDA OF TYRULE
BROKE THE TIFORCE OF
WISDOM INTO EIGHT PIECES
AND HID THEM FROM GANROM
BEFORE SHE WAS KIDNAPPED
BY GANROM'S MINIONS.
HERO, YOU MUST FIND THE
PIECES AND SAVE  TILDA.

GANROM & 's '- red
PRINCESS & TILDA - blue
HERO - green
other text - white
Updated cave text from 2003 release:
https://tcrf.net/The_Legend_of_Zelda/Console_Differences




TODO: High priority
Tektite AI
Add Zora & bullet
Add octorok bullets (stationary 24 frames before shooting)
Add moblin arrows
Add lynel swords (same as sword beam)
Bullets/arrows bounce off shield
Cloud/edge spawning for octorok/moblin/lynel
Smooth scrolling text after title screen
Animate going up/down cave (animate in bank 3) (move up/down 1 pixel every 4 frames, animate every 6 frames)

TODO:
Enemy stun (requires boomerang or clock)
Add Armos
Menu screen items and selection
Title screen music
Rewrite sound player
  Sound effect playback
  Pattern music 4 channel
Drops: bombs, fairy, clock
Heart container
Bombs
Boomerang
Arrows
Candle
Magic Rod
Ladder
Raft
Flute
Fairy pond - filling hearts
Sprite compression
Enemy respawn (8 screen LRU)
Save enemy count per screen
Implement forest maze and up up up mountain
Secrets opened by bombs/flame/power bracelet
Caves and stores
Dungeons & music
Dungeon enemies and bosses
Pushable rock to open cave
Continue/save/retry
Character selection / enter your name
FG99 saving
Disk save/load
Press joystick 1 up to start
Move hero sprites to slot 4-5, status bar sprites to 0-3
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