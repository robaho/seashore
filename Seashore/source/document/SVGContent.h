#import "Globals.h"
#import "SeaContent.h"

/*!
	@class		SVGContent
	@abstract	Loads the contents of an SVG file using Apache's Batik.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

@interface SVGContent : SeaContent {
}

/*!
	@method		typeIsViewable:
	@discussion	Whether or not the type is read only SVGContent
	@param		type
				A string type, could be an HFS File Type or UTI
	@result		A boolean indicating acceptance.
*/
+ (BOOL)typeIsViewable:(NSString *)type;

/*!
	@method		initWithDocument:contentsOfFile:
	@discussion	Initializes an instance of this class with the given image file.
	@param		doc
				The document with which to initialize the instance.
	@param		path
				The path of the image file with which to initalize this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;

@end
