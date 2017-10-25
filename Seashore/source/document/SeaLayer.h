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
	
	// The document that contains this layer
	id document;
	
	// The object responsible for changes to our bitmap
	id seaLayerUndo;
	
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
- (id)initWithDocument:(id)doc;

/*!
	@method		initWithDocument:width:height:opaque:spp:
	@discussion	Initializes an instance of this class with the given values.
	@param		doc
				The document with which to initialize the instance.
	@param		lwidth
				The width with which to initialize the instance.
	@param		lheight
				The height with which to initialize the instance.
	@param		opaque
				YES if the layer should be opaque, NO otherwise.
	@param		lspp
				The samples per pixel of the layer. This argument may seem
				redundant but it's not.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;

/*!
	@method		initWithDocument:rect:data:spp:
	@discussion	Initializes an instance of this class with the given bitmap data
				note that the bitmap data is copied so you are still free to
				throw away and play with the bitmap data after you have passed
				it to this initializer).
	@param		doc
				The document with which to initialize the instance.
	@param		lrect
				The rectangle with which to initialize the instance. This
				determines the width, height and offsets of the layer.
	@param		ldata
				The block of memory containing the bitmap data (data must be of
				same spp as document).
	@param		lspp
				The samples per pixel of the layer. This argument may seem
				redundant but it's not.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp;

/*!
	@method		initWithDocument:layer:type:
	@discussion	Initialize an instance of this class to mimic the contents of
				another. If necessary the bitmap data is converted to match the
				document type.
	@param		doc
				The document with which to initialize the instance. Not 
				necessarily the document from which the layer came.
	@param		layer
				The layer whose contents to mimic.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc layer:(SeaLayer*)layer;

/*!
	@method		initFloatingWithDocument:rect:data:
	@discussion	Initializes an instance of this class with the given values and
				the floating variable set.
	@param		doc
				The document with which to initialize the instance.
	@param		lrect
				The rectangle with which to initialize the instance. This
				determines the width, height and offsets of the layer.
	@param		ldata
				The data with which to initialize the instance. This should be
				of the format prescibed by the document.
*/
- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

// COMPRESSION METHODS

/*!
	@method		compress
	@discussion	Reduces the memory occupied by the layer by writing its data to
				disk. This data can then be recovered by sending a decompress
				message to the object. While the layer is compressed it is
				largely dysfunctional. For this reason layers are typically only
				compressed upon deletion and decompressed upon recovery (by an
				undo operation).
*/
- (void)compress;

/*!
	@method		decompress
	@discussion	Decompresses the layer if it has previously been compressed. See
				the compress method for more information.
*/
- (void)decompress;

// PROPERTY METHODS

/*!
	@method		document
	@discussion	Returns the document associated with this layer. Try to avoid
				using this method (instead reference the document directly).
	@result		Returns the document associated with this layer.
*/
- (id)document;

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
	@method		localRect
	@discussion	For finding out where it is, simply a combination of the above values.
	@result		An Integer Rectangle
*/
- (IntRect)localRect;

/*!
	@method		setOffsets:
	@discussion	Sets the horizontal and vertical offsets of the layer.
	@param		newOffsets
				The revised offsets of the layer.
*/
- (void)setOffsets:(IntPoint)newOffsets;

/*!
	@method		trimLayer
	@discussion	Reduces the layer's boundaries to remove fully transparent
				pixels.
*/
- (void)trimLayer;

/*!
	@method		flipHorizontally
	@discussion	Flips the layer horizontally.
*/
- (void)flipHorizontally;

/*!
	@method		flipVertically
	@discussion	Flips the layer vertically.
*/
- (void)flipVertically;

/*!
	@method		rotateLeft
	@discussion	Rotates the layer 90 degrees counter-clockwise.
*/
- (void)rotateLeft;

/*!
	@method		rotateRight
	@discussion	Rotates the layer 90 degrees clockwise.
*/
- (void)rotateRight;

/*!
	@method		setRotation:
	@discussion	Rotates the layer by the given number of degrees. Rotations
				directly impact the bitmap.
	@param		degrees
				The number of degrees to rotate by.
	@param		interpolation
				The interpolation style to be used with rotation (see
				NSGraphicsContext).
	@param		trim
				YES if the layer should be trimmed afterwards, NO otherwise.
*/
- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim;

/*!
	@method		visible
	@discussion	Returns whether or not the layer is currently visible.
	@result		Returns YES if the layer is currently visible, NO otherwise.
*/
- (BOOL)visible;

/*!
	@method		setVisible:
	@discussion	Sets whether or not the layer should be visible.
	@param		value
				YES if the layer should be visible, NO otherwise.
*/
- (void)setVisible:(BOOL)value;

/*!
	@method		linked
	@discussion	Returns whether or not the layer is currently linked to others.
	@result		Returns YES if the layer is currently linked to others, NO
				otherwise.
*/
- (BOOL)linked;

/*!
	@method		setLinked:
	@discussion	Sets whether or not the layer should be linked to others.
	@param		value
				YES if the layer should be linked to others, NO otherwise.
*/
- (void)setLinked:(BOOL)value;

/*!
	@method		opacity
	@discussion	Returns the opacity of the layer.
	@result		Reutrns an integer from 0 to 255 indicating the opacity of the
				layer. The layer's contents are fully opaque if the opacity is
				255.
*/
- (int)opacity;

/*!
	@method		setOpacity:
	@discussion	Sets the opacity of the layer.
	@param		value
				An integer from 0 to 255 representing the revised opacity of the
				layer.
*/
- (void)setOpacity:(int)value;

/*!
	@method		mode
	@discussion	Returns the method by which the layer should be composited
	@result		Returns an integer indicating the method by whcih the layer
				should be composited (see Constants documentation).
*/
- (int)mode;

/*!
	@method		setMode:
	@discussion	Sets the method by which the layer should be composited.
	@param		value
				An integer representing the revised method by which the layer
				should be composited (see Constants documentation).
*/
- (void)setMode:(int)value;

/*!
	@method		name
	@discussion	Returns the name of the layer.
	@result		Returns an NSString representing the name of the layer.
*/
- (NSString *)name;

/*!
	@method		setName:
	@discussion	Sets the name of the layer (the old name will be retained until
				the layer is destroyed).
	@param		newName
				The revised name of the layer.
*/
- (void)setName:(NSString *)newName;

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
	@method		toggleAlpha
	@discussion	Toggles whether or not the layer should be considered active
				handles undos).
*/
- (void)toggleAlpha;

/*!
	@method		introduceAlpha
	@discussion	Called to force the alpha channel to become active (e.g. after
				non-natural erasing). 
*/
- (void)introduceAlpha;

/*!
	@method		canToggleAlpha
	@discussion	Returns whether or not the user should be permitted to toggle
				the alpha channel treatment. Users aren't permitted to toggle
				the alpha channel treatment off if the alpha channel is not
				fully opaque.
	@result		Returns YES if the user should be permitted to toggle the alpha
				channel treament, NO otherwise.
*/
- (BOOL)canToggleAlpha;

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
	@method		index
	@discussion	Returns the index of this layer at the current moment. This
				method is a linear time operation. Use it sparingly maybe
				uniqueLayerID would serve your purpose better?
	@result		Returns an integer indicating the current index of the layer.
*/
- (int)index;

/*!
	@method		floating
	@discussion	Returns whether or not the layer is a floating layer.
	@result		Returns YES if the layer is a floating layer, NO otherwise. This
				implementation of the method always returns NO.
*/
- (BOOL)floating;

// EXTRA METHODS

/*!
	@method		seaLayerUndo
	@discussion	Returns the undo manager of the layer.
	@result		Returns an instance of SeaLayerUndo.
*/
- (id)seaLayerUndo;

/*!
	@method		thumbnail
	@discussion	Returns a thumbnail of the layer. This method does not ensure
				that the thumbnail is up-to-date with the layer's contents, to
				do that use updateThumbnail. However it will always return a
				thumbnail.
	@result		Returns an NSImage that is no greater in size than 50 by 40.
				pixels.
*/
- (NSImage *)thumbnail;

/*!
	@method		updateThumbnail
	@discussion	Updates the thumbnail so that it is up-to-date with the layer's
				contents. This routine does not consider the overlay so it
				should only be called after the overlay is applied to the layer.
				Thumbnails are calculated by taking at most 2000  pixels that
				are considered representative of the image.
*/
- (void)updateThumbnail;

/*!
	@method		TIFFRepresentation
	@discussion	Returns a TIFF representation of the layer.
	@result		Returns a TIFF representation of the layer.
*/
- (NSData *)TIFFRepresentation;

/*!
	@method		setMarginLeft:top:right:bottom:
	@discussion	Expands or reduces the margins of the layer as specified. All
				measurements are taken to be relative with zero indicating no
				change, negative values indicating that margin should be moved
				inward and positive values indicating that the margin should be
				moved outward.
	@param		left
				The adjustment to be made to the left margin (in pixels).
	@param		top
				The adjustment to be made to the top margin (in pixels).
	@param		right
				The adjustment to be made to the right margin (in pixels).
	@param		bottom
				The adjustment to be made to the bottom margin (in pixels).
*/
- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom;

/*!
	@method		setWidth:height:interpolation:
	@discussion	Scales the contents of the layer to match the specified height
				and width. Interpolation (allowing for smoother scaling) is used
				as specified but no adjustment is made to the layer's offsets.
	@param		width
				The revised width of the document or layer.
	@param		height
				The revised height of the document or layer.
	@param		interpolation
				The interpolation style to be used (see GIMPCore).
*/
- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation;

/*!
	@method		convertFromType:to:
	@discussion	Converts the bitmap data of the layer from a specified type to
				another. This is useful in RGB to grayscale conversions, etc.
				Conversions use ColorSync.
	@param		srcType
				The type from which the layer's bitmap data is being converted.
	@param		destType
				The type to which the layer's bitmap is being converted.
*/
- (void)convertFromType:(int)srcType to:(int)destType;

@end
