/*!
	@class		MovePanel
	@abstract	Forwards change font message to the text tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "Globals.h"

@interface MovePanel : NSPanel {

	// The associated text tool
	IBOutlet id textTool;

}

/*!
	@method		changeSpecialFont:
	@discussion	Responds to a font change by fowarding the message to the
				text tool.
	@param		sender
				Ignored.
*/
- (IBAction)changeSpecialFont:(id)sender;


/*!
	@method		keyDown:
	@discussion	Handles key down events.
	@param		theEvent
				The event triggering this method.
*/
- (void)keyDown:(NSEvent *)theEvent;

@end
