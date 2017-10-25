#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		SmudgeOptions
	@abstract	Handles the options pane for the smudge tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SmudgeOptions : AbstractPaintOptions {

	// A slider indicating the opacity of the bucket
	IBOutlet id rateSlider;
	
	// A label displaying the opacity of the bucket
	IBOutlet id rateLabel;
	
	// A checkbox that when checked implies that the tool should consider all pixels not those just in the current layer
	//IBOutlet id mergedCheckbox;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*
	@method		mergedSample
	@discussion	Returns whether all layers should be considered in sampling or
				just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO 
				if only the active layer should be considered.
*/
//- (BOOL)mergedSample;

/*!
	@method		rateChanged:
	@discussion	Called when the rate is changed.
	@param		sender
				Ignored.
*/
- (IBAction)rateChanged:(id)sender;

/*!
	@method		rate
	@discussion	Returns the rate of smudging. Higher values imply more smudging.
	@result		Returns an integer (between 0 and 255) representing the rate of
				smudging.
*/
- (int)rate;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
