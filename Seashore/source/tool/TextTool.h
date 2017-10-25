#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		TextTool
	@abstract	The text tool's role is much the same as in any paint program.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TextTool : AbstractTool {

	// The preview panel
	IBOutlet id panel;
	
	// The move panel
	IBOutlet id movePanel;
	
	// The preview text box
	IBOutlet id textbox;
	
	// The font manager associated with the text tool
	id fontManager;

	// The point where the mouse was released
	IntPoint where;
	
	// The rect containing the preview
	IntRect previewRect;
	
	// Is the tool running?
	BOOL running;
	
}

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		iwhere
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)iwhere withEvent:(NSEvent *)event;

/*!
	@method		apply:
	@discussion	Called to close the text specification dialog and apply the
				changes.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

/*!
	@method		cancel:
	@discussion	Called to close the text specification dialog and not apply the
				changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		preview:
	@discussion	Called to preview the text.
	@param		sender
				Ignored.
*/
- (IBAction)preview:(id)sender;

/*!
	@method		showFonts:
	@discussion	Shows the fonts panel to select the font to be used for the
				text.
	@param		sender
				Ignored.
*/
- (IBAction)showFonts:(id)sender;

/*!
	@method		move:
	@discussion	Shows the move panel to allow moving.
	@param		sender
				Ignored.
*/
- (IBAction)move:(id)sender;

/*!
	@method		doneMove:
	@discussion	Ends the move panel and applies the text.
	@param		sender
				Ignored.
*/
- (IBAction)doneMove:(id)sender;

/*!
	@method		cancelMove:
	@discussion	Ends the move panel and returns to the text specification panel.
	@param		sender
				Ignored.
*/
- (IBAction)cancelMove:(id)sender;

/*!
	@method		setNudge:
	@discussion	Nudges the text in the given direction.
	@param		nudge
				An IntPoint specifying the amount to nudge by in each direction.
*/
- (void)setNudge:(IntPoint)nudge;

/*!
	@method		centerHorizontally
	@discussion	Centres the text horizontally.
*/
- (void)centerHorizontally;

/*!
	@method		centerVertically
	@discussion	Centres the text vertically.
*/
- (void)centerVertically;

@end
