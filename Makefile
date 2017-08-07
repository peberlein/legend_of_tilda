AS=../endlos99-xdt99-1aab4a6/xas99.py

ifneq ($(shell uname -s),Darwin)
  QUIET := status=none
endif

tilda.rpk: layout.xml tilda_8.bin
	zip -q $@ $^

tilda_8.bin: tilda_b0_6000.bin tilda_b1_6000.bin tilda_b2_6000.bin tilda_b3_6000.bin
	@dd $(QUIET) if=tilda_b0_6000.bin of=$@ bs=8192
	@dd $(QUIET) if=tilda_b1_6000.bin of=$@ bs=8192 seek=1
	@dd $(QUIET) if=tilda_b2_6000.bin of=$@ bs=8192 seek=2
	@dd $(QUIET) if=tilda_b3_6000.bin of=$@ bs=8192 seek=3
	@dd $(QUIET) if=/dev/null         of=$@ bs=8192 seek=4
	@ls -l $^

tilda_b0_6000.bin: tilda_b0.asm tilda.asm
	$(AS) -b -R $< -L tilda_b0_6000.lst

tilda_b1_6000.bin: tilda_b1.asm tilda.asm music.snd dungeon.snd title.snd
	$(AS) -b -R $< -L tilda_b1_6000.lst

tilda_b2_6000.bin: tilda_b2.asm tilda.asm overworld.bin
	$(AS) -b -R $< -L tilda_b2_6000.lst

tilda_b3_6000.bin: tilda_b3.asm tilda.asm title.asm
	$(AS) -b -R $< -L tilda_b3_6000.lst


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
	mame nes -nomax -nomouse -cart "music/Legend of Zelda, The (USA).nes"
zeldamac:
	( cd ~/Downloads/mame0186b_macOS/; ./mame64 nes -cart "~/Dropbox/ti994a/legend/music/Legend of Zelda, The (USA).nes" -w -nomax -nomouse -resolution 562x434)

.PHONY: clean all playmame
.SECONDARY: music/ft2asm music/zelda.txt music/dungeon.txt music/title.txt overmap overworld.txt
