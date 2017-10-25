#import "Globals.h"

/*!
	@class		SeaUtilityPanel
	@abstract	Adjusts various attributes of Seashore's utility panels so that
				they behave as desired.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaUtilityPanel : NSPanel {

	// Used for window shading
	float priorShadeHeight;
	
	// Used for window shading
	id priorContentView;
	
	// Used for window shading
	IBOutlet id nullView;
	
}

/*!
	@method		awakeFromNib
	@discussion	Sets this panel to be its own delegate.
*/
- (void)awakeFromNib;

/*!
	@method		canBecomeKeyWindow
	@discussion	Returns whether or not this panel can become the key window.
	@result		Returns NO indicating that this panel should never become the
				key window.
*/
- (BOOL)canBecomeKeyWindow;

/*!
	@method		canBecomeMainWindow
	@discussion	Returns whether or not this panel can become the main window.
	@result		Returns NO indicating that this panel should never become the
				main window.
*/
- (BOOL)canBecomeMainWindow;

/*!
	@method		shade:
	@discussion	Performs a window shade on the window.
	@param		sender
				Ignored.
*/
- (IBAction)shade:(id)sender;

/*!
	@method		windowWillReturnUndoManager:
	@discussion	Returns the undo manager for this window.
	@param		sender
				Ignored.
	@result		Returns the undo manager for the current document ensuring that
				no panel maintains its own undo manager.
*/
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender;

@end
