#import "Globals.h"
#import "SeaContent.h"

/*!
	@struct		SharedXBMInfo
	@discussion	File formats weren't necessarily made with our object-oriented 
				structure in mind as such we sometimes need to share information
				between the content and layer loaders. This record allows us to
				do this. "-->" indicates the field is filled by the document and
				passed to the layer, "<--" indicates the opposite.
	@field		width
				--> The width of the X bitmap.
	@field		height
				--> The height of the X bitmap.
*/
typedef struct
{
	int width;
	int height;
} SharedXBMInfo;

/*!
	@class		XBMContent
	@abstract	Loads the contents of the document from an XBM file.
	@discussion	See http://www.dcs.ed.ac.uk/home/mxr/gfx/2d/XBM.txt for more
				information on the X BitMap Format.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XBMContent : SeaContent {

}

/*!
	@method		typeIsEditable:
	@discussion	Whether or not the type is XBMContent
	@param		type
				A string type, could be an HFS File Type or UTI
	@result		A boolean indicating acceptance.

*/
+ (BOOL)typeIsEditable:(NSString *)type;


/*!
	@method		initWithDocument:contentsOfFile:
	@discussion	Initializes an instance of this class with the given XBM file.
	@param		doc
				The document with which to initialize the instance.
	@param		path
				The path of the image file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;

@end
