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

	// The length warning panel
	IBOutlet id waitPanel;
	
	// The spinner to update
	IBOutlet id spinner;
	
	// The scaling panel
	IBOutlet id scalePanel;
	
	// The slider indicating the extent of scaling
	IBOutlet id scaleSlider;
	
	// A label indicating the document's expected size
	IBOutlet id sizeLabel;
	
	// The document's actual and scaled size
	IntSize trueSize, size;
	
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

/*!
	@method		endPanel:
	@discussion	Closes the current modal dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

/*!
	@method		update:
	@discussion	Updates the document's expected size.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

@end
