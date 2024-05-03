#import "Seashore.h"
#import "SeaLayer.h"

/*!
	@class		WEBPImporter
	@abstract	Imports an WEBP document as a layer.
*/

@interface WEBPImporter : NSObject {

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
- (SeaLayer*)loadLayer:(id)doc path:(NSString *)path;
+ (NSImage *)loadImage:(NSData *)data;


@end
