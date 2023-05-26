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
    unsigned char fillColor[4];
} fillContext;

/*!
	@function	bucketFill
	@discussion	Given a seed point replaces all neighbouring pixels of similar
				colours with a single given colour. The function does not work
				on the bitmap directly but instead on an overlay which can later
				be composited on to the bitmap.
	@param		rect
				The bounding rect for the fill.
	@param		op
				The operation to check for cancellation.
	@result		Returns the smallest possible IntRect including all affected
				pixels.
*/
IntRect bucketFill(fillContext *ctx,IntRect rect,NSOperation *op);
IntRect bucketFillAll(fillContext *ctx,IntRect rect,NSOperation *op);
BOOL inTolerance(unsigned char *base,unsigned char *color,unsigned char tolerance,int channel);
BOOL shouldFill(fillContext *ctx,int x,int y);

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
void smudgeFill(IntRect rect, unsigned char *layerData, unsigned char *data, int width, int height, unsigned char *accum, unsigned char *temp, unsigned char *mask, int brushWidth,int brushHeight, int rate, bool *noMoreBlur);
void blitImage(CGContextRef dst,vImage_Buffer *iBuf,IntRect r,unsigned char opacity);
