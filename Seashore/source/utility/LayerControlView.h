#import "Globals.h"

/*!
	@class		LayerControlView
	@abstract	The view for Layer controls
	@discussion	Draws a background and borders for the buttons.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface LayerControlView : NSView {
	// If the user is dragging right now
	BOOL dragging;
	
	// The previous width before the drag
	float oldWidth;
	NSPoint oldPoint;
	
	// The other views in the window
	__weak IBOutlet id leftPane;
	__weak IBOutlet id rightPane;
	
	// The buttons
	IBOutlet id newButton;
	IBOutlet id dupButton;
	IBOutlet id delButton;
	IBOutlet id infoButton;
	
    IBOutlet id grabberImage;
}
- (IBAction)newLayer:(id)sender;
- (IBAction)duplicateLayer:(id)sender;
- (IBAction)removeLayer:(id)sender;

@end
