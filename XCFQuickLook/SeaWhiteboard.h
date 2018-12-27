#import "Globals.h"
#import "SeaCompositor.h"

/*!
	@enum		k...ChannelsView
	@constant	kAllChannelsView
				Indicates that all channels are being viewed.
	@constant	kPrimaryChannelsView
				Indicates that just the primary channel(s) are being viewed.
	@constant	kAlphaChannelView
				Indicates that just the alpha channel is being viewed.
	@constant	kCMYKPreviewView
				Indicates that all channels are being viewed in CMYK previewing mode.
*/
enum {
	kAllChannelsView,
	kPrimaryChannelsView,
	kAlphaChannelView,
	kCMYKPreviewView
};


/*!
	@enum		k...Behaviour
	@constant	kNormalBehaviour
				Indicates the overlay is to be composited on to the underlying layer.
	@constant	kErasingBehaviour
				Indicates the overlay is to erase the underlying layer.
	@constant	kReplacingBehaviour
				Indicates the overlay is to replace the underling layer where specified.
	@constant	kMaskingBehaviour
				Indicates the overlay is to be composited on to the underlying layer with the
				replace data being used as a mask.
*/
enum {
	kNormalBehaviour,
	kErasingBehaviour,
	kReplacingBehaviour,
	kMaskingBehaviour
};


/*!
	@class		SeaWhiteboard
	@abstract	Combines the layers together to formulate a single bitmap that
				can be presented to the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
				Copyright (c) 2005 Daniel Jalkut
*/

@class SeaContent;
@class SeaCompositor;

@interface SeaWhiteboard : NSObject {

	// The document associated with this whiteboard
	SeaContent *contents;
	
	// The compositor for this whiteboard
	SeaCompositor *compositor;
	
	IntPoint gScreenResolution;

	// The width and height of the whitebaord
	int width, height;
	
	// The whiteboard's data
	unsigned char *data,*overlay,*replace;
	
	// The whiteboard's images
	NSImage *image;
	
	// The whiteboard's samples per pixel
	int spp;
	
}

// CREATION METHODS

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithContent:(SeaContent *)cont;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		compositor
	@discussion	Returns the instance of the compositor
*/
- (SeaCompositor *)compositor;

// OVERLAY METHODS

// UPDATING METHODS

/*!
	@method		update
	@discussion	Updates the full contents of the whiteboard.
*/
- (void)update;

/*!
	@method		printableImage
	@discussion	Returns an image representing the whiteboard as it should be
				printed. The representation is never channel-specific.
	@result		Returns an NSImage representing the whiteboard as it should be
				printed.
*/
- (NSImage *)printableImage;

/*!
	@method		data
	@discussion	Returns the bitmap data for the whiteboard.
	@result		Returns a pointer to the bitmap data for the whiteboard.
*/
- (unsigned char *)data;
/*!
 @method        data
 @discussion    Returns the bitmap data for the whiteboard.
 @result        Returns a pointer to the bitmap data for the whiteboard.
 */
- (unsigned char *)overlay;
/*!
 @method        data
 @discussion    Returns the bitmap data for the whiteboard.
 @result        Returns a pointer to the bitmap data for the whiteboard.
 */
- (unsigned char *)replace;
@end
