#import "Seashore.h"
#import "AbstractPaintOptions.h"
#import "BrushOptions.h"

/*!
	@class		EraserOptions
	@abstract	Handles the options pane for the eraser tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EraserOptions : BrushOptions {

	// A checkbox indicating whether to fade in the same style as the paintbrush
	IBOutlet id mimicBrushCheckbox;
	
}


/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;


/*!
	@method		mimicBrush
	@discussion	Returns whether to mimic the paintbrush settings when fading.
	@result		Returns YES if the eraser should mimic the paintbrush, NO 
				otherwise.
*/
- (BOOL)mimicBrush;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
