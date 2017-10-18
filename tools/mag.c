/* Char defs to binary
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>


// convert two bytes of ascii hex to decimal
static unsigned char a2h(char *a2)
{
	return ((a2[0]&0xf) + 9*(a2[0]>='A')) * 16 + ((a2[1]&0xf) + 9*(a2[1]>='A'));
}

static int ends_with(const char *s, const char *p)
{
	int ls = strlen(s), lp = strlen(p);
	return ls < lp ? 0 : (strcmp(s + ls - lp, p) == 0);
}

static int istxt(int ch)
{
	return ch > 32 && ch <= 90;
}

int main(int argc, char *argv[])
{
	unsigned char buf[16*1024] = {};
	unsigned char
		*ch = buf + 0x800,   // char patterns
		*sp = buf + 0x1000,  // sprite patterns
		*cc = buf + 0x340,   // color table
		*mp = buf + 0x0,     // screen table
		*sl = buf + 0x380;   // sprite list table
	enum {
		MAG,
		SP,
		CH,
		MP,
		TXT,
	} mode =
		ends_with(argv[0],"sp") ? SP :
		ends_with(argv[0],"ch") ? CH :
		ends_with(argv[0],"mp") ? MP :
		ends_with(argv[0],"txt") ? TXT :
		MAG;
	int minch = 0, maxch = 255;

	char line[200];
	int i, map = 0, sc = 0, mapnum = 1;

	FILE *f = fopen(argv[1],"r");
	if (!f) {
		fprintf(stderr,"Failed to open %s\n", argv[1]);
		return 0;
	}
	if (mode == MP || mode == TXT)
		mapnum = atoi(argv[2]);
	else if (mode == CH && argc >= 3) {
		minch = atoi(argv[2]);
		maxch = atoi(argv[3]);
	}

	fprintf(stderr, "%s %d %d\n", argv[0], mode, mapnum);
	while (fgets(line, sizeof line, f)) {
		if (strncmp(line, "CH:", 3) == 0) {
			for (i = 0; i < 8; i++)
				*ch++ = a2h(line+3+i*2);
		} else if (strncmp(line, "SP:", 3) == 0) {
			for (i = 0; i < 32; i++)
				*sp++ = a2h(line+3+i*2);
		} else if (strncmp(line, "CC:", 3) == 0 && mode == MAG) {
			*cc++ = (atoi(line+3) << 4) |
				atoi(strchr(line,'|')+1);
			//fprintf(stderr, "CC %02x\n", cc[-1]);
		} else if (strncmp(line, "M+", 2) == 0) {
			map += 1;
		} else if (strncmp(line, "MP:", 3) == 0 && map == mapnum) {
			char *c = line + 2;
			while (c) {
				*mp++ = atoi(++c);
				//fprintf(stderr, "%d ", mp[-1]);
				c = strchr(c, '|');
			}
			//fprintf(stderr, "\n");
		} else if (strncmp(line, "SL:", 3) == 0 && map == mapnum && mode == MAG) {
			char *c = line + 2;
			for (i = 0; i < 3; i++) {
				switch (i) {
				case 0: sl[1] = atoi(++c) * 8; break;
				case 1: sl[0] = atoi(++c) * 8-1; break;
				case 2: sl[2] = atoi(++c) * 4; break;
				}
				c = strchr(c, '|');
			}
			//fprintf(stderr, "sprite %02x %02x %02x\n",
			//	sl[0],sl[1],sl[2]);
			sl += 4;
		} else if (strncmp(line, "SC:", 3) == 0 && mode == MAG) {
			unsigned char *sl = buf + 0x380;
			for (i = 0; i < 32; i++) {
				if (sl[i*4+2] == sc*4)
					sl[i*4+3] = atoi(line+3);
			}
			sc++;
		}
	}
	fclose(f);
	*sl++ = 0xd0; // terminate sprite list

	if (mode == CH)
		fwrite(buf + 0x0800 + minch*8, (maxch-minch+1)*8, 1, stdout);
	else if (mode == SP)
		fwrite(buf + 0x1000, 256*8, 1, stdout);
	else if (mode == MP)
		fwrite(buf + 0x0000, mp - buf, 1, stdout);
	else if (mode == TXT) {
		int offset = 0;
		unsigned char *c = buf;
		fprintf(stderr, "       DATA");
		while (c < mp) {
			int i = 0;
			//fprintf(stderr, "%p\n", c);
			c += 4;
			fprintf(stderr, "%s%d", offset == 0 ? " ":",", offset);
			while (!istxt(c[i]))
				i++;
			if (i) {
				c += i;
				putchar(i);
				offset++;
			}
			while (1) {
				i = 0;
				while (istxt(c[i]) || istxt(c[i+1]))
					i++;
				fwrite(c, i, 1, stdout);
				offset += i;
				if (c[i-1] == '.' || c[i-1] == '!')
					break;
				c += i;
				i = 0;
				while (!istxt(c[i]))
					i++;
				putchar(i);
				offset++;
				c += i;
			}
			putchar(0); offset++;
			c += 32 - ((c - buf) % 32);
		}
		fprintf(stderr, "\n");
	} else
		fwrite(buf, sp - buf, 1, stdout);

	return 0;
}
