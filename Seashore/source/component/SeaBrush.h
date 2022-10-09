#import "Seashore.h"

/*!
	@class      SeaBrush
	@abstract   Represents a single brush.
*/
@interface SeaBrush : NSObject {
	
	// A grayscale mask of the brush
    unsigned char *mask;

	// A coloured pixmap of the brush (RGBA)
	unsigned char *pixmap;

    CGImageRef bitmap;
    CGImageRef maskImg;

	// The spacing between brush strokes
	int spacing;
	
	// The width and height of the brush
	int width;
	int height;
	
	// The name of the brush
	NSString *name;
	
	// Do we use the pixmap or the mask?
	BOOL usePixmap;
}

/*!
	@method		initWithContentsOfFile:
	@discussion	Initializes an instance of this class with the given ".gbr"
				file.
	@param		path
				The path of the file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithContentsOfFile:(NSString *)path;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		name
	@discussion	Returns the name of the brush.
	@result		Returns an NSString representing the name of the brush.
*/
- (NSString *)name;

/*!
	@method		spacing
	@discussion	Returns the default spacing between brush plots.
	@result		Returns an integer specifying the default spacing between brush
				plots  in pixels).
*/
- (int)spacing;

/*!
	@method		width
	@discussion	Returns the width of the original brush bitmap (i.e. that
				returned  by mask or pixmap).
	@result		Returns the width of the original brush bitmap in pixels.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the height of the original brush bitmap (i.e. that
				returned  by mask or pixmap).
	@result		Returns the height of the original brush bitmap in pixels.
*/
- (int)height;

/*!
 @method        isPixMap
 @result        Returns true if the brush is a pixmap (i.e. colored) brush
 */
- (bool)isPixMap;

/*!
	@method		compare:
	@discussion	Compares two brushes to see which should come first in the brush
				utility (comparisons are currently based on the brush's name).
	@param		other
				The other brush with which to compare this brush.
	@result		Returns an NSComparisonResult.
*/
- (NSComparisonResult)compare:(id)other;

-(void)drawBrushAt:(NSRect)rect;

-(CGImageRef)bitmap;

/*!
 @method        mask
 @discussion    Returns the alpha mask for a greyscale brush.
 @result        Returns a reference to an 8-bit single-channel bitmap.
 */
- (unsigned char *)mask;

@end
