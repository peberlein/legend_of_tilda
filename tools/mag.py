#!/usr/bin/env python3

# Extract binary data from Magellan files

# ./mag.py <args> <filename>.mag
# -c <id> <n>  starting and count of char defs
# -C <id> <n>  starting and count of color defs (bitmap)
# -s <id> <n>  starting and count of sprites
# -m <id>      map screen (first = 1)
# -sl <id>     sprite list (first = 1)
# -comp        compress sprites using reflection/rotation/symmetry
# -dan2        compress data using DAN2
# -dan2offset  DAN2 maximum offset size in bits, 10-16, default 11
# -bin         output as binary (otherwise DATA)
# -o <filename>   output to file (otherwise stdout)

import string,sys
import dan2

char_start = 0    # First char to extract
char_count = 0    # How many
color_start = 0   # First color to extract
color_count = 0   # How many
sprite_start = 0  # First sprite to extract
sprite_count = 0  # How many
map_index = 0     # Map index to extract
sprite_list = 0
sprite_compress = False
dan2_compress = False
dan2_max_offset = 11
binary = False
output_filename = False
output_file = sys.stdout
verbose = False


n = 1
while n < len(sys.argv):
	arg = sys.argv[n]
	if arg == "-c":
		char_start = int(sys.argv[n+1])
		char_count = int(sys.argv[n+2])
		n += 2
	elif arg == "-C":
		color_start = int(sys.argv[n+1])
		color_count = int(sys.argv[n+2])
		n += 2
	elif arg == "-s" or arg == "-sc":
		sprite_start = int(sys.argv[n+1])
		sprite_count = int(sys.argv[n+2])
		n += 2
		if arg == "-sc": sprite_compress = True
	elif arg == "-m":
		map_index = int(sys.argv[n+1])
		n += 1
	elif arg == "-sl":
		sprite_list = int(sys.argv[n+1])
		n += 1
	elif arg == "-o":
		#output_file = open(sys.argv[n+1], 'wb')
		output_filename = sys.argv[n+1]
		n += 1
	elif arg == "-comp":
		sprite_compress = True
	elif arg == "-dan2":
		dan2_compress = True
	elif arg == "-dan2offset":
		dan2_max_offset = int(sys.argv[n+1])
		n += 1
	elif arg == "-bin":
		binary = True
	elif arg == "-v":
		verbose = True
	else:
		break
	n += 1

if sprite_compress and dan2_compress:
       sys.stderr.write("Sprite compress and DAN2 compress cannot be used together")
       exit()

f = open(sys.argv[n], encoding="utf-8")

if output_filename:
	output_file = open(output_filename, 'wb' if binary or dan2_compress else 'w')

ch = 0
cc = 0
co = 0
mp = 0
mw = 0
mh = 0
sp = 0
sl = []
sc = []


data = bytes()

while True:
	line = f.readline()
	if line == "":
		break
	if line[:3] == 'CH:':
		if ch >= char_start and ch < char_start+char_count:
			data += bytes.fromhex(line[3:])
		ch += 1
	elif line[:3] == 'CO:':
		if co >= color_start and co < color_start+color_count:
			data += bytes.fromhex(line[3:])
		co += 1
	elif line[:3] == 'SP:':
		if sp >= sprite_start and sp < sprite_start+sprite_count:
			data += bytes.fromhex(line[3:])
		sp += 1
	elif line[:2] == 'M+':
		mp += 1
	elif line[:3] == 'MS:':
		mw, mh = list(map(int, line[3:].split('|')))
	elif line[:3] == 'MP:':
		if mp == map_index:
			data += bytes(list(map(
				lambda x: int(x)%256,
				line[3:].split('|'))))
	elif line[:3] == 'SL:':
		if mp == sprite_list:
			sl += [list(map(
				lambda x: int(x)%256,
				line[3:].split('|')))]
	elif line[:3] == 'SC:':
		sc += [int(line[3:])]
f.close()

# Look up sprite colors for sprite list and output data
for x, y, s in sl:
	data += bytes([x,(y+255)%256,(s*4)%256, sc[s]])








#############################################################################
#   Sprite compression using symmetry, flipping, rotation, or empty space   #
#############################################################################

# Reverse the bits of two 8-bit values in a word
def revb8(i):
	i = ((i & 0x5555) << 1) | ((i >> 1) & 0x5555)
	i = ((i & 0x3333) << 2) | ((i >> 2) & 0x3333)
	i = ((i & 0x0F0F) << 4) | ((i >> 4) & 0x0F0F)
	return i

# Reverse the bits of a 16-bit word
def revb16(i):
	return revb8(((i & 0xFF) << 8) | ((i >> 8) & 0xFF))

# clockwise
# this method calculates destination bytes in order, to be send directly to the VDP
def rotate3_spr(spr):
	s = bytes()
	for i in range(32):
		k = [8,24,0,16][i>>3]
		mask = 1 << (7-(i&7))
		c = 0
		for j in range(8):
			c >>= 1
			if spr[k] & mask:
				c |= 0x80
			k += 1
		s += bytes([c])
	return s

def vertical_flip(sa, sb):
	for i in range(8):
		if sa[i] != sb[15-i] or sa[i+16] != sb[31-i]:
			return False
	return True

def horizontal_flip(sa, sb):
	for i in range(16):
		if sa[i] != revb8(sb[i+16]) or sa[i+16] != revb8(sb[i]):
			return False
	return True

# |\/\/\
# |----- Horizontal Symmetry
# |/\/\/
def horizontal_symmetry(spr):
	return vertical_flip(spr, spr)

#   /|\
#  / | \  Vertical Symmetry
# /__|__\
def vertical_symmetry(spr):
	return horizontal_flip(spr, spr)

def vertical_center(spr):
	for i in range(4):
		if spr[i]!=0 or spr[15-i]!=0 or spr[i+16]!=0 or spr[31-i]!=0:
			return False
	return True

def horizontal_center(spr):
	for i in range(16):
		if (spr[i]&0xf0)!=0 or (spr[i+16]&0x0f)!=0:
			return False
	return True

def clockwise(sa, sb):
	return sa == rotate3_spr(sb)

if sprite_compress:
	sp = data
	modes = ["",
		"Full",
		"Hflip-1",
		"Vflip-1",
		"Hflip-2",
		"Vflip-2",
		"Vflip-3",
		"Clockwise-1",
		"Clockwise-2",
		"Clockwise-4",
		"HVcenter",
		"HVsymmetry",
		"Hcenter",
		"Vcenter",
		"Hsymmetry",
		"Vsymmetry"]
	csizes = [0, 32, 0,0,0,0,0, 0,0,0, 8,8,16,16,16,16]
	metadata = []
	offsets = []
	offset = 0
	output_file.write("SPRITE\n")
	for i in range(0, len(sp), 32):
		s = sp[i:i+32]
		hc = horizontal_center(s)
		vc = vertical_center(s)
		hs = horizontal_symmetry(s)
		vs = vertical_symmetry(s)

		if i >= 32 and horizontal_flip(s, sp[i-32:i]):
			m = 2  # Hflip-1
		elif i >= 32 and vertical_flip(s, sp[i-32:i]):
			m = 3  # Vflip-1
		elif i >= 64 and horizontal_flip(s, sp[i-64:i-32]):
			m = 4  # Hflip-2
		elif i >= 64 and vertical_flip(s, sp[i-64:i-32]):
			m = 5  # Vflip-2
		elif i >= 96 and vertical_flip(s, sp[i-96:i-64]):
			m = 6  # Vflip-3
		elif i >= 32 and clockwise(s, sp[i-32:i]):
			m = 7  # Clockwise-1
		elif i >= 64 and clockwise(s, sp[i-64:i-32]):
			m = 8  # Clockwise-2
		elif i >= 128 and clockwise(s, sp[i-128:i-96]):
			m = 9  # Clockwise-4
		elif hc and vc:
			m = 10 # HVcenter
			output_file.write("       DATA ")
			for j in range(4, 12, 2):
				output_file.write('>' + bytes([
					(sp[i+j]<<4)|(sp[i+j+16]>>4),
					(sp[i+j+1]<<4)|(sp[i+j+17]>>4)
					]).hex()+(',' if j<10 else ''))
		elif hs and vs:
			m = 11 # HVsymmetry
			output_file.write("       DATA ")
			for j in range(0, 8, 2):
				output_file.write('>' + sp[i+j:i+j+2].hex() +
					(',' if j<6 else ''))
		elif hc:
			m = 12 # Hcenter
			output_file.write("       DATA ")
			for j in range(0, 16, 2):
				output_file.write('>' + bytes([
					(sp[i+j]<<4)|(sp[i+j+16]>>4),
					(sp[i+j+1]<<4)|(sp[i+j+17]>>4)
					]).hex()+(',' if j<14 else ''))
		elif vc:
			m = 13 # Vcenter
			output_file.write("       DATA ")
			for j in [4,6,8,10,20,22,24,26]:
				output_file.write('>' + sp[i+j:i+j+2].hex() +
					(',' if j<26 else ''))
		elif hs:
			m = 14 # Hsymmetry
			output_file.write("       DATA ")
			for j in [0,2,4,6,16,18,20,22]:
				output_file.write('>' + sp[i+j:i+j+2].hex() +
					(',' if j<22 else ''))
		elif vs:
			m = 15 # Vsymmetry
			output_file.write("       DATA ")
			for j in range(0, 16, 2):
				output_file.write('>' + sp[i+j:i+j+2].hex() +
					(',' if j<14 else ''))
		else:
			m = 1  # Full
			output_file.write("       DATA ")
			for j in range(0, 32, 2):
				output_file.write('>' + sp[i+j:i+j+2].hex() +
					(',' if j<30 else '\n'))

		if m != 1: output_file.write(f"  ; {int(i/32)}: {modes[m]}\n")
		metadata.append(m)
		offsets.append(offset)
		offset += csizes[m]
	# write out metadata
	output_file.write("MODES\n")
	for i in range(0, len(metadata), 4):
		if i%64 == 0: output_file.write("       DATA ")
		output_file.write('>'+bytes([metadata[i]*16+metadata[i+1],metadata[i+2]*16+metadata[i+3]]).hex())
		if i%64 != 60: output_file.write(',')
		else: output_file.write('\n')
	output_file.write("MODEND DATA >0000 ; terminator\n")
	for i in range(0,len(offsets)):
		output_file.write(f"SPR_{i}{' ' if i<10 else ''}{' ' if i<100 else ''} EQU SPRITE+{offsets[i]}\n")

else:
	if dan2_compress:
		#print(f"input: {len(data)}")
		data = dan2.compress(data, dan2_max_offset)
		#print(f"output: {len(data)}")
		
	if output_file == sys.stdout:
		output_file.buffer.write(data)
	else:
		output_file.write(data)

