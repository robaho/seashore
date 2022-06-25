#import "Seashore.h"
#import "BrushOptions.h"

/*!
	@class		CloneOptions
	@abstract	Handles the options pane for the lasso tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CloneOptions : BrushOptions {

	// A checkbox that when checked implies that the tool should consider all pixels not those just in the current layer
	IBOutlet id mergedCheckbox;
	
	// A label indicating the source of the clone
	IBOutlet id sourceLabel;
	
    __weak IBOutlet NSTextField *opacityLabel;
    __weak IBOutlet NSSlider *opacitySlider;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		mergedSample
	@discussion	Returns whether all layers should be considered in sampling or
				just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO 
				if only the active layer should be considered.
*/
- (BOOL)mergedSample;

/*!
	@method		mergedChanged:
	@discussion	Called when the merged sample checkbox is changed to unset
				the source point.
	@param		sender
				Ignored.
*/
- (IBAction)mergedChanged:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
