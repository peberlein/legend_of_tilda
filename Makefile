AS:=../xdt99-master/xas99.py
ARCH:=$(shell uname -m)-$(shell uname -s)

MAG:=tools/$(ARCH)/mag
DAN2:=tools/$(ARCH)/dan2
FT2ASM:=tools/$(ARCH)/ft2asm
BIN2ASM:=tools/$(ARCH)/bin2asm
CH:=tools/$(ARCH)/ch
SP:=tools/$(ARCH)/sp
MP:=tools/$(ARCH)/mp
TXT:=tools/$(ARCH)/txt
OVERMAP:=tools/$(ARCH)/overmap

ifneq ($(shell uname -s),Darwin)
  QUIET := status=none
endif

tilda.rpk: layout.xml tilda_8.bin
	zip -q $@ $^

tilda_8.bin: tilda_b0_6000.bin tilda_b1_6000.bin tilda_b2_6000.bin tilda_b3_6000.bin tilda_b4_6000.bin tilda_b5_6000.bin tilda_b6_6000.bin 
	@dd $(QUIET) if=tilda_b0_6000.bin of=$@ bs=8192
	@dd $(QUIET) if=tilda_b1_6000.bin of=$@ bs=8192 seek=1
	@dd $(QUIET) if=tilda_b2_6000.bin of=$@ bs=8192 seek=2
	@dd $(QUIET) if=tilda_b3_6000.bin of=$@ bs=8192 seek=3
	@dd $(QUIET) if=tilda_b4_6000.bin of=$@ bs=8192 seek=4
	@dd $(QUIET) if=tilda_b5_6000.bin of=$@ bs=8192 seek=5
	@dd $(QUIET) if=tilda_b6_6000.bin of=$@ bs=8192 seek=6
	@dd $(QUIET) if=tilda_b4_6000.bin of=$@ bs=8192 seek=7
	@dd $(QUIET) if=/dev/null         of=$@ bs=8192 seek=8
	@ls -l $^

tilda_b0_6000.bin: tilda_b0.asm tilda.asm
	$(AS) -b -R $< -L tilda_b0_6000.lst

tilda_b1_6000.bin: tilda_b1.asm tilda.asm music.snd #dungeon.snd title.snd
	$(AS) -b -R $< -L tilda_b1_6000.lst

tilda_b2_6000.bin: tilda_b2.asm tilda.asm overworld.bin
	$(AS) -b -R $< -L tilda_b2_6000.lst

tilda_b3_6000.bin: tilda_b3.asm tilda.asm dan2.asm title.d2 overworld1.d2 overworld2.d2 dungeon1.d2 dungeon2.d2 menu.d2 cavetext.d2 dungeonm.d2
	$(AS) -b -R $< -L tilda_b3_6000.lst

tilda_b4_6000.bin: tilda_b4.asm tilda.asm
	$(AS) -b -R $< -L tilda_b4_6000.lst

tilda_b5_6000.bin: tilda_b5.asm tilda.asm
	$(AS) -b -R $< -L tilda_b5_6000.lst

tilda_b6_6000.bin: tilda_b6.asm tilda.asm music.asm
	$(AS) -b -R $< -L tilda_b6_6000.lst


title.d2: mag/title.mag $(MAG) $(DAN2)
	$(MAG) $< | $(DAN2) > $@
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
$(OVERMAP): tools/overmap.c
	$(CC) $< -o $@ -lpng -g


music.asm: Makefile $(FT2ASM) $(BIN2ASM) sound.asm
	echo "OVERW0" > $@
	$(FT2ASM) -c 0 music/Zelda3.txt | $(BIN2ASM) -b >> $@
	echo "OVERW1" >> $@
	$(FT2ASM) -c 1 music/Zelda3.txt | $(BIN2ASM) -b >> $@
	echo "OVERW2" >> $@
	$(FT2ASM) -c 2 music/Zelda3.txt | $(BIN2ASM) -b >> $@
	echo "OVERW3" >> $@
	$(FT2ASM) -c 3 music/Zelda3.txt | $(BIN2ASM) -b >> $@
	echo "       EVEN" >> $@
	echo "NOTETB" >> $@
	$(BIN2ASM) < noteuse.dat >> $@

sound.asm: Makefile $(FT2ASM) $(BIN2ASM)
	echo "BEEP" > $@
	$(FT2ASM) -c 0 music/ZeldaBeep.txt | $(BIN2ASM) -b >> $@
	echo "BLIP1" >> $@
	$(FT2ASM) -c 2 music/ZeldaBlip.txt | $(BIN2ASM) -b >> $@
	echo "BLIP2" >> $@
	$(FT2ASM) -c 3 music/ZeldaBlip.txt | $(BIN2ASM) -b >> $@
	echo "BOMB1" >> $@
	$(FT2ASM) -c 2 music/ZeldaBomb.txt | $(BIN2ASM) -b >> $@
	echo "BOMB2" >> $@
	$(FT2ASM) -c 3 music/ZeldaBomb.txt | $(BIN2ASM) -b >> $@
	echo "BUMP  ; hitting enemy with sword" >> $@
	$(FT2ASM) -c 0 music/ZeldaBump.txt | $(BIN2ASM) -b >> $@
	echo "CAST" >> $@
	$(FT2ASM) -c 0 music/ZeldaCasting.txt | $(BIN2ASM) -b >> $@
	echo "CLUNK" >> $@
	$(FT2ASM) -c 0 music/ZeldaClunk.txt | $(BIN2ASM) -b >> $@
	echo "CURSOR" >> $@
	$(FT2ASM) -c 0 music/ZeldaCursor.txt | $(BIN2ASM) -b >> $@
	echo "ENEMKO" >> $@
	$(FT2ASM) -c 1 music/ZeldaEnemyKill.txt | $(BIN2ASM) -b >> $@
	echo "FAIRY ; get item: fairy, bomb, or clock" >> $@
	$(FT2ASM) -c 0 music/ZeldaFairy.txt | $(BIN2ASM) -b >> $@
	echo "FLAME1" >> $@
	$(FT2ASM) -c 2 music/ZeldaFlame.txt | $(BIN2ASM) -b >> $@
	echo "FLAME2" >> $@
	$(FT2ASM) -c 3 music/ZeldaFlame.txt | $(BIN2ASM) -b >> $@
	echo "FLUTES" >> $@
	$(FT2ASM) -c 1 music/ZeldaFlute.txt | $(BIN2ASM) -b >> $@
	echo "LNKDIE" >> $@
	$(FT2ASM) -c 1 music/ZeldaGameOver.txt | $(BIN2ASM) -b >> $@
	echo "HEART" >> $@
	$(FT2ASM) -c 0 music/ZeldaHeart.txt | $(BIN2ASM) -b >> $@
	echo "ITEM1" >> $@
	$(FT2ASM) -c 0 music/ZeldaItem.txt | $(BIN2ASM) -b >> $@
	echo "ITEM2" >> $@
	$(FT2ASM) -c 1 music/ZeldaItem.txt | $(BIN2ASM) -b >> $@
	echo "ITEM3" >> $@
	$(FT2ASM) -c 2 music/ZeldaItem.txt | $(BIN2ASM) -b >> $@
	echo "RUPEE" >> $@
	$(FT2ASM) -c 1 music/ZeldaRupee.txt | $(BIN2ASM) -b >> $@
	echo "SECRET" >> $@
	$(FT2ASM) -c 1 music/ZeldaSecret.txt | $(BIN2ASM) -b >> $@
	echo "STAIR1" >> $@
	$(FT2ASM) -c 2 music/ZeldaStairs.txt | $(BIN2ASM) -b >> $@
	echo "STAIR2" >> $@
	$(FT2ASM) -c 3 music/ZeldaStairs.txt | $(BIN2ASM) -b >> $@
	echo "SWORD1" >> $@
	$(FT2ASM) -c 2 music/ZeldaSword.txt | $(BIN2ASM) -b >> $@
	echo "SWORD2" >> $@
	$(FT2ASM) -c 3 music/ZeldaSword.txt | $(BIN2ASM) -b >> $@
	echo "TINK" >> $@
	$(FT2ASM) -c 0 music/ZeldaTink.txt | $(BIN2ASM) -b >> $@
	echo "UNLOCK" >> $@
	$(FT2ASM) -c 1 music/ZeldaUnlock.txt | $(BIN2ASM) -b >> $@
	#echo "LASERS" >> $@
	#$(CC) music/lasersword.c -o music/lasersword -lm
	#music/lasersword > /dev/null


	

music.snd: $(FT2ASM) music/zelda.txt
	$^ > $@
dungeon.snd: $(FT2ASM) music/dungeon.txt
	$^ > $@
title.snd: $(FT2ASM) music/title.txt
	$^ > $@


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
