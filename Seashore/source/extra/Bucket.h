/*!
	@header		Bucket
	@abstract	Contains functions to help with bucket fills. 
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
				Copyright (c) 2005 Daniel Jalkut
*/

#import "Seashore.h"
#include <Accelerate/Accelerate.h>


typedef struct {
    unsigned char *overlay;
    unsigned char *data;
    IntPoint *seeds;
    int numSeeds;
    int tolerance;
    int channel;
    int width,height;
} fillContext;

/*!
	@function	bucketFill
	@discussion	Given a seed point replaces all neighbouring pixels of similar
				colours with a single given colour. The function does not work
				on the bitmap directly but instead on an overlay which can later
				be composited on to the bitmap.
	@param		rect
				The largest region of the bitmap to fill (must lie entirely
				within bitmap).
	@param		overlay
				The block of memory containing the overlay data. Rather than
				change pixels of the bitmap directly, changes will be made to
				this block which can then be manipulated.
	@param		data
				The block of memory containing the bitmap data.
	@param		width
				The width of both the bitmap and overlay.
	@param		height
				The height of both the bitmap and overlay.
	@param		seeds
				The seed points at which to begin filling.
	@param		numSeeds
				The number of seed points in the array.
	@param		fillColor
				The colour with which to replace the various pixels.
	@param		tolerance
				Pixels will only be replaced if their channel(s) are within this
				tolerance of the seed point. A tolerance of 255 indicates that
				all pixels should be replaced in the given rectangle (bucketFill
				works much faster on such calls).
	@param		channel
				The channel(s) to use in determining whether a pixel meets the
				above condition.
	@result		Returns the smallest possible IntRect including all affected
				pixels.
*/
IntRect bucketFill(fillContext *ctx,IntRect rect,unsigned char *fillColor);
/*!
@function    textureFill
@discussion    Given a bitmap, this function fills the bitmap with the given
texture replacing the bitmap's colour but preserving the
bitmap's transparency. It is often applied to the overlay.
@param        texture
The texture image.
@param        rect
The region of the bitmap to replace with the given texture (must
*/
void textureFill(CGContextRef dst,CGContextRef textureCtx, IntRect rect);
void cloneFill(CGContextRef dst,CGContextRef srcCtx,IntRect rect,IntPoint offset,IntRect srcRect);
BOOL shouldFill(fillContext *ctx,IntPoint point);
void smudgeFill(IntRect rect, unsigned char *layerData, unsigned char *data, int width, int height, unsigned char *accum, unsigned char *temp, unsigned char *mask, int brushWidth,int brushHeight, int rate);
void blitImage(CGContextRef dst,vImage_Buffer *iBuf,IntRect r,unsigned char opacity);
