#import <SeaLibrary/Globals.h>
#import "BrushOptions.h"

/*!
	@class		SmudgeOptions
	@abstract	Handles the options pane for the smudge tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SmudgeOptions : BrushOptions {
	id rateSlider;
}

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
