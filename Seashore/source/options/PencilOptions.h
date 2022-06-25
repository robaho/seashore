#import "Seashore.h"
#import "BrushOptions.h"

/*!
	@class		PencilOptions
	@abstract	Handles the options pane for the pencil tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PencilOptions : BrushOptions {
	
	// A slider indicating the size of the pencil block
	IBOutlet id sizeSlider;

    IBOutlet id circularTip;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		pencilSize
	@discussion	Returns the current pencil size.
	@result		Returns an integer representing the current pencil size.
*/
- (int)pencilSize;

/*!
 @method        circularTip
 @result        Returns true if a circular tip pencil should be used
 */
- (bool)circularTip;

/*!
 @method        setPencilSize
 @discussion    set the pencial size
 */
- (void)setPencilSize:(int)pencilSize;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
