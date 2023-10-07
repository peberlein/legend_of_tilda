AS:=../xdt99/xas99.py
GA:=../xdt99/xga99.py

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

SOURCES := $(wildcard *.asm)


tilda_8.bin: $(SOURCES)
	$(AS) -B -R main.asm -L tilda_8.lst -o $@
#	$(AS) -b -R main.asm -L main.lst -o $@

tilda.rpk: layout.xml tilda_c.bin tilda_g.bin
	zip -q $@ $^

tilda_g.bin: tilda_g.gpl
	$(GA) $< -o $@


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
#sprites.asm: mag/linkspr.mag mag/sprites.mag mag/enemies.mag mag/dungeon.mag mag/bosses.mag $(SP) $(SPRITEC)
#	grep -h "^SP:" mag/sprites.mag mag/enemies.mag mag/dungeon.mag mag/bosses.mag | $(SPRITEC) - > $@
sprites.asm: graphics.mag
	tools/mag.py -sc 64 256 -o $@ $<

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

#tilda_music1.asm: $(SL2TSF) tilda_soundlist1.bin
#	$^ $@ TSL

#tilda_music2.asm: $(SL2TSF) tilda_soundlist2.bin
#	$^ $@ TSF

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
