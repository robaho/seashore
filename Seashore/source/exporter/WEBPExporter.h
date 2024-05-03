#import "Seashore.h"
#import "AbstractExporter.h"

/*!
	@defined	kMaxCompression
	@discussion	Specifies the maximum compression value for a JPEG image.
*/
#define kMaxWEBPCompression 100

/*!
	@class		WEBPExporter
	@abstract	Exports to theWEBP file format using Cocoa.
	@discussion	N/A
*/

@interface WEBPExporter : AbstractExporter {

	// The compression factor to be used with the web target (between 0 and 30)
	int webCompression;

    bool lossless;

    // The panel allowing compression options to be set
	IBOutlet NSPanel *panel;

    IBOutlet id losslessCheckbox;

	// The compressed preview
	IBOutlet id compressImageView;
	
	// The uncompressed preview
	IBOutlet id realImageView;
	
	// The label specifying the compression level
	IBOutlet id compressLabel;
	
	// The slider allowing compression to be adjusted
	IBOutlet id compressSlider;

    NSBitmapImageRep *realImageRep;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		compressionChanged:
	@discussion	Called when the user adjusts the compression slider.
	@param		sender
				Ignored.
*/
- (IBAction)compressionChanged:(id)sender;

/*!
	@method		endPanel:
	@discussion	Called to close the options dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
