#include "Globals.h"
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

@class SeaWhiteboard;

@interface SeaContent : NSObject {
	IntPoint gScreenResolution;
	
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
- (id)init;


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
	@method		selectedChannel
	@discussion	Returns the currently selected group of channels.
	@result		Returns an integer representing the currently selected group of
				channels (see Constants documentation).
*/
- (int)selectedChannel;

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
	@method		bitmapUnderneath:
	@discussion	Returns the bitmap underneath the rectangle.
	@param		rect
				The rectangle concerned.
*/
- (unsigned char *)bitmapUnderneath:(IntRect)rect forWhiteboard:(SeaWhiteboard *)whiteboard;

@end
