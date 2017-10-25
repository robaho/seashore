#import "Globals.h"
#import "SeaBrushFuncs.h"

/*!
	@struct		CachedMask
	@discussion	Specifies a cached mask entry.
	@param		index1
				The corresponding horizontal subsample entry.
	@param		index2
				The corresponding horizontal subsample entry.
	@param		scale
				The corresponding scaling entry (major axis).
	@param		lastCheck
				The time the entry was last used.
*/
typedef struct {
	unsigned char *cache;
	int index1;
	int index2;
	int scale;
	int lastCheck;
} CachedMask;

/*!
	@defined	kBrushCacheSize
	@discussion	Specifies the number of brush masks to keep in the cache.
*/
#define kBrushCacheSize 25

/*!
	@class		SeaBrush
	@abstract	Represents a single GIMP brush.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaBrush : NSObject {
	
	// A grayscale mask of the brush
	unsigned char *mask, *scaled, *positioned;
	BOOL maskLibraryValid;
	
	// A cache of all the brushes
	CachedMask *maskCache;
	int checkCount;
	
	// A coloured pixmap of the brush (RGBA)
	unsigned char *pixmap;
	
	// A premultiplied colour pixmap of the brush (RGBA)
	unsigned char *prePixmap;
	
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
	@method		activate
	@discussion	Activates the brush.
*/
- (void)activate;

/*!
	@method		deactivate
	@discussion	Deactivates the brush.
*/
- (void)deactivate;

/*!
	@method		pixelTag
	@discussion	Returns a string indicating the size of oversize brushes.
	@result		Returns a string indicating the size of oversize brushes or NULL
				if such a string is not required.
*/
- (NSString *)pixelTag;

/*!
	@method		thumbnail
	@discussion	Returns a thumbnail of the brush.
	@result		Returns an NSImage that is no greater in size than 44 by 44
				pixels.
*/
- (NSImage *)thumbnail;

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
	@method		fakeWidth
	@discussion	Returns the width of the anti-aliased brush bitmaps (i.e. those
				returned by maskForPoint: or pixmapForPoint:).
	@result		Returns the width of the anti-aliased brush bitmaps in pixels.
*/
- (int)fakeWidth;

/*!
	@method		fakeHeight
	@discussion	Returns the height of the anti-aliased brush bitmaps (i.e. those
				returned by maskForPoint: or pixmapForPoint:).
	@result		Returns the height of the anti-aliased brush bitmaps in pixels.
*/
- (int)fakeHeight;

/*!
	@method		mask
	@discussion	Returns the alpha mask for a greyscale brush.
	@result		Returns a reference to an 8-bit single-channel bitmap.
*/
- (unsigned char *)mask;

/*!
	@method		pixmap
	@discussion	Returns the pixmap for a full-coloured brush.
	@result		Returns a reference to a 8-bit RGBA bitmap.
*/
- (unsigned char *)pixmap;

/*!
	@method		maskForPoint:
	@discussion	Returns an alpha mask for the specified point, the mask varies
				according to the fractional part of the point.
	@param		point
				An NSPoint at which the mask is being plotted.
	@param		pressure
				An integer representing the pressure.
	@result		Returns a reference to an 8-bit single-channel bitmap.
*/
- (unsigned char *)maskForPoint:(NSPoint)point pressure:(int)value;

/*!
	@method		pixmapForPoint:
	@discussion	Returns the same as pixmap, is made available in case future
				versions wish to adopt anti-aliasing.
	@param		point
				Ignored.
	@result		Returns a reference to an 8-bit RGBA bitmap.
*/
- (unsigned char *)pixmapForPoint:(NSPoint)point;

/*!
	@method		usePixmap
	@discussion	Returns whether the brush uses a pixmap or an alpha mask. A
				brush either uses one or the other, calls to mask or
				maskForPoint: are invalid if the brush uses a pixmap and
				vice-versa.
	@result		Returns YES if the brush uses a pixmap, NO otherwise.
*/
- (BOOL)usePixmap;

/*!
	@method		compare:
	@discussion	Compares two brushes to see which should come first in the brush
				utility (comparisons are currently based on the brush's name).
	@param		other
				The other brush with which to compare this brush.
	@result		Returns an NSComparisonResult.
*/
- (NSComparisonResult)compare:(id)other;

@end
