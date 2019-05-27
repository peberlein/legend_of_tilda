;
; Legend of Tilda
; Copyright (c) 2019 Pete Eberlein
;
; Bank 6: overworld+dungeon music and sounds

       COPY 'tilda.asm'

MAIN   ; R11 = return address

       ; modifies R0-R3,R12
       COPY 'tilda_player.asm'

       LI R0,BANK0      ; return to bank 0
       MOV R11,R1
       B @BANKSW

       ; overworld and dungeon music, and sound effects
       COPY "tilda_music2.asm"

* overworld music pointers
OWMUS1 EQU TSF00 & >1FFF    ; tilda_equ
OWMUS2 EQU TSF01 & >1FFF    ; tilda_equ
OWMUS3 EQU TSF02 & >1FFF    ; tilda_equ
OWMUS4 EQU TSF03 & >1FFF    ; tilda_equ

* dungeon music pointers
DNMUS1 EQU TSF10 & >1FFF    ; tilda_equ
DNMUS2 EQU TSF11 & >1FFF    ; tilda_equ
DNMUS3 EQU TSF12 & >1FFF    ; tilda_equ

* dungeon 9 music pointers
D9MUS1 EQU TSF20 & >1FFF    ; tilda_equ
D9MUS2 EQU TSF21 & >1FFF    ; tilda_equ
D9MUS3 EQU TSF22 & >1FFF    ; tilda_equ

* game over (continue/save/retry) pointers
GOMUS1 EQU TSF31 & >1FFF    ; tilda_equ

* Beep
SND_40 EQU TSF40 & >1FFF    ; tilda_equ
* Blip  (boomerang?)
SND_52 EQU TSF52 & >1FFF    ; tilda_equ
SND_53 EQU TSF53 & >1FFF    ; tilda_equ
* Bomb
SND_62 EQU TSF62 & >1FFF    ; tilda_equ
SND_63 EQU TSF63 & >1FFF    ; tilda_equ
* Bump
SND_70 EQU TSF70 & >1FFF    ; tilda_equ
* Casting
SND_80 EQU TSF80 & >1FFF    ; tilda_equ
* Clunk
SND_90 EQU TSF90 & >1FFF    ; tilda_equ
* Cursor / Text Writing
SND100 EQU TSF100 & >1FFF    ; tilda_equ
* Enemy kill
SND111 EQU TSF111 & >1FFF    ; tilda_equ
* Fairy / Clock / Collecting Bomb / Finding man in dungeon
* pickup compass/map/boomerang/heart container in dungeon/triforce
SND121 EQU TSF121 & >1FFF    ; tilda_equ
* Flame
SND132 EQU TSF132 & >1FFF    ; tilda_equ
SND133 EQU TSF133 & >1FFF    ; tilda_equ
* Flute
SND141 EQU TSF141 & >1FFF    ; tilda_equ
* Dead
SND151 EQU TSF151 & >1FFF    ; tilda_equ
* Heart / pickup key
SND160 EQU TSF160 & >1FFF    ; tilda_equ
* Item (cave)
SND170 EQU TSF170 & >1FFF    ; tilda_equ
SND171 EQU TSF171 & >1FFF    ; tilda_equ
SND172 EQU TSF172 & >1FFF    ; tilda_equ
* Rupee / Menu cursor
SND181 EQU TSF181 & >1FFF    ; tilda_equ
* Secret
SND191 EQU TSF191 & >1FFF    ; tilda_equ
* Sound7 (triforce?)
SND200 EQU TSF200 & >1FFF    ; tilda_equ
SND201 EQU TSF201 & >1FFF    ; tilda_equ
SND202 EQU TSF202 & >1FFF    ; tilda_equ

* Stairs
SND212 EQU TSF212 & >1FFF    ; tilda_equ
SND213 EQU TSF213 & >1FFF    ; tilda_equ
* Sword / Boomerang
SND222 EQU TSF222 & >1FFF    ; tilda_equ
SND223 EQU TSF223 & >1FFF    ; tilda_equ
* Lasersword
SND232 EQU TSF232 & >1FFF    ; tilda_equ
SND233 EQU TSF233 & >1FFF    ; tilda_equ
* Tink / Shield Reflect
SND240 EQU TSF240 & >1FFF    ; tilda_equ
* Unlock  (find hidden item in dungeon, open shutter door)
SND251 EQU TSF251 & >1FFF    ; tilda_equ
* Triforce collection music
SND261 EQU TSF261 & >1FFF    ; tilda_equ
SND262 EQU TSF262 & >1FFF    ; tilda_equ
* Fanfare music?
SND270 EQU TSF270 & >1FFF    ; tilda_equ
SND271 EQU TSF271 & >1FFF    ; tilda_equ
SND272 EQU TSF272 & >1FFF    ; tilda_equ
* Door open/close
SND282 EQU TSF282 & >1FFF    ; tilda_equ
SND283 EQU TSF283 & >1FFF    ; tilda_equ
* Boss hurt
SND292 EQU TSF292 & >1FFF    ; tilda_equ
SND293 EQU TSF293 & >1FFF    ; tilda_equ
* Link hurt
SND302 EQU TSF302 & >1FFF    ; tilda_equ
SND303 EQU TSF303 & >1FFF    ; tilda_equ
