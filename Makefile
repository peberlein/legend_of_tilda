AS:=../xdt99-master/xas99.py
GA:=../xdt99-master/xga99.py
#GA:=/home/pete/Downloads/xdt99-1.7.0/xga99.py

ARCH:=$(shell uname -m)-$(shell uname -s)

MAG:=tools/$(ARCH)/mag
DAN2:=tools/$(ARCH)/dan2
FT2ASM:=tools/$(ARCH)/ft2asm
SL2TSF:=tools/$(ARCH)/sl2tsf
LASERSWORD:=tools/$(ARCH)/lasersword
BIN2ASM:=tools/$(ARCH)/bin2asm
CH:=tools/$(ARCH)/ch
SP:=tools/$(ARCH)/sp
MP:=tools/$(ARCH)/mp
TXT:=tools/$(ARCH)/txt
OVERMAP:=tools/$(ARCH)/overmap
SPRITEC:=tools/$(ARCH)/spritec

ifneq ($(shell uname -s),Darwin)
  QUIET := status=none
endif

tilda.rpk: layout.xml tilda_c.bin tilda_g.bin
	zip -q $@ $^

tilda_c.bin: tilda_b0.bin tilda_b1.bin tilda_b2.bin tilda_b3.bin tilda_b4.bin tilda_b5.bin tilda_b6.bin tilda_b7.bin
	@dd $(QUIET) if=tilda_b0.bin of=$@ bs=8192
	@dd $(QUIET) if=tilda_b1.bin of=$@ bs=8192 seek=1
	@dd $(QUIET) if=tilda_b2.bin of=$@ bs=8192 seek=2
	@dd $(QUIET) if=tilda_b3.bin of=$@ bs=8192 seek=3
	@dd $(QUIET) if=tilda_b4.bin of=$@ bs=8192 seek=4
	@dd $(QUIET) if=tilda_b5.bin of=$@ bs=8192 seek=5
	@dd $(QUIET) if=tilda_b6.bin of=$@ bs=8192 seek=6
	@dd $(QUIET) if=tilda_b7.bin of=$@ bs=8192 seek=7
	@dd $(QUIET) if=/dev/null         of=$@ bs=8192 seek=8
	@ls -l $^

tilda_g.bin: tilda_g.gpl
	$(GA) $< -o $@

tilda_b0.bin: tilda_b0.asm tilda.asm tilda_common.asm tilda_b6_equ.asm
	$(AS) -b -R $< -L tilda_b0.lst

tilda_b1.bin: tilda_b1.asm tilda.asm tilda_common.asm sprites.asm
	$(AS) -b -R $< -L tilda_b1.lst

tilda_b2.bin: tilda_b2.asm tilda.asm tilda_common.asm overworld.bin
	$(AS) -b -R $< -L tilda_b2.lst

tilda_b3.bin: tilda_b3.asm tilda.asm tilda_common.asm dan2.asm title.d2 overworld1.d2 overworld2.d2 dungeon1.d2 dungeon2.d2 menu.d2 cavetext.d2 dungeonm.d2 dmenu.d2 dungdark.d2 register.d2
	$(AS) -b -R $< -L tilda_b3.lst

tilda_b4.bin: tilda_b4.asm tilda.asm tilda_common.asm tilda_b7_equ.asm
	$(AS) -b -R $< -L tilda_b4.lst

tilda_b5.bin: tilda_b5.asm tilda.asm tilda_common.asm tilda_b6_equ.asm
	$(AS) -b -R $< -L tilda_b5.lst

tilda_b6.bin: tilda_b6.asm tilda.asm tilda_player.asm tilda_music2.asm
	$(AS) -b -R $< -L tilda_b6.lst

tilda_b7.bin: tilda_b7.asm tilda.asm tilda_player.asm tilda_music1.asm
	$(AS) -b -R $< -L tilda_b7.lst


tilda_b6_equ.asm: tilda_b6.bin
	awk '/tilda_equ/ {print $$3,$$4,">"$$2}' tilda_b6.lst > $@
tilda_b7_equ.asm: tilda_b7.bin
	awk '/tilda_equ/ {print $$3,$$4,">"$$2}' tilda_b7.lst > $@


title.d2: mag/title.mag $(MAG) $(DAN2)
	$(MAG) $< | $(DAN2) > $@
register.d2: mag/title.mag $(MP) $(DAN2)
	($(MP) $< 4; $(MP) $< 5; $(MP) $< 6) | $(DAN2) > $@
overworld1.d2: mag/sprites.mag $(DAN2) $(CH)
	$(CH) $< 4 23 | $(DAN2) > $@
overworld2.d2: mag/sprites.mag $(DAN2) $(CH)
	$(CH) $< 96 247 | $(DAN2) > $@
menu.d2: mag/sprites.mag $(DAN2) $(MP)
	$(MP) $< 3 | $(DAN2) > $@
cavetext.d2: mag/sprites.mag $(DAN2) $(TXT)
	$(TXT) $< 6 | $(DAN2) > $@

dungeon1.d2: mag/dungeon.mag $(DAN2) $(CH)
	$(CH) $< 4 23 | $(DAN2) > $@
dungeon2.d2: mag/dungeon.mag $(DAN2) $(CH)
	$(CH) $< 96 247 | $(DAN2) > $@
dungeonm.d2: mag/dungeon.mag $(DAN2) $(MP)
	$(MP) $< 10 | $(DAN2) > $@
dmenu.d2: mag/dungeon.mag $(DAN2) $(MP)
	$(MP) $< 8 | $(DAN2) > $@
dungdark.d2: mag/dungdark.mag $(DAN2) $(CH)
	$(CH) $< 96 239 | $(DAN2) > $@
sprites.asm: mag/linkspr.mag mag/sprites.mag mag/enemies.mag mag/dungeon.mag mag/bosses.mag $(SP) $(SPRITEC)
	grep -h "^SP:" mag/sprites.mag mag/enemies.mag mag/dungeon.mag mag/bosses.mag | $(SPRITEC) - > $@


$(MAG): tools/mag.c
	$(CC) $< -o $@
$(CH): tools/mag.c
	$(CC) $< -o $@
$(SP): tools/mag.c
	$(CC) $< -o $@
$(MP): tools/mag.c
	$(CC) $< -o $@
$(TXT): tools/mag.c
	$(CC) $< -o $@
$(DAN2): tools/dan2.c
	$(CC) $< -o $@
$(BIN2ASM): tools/bin2asm.c
	$(CC) $< -o $@
$(FT2ASM): music/ft2asm.c
	$(CC) $< -o $@ -lm
$(SL2TSF): music/sl2tsf.c
	$(CC) -g $< -o $@ -lm
$(LASERSWORD): music/lasersword.c
	$(CC) $< -o $@ -lm
$(OVERMAP): tools/overmap.c
	$(CC) $< -o $@ -lpng -g
$(SPRITEC): tools/spritec.c
	$(CC) $< -o $@

tilda_music1.asm: $(SL2TSF) tilda_soundlist1.bin
	$^ > $@

tilda_music2.asm: $(SL2TSF) tilda_soundlist2.bin
	$^ > $@

tilda_soundlist1.bin: $(FT2ASM) $(LASERSWORD)
	( $< -l music/ZeldaTitle.txt ;\
	$< -l music/ZeldaRegister.txt ;\
	$< -l music/ZeldaRupee.txt ;\
	$< -l music/ZeldaClunk.txt ;\
	$(LASERSWORD) 3 "hero hurt" ;\
	) > $@

tilda_soundlist2.bin: $(FT2ASM) $(LASERSWORD)
	( $< -l music/ZeldaOverworld.txt ;\
	$< -l music/ZeldaDungeon.txt ;\
	$< -l music/ZeldaBoss.txt ;\
	$< -l music/ZeldaGameOver.txt ;\
	$< -l music/ZeldaBeep.txt ;\
	$< -l music/ZeldaBlip.txt ;\
	$< -l music/ZeldaBomb.txt ;\
	$< -l music/ZeldaBump.txt ;\
	$< -l music/ZeldaCasting.txt ;\
	$< -l music/ZeldaClunk.txt ;\
	$< -l music/ZeldaCursor.txt ;\
	$< -l music/ZeldaEnemyKill.txt ;\
	$< -l music/ZeldaFairy.txt ;\
	$< -l music/ZeldaFlame.txt ;\
	$< -l music/ZeldaFlute.txt ;\
	$< -l music/ZeldaDead.txt ;\
	$< -l music/ZeldaHeart.txt ;\
	$< -l music/ZeldaItem.txt ;\
	$< -l music/ZeldaRupee.txt ;\
	$< -l music/ZeldaSecret.txt ;\
	$< -l music/ZeldaSound7.txt ;\
	$< -l music/ZeldaStairs.txt ;\
	$< -l music/ZeldaSword.txt ;\
	$(LASERSWORD) 0 "laser sword" ;\
	$< -l music/ZeldaTink.txt ;\
	$< -l music/ZeldaUnlock.txt ;\
	$< -l music/ZeldaTriforce.txt ;\
	$< -l music/ZeldaFanfare.txt ;\
	$(LASERSWORD) 1 "door open/close";\
	$(LASERSWORD) 2 "boss roar" ;\
	$(LASERSWORD) 3 "hero hurt";\
	) > $@



# This is disabled since we made changes to overworld.txt
#overworld.txt: tools/overmap levels/z1map.png
#	tools/overmap levels/z1map.png > /dev/null

overworld.bin: $(OVERMAP) overworld.txt
	$(OVERMAP) > $@


dbgmame:
	mame ti99_4a -cart tilda.rpk -w -nomax -nomouse -debug -resolution 840x648
playmame:
	mame ti99_4a -cart tilda.rpk -w -nomax -nomouse
playmac:
	( cd ~/Downloads/mame0186b_macOS/; \
	./mame64 ti99_4a -cart ~/Dropbox/ti994a/legend/tilda.rpk \
	-w -nomax -nomouse -resolution 840x648)
#	-w -nomax -nomouse -resolution 562x434)
dbgmac:
	( cd ~/Downloads/mame0186b_macOS/; \
	./mame64 ti99_4a -cart ~/Dropbox/ti994a/legend/tilda.rpk \
	-w -nomax -nomouse -resolution 840x648 -debug)
winemac:
	( cd ~/.wine/drive_c ; \
	FREETYPE_PROPERTIES="truetype:interpreter-version=35" \
	wine classic99/classic99.exe tilda_8.bin   )



zeldanes:
	mame nes -w -nomax -nomouse -cart "music/Legend of Zelda, The (USA).nes"
zeldamac:
	( cd ~/Downloads/mame0186b_macOS/; ./mame64 nes -cart "~/Dropbox/ti994a/legend/music/Legend of Zelda, The (USA).nes" -w -nomax -nomouse -resolution 562x434)

.PHONY: clean all playmame
.SECONDARY: music/ft2asm music/zelda.txt music/dungeon.txt music/title.txt overmap overworld.txt
