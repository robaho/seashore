#import "Seashore.h"

/*!
	@class		SeaTexture
	@abstract	Represents a single texture.
	@discussion	N/A 
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaTexture : NSObject {

    NSImage *image;

	// The width and height of the texture
	int width;
	int height;
	
	// The name of the texture
	NSString *name;
}

/*!
	@method		initWithContentsOfFile:
	@discussion	Initializes an instance of this class with the given image file.
				The image must be 8-bit, may or may not have an alpha channel in
				either case such a channel is ignored) and must be an RGB or
				greyscale (with white = 255) image.
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
	@discussion	Returns the name of the texture.
	@result		Returns an NSString representing the name of the texture.
*/
- (NSString *)name;

/*!
	@method		width
	@discussion	Returns the width of the texture.
	@result		Returns the width of the texture in pixels.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the height of the texture.
	@result		Returns the height of the texture in pixels.
*/
- (int)height;

- (NSImage*)image;

/*!
	@method		compare:
	@discussion	Compares two brushes to see which should come first in the
				texture utility (comparisons are currently based on the
				texture's name).
	@param		other
				The other texture with which to compare this texture.
	@result		Returns an NSComparisonResult.
*/
- (NSComparisonResult)compare:(id)other;

@end
