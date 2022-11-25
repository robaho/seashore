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
	id mergedCheckbox;
	
	// A label indicating the source of the clone
	id sourceLabel;
}

/*!
	@method		mergedSample
	@discussion	Returns whether all layers should be considered in sampling or
				just the active layer.
	@result		Returns YES if all layers should be considered in sampling, NO 
				if only the active layer should be considered.
*/
- (BOOL)mergedSample;

@end
