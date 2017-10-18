/* DAN2 Encoder - Decoder
 * ------------
 * HISTORY
 * 20170106 - BETA - ENCODER HANDLE UP TO 16 BITS OFFSETS
 * 20170106 - BETA - DECODER WITH UNSIGNED VALUES
 * 20170101 - BETA - CODE CLEAN UP
 * 20161231 - ALPHA - REMOVE RLE SUPPORT (SMALLER DECOMPRESSION ROUTINE)
 * 20161231 - ALPHA - SET VARIABLE NUMBER OF BITS FOR HIGH-VALUE OFFSETS, DEFAULT 10
 * 20161211 - ALPHA - FIRST DRAFT BASED ON DAN1 BETA 20160725
 */
#include <stdio.h> /* printf, file */
#include <stdlib.h> /* exit */
#include <unistd.h> /* getopt */
#include <string.h> /* memcpy, memset */
#include <ctype.h> /* tolower */
/*
 * - AUTHOR'S NAME -
 */
#define AUTHOR "Daniel Bienvenu aka NewColeco"
/*
 * - PROGRAM TITLE -
 */
#define PRGTITLE "DAN2 (de)Compression Tool"
/*
 * - VERSION NUMBER -
 */
#define VERSION "BETA-20170106"
/*
 * - YEAR -
 */
#define YEAR "2017"
/*
 * - FILE EXTENSION -
 */
#define EXTENSION ".dan2"
/*
 * - FORMAT NAME -
 */
#define FORMATNAME "DAN2"
/*
 * - BOOLEAN VALUES -
 */
#define TRUE -1
#define FALSE 0
/*
 * - MAX INPUT FILE SIZE -
 */
#define MAX 512*1024
/*
 * - COMPRESSION CONSTANTS -
 */
#define MAX_ELIAS_GAMMA (1<<16)
#define MAX_LEN (1<<16)-1
#define BIT_OFFSET1 1
#define BIT_OFFSET2 4
#define BIT_OFFSET3 8
#define BIT_OFFSET4_MIN 10
#define BIT_OFFSET4_MAX 16
#define MAX_OFFSET1 (1<<BIT_OFFSET1)
#define MAX_OFFSET2 MAX_OFFSET1 + (1<<BIT_OFFSET2)
#define MAX_OFFSET3 MAX_OFFSET2 + (1<<BIT_OFFSET3)
int MAX_OFFSET4;
int BIT_OFFSET4;
/*
 * - FILE STREAMS -
 */
FILE *infile = NULL, *outfile = NULL;
/*
 * - TABLES, VARIABLES AND DATA STRUCTURES -
 */
long index_wheel = 0;
int infile_index = 0;
int outfile_index = 0;
int reg_A = 128;
int flag_carry = 0;
int flag_zero = 0;
unsigned char data_src[MAX];
unsigned char data_dest[MAX];
unsigned char bit_mask;
int index_src;
int index_dest;
int bit_index;
struct t_match
	{
		int index;
		struct t_match *next;
	};
struct t_match matches[65536];
struct t_optimal
	{
		int bits; /* COST */
		int offset;
		int len;
	} optimals[MAX];
/*
 * - OPTIONS FLAGS -
 */
int bVerbose = FALSE;
int bYes = FALSE;
int bFAST = FALSE;
/* - NEW -
 * - UPDATE MAXOFFSET4 -
 */
int bitsboundaries(int bits)
{
	if (bits<BIT_OFFSET4_MIN) bits = BIT_OFFSET4_MIN;
	if (bits>BIT_OFFSET4_MAX) bits = BIT_OFFSET4_MAX;
	return bits;
}
void update_maxoffset4(int bits)
{
	/* Update OFFSET4 BIT and MAX values */
	BIT_OFFSET4 = bits;
	MAX_OFFSET4 = MAX_OFFSET3 + (1<<BIT_OFFSET4);
}
/*
 * - HELP (EXIT) -
 */
void help(void)
{
	fprintf(stderr,"\nFor help use -h option\n");
	fprintf(stderr,"Press Enter to exit.\n");
	getchar();
	exit(0);
}
/*
 * - RESET DATA -
 */
void reset_data()
{
	index_src = 0;
	index_dest = 0;
	bit_mask = 0;
}
/*
 * - FILE EXITS -
 */
int file_exits(char *filename)
{
	int exists;
	FILE *file = NULL;
	file = fopen(filename, "r");
	exists = (file != NULL);
	fclose(file);
	return(exists);
}
/*
 * - FILE SIZE -
 */
long file_size(FILE *file)
{
	long size;
	fseek(file, 0l, SEEK_END);
	size = ftell(file);
	fseek(file, 0l, SEEK_SET);
	/* rewind(file);*/
	return size;
}
/*
 * - YES OR NO -
 */
int yesno ()
{
	char cYesNo;
	do
		{
			scanf(" %c", &cYesNo);
			cYesNo = tolower(cYesNo);
		}
	while (cYesNo != 'n' && cYesNo != 'y');
	return (cYesNo == 'y');
}
/*
 * - ASK IF OVERWRITE OUTPUT FILE -
 */
void ask_overwrite(char *filename)
{
	if (bYes == FALSE && file_exits(filename))
		{
			fprintf(stderr,"Overwrite output file %s? (y or n): ", filename);
			if (!yesno())
				{
					fprintf(stderr,"Program terminated.\n");
					exit(0);
				}
		}
}
/*
 * - LOW BYTE VALUE -
 */
int mask_byte(int value)
{
	return (value & 0x000000FF);
}
/*
 * - FWRITE BYTE -
 */
int fwrite_byte(int c)
{
	c = mask_byte(c);
	data_dest[index_wheel] = (unsigned char) c;
	index_wheel++;
	outfile_index++;
	if (index_wheel == MAX) index_wheel = 0;
	return fputc(c, outfile);
}
/*
 * - ERROR MESSAGE (EOF) -
 */
void error(void)
{
	fprintf(stderr,"Output error\n");
	exit(1);
}
/*
 * - FREAD BYTE -
 */
int fread_byte()
{
	int c;
	c = fgetc(infile);
	infile_index++;
	if (bVerbose) fprintf(stderr,"\rScan : %d bytes", (infile_index));
	if (c == EOF) error();
	return mask_byte(c);
}
/*
 * - WRITE DATA -
 */
void write_byte(unsigned char value)
{
	data_dest[index_dest++] = value;
}
void write_bit(int value)
{
	if (bit_mask == 0)
		{
			bit_mask  = (unsigned char) 128;
			bit_index = index_dest;
			write_byte((unsigned char) 0);
		}
	if (value) data_dest[bit_index] |= bit_mask;
	bit_mask >>= 1 ;
}
void write_bits(int value, int size)
{
	int i;
	int mask = 1;
	for (i = 0 ; i < size ; i++)
		{
			mask <<= 1;
		}
	while (mask > 1)
		{
			mask >>= 1;
			write_bit (value & mask);
		}
}
void write_elias_gamma(int value)
{
	int i;
	for (i = 2; i <= value; i <<= 1)
		{
			write_bit(0);
		}
	while ((i >>= 1) > 0)
		{
			write_bit(value & i);
		}
}
void write_offset(int value, int option)
{
	value--;
	if (value >= MAX_OFFSET3)
		{
			write_bit(1);
			value -= (MAX_OFFSET3);
			write_bits((value >> 8), BIT_OFFSET4 - 8);
			write_byte((unsigned char) (value & 0x000000ff));
		}
	else if (value >= MAX_OFFSET2)
		{
			if (option > 2) write_bit(0);
			write_bit(1);
			value -= (MAX_OFFSET2);
			write_byte((unsigned char) (value & 0x000000ff));
		}
	else if (value >= MAX_OFFSET1)
		{
			if (option > 2) write_bit(0);
			if (option > 1) write_bit(0);
			write_bit(1);
			value -= MAX_OFFSET1;
			write_bits(value, BIT_OFFSET2);
		}
	else
		{
			if (option > 2) write_bit(0);
			if (option > 1) write_bit(0);
			write_bit(0);
			write_bits(value, BIT_OFFSET1);
		}
}
void write_doublet(int length, int offset)
{
	int i;
	write_bit(0);
	write_elias_gamma(length);
	write_offset(offset, length);
}
void write_end()
{
	write_bit(0);
	write_bits(0, 16);
}
void write_literal(unsigned char c)
{
	write_bit(1);
	write_byte(c);
}
void write_destination()
{
	int c;
	int index = 0;
	while (index < index_dest)
		{
			c = (int) data_dest[index++];
			fputc(c, outfile);
		}
}
void write_lz()
{
	int i, j;
	int index;
	int bits = BIT_OFFSET4;
	fprintf(stderr,"MAXIMUM OFFSET SIZE IS %d BITS\n",bits);
	/* WRITE OFFSET4 BIT SIZE */
	bits += - BIT_OFFSET4_MIN + 1;
	write_bits(0xFE, bits);
	/* FIRST IS LITERAL */
	write_byte(data_src[0]);
	for (i = 1;i < index_src;i++)
		{
			if (optimals[i].len > 0)
				{
					index = i -  optimals[i].len + 1;
					if (optimals[i].offset == 0)
						{
							write_literal(data_src[index]);
						}
					else
						{
							write_doublet(optimals[i].len, optimals[i].offset);
						}
				}
		}
	write_end();
	write_destination();
}
/*
 * - READ DATA -
 */
void read_source()
{
	int c;
	index_src = 0;
	while (1)
		{
			c = fgetc(infile);
			if (c == EOF) break;
			data_src[index_src++] = (unsigned char) (c & 0x000000ff);
		}
}
/*
 * - INITIALIZE MATCHES TABLE -
 */
void reset_matches(void)
{
	int i;
	for (i = 0;i < 65536;i++)
		{
			matches[i].next = NULL;
		}
}
/*
 * - INSERT A MATCHE IN TABLE -
 */
void insert_match(struct t_match *match, int index)
{
	struct t_match *new_match = (struct t_match *) malloc( sizeof(struct t_match) );
	new_match->index = match->index;
	new_match->next = match->next;
	match->index = index;
	match->next = new_match;
}
/*
 * - REMOVE MATCHE(S) FROM MEMORY -
 */
void flush_match(struct t_match *match)
{
	struct t_match *node;
	struct t_match *head = match->next;
	while ((node = head) != NULL)
		{
			head = head->next;
			free(node);
		}
	match->next = NULL;
}
/*
 * - FREE MATCHE(S) FROM TABLE -
 */
void free_matches(void)
{
	int i;
	for (i = 0;i < 65536;i++)
		{
			flush_match(&matches[i]);
		}
}
/*
 * - ELIAS GAMMA -
 */
int elias_gamma_bits(int value)
{
	int bits = 1;
	while (value > 1)
		{
			bits += 2;
			value >>= 1;
		}
	return bits;
}
/*
 * - CALCULATE BITS COST -
 */
int count_bits(int offset, int len)
{
	int offset_bits;
	int bits = 1 + elias_gamma_bits(len);
	if (len == 1) return bits + 1 + (offset > MAX_OFFSET1 ? BIT_OFFSET2 : BIT_OFFSET1);
	if (len == 2) return bits + 1 + (offset > MAX_OFFSET2 ? BIT_OFFSET3 : 1 + (offset > MAX_OFFSET1 ? BIT_OFFSET2 : BIT_OFFSET1));
	return bits + 1 + (offset > MAX_OFFSET3 ? BIT_OFFSET4 : 1 + (offset > MAX_OFFSET2 ? BIT_OFFSET3 : 1 + (offset > MAX_OFFSET1 ? BIT_OFFSET2 : BIT_OFFSET1)));
}
/*
 * - REMOVE USELESS FOUND OPTIMALS -
 */
void cleanup_optimals()
{
	int j;
	int i = index_src - 1;
	int len;
	while (i > 1)
		{
			len = optimals[i].len;
			for (j = i - 1; j > i - len;j--)
				{
					optimals[j].offset = 0;
					optimals[j].len = 0;
				}
			i = i - len;
		}
}
/*
 * - PRINT OUT LZ LISTING -
 */
void print_lz(int limit)
{
	int i;
	int counter = 0;
	for (i = 0;i < index_src;i++)
		{
			if (optimals[i].len > 0)
				{
					counter++;
					if (counter < limit)
						{
							if (optimals[i].offset == 0)
								{
									fprintf(stderr,"%d\t: RAW\t%d BYTE(S)\n", (i -  optimals[i].len + 1) , optimals[i].len);
								}
							else
								{
									fprintf(stderr,"%d\t: COPY\t%d BYTE(S) FROM %d ( -%d )\n", (i - optimals[i].len + 1), optimals[i].len, (i - optimals[i].len + 1 - optimals[i].offset), optimals[i].offset);
								}
						}
					else break;
				}
		}
}
/*
 * - LZSS COMPRESSION -
 */
void lzss()
{
	int i, j, k;
	int temp_bits;
	struct t_match *match;
	int len, best_len, old_best_len;
	int offset;
	int match_index;
	optimals[0].bits = 8; /* FIRST ALWAYS LITERAL */
	optimals[0].offset = 0;
	optimals[0].len = 1;
	for (i = 1;i < index_src;i++)
		{
			if (bVerbose) fprintf(stderr,"\rScan : %d bytes", (i + 1));
			/* TRY LITERALS */
			optimals[i].bits = optimals[i-1].bits + 1 + 8;
			optimals[i].offset = 0;
			optimals[i].len = 1;
			/* LZ MATCH OF ONE : LEN = 1 */
			j = MAX_OFFSET2;
			if (j > i) j = i;
			/* temp_bits = optimals[i-1].bits + 1+1+1+2; */
			for (k = 1; k <= j; k++)
				{
					/* if (k==5) temp_bits += 3; */
					if (data_src[i] == data_src[i-k])
						{
							temp_bits = optimals[i-1].bits + count_bits(k, 1);
							if (temp_bits < optimals[i].bits)
								{
									optimals[i].bits = temp_bits;
									optimals[i].len = 1;
									optimals[i].offset = k;
									break;
								}
						}
				}
			/* LZ MATCH OF TWO OR MORE : LEN = 2, 3 , 4 ... */
			match_index = ((int) data_src[i-1]) << 8 | ((int) data_src[i] & 0x000000ff);
			match = &matches[match_index];
			best_len = 1;
			for (/* match = &matches[match_index] */; match->next != NULL && best_len < MAX_LEN; match = match->next)
				{
					offset = i - match->index;
					if (offset > MAX_OFFSET4)
						{
							flush_match(match);
							break;
						}
					for (len = 2;len <= MAX_LEN;len++)
						{
							if (len > best_len)
								{
									if (!(len == 2 && offset > MAX_OFFSET3))
										{
											best_len = len;
											temp_bits = optimals[i-len].bits + count_bits(offset, len);
											if (optimals[i].bits > temp_bits)
												{
													optimals[i].bits = temp_bits;
													optimals[i].offset = offset;
													optimals[i].len = len;
												}
										}
								}
							if (i < offset + len || data_src[i-len] != data_src[i-len-offset])
								{
									break;
								}
						}
					/* SKIP SOME TESTS */
					if (bFAST)
						{
							if (len > 6 && len == best_len - 1 && match->index == match->next->index + 1)
								{
									j = 1;
									while (match->next != NULL)
										{
											match = match->next;
											if (i - match->index > MAX_OFFSET4)
												{
													flush_match(match);
													break;
												}
											j++;
											if (j == len)
												{
													break;
												}
										}
									if (match->next == NULL) break;
								}
						}
				}
			insert_match(&matches[match_index], i);
		}
	fprintf(stderr,"\nscan done.\n\n");
	len = (optimals[index_src-1].bits + 17 + 7) / 8;
	cleanup_optimals();
	if (bVerbose)
		{
			fprintf(stderr,"\nPrint LZ listing first lines? (for educational purpose): ");
			if (yesno()) print_lz(200);
			fprintf(stderr,"\nSave.\n");
		}
	write_lz();
}
/*
 * - DAN1 ENCODING SCRIPT -
 */
void encode(void)
{
	/* Read Source data */
	read_source();
	/* Initialize Matches Array */
	reset_matches();
	/* Apply compression */
	lzss();
	free_matches();
	index_dest = optimals[index_src-1].bits += 1 + 16 + 1 + 7;
	index_dest /= 8;
	/* Print Results */
	fprintf(stderr,"\t     source:\t%d bytes\n", index_src);
	fprintf(stderr,"\tdestination:\t%d bytes (%d%%)\n",
	       index_dest, (index_dest * 100) / index_src);
}
/*
 * - DECODER ROUTINES -
 */
void update_flags()
{
	flag_carry = ((reg_A & 0x100) == 0 ? 0 : 1);
	reg_A = mask_byte(reg_A);
	flag_zero = (reg_A == 0);
}
void reset_carry_flags()
{
	flag_carry = 0;
}
void sla()
{
	reg_A = reg_A << 1;
	update_flags();
}
void read_bit()
{
	sla();
	if (flag_zero)
		{
			reg_A = fread_byte();
			sla();
			reg_A |= 1;
		}
}
int read_elias_gamma()
{
	int i;
	int counter = 0;
	int elias_gamma = 1;
	reset_carry_flags();
	while (flag_carry == 0)
		{
			read_bit();
			counter++;
			if (counter == 17) break;
		}
	if (counter < 17)
		{
			for (i = 1;i < counter;i++)
				{
					read_bit();
					elias_gamma <<= 1;
					if (flag_carry) elias_gamma |= 1;
				}
		}
	else
		{
			elias_gamma = 0;
		}
	return elias_gamma;
}
int read_bits(int bits)
{
	int i, c = 0;
	for (i = 0;i < bits;i++)
		{
			read_bit();
			c <<= 1;
			if (flag_carry) c |= 1;
		}
	return c;
}
int read_offset(int option)
{
	int i;
	int offset_hi = 0;
	int offset;
	if (option > 2)
		{
			read_bit();
			if (flag_carry)
				{
					offset_hi = read_bits(BIT_OFFSET4 - 8);
					offset = fread_byte();
					offset = (offset_hi << 8) + offset;
					offset +=MAX_OFFSET3;
					return offset;
				}
		}
	if (option > 1)
		{
			read_bit();
			if (flag_carry)
				{
					offset = fread_byte() + MAX_OFFSET2;
					return offset;
				}
		}
	read_bit();
	if (flag_carry)
		{
			offset = read_bits(4) + MAX_OFFSET1;
		}
	else
		{
			read_bit();
			offset = ( flag_carry ? 1 : 0);
		}
	return offset;
}
void decode(void)
{
	int i;
	int c;
	unsigned int lenght;
	unsigned int offset;
	unsigned int index;
	int bits = BIT_OFFSET4_MIN;
	/* Decode number of bits for OFFSET4 */
maxoffsetbit:
	read_bit();
	if (flag_carry == 1)
		{
			bits++;
			goto maxoffsetbit;
		}
	if (bits > BIT_OFFSET4_MAX) error();
	update_maxoffset4(bits);
	fprintf(stderr,"MAXIMUM OFFSET SIZE IS %d BITS\n",bits);
	/* First byte is literal */
literal:
	c = fread_byte();
	fwrite_byte(c);
	/* LZ loop */
lz_loop:
	read_bit();
	if (flag_carry == 1) goto literal;
	lenght = read_elias_gamma();
	if (lenght != 0)
		{
			offset = read_offset(lenght);
			index = index_wheel - offset - 1;
			for (i = 0;i < lenght;i++)
				{
					c = (int) data_dest[index++];
					fwrite_byte(c);
					/*
					if (index == MAX) index = 0;
					*/
				}
			goto lz_loop;
		}
	/* Print Results */
	if (bVerbose)
		{
			fprintf(stderr,"\n\t     source:\t%d bytes\n", infile_index);
			fprintf(stderr,"\tdestination:\t%d bytes\n", outfile_index);
		}
}
/*
 * - SET FILE EXTENSION TO OUTPUT FILENAME -
 */
char *newfilepath(char* filepath)
{
	size_t len1 = strlen(filepath), len2 = strlen(EXTENSION);
	char *concat = (char*) malloc(len1 + len2 + 1);
	memcpy(concat, filepath, len1);
	memcpy(concat + len1, EXTENSION, len2 + 1);
	return concat;
}
/*
 * - MAIN -
 */
int main(int argc, char *argv[])
{
	char *sInput = NULL;
	char *sOutput = NULL;
	char c;
	int bDecode = FALSE;
	int maxbits = BIT_OFFSET4_MIN+1;
	/*
	 * - PROGRAM TITLE AND VERSION -
	 */
	fprintf(stderr,"%s Version %s\n", PRGTITLE, VERSION);
	fprintf(stderr,"by %s, %s\n\n", AUTHOR, YEAR);
	fprintf(stderr,"Warning : input file size limit of %d bytes\n\n", MAX);
	/*
	 * - EXTRACT COMMAND LINE OPTIONS -
	 */
	while ((c = getopt(argc, argv, "dhvyfm:i:o:")) != -1)
		{
			switch (c)
				{
				case 'h':
					fprintf(stderr,"This compress data using %s format.\n",FORMATNAME);
					fprintf(stderr,"Usage : %s [options] -i input -o output\n",argv[0]);
					fprintf(stderr,"    -i filename : Input file name\n");
					fprintf(stderr,"    -o filename : Output file name\n");
					fprintf(stderr,"    -m # : maximum number of bits for high offset from %d to %d (default %d)\n",BIT_OFFSET4_MIN,BIT_OFFSET4_MAX,BIT_OFFSET4);
					fprintf(stderr,"    -d   : decode %s file\n",EXTENSION);
					fprintf(stderr,"    -f   : fast compression (less optimization)\n");
					fprintf(stderr,"    -h   : show this Help\n");
					fprintf(stderr,"    -v   : verbose\n");
					fprintf(stderr,"    -y   : auto-answer Yes to overwrite output file if exists\n");
					help();
				case 'i':
					sInput = optarg;
					break;
				case 'o':
					sOutput = optarg;
					break;
				case 'm':
					maxbits = bitsboundaries(atoi(optarg));
					break;
				case 'f':
					bFAST = TRUE;
					break;
				case 'd':
					bDecode = TRUE;
					break;
				case 'v':
					bVerbose = TRUE;
					break;
				case 'y':
					bYes = TRUE;
					break;
				case '?':
					if (optopt == 'i' || optopt == 'o' || optopt == 'm')
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					else
						fprintf(stderr, "Unknown option -%c.\n", optopt);
					help();
				default:
					abort();
					break;
				}
		}
	/*
	 * - SET MAX BITS FOR BIG OFFSET VALUES -
	 */
	update_maxoffset4(maxbits);
	/*
	 * - OPEN FILES -
	 */
	if (sInput == NULL)
		{
			if (optind < argc)
				{
					sInput = argv[optind];
				}
			else
				{
					//fprintf(stderr,"Missing input file specification\n");
					//help();
					infile = stdin;
				}
		}
	if (bVerbose) fprintf(stderr,"> input file : %s\n", sInput);
	if (infile == NULL && (infile  = fopen(sInput, "rb")) == NULL)
		{
			fprintf(stderr,"? %s\n", sInput);
			return 1;
		}
	if (sOutput == NULL)
		{
			if (bDecode)
				{
					//fprintf(stderr,"Missing output file specification\n");
					//help();
				}
			if (sInput == NULL)
				outfile = stdout;
			else
				sOutput = newfilepath(sInput);
		}
	if (bVerbose) fprintf(stderr,"> output file : %s\n", sOutput);
	if (sOutput) ask_overwrite(sOutput);
	if (outfile == NULL && (outfile  = fopen(sOutput, "wb")) == NULL)
		{
			fprintf(stderr,"? %s\n", sOutput);
			return 1;
		}
	/*
	 * - ENCODE -
	 */
	if (bDecode) decode();
	else encode();
	/*
	 * - CLOSE FILES -
	 */
	if (infile != stdin) fclose(infile);
	if (outfile != stdout) fclose(outfile);
	/*
	 * - END -
	 */
	if (bVerbose) fprintf(stderr,"Done.\n");
	return 0;
}

