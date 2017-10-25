#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int svg2png_main (int argc, char **argv);

int main (int argc, const char * argv[])
{
	char *args[7];
	
	switch (argc) {
		case 3:
			args[0] = "svg2png";
			args[1] = (char *)argv[1];
			args[2] = (char *)argv[2];
			svg2png_main(3, args);
		break;
		case 5:
			args[0] = "svg2png";
			args[1] = "-w";
			args[2] = (char *)argv[3];
			args[3] = "-h";
			args[4] = (char *)argv[4];
			args[5] = (char *)argv[1];
			args[6] = (char *)argv[2];
			svg2png_main(7, args);
		break;
	}
	
	return 0;
}
