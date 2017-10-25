/*!
	@header		StandardMerge
	@abstract	Contains functions to help with the merging of layers, these
				functions are not AltiVec-enabled.
	@discussion	All functions in this header will return immediately if the
				source pixel is transparent or the opacity is zero.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import "Globals.h"

/*!
	@defined	RANDOM_SEED
	@discussion	The value to be used by the dissolve merge technique.
*/
#define RANDOM_SEED      314159265

/*!
	@defined	RANDOM_TABLE_SIZE
	@discussion	The size of the table to be used with the dissolve merge
				technique.
*/
#define RANDOM_TABLE_SIZE  4096

/*!
	@function	replaceMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
 void replaceMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	replacePrimaryMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel but only for the primary channels.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
 void replacePrimaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	replaceAlphaMerge
	@discussion	Given two pixels in two bitmaps replaces the destination pixel
				with the source pixel but only for the alpha channel.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel being replaced.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is replacing.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should replace.
*/
void replaceAlphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	specialMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the special merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
 void specialMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	normalMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the normal merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
 void normalMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	eraseMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the erase merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
 void eraseMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	primaryMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the primary merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
	@param		lazy
				YES if merges to destination pixel whose alpha is zero should be
				skipped, NO otherwise.
*/
 void primaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity, BOOL lazy);

/*!
	@function	alphaMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the alpha merge technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
void alphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
	@function	blendPixel
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using a simple blending technique.
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		blend
				The amount of blending to go on (between 0 and 255 inclusive).
*/
 void blendPixel(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int blend);

/*!
	@function	selectMerge
	@discussion	Given two pixels in two bitmaps composites the source pixel on
				to the destination pixel using the selected merge technique.
				Note for XCF_DISSOLVE_MODE you must call srandom(randomTable[y %
				4096]); for (k = 0; k < x; k++)  random();" for the merge to
				work correctly.
	@param		choice
				The selected merge technique (see Constants documentation).
	@param		spp
				The samples per pixel of the bitmaps (can be 2 or 4).
	@param		destPtr
				The block of memory containing the pixel upon which the source
				pixel is being composited.
	@param		destLoc
				The position in that block of the pixel.
	@param		srcPtr
				The block of memory containing the pixel which is being
				composited.
	@param		srcLoc
				The position in that block of the pixel.
	@param		srcOpacity
				The opacity with which the source pixel should be composited.
*/
 void selectMerge(int choice, int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc);

