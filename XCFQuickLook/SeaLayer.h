#import "Globals.h"

/*!
	@class		SeaLayer
	@abstract	Represents a layer of the document.
	@discussion	Unless specified otherwise all methods in this class do not
				handle updates and undos.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaLayer : NSObject {
	
	// The layer's height, width and mode
	int height, width, mode;
	
	// The layer's name
	NSString *name;

	// Old names of the layers
	NSArray *oldNames;
	
	// The opacity of the layer (at most 255)
	int opacity;
	
	// The layer's offset
	int xoff, yoff;
	
	// The samples per pixel in this layer
	// (this should be the same as determined from the document's type)
	int spp;
	
	// Is the layer visible?
	BOOL visible;
	
	// Is the layer linked?
	BOOL linked;
	
	// Is the layer floating?
	BOOL floating;
	
	// The lost properties of the document
	char *lostprops;
	int lostprops_len;
	
	// A reference to the image data representing this layer
	unsigned char *data;
	
	// A NSImage representing a thumbnail of the layer
	NSImage *thumbnail;
	unsigned char *thumbData;
	int thumbWidth, thumbHeight;
	
	// Stores whether or not the data is compressed
	BOOL compressed;
	unsigned int compressedLen;
	
	// Remembers whether or not the layer has an alpha channel
	BOOL hasAlpha;
	
	// The unique ID for this layer - sometimes used
	int uniqueLayerID;

	// A path to the file we use for undoing
	NSString *undoFilePath;
	
	// The affine transform plug-in (used to do CoreImage transforms)
	id affinePlugin;

}

// CREATION METHODS

/*!
	@method		initWithDocument:
	@discussion	Initializes an instance of this class with the given document.
				This method is usually only called by other initializers.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;
/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

// PROPERTY METHODS

/*!
	@method		width
	@discussion	Returns the width of the layer.
	@result		Returns an integer representing the width of the layer.
*/
- (int)width;

/*!
	@method		height
	@discussion	Returns the height of the layer.
	@result		Returns an integer representing the height of the layer.
*/
- (int)height;

/*!
	@method		xoff
	@discussion	Returns the horizontal offset of the layer.
	@result		Returns an integer representing the horizontal offset of the
				layer (from the top-left).
*/
- (int)xoff;

/*!
	@method		yoff
	@discussion	Returns the vertical offset of the layer.
	@result		Returns an integer representing the vertical offset of the layer
				from the top-left).
*/
- (int)yoff;


/*!
	@method		visible
	@discussion	Returns whether or not the layer is currently visible.
	@result		Returns YES if the layer is currently visible, NO otherwise.
*/
- (BOOL)visible;

/*!
	@method		linked
	@discussion	Returns whether or not the layer is currently linked to others.
	@result		Returns YES if the layer is currently linked to others, NO
				otherwise.
*/
- (BOOL)linked;

/*!
	@method		opacity
	@discussion	Returns the opacity of the layer.
	@result		Reutrns an integer from 0 to 255 indicating the opacity of the
				layer. The layer's contents are fully opaque if the opacity is
				255.
*/
- (int)opacity;

/*!
	@method		mode
	@discussion	Returns the method by which the layer should be composited
	@result		Returns an integer indicating the method by whcih the layer
				should be composited (see Constants documentation).
*/
- (int)mode;

/*!
	@method		name
	@discussion	Returns the name of the layer.
	@result		Returns an NSString representing the name of the layer.
*/
- (NSString *)name;

/*!
	@method		data
	@discussion	Returns the bitmap data for the layer.
	@result		Returns a pointer to the bitmap data for the layer.
*/
- (unsigned char *)data;

/*!
	@method		hasAlpha
	@discussion	Returns whether or not the layer's alpha channel should be
				considered active.
	@result		Returns YES if the layer's alpha channel should be considered
				active, NO otherwise.
*/
- (BOOL)hasAlpha;

/*!
	@method		introduceAlpha
	@discussion	Called to force the alpha channel to become active (e.g. after
				non-natural erasing). 
*/
- (void)introduceAlpha;

/*!
	@method		lostprops
	@discussion	Returns the lost properties of the layer. Lost properties are
				those saved by the GIMP that Seashore cannot interpret.
	@result		Returns a pointer to the block of memory containing the lost
				properties of the layer.
*/
- (char *)lostprops;

/*!
	@method		lostprops_len
	@discussion	Returns the size of the lost properties of the layer. Lost
				properties are those saved by the GIMP that Seashore cannot
				interpret.
	@result		Returns an integer indicating the size in bytes of the block of
				memory containing the lost properties of the layer.
*/
- (int)lostprops_len;

/*!
	@method		uniqueLayerID
	@discussion	Returns an unique integer identifying the layer. Layer IDs are
				numbered sequentially.
	@result		Returns an unique integer identifying the layer.
*/
- (int)uniqueLayerID;

/*!
	@method		floating
	@discussion	Returns whether or not the layer is a floating layer.
	@result		Returns YES if the layer is a floating layer, NO otherwise. This
				implementation of the method always returns NO.
*/
- (BOOL)floating;

@end
