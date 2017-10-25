#import "Globals.h"

/*!
	@class		ColorSelectView
	@abstract	Represents the current colour selection to the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface ColorSelectView : NSView {

	// The document associated with this colour selection view
	id document;

	// YES if the mouse is down on the swap button
	BOOL mouseDownOnSwap;

	// The texture utility
	IBOutlet id textureUtility;
	
}

/*!
	@method		initWithFrame:
	@discussion	Initializes an instance of this class with the given frame.
	@param		frame
				The frame with which to initialize the view.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithFrame:(NSRect)frame;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		setDocument:
	@discussion	Sets the view and its associated panels to reflect the colours
				of the given document.
	@param		doc
				The document whose colours should be reflected.
*/
- (void)setDocument:(id)doc;

/*!
	@method		acceptsFirstMouse:
	@discussion	Returns whether or not the window accepts the first mouse click
				upon it.
	@param		event
				Ignored.
	@result		Returns YES indicating that the window does accept the first
				mouse click upon it.
*/
- (BOOL)acceptsFirstMouse:(NSEvent *)event;

/*!
	@method		drawRect:
	@discussion	Draws the contents of the view within the given rectangle.
	@param		rect
				The rectangle containing the contents to be drawn.
*/
- (void)drawRect:(NSRect)rect;

/*!
	@method		activateForegroundColor
	@discussion	Activates the foreground color panel.\
	@param		sender
				Ignored.
*/
- (IBAction)activateForegroundColor:(id)sender;

/*!
	@method		activateBackgroundColor
	@discussion	Activates the background color panel.
	@param		sender
				Ignored.
*/
- (IBAction)activateBackgroundColor:(id)sender;

/*!
	@method		swapColors
	@discussion	Swaps the foreground and background colors.
	@param		sender
				Ignored.
*/
- (IBAction)swapColors:(id)sender;

/*!
	@method		defaultColors
	@discussion	Sets the foreground and background colors to their defaults.
	@param		sender
				Ignored.
*/
- (IBAction)defaultColors:(id)sender;

/*!
	@method		mouseDown:
	@discussion	Handles mouse down events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseDown:(NSEvent *)theEvent;

/*!
	@method		mouseUp:
	@discussion	Handles mouse up events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseUp:(NSEvent *)theEvent;

/*!
	@method		changeForegroundColor:
	@discussion	Called when the foreground colour is changed. Updates the view
				and active document.
	@param		sender
				The colour panel responsible for the change in colour.
*/
- (void)changeForegroundColor:(id)sender;

/*!
	@method		changeBackgroundColor:
	@discussion	Called when the background colour is changed. Updates the view
				and active document.
	@param		sender
				The colour panel responsible for the change in colour.
*/
- (void)changeBackgroundColor:(id)sender;

/*!
	@method		update
	@discussion	Updates the view and its associated panels to reflect the
				currently selected background and foreground colours.
*/
- (void)update;

/*!
	@method		isFlipped
	@discussion	Returns whether or not the view uses a flipped co-ordinate
				system.
	@result		Returns YES indicating that the view does use a flipped
				co-ordinate system.
*/
- (BOOL)isFlipped;

/*!
	@method		isOpaque
	@discussion	Returns whether or not the view is opaque.
	@result		Returns NO indicating that the view is opaque.
*/
- (BOOL)isOpaque;

@end
