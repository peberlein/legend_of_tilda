AS=../endlos99-xdt99-1aab4a6/xas99.py

ifneq ($(shell uname -s),Darwin)
  QUIET := status=none
endif

legend.rpk: layout.xml legend_8.bin
	zip -q $@ $^

legend_8.bin: legendb0_6000.bin legendb1_6000.bin legendb2_6000.bin legendb3_6000.bin
	@dd $(QUIET) if=legendb0_6000.bin of=$@ bs=8192
	@dd $(QUIET) if=legendb1_6000.bin of=$@ bs=8192 seek=1
	@dd $(QUIET) if=legendb2_6000.bin of=$@ bs=8192 seek=2
	@dd $(QUIET) if=legendb3_6000.bin of=$@ bs=8192 seek=3
	@dd $(QUIET) if=/dev/null         of=$@ bs=8192 seek=4
	@ls -l $^

legendb0_6000.bin: legendb0.asm legend.asm
	$(AS) -b -R $< -L legendb0.lst

legendb1_6000.bin: legendb1.asm legend.asm music.snd dungeon.snd title.snd
	$(AS) -b -R $< -L legendb1.lst

legendb2_6000.bin: legendb2.asm legend.asm overworld.bin
	$(AS) -b -R $< -L legendb2.lst

legendb3_6000.bin: legendb3.asm legend.asm tilda.asm
	$(AS) -b -R $< -L legendb3.lst


music.snd: music/ft2asm music/zelda.txt
	music/ft2asm -t 5 music/zelda.txt > $@
dungeon.snd: music/ft2asm music/dungeon.txt
	$^ > $@
title.snd: music/ft2asm music/title.txt
	music/ft2asm -t 12 music/title.txt  > $@

music/ft2asm: LDLIBS=-lm

overmap: LDLIBS+=-lpng
overmap: CFLAGS+=-g

# This is disabled since we made changes to overworld.txt
#overworld.txt: overmap levels/z1map.png
#	./overmap levels/z1map.png > /dev/null

overworld.bin: overmap overworld.txt
	./overmap > $@


dbgmame:
	mame ti99_4a -cart legend.rpk -w -nomax -nomouse -debug -resolution 840x648
playmame:
	mame ti99_4a -cart legend.rpk -w -nomax -nomouse
playmac:
	( cd ~/Downloads/mame0186b_macOS/; \
	./mame64 ti99_4a -cart ~/Dropbox/ti994a/legend/legend.rpk \
	-w -nomax -nomouse -resolution 840x648)
#	-w -nomax -nomouse -resolution 562x434)
dbgmac:
	( cd ~/Downloads/mame0186b_macOS/; \
	./mame64 ti99_4a -cart ~/Dropbox/ti994a/legend/legend.rpk \
	-w -nomax -nomouse -resolution 840x648 -debug)
winemac:
	( cd ~/.wine/drive_c ; \
	FREETYPE_PROPERTIES="truetype:interpreter-version=35" \
	wine classic99/classic99.exe legend_8.bin   )
	


zeldanes:
	mame nes -nomax -nomouse -cart "music/Legend of Zelda, The (USA).nes"
zeldamac:
	( cd ~/Downloads/mame0186b_macOS/; ./mame64 nes -cart "~/Dropbox/ti994a/legend/music/Legend of Zelda, The (USA).nes" -w -nomax -nomouse -resolution 562x434)

.PHONY: clean all playmame
.SECONDARY: music/ft2asm music/zelda.txt music/dungeon.txt music/title.txt overmap overworld.txt
