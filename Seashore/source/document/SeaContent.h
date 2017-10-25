#import "Globals.h"
#import "IndiciesKeeper.h"

/*!
	@struct		ParasiteData
	@discussion	A record containing arbitrary data that will be saved with the
				image using the XCF file format.
	@field		name
				The name of the parasite.
	@field		flags
				Any flags associated with the parasite.
	@field		size
				The size of the parasite's data.
	@field		data
				The parasite's data.
*/
typedef struct {
	NSString *name;
	unsigned int flags;
	unsigned int size;
	unsigned char *data;
} ParasiteData;

/*!
	@class		SeaContent
	@abstract	Represents the contents of the document.
	@discussion	Unless specified otherwise all methods in this class do not
				handle updates and undos.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaContent : NSObject {
	
	// The document associated with this object
	id document;
	
	// The document's x and y resolution
	int xres, yres;
	
	// The document's height, width and type
	int height, width, type;
	
	// The lost properties of the document
	char *lostprops;
	int lostprops_len;
	
	// The layers in the document
	NSArray *layers;
	
	// These are layers that are no longer in the document but are kept for undo operations
	NSArray *deletedLayers;	
	NSMutableArray *layersToUndo;
	NSMutableArray *layersToRedo;
	NSMutableArray *orderings;
	
	// Stores index of layer that is active
	int activeLayerIndex;
	
	// The currently selected channel (see constants)
	int selectedChannel;
	
	//  If YES the user wants the typical view otherwise the user wants the channel-specific view
	BOOL trueView;
	
	// The keeper we use to keep IndiciesRecords in memory
	IndiciesKeeper keeper;
	
	// All the parasites
	ParasiteData *parasites;
	int parasites_count;
	
	// Save as a CMYK TIFF file
	BOOL cmykSave;
	
	// The EXIF data associated with this image
	NSDictionary *exifData;
	
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
	@method		initForPasteboardWithDocument:
	@discussion	Initializes an instance of this class with the pasteboard's
				contents.
	@param		doc
				The document with which to initialize the instance.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initFromPasteboardWithDocument:(id)doc;

/*!
	@method		initWithDocument:type:width:height:res:opaque:
	@discussion	Initializes an instance of this class with the given values.
				Creates appropriate layer based upon values.
	@param		doc
				The document with which to initialize the instance.
	@param		dtype
				The document type with which to initialize the instance (see
				Constants documentation).
	@param		dwidth
				The width with which to initialize the instance.
	@param		dheight
				The height with which to initialize the instance.
	@param		dres
				The resolution with which to intialize the instance (note that
				it is an integer not an IntResolution because this method only
				accepts square resolutions).
	@param		dopaque
				YES if the background layer should be opaque, NO otherwise.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres opaque:(BOOL)dopaque;

/*!
	@method		initWithDocument:data:type:width:height:res:
	@discussion	Initializes an instance of this class with the given values.
				Creates appropriate layer based upon values.
	@param		doc
				The document with which to initialize the instance.
	@param		ddata
				The data with which to initialize the instance.
	@param		dtype
				The type with which to initialize the instance (see
				Constants documentation).
	@param		dwidth
				The width with which to initialize the instance.
	@param		dheight
				The height with which to initialize the instance.
	@param		dres
				The resolution with which to intialize the instance (note that
				it is an integer not an IntResolution because this method only
				accepts square resolutions).
	@param		dopaque
				YES if the background layer should be opaque, NO otherwise.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc data:(unsigned char *)ddata type:(int)dtype width:(int)dwidth height:(int)dheight res:(int)dres;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

// PROPERTY METHODS

/*!
	@method		type
	@discussion	Returns the document type.
	@result		Returns an integer representing the document type (see Constants
				documentation).
*/
- (int)type;

/*!
	@method		spp
	@discussion	Returns the samples per pixel of the document.
	@result		Returns an integer indicating the samples per pixel of the
				document.
*/
- (int)spp;

/*!
	@method		xres
	@discussion	Returns the horizontal resolution of the document.
	@result		Returns the horizontal resolution as an integer in
				dots-per-inch.
*/
- (int)xres;

/*!
	@method		yres
	@discussion	Returns the vertical resolution of the document.
	@result		Returns the vertical resolution as an integer in dots-per-inch.
*/
- (int)yres;

/*!
	@method		xscale
	@discussion	Returns how much the image should be scaled by horizontally given
				the current zoom and resolution.
	@result		A floating-point number indicating how much the image should be scaled
				by horizontally given the current zoom and resolution.
*/
- (float)xscale;

/*!
	@method		yscale
	@discussion	Returns how much the image should be scaled by vertically given
				the current zoom and resolution.
	@result		A floating-point number indicating how much the image should be scaled
				by vertically given the current zoom and resolution.
*/
- (float)yscale;

/*!
	@method		setResolution:
	@discussion	Sets the horizontal and vertical resolutions for the document.
	@param		newRes
				The revised resolution (the IntResolution type is the same as
				IntPoint see Globals documentation for more information).
*/
- (void)setResolution:(IntResolution)newRes;

/*!
	@method		height
	@discussion	Returns the height of the document.
	@result		Returns the height as an integer in pixels.
*/
- (int)height;

/*!
	@method		width
	@discussion	Returns the width of the document.
	@result		Returns the width as an integer in pixels.
*/
- (int)width;

/*!
	@method		setWidth:height:
	@discussion	Sets the width and height for the document.
	@param		newWidth
				The revised width as an integer in pixels.
	@param		newHeight
				The revised height as an integer in pixels.
*/
- (void)setWidth:(int)newWidth height:(int)newHeight;

/*!
	@method		setMarginLeft:top:right:bottom:
	@discussion	Expands or reduces the margins of the document as specified. All
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
	@method		selectedChannel
	@discussion	Returns the currently selected group of channels.
	@result		Returns an integer representing the currently selected group of
				channels (see Constants documentation).
*/
- (int)selectedChannel;

/*!
	@method		setSelectedChannel:
	@discussion	Sets the currently selected group of channels.
	@param		value
				The revised group of channels (see Constants documentation)
*/
- (void)setSelectedChannel:(int)value;

/*!
	@method		lostprops
	@discussion	Returns the lost properties of the document. Lost properties are
				those saved by the GIMP that Seashore cannot interpret.
	@result		Returns a pointer to the block of memory containing the lost
				properties of the document.
*/
- (char *)lostprops;

/*!
	@method		lostprops_len
	@discussion	Returns the size of the lost properties of the document. Lost
				properties are those saved by the GIMP that Seashore cannot
				interpret.
	@result		Returns an integer indicating the size in bytes of the block of
				memory containing the lost properties of the document.
*/
- (int)lostprops_len;

/*!
	@method		parasites
	@discussion	Returns the parasistes of the document. Parasites are arbitrary
				pieces of data that are saved by the GIMP and Seashore in XCF
				documents.
	@result		Returns an array of ParasiteData records of length given by the
				parasites_count method.
*/
- (ParasiteData *)parasites;

/*!
	@method		parasites_count
	@discussion	Returns the number of parasites in the document's parasite
				array.
	@result		Returns an integer representing the number of parasites in the
				document's parasite array.
*/
- (int)parasites_count;

/*!
	@method		parasiteWithName:
	@discussion	Returns a pointer to the parasite with the given name.
	@param		name
				The name of the parasite.
	@result		Returns a pointer to the ParasiteData record with the requested
				name or NULL if no parasites match.
*/
- (ParasiteData *)parasiteWithName:(NSString *)name;

/*!
	@method		deleteParasiteWithName:
	@discussion	Deletes the parasite with the given name.
	@param		name
				The name of the parasite to delete.
*/
- (void)deleteParasiteWithName:(NSString *)name;

/*!
	@method		addParasite:
	@discussion	Adds a parasite (replacing an existing one with the same name if
				it exists).
	@param		parasite
				The ParasiteData record to add (no copying is done, the record
				is inserted directly into the parasites array so don't use free
				afterwards).
*/
- (void)addParasite:(ParasiteData)parasite;

/*!
	@method		trueView
	@discussion	Returns whether the document view should be showing all channels
				or just the channel being edited.
	@result		YES if the document view should be showing all channels, NO
				otherwise.
*/
- (BOOL)trueView;

/*!
	@method		setTrueView:
	@discussion	Sets whether the document view should be showing all channels or
				just the channel being edited.
	@param		value
				YES if the document should be showing all channels, NO
				otherwise.
*/
- (void)setTrueView:(BOOL)value;

/*!
	@method		foreground
	@discussion	Returns the foreground colour, converting it to the same colour
				space as the document and stripping any colour from it if the
				alpha channel is selected.
	@result		Returns a NSColor representing the foreground colour.
*/
- (NSColor *)foreground;

/*!
	@method		background
	@discussion	Returns the background colour, converting it to the same colour
				space as the document and stripping any colour from it if the
				alpha channel is selected.
	@result		Returns a NSColor representing the background colour.
*/
- (NSColor *)background;

/*!
	@method		setCMYKSave
	@discussion	Sets whether TIFF files should be saved using the CMYK colour
				space.
	@param		value
				YES if TIFF files should be saved using the CMYK colour space,
				NO otherwise.
*/
- (void)setCMYKSave:(BOOL)value;

/*!
	@method		cmykSave
	@discussion	Returns whether TIFF files should be saved using the CMYK colour
				space.
	@result		YES if TIFF files should be saved using the CMYK colour space,
				NO otherwise.
*/
- (BOOL)cmykSave;

/*!
	@method		exifData
	@discussion	Returns the EXIF data for this document.
	@result		Returns an NSDictionary containing the EXIF data or NULL if no
				such data exists.
*/
- (NSDictionary *)exifData;

// LAYER METHODS

/*!
	@method		layer:
	@discussion	Returns the layer with the given index.
	@param		index
				The index of the desired layer.
	@result		An instance of SeaLayer corresponding to the specified index.
*/
- (id)layer:(int)index;

/*!
	@method		layerCount
	@discussion	Returns the total number of layers in the document.
	@result		Returns an integer indicating the total number of layers in the
				document.
*/
- (int)layerCount;

/*!
	@method		activeLayer
	@discussion	Returns the currently active layer.
	@result		An instance of SeaLayer representing the active layer.
*/
- (id)activeLayer;

/*!
	@method		activeLayerIndex
	@discussion	Returns the index of the currently active layer.
	@result		Returns an integer representing the index of the active layer.
*/
- (int)activeLayerIndex;

/*!
	@method		setActiveLayerIndex:
	@param		value
				The index of the new active layer.
*/
- (void)setActiveLayerIndex:(int)value;

/*!
	@method		layerAbove
	@discussion	Selects the layer above the current one. Wraps if at the top.
	@result		Calls set active layer index.
*/
- (void)layerAbove;

/*!
	@method		layerBelow
	@discussion	Selects the layer below the current one. Wraps if at the bottom.
	@result		Calls set active layer index.
*/
- (void)layerBelow;

/*!
	@method		canImportLayerFromFile:
	@discussion	Returns whether layers can be imported from the given file.
	@param		path
				The path to the file.
	@result		YES if layers can be imported, NO otherwise.
*/
- (BOOL)canImportLayerFromFile:(NSString *)path;

/*!
	@method		importLayerFromFile:
	@discussion	Imports new layer(s) from a file into the document (handles
				updates and undos).
	@result		YES if import was successful, NO otherwise.
*/
- (BOOL)importLayerFromFile:(NSString *)path;

/*!
	@method		importLayer
	@discussion	Imports new layer(s) into the document (handles updates and
				undos).
*/
- (void)importLayer;

/*!
	@method		addLayer:
	@discussion	Adds a transparent layer to the document (handles updates and
				undos).
	@param		index
				The index above which to add the layer or kActiveLayer to
				indicate the active layer.
*/
- (void)addLayer:(int)index;

/*!
	@method		addLayerObject:
	@discussion	Adds the given layer to the document (handles updates and
				undos).
	@param		layer
				The layer to add.
*/
- (void)addLayerObject:(id)layer;

/*!
	@method		addLayerFromPasteboard:
	@discussion	Adds a layer to the document based on the pasteboard's contents
				handles updates and undos).
	@param		pboard
				
*/
- (void)addLayerFromPasteboard:(id)pboard;

/*!
	@method		copyLayer:
	@discussion	Adds a layer to the document identical to the given layer
				handles updates and undos).
	@param		layer
				The layer upon which to base the new layer.
*/
- (void)copyLayer:(id)layer;

/*!
	@method		duplicateLayer:
	@discussion	Duplicates a layer in the document (handles updates and undos).
	@param		index
				The index of the layer to duplicate, the duplicate will be added
				above this layer or kActiveLayer to indicate the active layer.
*/
- (void)duplicateLayer:(int)index;

/*!
	@method		deleteLayer:
	@discussion	Deletes a layer from the document (handles updates and undos).
	@param		index
				The index of the layer to delete or kActiveLayer to indicate the
				active layer.
*/
- (void)deleteLayer:(int)index;

/*!
	@method		restoreLayer:fromLostIndex:
	@discussion	Restores a layer to the document (this method should only ever
				be called by the undo manager following a call to 
				deleteLayer:).
	@param		index
				The index of where to restore the layer.
	@param		lostIndex
				The index in the lost layers of the layer.
*/
- (void)restoreLayer:(int)index fromLostIndex:(int)lostIndex;

/*!
	@method		makeSelectionFloat
	@discussion	Makes the current selection a floating one.
	@param		duplicate
				Should the floating layer be a duplicate.
*/
- (void)makeSelectionFloat:(BOOL)duplicate;

/*!
	 @method		duplicate
	 @discussion	Calls the above method (make selection float) with YES.
	 @param			sender
					Ignored
*/
- (IBAction)duplicate:(id)sender;

/*!
	@method		toggleFloatingSelection
	@discussion	Toggles between making the selection float or not
*/
- (void)toggleFloatingSelection;

/*!
	@method		makePasteboardFloat
	@discussion	Makes the current contents of the pasteboard into a floating
				selection.
*/
- (void)makePasteboardFloat;

/*!
	@method		anchorSelection
	@discussion	Anchors the currently floating selection.
*/
- (void)anchorSelection;

/*!
	@method		canRaise:
	@discussion	Returns whether a given layer can be raised or not.
	@param		index
				The index of the layer to test or kActiveLayer to indicate the
				active layer.
	@result		YES if the layer can be risen, NO otherwise.
*/
- (BOOL)canRaise:(int)index;

/*!
	@method		canLower:
	@discussion	Returns whether a given layer can be lowered or not.
	@param		index
				The index of the layer to test or kActiveLayer to indicate the
				active layer.
	@result		YES if the layer can be lowered, NO otherwise.
*/
- (BOOL)canLower:(int)index;

/*!
	@method		moveLayer:toIndex:
	@discussion	Reorders the layers in the image so that the layer will be at
				the passed index.
	@param		layer
				A pointer to the layer object being moved.
				index
				The new index of the moved layer.
*/
- (void)moveLayer:(id)layer toIndex:(int)index;

/*!
	@method		moveLayerOfIndex:toIndex:
	@discussion	Reorders the layers in the image so that the source layer will
				be at the passed index.
	@param		source
				The index of the layer object being moved.
				dest
				The new index of the moved layer.
*/
- (void)moveLayerOfIndex:(int)source toIndex:(int)dest;

/*!
	@method		raiseLayer:
	@discussion	Raises the level of a particular layer in the document if
				possible.
	@param		index
				The index of the layer to raise or kActiveLayer to indicate the
				active layer.
*/
- (void)raiseLayer:(int)index;

/*!
	@method		lowerLayer:
	@discussion	Lowers the level of a particular layer in the document if
				possible.
	@param		index
				The index of the layer to lower or kActiveLayer to indicate the
				active layer.
*/
- (void)lowerLayer:(int)index;

/*!
	@method		clearAllLinks
	@discussion	Unlinks all linked layers (handles updates and undos).
*/
- (void)clearAllLinks;

/*!
	@method		setLinked:forLayer:
	@discussion	Sets the linked status of the given layer (handles updates
				and undos).
	@param		isLinked
				A BOOL of whether or not it should be linked.
	@param		index
				The index of the layer whose linked status to toggle or
				kActiveLayer to indicate the active layer.
*/
- (void)setLinked:(BOOL)isLinked forLayer:(int)index;

/*!
	@method		setVisible:forLayer:
	@discussion	Sets the visible status of the given layer (handles updates
				and undos).
	@param		isVisible
				A BOOL of whether or not it should be linked.
	@param		index
				The index of the layer whose visible status to toggle or
				kActiveLayer to indicate the active layer.
*/
- (void)setVisible:(BOOL)isVisible forLayer:(int)index;

/*!
	@method		copyMerged
	@discussion	Places the merged bitmap under the selection onto the clipboard
*/
- (void)copyMerged;

/*!
	@method		canFlatten
	@discussion	Returns whether or not the document can be flattened, documents
				for which flattening would have no effect cannot be flattened.
	@result		Returns YES if the document can be flattened, NO otherwise.
*/
- (BOOL)canFlatten;

/*!
	@method		flatten
	@discussion	Flattens the document (handles updates and undos).
*/
- (void)flatten;

/*!
	@method		mergeLinked
	@discussion	Merges the linked layers in the image.
*/
- (void)mergeLinked;

/*!
	@method		mergeDown
	@discussion	Merges the current active layer into the layer below it.
*/
- (void)mergeDown;

/*!
	@method		merge
	@discussion	Merges the layers passed into it into one layer.
	@param		mergingLayers
				Any array of all of the layers that should be merged.
	@param		useRepresenation
				Whether or not to use the image's bitmap representation.
	@param		withName
				The name of the new layer that will be output
*/
- (void)merge:(NSArray *)mergingLayers useRepresentation: (BOOL)useRepresenation withName:(NSString *)newName;

/*!
	@method		undoMergeWith:andOrdering:
	@discussion	Undoes the merging of the  layers (this method should only
				ever be called by the undo manager following a call to merge).
	@param		origNoLayers
				The number of layers before the document was merged.
	@param		ordering
				The indexes of the the lost layers of the image.
*/
- (void)undoMergeWith:(int)origNoLayers andOrdering:(NSMutableDictionary *)ordering;

/*!
	@method		bitmapUnderneath:
	@discussion	Returns the bitmap underneath the rectangle.
	@param		rect
				The rectangle concerned.
*/
- (unsigned char *)bitmapUnderneath:(IntRect)rect;

/*!
	@method		redoMergeWith:andOrdering:
	@discussion	Redoes the merging of the  layers (this method should only
				ever be called by the undo manager following a call to 
				undoMerge:fromLostIndex:).
	@param		origNoLayers
				The number of layers before the document was merged.
	@param		ordering
				The indexes of the the lost layers of the image.
*/
- (void)redoMergeWith:(int)origNoLayers andOrdering:(NSMutableDictionary *)ordering;

/*!
	@method		convertToType:
	@discussion	Converts the document and all its layers to a given type.
	@param		newType
				The new type to convert the document to (see Constants
				documentation)
*/
- (void)convertToType:(int)newType;

/*!
	@method		revertToType:withRecord:
	@discussion	Reverts the document to a previous type restoring previous
				contents (this method should only ever be called by the undo
				manager following a call to converToType:).
	@param		newType
				The type to revert the document to (see Constants
				documentation).
	@param		record
				The record containing all the indicizes of the snapshots taken
				before the conversion.
*/
- (void)revertToType:(int)newType withRecord:(IndiciesRecord)record;

@end
