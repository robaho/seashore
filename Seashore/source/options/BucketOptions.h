#import "Seashore.h"
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
	id toleranceSlider;
    id fillAllRegions;
}

/*!
	@method		tolerance
	@discussion	Returns the tolerance to be used with the paint bucket tool.
	@result		Returns an integer indicating the tolerance to be used with the
				bucket tool.
*/
- (int)tolerance;
- (Boolean)fillAllRegions;
@end
