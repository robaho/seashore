#import "Globals.h"
#import "SeaContent.h"

/*!
	@struct		SharedXCFInfo
	@discussion	File formats weren't necessarily made with our object-oriented 
				structure in mind as such we sometimes need to share information
				between the content and layer loaders. This record allows us to
				do this. "-->" indicates the field is filled by the document and
				passed to the layer, "<--" indicates the opposite.
	@field		cmap
				--> The block of memory containing the document's colour map,
				this block of memory will be deallocated after document
				initialization finishes.
	@field		cmap_len
				--> The number of colours in the document's colour map.
	@field		compression
				--> The compresssion style use by the document (see Constants
				documentation).
	@field		type
				--> The document type (see Constants documentation), please be
				aware this can be XCF_INDEXED_IMAGE.
	@field		active
				<-- YES if the layer is the active one, NO otherwise.
	@field		maskToAlpha
				<--- YES if the mask of a layer was composited to its alpha
				channel, NO otherwise.
*/
typedef struct
{
	unsigned char *cmap;
	int cmap_len;
	int compression;
	int type;
	BOOL active;
	BOOL floating;
	BOOL maskToAlpha;
} SharedXCFInfo;

/*!
	@class		XCFContent
	@abstract	Loads the contents of the document from an XCF file.
	@discussion	The XCF file format is the GIMP's native file format. XCF stands
				for "eXperimental Comupting Facility".
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XCFContent : SeaContent {

	// The version of this document
	int version;
	
	// These hold 64 bytes of temporary information for us 
	int tempIntString[16];
	char tempString[64];

}

/*!
	@method		typeIsEditable:
	@discussion	Whether or not the type is XCFContent
	@param		type
				A string type, could be an HFS File Type or UTI
	@result		A boolean indicating acceptance.

*/
+ (BOOL)typeIsEditable:(NSString *)type;

/*!
	@method		initWithDocument:contentsOfFile:
	@discussion	Initializes an instance of this class with the given XCF file.
	@param		doc
				The document with which to initialize the instance.
	@param		path
				The path of the XCF file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;

@end
