/*!
	@header		SeaBrushFuncs
	@abstract	Determines the anti-aliased brush masks.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import "Globals.h"

#define kSubsampleLevel 4

void determineBrushMask(unsigned char *input, unsigned char *output, int width, int height, int index1, int index2);

void arrangePixels(unsigned char *dest, int destWidth, int destHeight, unsigned char *src, int srcWidth, int srcHeight);
