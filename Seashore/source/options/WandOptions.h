#import "Seashore.h"
#import "AbstractSelectOptions.h"

/*!
	@class		WandOptions
	@abstract	Handles the options pane for the magic wand tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface WandOptions : AbstractSelectOptions {
	
	// A slider indicating the tolerance of the wand
	id toleranceSlider;
    // if checked then non-continguous regions are checked
    id selectAllRegions;
}

/*!
	@method		tolerance
	@discussion	Returns the tolerance to be used with the paint bucket tool.
	@result		Returns an integer indicating the tolerance to be used with the
				bucket tool.
*/
- (int)tolerance;

/*!
 @method        selectAllRegions
 @discussion    Returns the value of the 'select all regions' checkbox
 @result        Returns a Bool.
 */
- (bool)selectAllRegions;

@end
