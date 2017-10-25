#import "Globals.h"
#import "AbstractSelectOptions.h"
#import "AspectRatio.h"

/*!
	@class		EllipseSelectOptions
	@abstract	Handles the options pane for the elliptical selection tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EllipseSelectOptions : AbstractSelectOptions {
	
	// The AspectRatio instance linked to this options panel
	IBOutlet id aspectRatio;
	
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
