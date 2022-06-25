#import "Seashore.h"
#import "AbstractOptions.h"
#import "AbstractSelectOptions.h"

/*!
	@class		ZoomOptions
	@abstract	Handles the options pane for the zoom tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface ZoomOptions : AbstractSelectOptions {

	// A label specifying the current zoom
    IBOutlet id zoomLabel;
	
}

@end
