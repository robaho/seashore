#import "Seashore.h"
#import "SeaColorProfiles.h"
#import <CoreImage/CoreImage.h>

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
	kAlphaChannelView
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
    kMaskingBehavior,
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

@class SeaDocument;

@interface SeaWhiteboard : NSView <CALayerDelegate> {

	// The document associated with this whiteboard
	__weak SeaDocument *document;
	
	// The width and height of the whiteboard
	int width, height;
	
	// The whiteboard's data
	unsigned char *data;

	// The overlay for the current layer
	unsigned char *overlay;

	// The replace mask for the current layer
	unsigned char *replace;

    // The temporary ares for compositing the overlay into the layer
    unsigned char *temp;
	
	// The behaviour of the overlay
	int overlayBehaviour;
	
	// The opacity for the overlay
	int overlayOpacity;
    float overlayOpacity_float;

    IntRect overlayModifiedRect;
    IntRect whiteboardModifiedRect;

	// The whiteboard's samples per pixel
	int spp;
	
	// Remembers whether is or is not active
    SeaColorProfile *proofProfile;
	
    CGContextRef overlayCtx;
    CGContextRef dataCtx;
    CGContextRef tempCtx;
    CGContextRef proofCtx;

    CIFilter *alphaToGray;
}

// CREATION METHODS

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

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
*/
- (void)applyOverlay;

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

// ColorSync PREVIEWING METHODS

/*!
 @method        proofProfile
 @discussion    Returns the selected proof profile, or NULL
 @result        Returns a SeaColorProfile or NULL
 */
- (SeaColorProfile*)proofProfile;

/*!
	@method		toggleSoftProof
	@discussion	sets the color profile for proof
    @param      sender
                the profile or null
*/
- (void)toggleSoftProof:(SeaColorProfile*)profile;

// UPDATING METHODS

/*!
	@method		update
	@discussion	Updates the full contents of the whiteboard.
*/
- (void)update;

/*!
	@method		update:rect
	@discussion	Updates a specified rectangle of the whiteboard.
	@param		rect
				The rectangle to be updated.
*/
- (void)update:(IntRect)rect;

- (void)overlayModified:(IntRect)rect;

// ACCESSOR METHODS

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

- (void)drawRect:(NSRect)rect;

- (CGContextRef)overlayCtx;

- (NSColor*) getPixelX:(int)x Y:(int)y;

- (NSBitmapImageRep *)sampleImage;

- (NSBitmapImageRep *)bitmap;

@end
