#import "Seashore.h"
#import "AbstractSelectOptions.h"
#import "AspectRatio.h"
#import <SeaComponents/SeaComponents.h>

/*!
	@class		RectSelectOptions
	@abstract	Handles the options pane for the rectangular selection tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface RectSelectOptions : AbstractSelectOptions {
    id radiusSlider;
    AspectRatio *aspectRatio;
}

/*!
	@method		radius
	@discussion	Returns the curve rdius to be used with the rounded rectangle.
	@result		Returns an integer indicating the curve radius to be used with
				the rounded rectangle.
*/
- (int)radius;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
