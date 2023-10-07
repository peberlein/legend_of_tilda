# DAN2 Encoder - Decoder



import sys

verbose = False
MAX_LEN = 65536-1
BIT_OFFSET1 = 1
BIT_OFFSET2 = 4
BIT_OFFSET3 = 8
BIT_OFFSET4_MIN = 10
BIT_OFFSET4_MAX = 16
MAX_OFFSET1 = 1 << BIT_OFFSET1
MAX_OFFSET2 = MAX_OFFSET1 + (1 << BIT_OFFSET2)
MAX_OFFSET3 = MAX_OFFSET2 + (1 << BIT_OFFSET3)

# DAN2 compression scheme by Daniel Bienvenu aka NewColeco
class DAN2:

	def __init__(self, max_offset_bits):
		self.data = []
		if max_offset_bits < BIT_OFFSET4_MIN or max_offset_bits > BIT_OFFSET4_MAX:
			print(f"DAN2 max offset bits must be between {BIT_OFFSET4_MIN} and {BIT_OFFSET4_MAX}", file=sys.stderr)
			sys.exit(1)
		self.bit_index = 0
		self.bit_mask = 0
		self.option = 0
		self.bit_offset4 = max_offset_bits
		self.max_offset4 = MAX_OFFSET3 + (1 << max_offset_bits)

	def write_byte(self, value):
		#print(f"write_byte: {value:x}", file=sys.stderr)
		self.data += [value]

	def write_bit(self, value):
		#print(f"write_bit: {value:x} mask={self.bit_mask:02x} idx={self.bit_index}", file=sys.stderr)
		if self.bit_mask == 0:
			self.bit_mask = 0x80
			self.bit_index = len(self.data)
			self.write_byte(0)
		if value:
			self.data[self.bit_index] |= self.bit_mask
		self.bit_mask >>= 1

	def write_bits(self, value, n_bits):
		mask = 1 << n_bits
		#print(f"write_bits: {value:x} {n_bits} mask={mask:x}", file=sys.stderr)
		while mask > 1:
			mask >>= 1
			self.write_bit(value & mask)


	def write_elias_gamma(self, value):
		i = 2
		#print(f"write_elias_gamma: {value:x}", file=sys.stderr)
		while i <= value:
			self.write_bit(0)
			i <<= 1
		while i > 1:
			i >>= 1
			self.write_bit(value & i)

	def write_offset(self, value, option):
		#print(f"write_offset: {value:x} {option}", file=sys.stderr)
		value -= 1
		if value >= MAX_OFFSET3:
			self.write_bit(1)
			value -= MAX_OFFSET3
			self.write_bits(value >> 8, self.bit_offset4 - 8)
			self.write_byte(value & 0xff)
		elif value >= MAX_OFFSET2:
			if option > 2: self.write_bit(0)
			self.write_bit(1)
			value -= MAX_OFFSET2
			self.write_byte(value & 0xff)
		elif value >= MAX_OFFSET1:
			if option > 2: self.write_bit(0)
			if option > 1: self.write_bit(0)
			self.write_bit(1)
			value -= MAX_OFFSET1
			self.write_bits(value, BIT_OFFSET2)
		else:
			if option > 2: self.write_bit(0)
			if option > 1: self.write_bit(0)
			self.write_bit(0)
			self.write_bits(value, BIT_OFFSET1)

	def write_doublet(self, length, offset):
		#print(f"write_doublet: {length} {offset}", file=sys.stderr)
		self.write_bit(0)
		self.write_elias_gamma(length)
		self.write_offset(offset, length)
	
	def write_end(self):
		self.write_bit(0)
		self.write_bits(0, 16)

	def write_literal(self, c):
		#print(f"write_literal: {c:02x}", file=sys.stderr)
		self.write_bit(1)
		self.write_byte(c)

	def elias_gamma_bits(value):
		bits = 1
		while value > 1:
			bits += 2
			value >>= 1
		return bits
	
	def count_bits(self, offset, length):
		mask = 1
		result = 1 + DAN2.elias_gamma_bits(length)
		offset -= 1
		if offset >= MAX_OFFSET3:
			result += 1 + self.bit_offset4
		elif offset >= MAX_OFFSET2:
			if length > 2: result += 1
			result += 1 + BIT_OFFSET3
		elif offset >= MAX_OFFSET1:
			if length > 2: result += 1
			if length > 1: result += 1
			result += 1 + BIT_OFFSET2
		else:
			if length > 2: result += 1
			if length > 1: result += 1
			result += 1 + BIT_OFFSET1
		return result

	def lzss(self, src):

		optimal_bits = [8]  # First always literal
		optimal_offset = [0]
		optimal_len = [1]
		matches = list(map(lambda x:[], range(256*256)))

		for i in range(1, len(src)):
			# TRY LITERALS
			optimal_bits.append(optimal_bits[i-1] + 1 + 8)
			optimal_offset.append(0)
			optimal_len.append(1)

			# LZ MATCH OF ONE : LEN=1
			j = MAX_OFFSET2
			if j > i:
				j = i
			for k in range(1,j+1):
				if src[i] == src[i-k]:
					temp_bits = optimal_bits[i-1] + self.count_bits(k, 1)
					if temp_bits < optimal_bits[i]:
						optimal_bits[i] = temp_bits
						optimal_len[i] = 1
						optimal_offset[i] = k
						break

			# LZ MATCH OF TWO OR MORE : LEN=2,3,4,...
			match_index = src[i-1]*256 + src[i]
			match = matches[match_index]
			best_len = 1
			#print("i=",i," match=",match)
			for midx in range(len(match)-1, -1, -1):
				offset = i - match[midx]
				if offset > self.max_offset4:
					matches[match_index] = match[midx+1:]
					break
				for k in range(2, MAX_LEN+1):
					if k > best_len and not (k == 2 and offset > MAX_OFFSET3):
						best_len = k
						temp_bits = optimal_bits[i-k] + self.count_bits(offset, k)
						if optimal_bits[i] > temp_bits:
							optimal_bits[i] = temp_bits
							optimal_offset[i] = offset
							optimal_len[i] = k
					if i < offset+k or src[i-k] != src[i-k-offset]:
						break
			matches[match_index].append(i)

		# cleanup optimals
		i = len(src)-1
		while i > 1:
			j = i-1
			i -= optimal_len[i]
			while j > i:
				optimal_offset[j] = 0
				optimal_len[j] = 0
				j -= 1
		
		# Write offset4 bit size
		self.write_bits(0xFE, self.bit_offset4 - BIT_OFFSET4_MIN + 1)
		# First is always literal
		self.write_byte(src[0])
		for i in range(1,len(src)):
			if optimal_len[i] > 0:
				if optimal_offset[i] == 0:
					self.write_literal(src[i])
					if verbose:
						print(f"{i-optimal_len[i]+1}\t: RAW\t{optimal_len[i]} BYTE(S) bits={optimal_bits[i]}", file=sys.stderr)
				else:
					self.write_doublet(optimal_len[i], optimal_offset[i])
					if verbose:
						print(f"{i-optimal_len[i]+1}\t: COPY\t{optimal_len[i]} BYTE(S) FROM {i - optimal_len[i] + 1 - optimal_offset[i]} ( {-optimal_offset[i]}) bits={optimal_bits[i]}", file=sys.stderr)
		self.write_end()
		return bytes(self.data)

	def old_encode(self, data):
		i = 0
		# write max offset bits
		max_offset = (1 << max_offset_bits)
		for b in range(max_offset_bits-8):
			self.write_bit(1)

		# write first literal byte
		#print("literal byte ", data[idx], "idx=", idx)
		self.write_literal(data[i])
		i += 1
		while i < len(data):
			cur_off = 1
			cur_len = 0
			cur_enc = 0
			off = 1
			while off < max_offset and off <= i:
				l = scan(data, i - off, i)
				#print(f"scan {i} off={off} l={l}")
				if l > cur_len and self.count_bits(off, l) < 8*l:
					cur_len = l
					cur_off = off
				off += 1

			if cur_len > 1:
				#print(f"off={cur_off} len={cur_len}")
				i += cur_len
				self.write_doublet(cur_len, cur_off)
			else:
				#print("literal byte ", data[i], "i=", i)
				self.write_literal(data[i])
				i += 1

		self.write_end()
		return bytes(self.data)

# Returns the length of matching src_off and dst_off
def scan(data, src_off, dst_off):
	i = 0
	while dst_off+i < len(data) and data[src_off+i] == data[dst_off+i]:
		i += 1
	return i


def compress(data, max_offset):

	d2 = DAN2(max_offset)
	
	print("DAN2 (de)Compression Tool Version BETA-20170106", file=sys.stderr)
	print("Original C code by Daniel Bienvenu aka NewColeco, 2017", file=sys.stderr)

	print(f"Max offset size is {d2.bit_offset4} bits", file=sys.stderr)

	ret = d2.lzss(data)
	
	print(f"         source:    {len(data)} bytes", file=sys.stderr)
	print(f"    destination:    {len(ret)} bytes ({int(len(ret)*100/len(data))}%)", file=sys.stderr)
	return ret
