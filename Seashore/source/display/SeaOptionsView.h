#import "Globals.h"

/*!
	@class		SeaOptionsView
	@abstract	View for the options bar
	@discussion	This class is just responsible for the background.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/



@interface SeaOptionsView : NSView {
	// A connection to the host window is needed so that when the window gains / stops being
	// key this view's background can change.
	IBOutlet id window;
}

@end
