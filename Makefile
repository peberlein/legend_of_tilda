AS=../endlos99-xdt99-1aab4a6/xas99.py

legend_8.bin: legendb0_6000.bin legendb1_6000.bin legendb2_6000.bin legendb3_6000.bin
	@dd status=none if=legendb0_6000.bin of=$@ bs=8K
	@dd status=none if=legendb1_6000.bin of=$@ bs=8K seek=1
	@dd status=none if=legendb2_6000.bin of=$@ bs=8K seek=2
	@dd status=none if=legendb3_6000.bin of=$@ bs=8K seek=3
	@dd status=none if=/dev/null of=$@ bs=8K seek=4

legendb0_6000.bin: legendb0.asm legend.asm overworld.asm dungeon.asm
	$(AS) -b -R $< -L legendb0.lst

legendb1_6000.bin: legendb1.asm legend.asm music.snd dungeon.snd
	$(AS) -b -R $< -L legendb1.lst

legendb2_6000.bin: legendb2.asm legend.asm overworld.map
	$(AS) -b -R $< -L legendb2.lst

legendb3_6000.bin: legendb3.asm legend.asm 
	$(AS) -b -R $< -L legendb3.lst


music.snd: music/ft2asm music/zelda.txt
	music/ft2asm -t 5 music/zelda.txt > $@
dungeon.snd: music/ft2asm music/dungeon.txt
	music/ft2asm music/dungeon.txt > $@

music/ft2asm: LDLIBS=-lm

overmap: LDLIBS=-lpng

#overworld.txt: overmap levels/z1map.png
#	./overmap levels/z1map.png > /dev/null

overworld.map: overmap overworld.txt
	./overmap > $@

legend.rpk:
	$(AS) -c -R legend.asm -n "HELLO CART" -o legend.rpk

