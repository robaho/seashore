#import "Globals.h"

/*!
	@header		CIAffineTransformClass
	@abstract	Applies a triangle effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

@interface CIAffineTransformClass : NSObject {

}

/*!
	@method		runAffineTransform:withImage:spp:width:height:
	@discussion	Completes an affine transform of the image returning a freshly allocated bitmap with the result.
				The initial image is left untouched. Useful if Seashore wants to run affine transforms using
				CoreImage.
	@param		at
				The affine transform.
	@param		data
				The bitmap data to work with.
	@param		spp
				The samples per pixel of the bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		opaque
				A boolean that is YES if the image is opaque (speeds up processing).
	@param		newWidth
				The width of the returned bitmap.
	@param		newHeight
				The height of the returned bitmap.
	@result		Returns the resulting bitmap (must be freed by user).
*/
- (unsigned char *)runAffineTransform:(NSAffineTransform *)at withImage:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height opaque:(BOOL)opaque newWidth:(int *)newWidth newHeight:(int *)newHeight;

@end
