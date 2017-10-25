#import "Globals.h"

/*		
	@class		AbstractPanelUtility
	@abstract	Acts as a base class for the utilites that use info panels.
	@discussion	This class is responsible for just showing and hiding the panels.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractPanelUtility : NSObject {
	// The window associated with this utility
    IBOutlet id window;
	// The parent this is associated with
	NSWindow *parentWin;
}

/*!
	@method		showPanelFrom:
	@discussion	Brings the panel to the front (it's modal).
	@param		p
				This is an NSPoint which is the point the pointy part
				of the panel should be located at. Generally, it is just
				the point the mouse was, though it can be any point.
	@param		parent
				This is the window that the panel is attached to.
*/
- (void)showPanelFrom:(NSPoint)p onWindow:(NSWindow*) parent;

/*!
	@method		closePanel:
	@discussion	Closes the modal panel shown earlier.
	@param		sender
				Ignored.
*/
- (IBAction)closePanel:(id)sender;

@end
