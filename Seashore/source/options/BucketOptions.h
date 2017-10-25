#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		BucketOptions
	@abstract	Handles the options pane for the paint bucket tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BucketOptions : AbstractPaintOptions {
	
	// A slider indicating the tolerance of the bucket
	IBOutlet id toleranceSlider;
	
	// A label displaying the tolerance of the bucket
	IBOutlet id toleranceLabel;

	// A slider for the density of the wand sampling
	IBOutlet id intervalsSlider;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		toleranceSliderChanged:
	@discussion	Called when the tolerance is changed.
	@param		sender
				Ignored.
*/
- (IBAction)toleranceSliderChanged:(id)sender;

/*!
	@method		tolerance
	@discussion	Returns the tolerance to be used with the paint bucket tool.
	@result		Returns an integer indicating the tolerance to be used with the
				bucket tool.
*/
- (int)tolerance;


/*!
	@method		numIntervals
	@discussion	Returns the number of intervals for the wand sampling
	@result		Returns an integer.
*/
- (int)numIntervals;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
