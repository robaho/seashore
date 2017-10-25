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
	unsigned char *data;
	unsigned char *altData;
	
	// The whiteboard's images
	NSImage *image;
	
	// The overlay for the current layer
	unsigned char *overlay;
	
	// The replace mask for the current layer
	unsigned char *replace;
	
	// The behaviour of the overlay
	int overlayBehaviour;
	
	// The opacity for the overlay
	int overlayOpacity;
	
	// The colour world for colour space conversions
	CMWorldRef cw;
	
	// The whiteboard's samples per pixel
	int spp;
	
	// Remembers whether is or is not active
	BOOL CMYKPreview;
	
	// One of the above constants to specify what is seen by the user
	int viewType;
	
	// The rectangle the update is needed in (useUpdateRect may be NO in which case the entire whiteboard is updated)
	BOOL useUpdateRect;
	IntRect updateRect;
	
	// Used for multi-threading
	NSRect threadUpdateRect;
	
	// The thread that is locking or NULL otherwise
	NSThread *lockingThread;
	
	// The display profile
	CMProfileRef displayProf;
	CGColorSpaceRef cgDisplayProf;
	
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

/*!
	@method		setOverlayBehaviour:
	@discussion	Sets the overlay behaviour.
	@param		value
				The new overlay behaviour (see SeaWhiteboard).
*/
- (void)setOverlayBehaviour:(int)value;

/*!
	@method		setOverlayOpacity:
	@discussion	Sets the opacity of the overlay.
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				overlay.
*/
- (void)setOverlayOpacity:(int)value;

/*!
	@method		applyOverlay
	@discussion	Applies and clears the overlay.
	@result		Returns a rectangle representing the changed content in the
				document's co-ordinates. This rectangle can then be passed to
				update:.
*/
- (IntRect)applyOverlay;

/*!
	@method		clearOverlay
	@discussion	Clears the overlay without applying it.
*/
- (void)clearOverlay;

/*!
	@method		overlay
	@discussion	Returns the bitmap data of the overlay.
	@result		Returns a pointer to the bitmap data of the overlay.
*/
- (unsigned char *)overlay;

/*!
	@method		replace
	@discussion	Returns the replace mask of the overlay.
	@result		Returns a pointer to the 8 bits per pixel replace mask of the
				overlay.
*/
- (unsigned char *)replace;

// READJUSTING METHODS

/*!
	@method		whiteboardIsLayerSpecific
	@discussion	Returns whether after the active layer is changed the alternate
				data must be readjusted.
	@result		YES if the alternate data must be readjusted after the active
				layer is changed, NO otherwise.
*/
- (BOOL)whiteboardIsLayerSpecific;

/*!
	@method		readjust
	@discussion	Readjusts and updates the whiteboard after the document's type
				or boundaries are changed.
*/
- (void)readjust;

/*!
	@method		readjustLayer
	@discussion	Readjusts and updates the whiteboard after one or more layers'
				boundaries are changed.
*/
- (void)readjustLayer;

/*!
	@method		readjustAltData
	@discussion	Readjusts the whiteboard's alternate data after the view type is
				changed. (Also called by readjust.)
	@param		update
				YES if the document should be updated after the readjustment, NO
				otherwise.
*/
- (void)readjustAltData:(BOOL)update;

// CMYK PREVIEWING METHODS

/*!
	@method		CMYKPreview
	@discussion	Returns whether or not CMYK previewing is active.
	@result		Returns YES if the CMYK previewing is active, NO otherwise.
*/
- (BOOL)CMYKPreview;


/*!
	@method		canToggleCMYKPreview
	@discussion	Returns whether or not CMYK previewing can be toggled for this
				document.
	@result		Returns YES if CMYK previewing can be toggled, NO otherwise.
*/
- (BOOL)canToggleCMYKPreview;

/*!
	@method		toggleCMYKPreview
	@discussion	Toggles whether or not CMYK previewing is active.
*/
- (void)toggleCMYKPreview;

/*!
	@method		matchColor:
	@discussion	Returns the appropriately matched colour given an unmatched
				colour.
	@param		color
				The unmatched RGBA color.
	@result		The matched RGBA color. 
*/
- (NSColor *)matchColor:(NSColor *)color;

// UPDATING METHODS

/*!
	@method		update
	@discussion	Updates the full contents of the whiteboard.
*/
- (void)update;

/*!
	@method		update:inThread:
	@discussion	Updates a specified rectangle of the whiteboard.
	@param		rect
				The rectangle to be updated.
	@param		thread
				YES if drawing should be done in thread, NO otherwise.
*/
- (void)update:(IntRect)rect inThread:(BOOL)thread;

/*!
	@method		updateColorWorld
	@discussion	Called to inform the whiteboard that the user has changed the
				ColorSync system settings. Updates the CMYK preview to reflect
				the changes.
*/
- (void)updateColorWorld;

// ACCESSOR METHODS

/*!
	@method		imageRect
	@discussion	Returns the rectangle in which the whiteboard's image should be
				plotted. This is only not equal to the document rectangle if
				whiteboardIsLayerSpecific returns YES.
	@result		Returns an IntRect indicating the rectangle in which the
				whiteboard's image should be plotted. 
*/
- (IntRect)imageRect;

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
	@method		altData
	@discussion	Returns the alternate bitmap data for the whiteboard.
	@result		Returns a pointer to the alternate bitmap data for the
				whiteboard.
*/
- (unsigned char *)altData;

/*!
	@method		displayProf
	@discussion	Returns the current display profile.
	@result		Returns a CMProfileRef representing the ColorSync display profile
				Seashore is using.
*/
- (CGColorSpaceRef)displayProf;

@end
