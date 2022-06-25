#import "Seashore.h"
#import "AbstractExporter.h"

/*!
	@defined	kMaxCompression
	@discussion	Specifies the maximum compression value for a HEIC image.
*/
#define kMaxCompression 30

/*!
	@class		HEICExporter
	@abstract	Exports to the HEIC file format using Cocoa.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface HEICExporter : AbstractExporter {

	// The compression factor to be used with the web target (between 0 and 30)
	int webCompression;

	// The compression factor to be used with the print target (between 0 and 30)
	int printCompression;
	
	// YES if targeting the web, NO if targeting print
	BOOL targetWeb;

	// The panel allowing compression options to be set
	IBOutlet NSPanel *panel;
	
	// The compressed preview
	IBOutlet id compressImageView;
	
	// The uncompressed preview
	IBOutlet id realImageView;
	
	// The label specifying the compression level
	IBOutlet id compressLabel;
	
	// The slider allowing compression to be adjusted
	IBOutlet id compressSlider;
	
	// The radio buttons specifying the target
	IBOutlet id targetRadios;

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
	@method		targetChanged:
	@discussion	Called when the user adjusts the media target.
	@param		sender
				Ignored.
*/
- (IBAction)targetChanged:(id)sender;

/*!
	@method		endPanel:
	@discussion	Called to close the options dialog.
	@param		sender
				Ignored.
*/
- (IBAction)endPanel:(id)sender;

@end
