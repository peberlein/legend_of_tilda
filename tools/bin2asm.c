/* Binary data to asm text DATA statements
 * Use -b for BYTE statements
 */
 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>




int main(int argc, char *argv[])
{
	char line[100];
	int i = 0;
	FILE *f = stdin;
	int byte = 0;
	
	if (argc > 1 && strcmp(argv[1],"-b") == 0) {
		byte = 1;
		argc--;
		argv++;
	}
	
	if (argc > 1 && strcmp(argv[1],"-") != 0) {
		f = fopen(argv[1],"r");
	}
	
	if (!f) {
		fprintf(stderr,"Failed to open %s\n", argv[1]);
		return 0;
	}
	while (!feof(f)) {
		int ch = fgetc(f);

		if (ch < 0)
			break;

		if (i == 0) {
			printf("       %s ", byte ? "BYTE " : "DATA");
		} else {
			printf(",");
		}
		
		printf(">%02x", ch);
		if (!byte) {
			ch = fgetc(f);
			if (ch < 0) ch = 0;
			printf("%02x", ch);
			i++;
		}
		i=(i+1)&15;
		if (i == 0) {
			printf("\n");
		}
	}
	if (i != 0 ) printf("\n");
	fclose(f);
	return 0;
}
