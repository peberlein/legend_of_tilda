#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>

#include <png.h>


static void abort_(const char *s, ...)
{
        va_list args;
        va_start(args, s);
        vfprintf(stderr, s, args);
        fprintf(stderr, "\n");
        va_end(args);
        abort();
}

static int x, y;

static int width, height;
static png_byte color_type;
static png_byte bit_depth;
static unsigned int bytesperline = 0;

static png_structp png_ptr;
static png_infop info_ptr;
static int number_of_passes;
static png_bytep *row_pointers;

static void read_png_file(char *file_name)
{
	unsigned char header[8];    // 8 is the maximum size that can be checked

	/* open file and test for it being a png */
	FILE *fp = fopen(file_name, "rb");
	if (!fp)
			abort_("[read_png_file] File %s could not be opened for reading", file_name);
	fread(header, 1, 8, fp);
	if (png_sig_cmp(header, 0, 8))
			abort_("[read_png_file] File %s is not recognized as a PNG file", file_name);


	/* initialize stuff */
	png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (!png_ptr)
			abort_("[read_png_file] png_create_read_struct failed");

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
			abort_("[read_png_file] png_create_info_struct failed");

	if (setjmp(png_jmpbuf(png_ptr)))
			abort_("[read_png_file] Error during init_io");

	png_init_io(png_ptr, fp);
	png_set_sig_bytes(png_ptr, 8);

	png_read_info(png_ptr, info_ptr);

	width = png_get_image_width(png_ptr, info_ptr);
	height = png_get_image_height(png_ptr, info_ptr);
	color_type = png_get_color_type(png_ptr, info_ptr);
	bit_depth = png_get_bit_depth(png_ptr, info_ptr);

	number_of_passes = png_set_interlace_handling(png_ptr);
	png_read_update_info(png_ptr, info_ptr);

	/* read file */
	if (setjmp(png_jmpbuf(png_ptr)))
			abort_("[read_png_file] Error during read_image");

	row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
	bytesperline = png_get_rowbytes(png_ptr, info_ptr);
	for (y = 0; y < height; y++)
			row_pointers[y] = (png_byte*) malloc(bytesperline);

	png_read_image(png_ptr, row_pointers);

	fclose(fp);	
}

static unsigned char *tiles[256];
static unsigned int tilecount = 0;
static int tilew;
static unsigned char *metamap = NULL;
static unsigned char palette[128];  // outer[0:3] inner[4:7]


// palette
// 0: tan
// 1: brown
// 2: black
// 3: blue
// 4: green?
// 5: dark grey
// 6: white



// returns tile idx
static int get_metatile(int x, int y)
{
	int i, j;
	char *tile = alloca(16 * tilew);
	
	if (y >= 8*11 && y < 9*11 && x >= 0 && x < 48) {
		const char X=0x00, T=0x03, _=0x32, F=0x07, // wall, top, space, fireline 
		           S=0x37, B=0x38, L=0x39, D=0x3A; // solid space, brick, ladder, door
		unsigned char cave[] = {
			X,X,X,X,X,X,X,X,X,X,X,X,X,X,X,X, S,S,S,D,S,S,S,S,S,S,S,S,S,S,S,S, S,S,S,D,S,S,S,S,S,S,S,S,D,S,S,S,
			X,X,X,X,X,X,X,X,X,X,X,X,X,X,X,X, B,B,B,L,B,B,B,B,B,B,B,B,B,B,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,B,L,B,B,B,B,B,B,B,B,B,B,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,B,L,B,B,B,S,S,S,S,S,S,S,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,B,L,B,B,B,S,S,S,S,S,S,S,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,F,F,F,F,F,F,F,F,F,F,F,F,X,X, B,B,B,L,B,B,B,D,D,D,D,D,D,D,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,B,L,B,B,B,B,B,B,B,L,B,B,B,B, B,B,B,L,B,B,B,B,B,B,B,B,L,B,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,S,L,S,S,S,S,S,S,S,L,S,S,B,B, B,B,S,L,S,S,S,S,S,S,S,S,L,S,B,B,
			X,X,_,_,_,_,_,_,_,_,_,_,_,_,X,X, B,B,D,L,D,D,D,D,D,D,D,L,D,D,B,B, B,B,D,L,D,D,D,D,D,D,D,D,L,D,B,B,
			X,X,T,T,T,T,T,_,_,T,T,T,T,T,X,X, B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B, B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,
			X,X,X,X,X,X,X,_,_,X,X,X,X,X,X,X, B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B, B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,
			
			//0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
			//0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x32,0x00,0x00,
			//0x00,0x00,0x03,0x03,0x03,0x03,0x03,0x32,0x32,0x03,0x03,0x03,0x03,0x03,0x00,0x00,
			//0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x32,0x32,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
		};
		return cave[(y-8*11)*48+x];
	}
	
	if (metamap) return metamap[y*256+x];
	
	for (j = 0; j < 16; j++) {
		unsigned char *p = row_pointers[y * 16 + j] + (x * tilew);
		memcpy(tile + j * tilew, p, tilew);
	}
	
	{
	int pal = 0; // 1=brown 2=green 3=white
	for (i = 0 ; i < 16 * 16; i++) {
		int c = (tile[i>>1] >> ((i&1)?4:0)) & 0xf;
		//palette[c] = 1;
		if (c == 1) { // brown
			pal = 1;
		} else if (c == 4) { // green
			pal = 2;
			tile[i>>1] -= (i&1) ? 0x30 : 3; // to brown
		} else if (c == 5 || c == 6) { // dark grey or white
			pal = 3;
			tile[i>>1] -= (i&1) ? 0x50 : 5; // to tan or brown
		}
	}
	
	//fprintf(stderr, "%d,%d %02x%02x%02x%02x%02x%02x%02x%02x %02x%02x%02x%02x%02x%02x%02x%02x\n",x,y,
	//		tile[0],tile[1],tile[2],tile[3],tile[4],tile[5],tile[6],tile[7],
	//		tile[8],tile[9],tile[10],tile[11],tile[12],tile[13],tile[14],tile[15]);	
	if (pal) {
		int inner = (x & 15) > 1 && (x & 15) < 14 && (y % 11) > 1 && (y % 11) < 10;
		palette[(x/16)+(y/11)*16] |= pal << (inner*4);
	}
	}
	
#if 0
	int tilecolors[4] = {-1,-1,-1,-1};
	// recolor tiles
	for (i = 0; i < 16*16; i++) {
		j = i>>1;
		int c = (i&1) ? ((tile[j]>>4)&0xf) : (tile[j] & 0xf);
		if (c == tilecolors[0])
			c = 0;
		else if (c == tilecolors[1])
			c = 1;
		else if (c == tilecolors[2])
			c = 2;
		else if (c == tilecolors[3])
			c = 3;
		else {
			int tmp = 
				tilecolors[0] == -1 ? 0 :
				tilecolors[1] == -1 ? 1 :
				tilecolors[2] == -1 ? 2 :
				tilecolors[3] == -1 ? 3 : 0;
			tilecolors[tmp] = c;
			c = tmp;
		}
		if (i&1)
			tile[j] = (tile[j] & 0xf) | (c << 4);
		else
			tile[j] = (tile[j] & 0xf0) | c;
	}
#endif
	for (i = 0; i < tilecount; i++) {
		if (memcmp(tile, tiles[i], 16 * tilew) == 0)
			return i;
	}
	tiles[i] = malloc(16 * tilew);
	memcpy(tiles[i], tile, 16 * tilew);
	return tilecount++;
}


static unsigned char *strips[256] = {};
static unsigned char striplen[256] = {};
static unsigned int stripcount = 0;

#define START_BIT 0x80
#define TWICE_BIT 0x40
#define TILE_MASK 0x3f
#define STRIP_H 11

static int get_strip(int x, int y)
{
	unsigned char strip[STRIP_H];
	unsigned char data[STRIP_H];
	int i, j, len = 0;
	for (j = 0; j < STRIP_H; j++) {
		unsigned char mt = get_metatile(x, y+j);
		if (j && strip[len-1] == mt)
			strip[len-1] |= TWICE_BIT;
		else
			strip[len++] = mt;
	}
#if 0	
	for (j = len-2; j >= len/2; j--) {
		if (strip[j] == strip[j+1]  && (strip[j] <= TILE_MASK)) {
			strip[j] |= TWICE_BIT;
			memmove(strip+j+1, strip+j+2, len-(j+2));
			len--;
		}
	}
	
	for (j = 0; j+1 < len; j++) {
		if (strip[j] == strip[j+1] && (strip[j] <= TILE_MASK)) {
			strip[j] |= TWICE_BIT;
			memmove(strip+j+1, strip+j+2, len-(j+2));
			len--;
		}
	}
#endif
	
	
	for (i = 0; i < stripcount; i++) {
		unsigned char *s = strips[i];
		if (len == striplen[i] && memcmp(strip, s, len) == 0)
			return i; // found a matching strip

	}
	// create a new strip
	strips[stripcount] = malloc(len);
	memcpy(strips[stripcount], strip, len);
	striplen[stripcount] = len;

	return stripcount++;
}


static int check_strip_overlap(int x, int y)
{
	int i = striplen[x];
	if (x == y) return 0;
	if (i > striplen[y])
		i = striplen[y];
	while (i > 0) {
		if (memcmp(strips[x] + striplen[x] - i, strips[y], i) == 0)
			return i;
		i--;
	}
	return 0;
}






// convert two bytes of ascii hex to decimal
unsigned char a2h(char *a2)
{
	return ((a2[0]&0xf) + 9*(a2[0]>='A')) * 16 + ((a2[1]&0xf) + 9*(a2[1]>='A'));
}




int main(int argc, char *argv[])
{
	FILE *f = NULL;
	
	if (argc > 1) {
		read_png_file(argv[1]);
	
		tilew = 16 * bit_depth / 8;
		fprintf(stderr, "%dx%d (%d) colortype=%d bpp=%d\n", width, height, bytesperline, color_type, bit_depth);
		f = fopen("overworld.txt", "w");
	} else {
		int i, j;
		char line[256*2+3];

#if 0
		unsigned int tile[255];
		unsigned int equiv_tile[255] = {};
		f = fopen("legendb2.asm", "r");

		i = 0;
		j = -1;
		while (!feof(f)) {
			fgets(line, 256*2+3, f);
			if (line[0] == 'M' && line[1] == 'T') {
				j = a2h(line+2);
			}
			//if (j!=-1) fprintf(stderr, "%d %s", j, line);
			if (j != -1 && strlen(line) > 10 && strncmp(line+7,"DATA ",5) == 0) {
				equiv_tile[j] = j;
				tile[j++] = (a2h(line+13)<<24) + (a2h(line+15)<<16) + (a2h(line+19)<<8) + a2h(line+21);
				for (i = 0; i < j; i++) {
					if (tile[j-1] == tile[i]) {
						if (j-1!=i) fprintf(stderr, "%08x %d %d\n", tile[j-1], j-1, i);
						equiv_tile[j-1] = i;
						break;
					}
				}
			} else {
				j = -1;
			}
		}
		fclose(f);
		f = NULL;
#endif

		f = fopen("overworld.txt", "r");
		metamap = malloc(16*8*16*11+3);
		
		for (j = 0; j < 8*11; j++) {
			fgets(line, 256*2+3, f);

			for (i = 0; i < 256; i++) {
				//metamap[j*256+i] = equiv_tile[a2h(line+i*2)];
				metamap[j*256+i] = a2h(line+i*2);
				if (tilecount < metamap[j*256+i]+1)
					tilecount = metamap[j*256+i]+1;
			}
		}
		fclose(f);
		f = NULL;
	}
	
	{
		int x, y;
#if 0
		for (y = 0; y < 11*8; y++) {
			for (x = 0; x < 16*16; x++) {
				get_metatile(x, y);
			}
		}
		for (y = 0; y < 11*8; y++) {
			for (x = 0; x < 16*2; x++) {
				printf("%02x ", get_metatile(x, y));
			}
			printf("\n");
		}
#endif
		unsigned char strip_idx[16*16*8];
		for (y = 0; y < 8*11; y++) {
			for (x = 0; x < 16*16; x++) {
				if (f) fprintf(f, "%02x", get_metatile(x, y));
				if (y % 11 == 0)
					strip_idx[(y/11)*256+x] = get_strip(x, y);
					//fputc(get_strip(x, y), stdout);
			}
			if (f) fprintf(f, "\n");
		}
		unsigned char cave_idx[48];
		for (x = 0; x < 48; x++) {
			cave_idx[x] = get_strip(x, 8*11);
		}
		
		fprintf(stderr, "%d unique tiles\n", tilecount);
		y = 0;
		for (x = 0; x < stripcount; x++) {
			//fwrite(strips[x], 1, striplen[x], stdout);
			y += striplen[x];
		}
		fprintf(stderr, "%d strips, total %d bytes\n", stripcount, y);
		
		unsigned char *strip_data = malloc(y);
		
		int savings = 0;
		unsigned char strip_pair[256] = {};
		unsigned char strip_ol[256] = {};
		char strip_used[256] = {};
		int strip_start[16] = {};
		unsigned char strip_ren[256] = {}; // renumbering

		int n = 0;
		for (n = 10; n > 0; n--) {
			for (x = 0; x < stripcount; x++) {
				int best_ol = 0, best = 0;
				if (strip_ol[x]) continue;
				
				for (y = 0; y < stripcount; y++) {
					int ol = check_strip_overlap(x, y);
					if (ol > best_ol && !strip_used[y] && (strip_ol[y] == 0 || strip_pair[y] != x)) {
						best = y;
						best_ol = ol;
					}
				}
				//if (n == 10) fprintf(stderr, "ideal %3d -> %3d %2d  \n", x, best, best_ol);
				if (best_ol >= n && strip_used[best] == 0) {
					strip_pair[x] = best;
					strip_ol[x] = best_ol;
					strip_used[best] = 1;
				}
			}
		}
		for (x = 0; x < stripcount; x++) {
			//fprintf(stderr, "strip %3d -> %3d %2d  \n", x, strip_pair[x], strip_ol[x]);
			savings += strip_ol[x];
		}
		fprintf(stderr, "overlap savings %d\n", savings);
		
		int pos = 0;
		
		memset(strip_ren, 255, 256);
		
		// find a n that none refer to
		for (n = 0; n < stripcount; n++) {
			for (x = 0; x < stripcount; x++) {
				if (strip_pair[x] == n)
					break;
			}
			if (x == stripcount)
				break;
		}
		for (x = 0; x < stripcount; x++) {
			//fprintf(stderr, "ren[%d]=%d pos=%d\n", n, x, pos);
			if (strip_ren[n] != 255)
				fprintf(stderr, "strip %d already renamed to %d\n", n, strip_ren[n]);
			strip_ren[n] = x;
			if (x == stripcount-1) strip_ol[n] = 0; // final strip can't overlap any more strips
			for (y = 0; y < striplen[n] - strip_ol[n]; y++) {
				unsigned char byte = strips[n][y];
				if (y == 0) {
					byte |= START_BIT;
					if ((x & 15) == 0)
						strip_start[x/16] = pos;
				}
				if (0 && y+1 < striplen[n] - strip_ol[n] &&
				    strips[n][y] == strips[n][y+1]) {
					byte |= TWICE_BIT;
					y++;
				}
				strip_data[pos++] = byte;
			}
			// get next n
			if (strip_ol[n] && strip_ren[strip_pair[n]] == 255) {
				n = strip_pair[n];
			} else if (x < stripcount-1) {
				for (n = 0; n < stripcount; n++) {
					if (strip_ren[n] != 255)
						continue;
					// find a n that none refer to
					for (y = 0; y < stripcount; y++)
						if (strip_pair[y] == n) {
							break;
					}
					if (y == stripcount)
						break;
				}
				if (n == stripcount) {
					int min_ol = 255;
					for (y = 0; y < stripcount; y++) {
						int z = strip_pair[y];
						if (strip_ren[z] != 255)
							continue;
						//fprintf(stderr, "%d -> %d  ol=%d\n", y, z, strip_ol[z]);
						if (min_ol > strip_ol[z]) {
							n = z;
							min_ol = strip_ol[z];
						}
					}
				}
				if (n == stripcount)
					fprintf(stderr, "failed to find strip\n");
			}
		}
		fprintf(stderr, "strip table: %d bytes\n", pos);
		
		int i;
		// write 2k screen idx's
		for (i = 0; i < 16*16*8; i++) {
			fputc(strip_ren[strip_idx[i]], stdout);
		}
		// write 16 cave idx's
		for (i = 0; i < 48; i++) {
			fputc(strip_ren[cave_idx[i]], stdout);
		}
		// write strip offsets
		for (i = 0; i < 16; i++) {
			fputc(strip_start[i] >> 8, stdout);
			fputc(strip_start[i] & 0xff, stdout);
		}
		// write strips data
		fwrite(strip_data, 1, pos, stdout);
		

		
	}
	if(!metamap) {	
		int i;	
		for (i = 0; i < 128; i++) {
			//fprintf(stderr, "0x%02x,", palette[i]);
			fprintf(stderr, ">%02X,", palette[i]);
			if ((i&15) == 15) fprintf(stderr, "\n");
		}
	}
				
	if (f) fclose(f);
	return 0;
}

