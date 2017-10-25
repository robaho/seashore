#import "Globals.h"

/*!
	@class		CocoaImporter
	@abstract	Imports a Cocoa-compatible document as a layer.
	@discussion	Cocoa-compatible image files are those supported by the
				NSBitmapImageRep class.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CocoaImporter : NSObject {

	IBOutlet id pdfPanel;
	IBOutlet id pageLabel;
	IBOutlet id pageInput;
	IBOutlet id resMenu;

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

/*!
	@method		endPanel:
	@discussion	Closes the current modal dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
