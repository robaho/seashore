#import "Globals.h"
#import "SeaLayer.h"
#import "XCFContent.h"

/*!
	@class		XCFLayer
	@abstract	Loads a particular layer from an XCF file.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XCFLayer : SeaLayer {

	// These hold 64 bytes of temporary information for us 
	int tempIntString[16];
	char tempString[64];

}

/*!
	@method		initWithFile:document:shareInfo:
	@discussion	Initializes an instance of this class with the layer at a given
				offset inside a given file.
	@param		file
				The file containing the layer.
	@param		offset
				The offset at which the layer begins.
	@param		doc
				The document to be associated with this instance.
	@param		info
				A pointer to an information record for exchanging information
				with the XCFContent class (see XCFContent documentation for more
				information).
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithFile:(FILE *)file offset:(int)offset sharedInfo:(SharedXCFInfo *)info;

@end
