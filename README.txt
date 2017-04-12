http://anonymous-function.com/zelda-canvas/

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


Name: "Legend of Tilda"  (Matilda)
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
Some enemies appear from beneath the surface of the ground
Clock powerup freezes enemies onscreen
Bombs produce screen flash and 5 smoke
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
Heart pickups blink red/blue
1 Rupee pickups blink yellow/lightblue
5 Rupee pickups solid lightblue
Before moving in a new direction, Link will align to 8-pixel grid
Walking animation changes every 6 frames (10Hz) (Fire also)
32,34,35,37,38,
40,41,43,44,46,47,
48,49,51,52,54,55,
56,57,59,60,62,63,
64,65,67,68,70,71


Functions:
wipe in from center to left/right
wipe out from left/right
bright flash (palette: black becomes gray, others become white)
draw sprite bitmap on character map
scroll map up/down/left/right
sprite sink/down rise/up (while animating) (use solid higher-priority sprite over it)
update hearts (use sprite for half-heart)
potions fill hearts to full (slowly, half-heart each time) (red potion turns to blue when used)


Use black, dark blue, dark green, dark red for tile foreground color
So that sprite->character map drawing will look OK-ish
Only use sprite-character map as needed (5+ sprites on a line)

in cave, use sprites for fire, old man and sword, with 2nd color in bg chars



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


1 word xy location for secret exit (cave, bomb hole, stairs, etc)
4 side transitions (some are not consistent, such as puzzle mazes)
2 enemy types, flag if zora present

Cave contains message, character and items (always 2 fires)


Input Priority
Sword, Up/Down (unless blocked), Right/Left



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


Music



