/*!
	@header		SeaBrushFuncs
	@abstract	Determines the anti-aliased brush masks.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import "Seashore.h"

#define kSubsampleLevel 4

void determineBrushMask(unsigned char *input, unsigned char *output, int width, int height, int index1, int index2);

/*!
   @method scaleAndCenterMask
   @discussion the scaled and source must be width x height bytes
 */
void scaleAndCenterMask(unsigned char *scaled,int scalew,int scaleh,unsigned char *source,int width,int height);

