#import "Globals.h"
#import "SeaContent.h"

/*!
	@class		CocoaContent
	@abstract	Loads the contents of the document from a given Cocoa-compatible
				image file.
	@discussion	Cocoa-compatible image files are those supported by the
				NSBitmapImageRep class.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CocoaContent : SeaContent {

	IBOutlet id pdfPanel;
	IBOutlet id pageLabel;
	IBOutlet id pageInput;
	IBOutlet id resMenu;

}

/*!
	@method		typeIsEditable:
	@discussion	Whether or not the type is read/write CocoaContent
	@param		type
				A string type, could be an HFS File Type or UTI
	@param		doc
				Somewhere to put errors (if any)
	@result		A boolean indicating acceptance.

*/
+ (BOOL)typeIsEditable:(NSString *)type forDoc:(id)doc;

/*!
	@method		typeIsViewable:
	@discussion	Whether or not the type is read only CocoaContent
	@param		type
				A string type, could be an HFS File Type or UTI
	@param		doc
				Somewhere to put errors (if any)
	@result		A boolean indicating acceptance.
*/
+ (BOOL)typeIsViewable:(NSString *)type forDoc:(id)doc;

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

/*!
	@method		endPanel:
	@discussion	Closes the current modal dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
