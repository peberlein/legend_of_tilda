// Sprite packer
// Take advantage of symmetry, flipping, rotation, or empty space

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>



// convert two bytes of ascii hex to decimal
unsigned char a2h(char *a2)
{
	return ((a2[0]&0xf) + 9*(a2[0]>='A')) * 16 + ((a2[1]&0xf) + 9*(a2[1]>='A'));
}

// reverse the bits in a 8-bit value
int revb8(int i)
{
	i = ((i & 0x5555) << 1) | ((i >> 1) & 0x5555);
	i = ((i & 0x3333) << 2) | ((i >> 2) & 0x3333);
	i = ((i & 0x0F0F) << 4) | ((i >> 4) & 0x0F0F);
	return i;
}
int revb16(int i)
{
	return revb8(((i & 0xFF) << 8) | ((i >> 8) & 0xFF));
}


// clockwise
// this method calculates destination bytes in order, to be sent directly to VDP
static void rotate3_spr(unsigned char *spr)
{
	unsigned char c[32] = {};
	unsigned int i, j;

	for (i = 0; i < 32; i++) {
		int ks[] = {8,24,0,16};
		int k = ks[i>>3];
		int mask = 1 << (7-(i&7));

		for (j = 0; j < 8; j++) {
			c[i] >>= 1;
			c[i] |= (spr[k++] & mask) ? 0x80 : 0;
		}
	}
	memcpy(spr, c, 32);
}

// counterclockwise
// this method calculates destination bytes in order, to be sent directly to VDP
static void rotate4_spr(unsigned char *spr)
{
	unsigned char c[32] = {};
	unsigned int i, j;
	
	for (i = 0; i < 32; i++) {
		int ks[] = {16,0,24,8};
		int k = ks[i>>3];
		int mask = 1 << ((i&7));

		for (j = 0; j < 8; j++) {
			c[i] <<= 1;
			c[i] |= (spr[k++] & mask) ? 1 : 0;
		}
	}
	memcpy(spr, c, 32);
}




/* |\/\/\ 
 * |-----  Horizontal Symmetry
 * |/\/\/ 
 */
int horizontal_symmetry(unsigned char *s)
{
	int i;
	for (i = 0; i < 8; i++) {
		if (s[i] != s[15-i] || s[i+16] != s[31-i])
			return 0;
	}
	return 1;
}

/*   /|\
 *  / | \  Vertical Symmetry
 * /__|__\
 */
int vertical_symmetry(unsigned char *s)
{
	int i;
	for (i = 0; i < 16; i++) {
		if (s[i] != revb8(s[i+16]))
			return 0;
	}
	return 1;
}


int vertical_flip(unsigned char *s, unsigned char *src)
{
	int i;
	for (i = 0; i < 8; i++) {
		if (s[i] != src[15-i] || s[i+16] != src[31-i])
			return 0;
	}
	return 1;
}

int horizontal_flip(unsigned char *s, unsigned char *src)
{
	int i;
	for (i = 0; i < 16; i++) {
		int x = revb8(src[i] | (src[i+16] << 8));
		if (x != ((s[i] << 8) | s[i+16]))
			return 0;
		
	}
	return 1;
}

int vertical_center(unsigned char *s)
{
	int i;
	for (i = 0; i < 4; i++) {
		if (s[i] || s[15-i] || s[i+16] || s[31-i])
			return 0;
	}
	return 1;
	
}

int horizontal_center(unsigned char *s)
{
	int i;
	for (i = 0; i < 15; i++) {
		if ((s[i] & 0xF0) || (s[i+16] & 0x0F))
			return 0;
	}
	return 1;
}

int clockwise(unsigned char *s, unsigned char *src)
{
	unsigned char tmp[32];
	
	memcpy(tmp, src, 32);
	rotate3_spr(tmp);
	return memcmp(s, tmp, 32) == 0;	
}

int cclockwise(unsigned char *s, unsigned char *src)
{
	unsigned char tmp[32];
	
	memcpy(tmp, src, 32);
	rotate4_spr(tmp);
	return memcmp(s, tmp, 32) == 0;	
}

enum {
	None = 0,
	Full = 1,
	Hflip1 = 2,
	Vflip1 = 3,
	Hflip2 = 4,
	Vflip2 = 5,
	Vflip3 = 6,
	Clockwise1 = 7,
	Clockwise2 = 8,
	Clockwise4 = 9,
	HVcenter = 0xA,
	HVsymmetry = 0xB,
	Hcenter = 0xC,
	Vcenter = 0xD,
	Hsymmetry = 0xE,
	Vsymmetry = 0xF,
};

int main(int argc, char *argv[])
{
	FILE *f;
	unsigned char sp[1024][32];
	unsigned int index = 0;
	int i, j;
	char mode[1024] = {};
	int offsets[1024] = {};
	unsigned int csize = 0, osize = 0;

	f = strcmp(argv[1],"-")==0 ? stdin : fopen(argv[1] ,"r");
	if (!f) return 0;

	while (!feof(f)) {
		char line[100];

		if (fgets(line, sizeof line, f) == NULL)
			break;

		if (line[0] != 'S' || line[1] != 'P' || line[2] != ':') continue;
		//fprintf(stderr, "%d %s\n", index, line);
		for (i = 0; i < 32; i++)
			sp[index][i] = a2h(line+3+i*2);
		osize += 32;
		index++;
	}

	char* modes[] = {
		"",
		"",
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
		"Vsymmetry",
		};
	int csizes[] = { 0, 32, 0,0,0,0,0, 0,0,0, 8,8,16,16,16,16 };

	printf("SPRITE\n");
	for (i = 0; i < index; i++) {
		int hs = horizontal_symmetry(&sp[i][0]);
		int vs = vertical_symmetry(&sp[i][0]);
		int hf = i >= 1 ? horizontal_flip(&sp[i][0], &sp[i-1][0]) : 0;
		int vf = i >= 1 ? vertical_flip(&sp[i][0], &sp[i-1][0]) : 0;
		int hf2 = i >= 2 ? horizontal_flip(&sp[i][0], &sp[i-2][0]) : 0;
		int vf2 = i >= 2 ? vertical_flip(&sp[i][0], &sp[i-2][0]) : 0;
		int vf3 = i >= 3 ? vertical_flip(&sp[i][0], &sp[i-3][0]) : 0;
		int hc = horizontal_center(&sp[i][0]);
		int vc = vertical_center(&sp[i][0]);
		int cw = i >= 1 ? clockwise(&sp[i][0], &sp[i-1][0]) : 0;
		int ccw = i >= 1 ? cclockwise(&sp[i][0], &sp[i-1][0]) : 0;
		int cw2 = i >= 2 ? clockwise(&sp[i][0], &sp[i-2][0]) : 0;
		int cw4 = i >= 4 ? clockwise(&sp[i][0], &sp[i-4][0]) : 0;
		int ccw2 = i >= 2 ? cclockwise(&sp[i][0], &sp[i-2][0]) : 0;

		mode[i] =
			hf ? Hflip1 :
			vf ? Vflip1 :
			hf2 ? Hflip2 :
			vf2 ? Vflip2 :
			vf3 ? Vflip3 :
			cw ? Clockwise1 :
			cw2 ? Clockwise2 :
			cw4 ? Clockwise4 :
			hc && vc ? HVcenter :
			hs && vs ? HVsymmetry :
			hc ? Hcenter :
			vc ? Vcenter :
			hs ? Hsymmetry :
			vs ? Vsymmetry :
			Full;
		offsets[i] = i ? offsets[i-1]+csizes[mode[i-1]] : 0;

		//printf("; %d %d %d %d %d %d %d %d %d %d %d %d %s\n",
		//	hs, vs, hf, vf, hf2, vf2, hc, vc, cw, ccw, cw2, ccw2, modes[mode[i]]);
		switch (mode[i]) {
		case Full:
			printf("       DATA ");
			for (j = 0; j < 32; j+=2)
				printf(">%02x%02x%s", sp[i][j], sp[i][j+1], j<30 ? ",":"\n");
			continue;
		default:
			break;
		case HVcenter: // HVcenter
			printf("       DATA ");
			for (j = 4; j < 12; j+=2)
				printf(">%02x%02x%s",
					(sp[i][j] << 4) | (sp[i][j+16]>>4),
					(sp[i][j+1]<<4) | (sp[i][j+17]>>4),
					j<10 ? ",":"");
			break;
		case HVsymmetry: // HVSymmetry
			printf("       DATA ");
			for (j = 0; j < 8; j+=2)
				printf(">%02x%02x%s", sp[i][j], sp[i][j+1], j<6 ? ",":"");
			break;

		case Hcenter: // Hcenter
			printf("       DATA ");
			for (j = 0; j < 16; j+=2)
				printf(">%02x%02x%s",
					(sp[i][j] << 4) | (sp[i][j+16]>>4),
					(sp[i][j+1]<<4) | (sp[i][j+17]>>4),
					j<14 ? ",":"");
			break;
		case Vcenter: // Vcenter
			printf("       DATA ");
			for (j = 4; j < 12; j+=2)
				printf(">%02x%02x,", sp[i][j], sp[i][j+1]);
			for (j = 20; j < 28; j+=2)
				printf(">%02x%02x%s", sp[i][j], sp[i][j+1], j<26 ? ",":"");
			break;
		case Hsymmetry: // HSymmetry
			printf("       DATA ");
			for (j = 0; j < 8; j+=2)
				printf(">%02x%02x,", sp[i][j], sp[i][j+1]);
			for (j = 16; j < 24; j+=2) {
				printf(">%02x%02x%s", sp[i][j], sp[i][j+1], j<22 ? ",":"");
			}
			break;
		case Vsymmetry: // VSymmetry
			printf("       DATA ");
			for (j = 0; j < 16; j+=2)
				printf(">%02x%02x%s", sp[i][j], sp[i][j+1], j<14 ? ",":"");
			break;
		}
		printf("  ; %d: %s\n", i, modes[mode[i]]);
		csize += csizes[mode[i]];
	}
	printf("MODES\n");
	for (i = 0; i < index; i+=4) {
		if ((i & 63) == 0)
			printf("       DATA ");
		printf(">%x%x%x%x%s",
			mode[i],
			mode[i+1],
			mode[i+2],
			mode[i+3],
			(i < index-4) && ((i & 63) != 60)? ",":"\n");
	}
	printf("MODEND DATA >0000 ; terminator\n");
	for (i = 0; i < index; i++) {
		printf("SPR%-3d EQU SPRITE+%d\n", i, offsets[i]);
	}
	fprintf(stderr, "compressed %d -> %d bytes\n", osize, csize);

	fclose(f);
}
