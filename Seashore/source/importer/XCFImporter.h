#import "Globals.h"

/*!
	@class		XCFImporter
	@abstract	Imports the layers of an XCF file.
	@discussion	The XCF file format is the GIMP's native file format. XCF stands
				for "eXperimental Comupting Facility".
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XCFImporter : NSObject {

	// The version of this document
	int version;
	
	// The type of this document
	int type;
	
	// These hold 64 bytes of temporary information for us 
	int tempIntString[16];
	char tempString[64];

}

/*!
	@method		addToDocument:contentsOfFile:
	@discussion	Adds the given image file to the given document.
	@param		doc
				The document to add to.
	@param		path
				The path to the image file.
	@result		YES if the operation was successful, NO otherwise.
*/
- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path;

@end
