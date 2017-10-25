#import "Globals.h"

/*!
	@defined	kBrushPreviewSize
	@discussion	Defines the preview size of the brushes in the view.
*/
#define kBrushPreviewSize 48

/*!
	@defined	kBrushesPerRow
	@discussion	Defines the number of brushes per row in the view.
*/
#define kBrushesPerRow 5

/*!
	@class		BrushView
	@abstract	Displays all available brushes for easy selection by the user.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli	
*/

@interface BrushView : NSView {
	
	// The BrushUtility controlling this view
	id master;
	
}

/*!
	@method		initWithMaster:
	@discussion	Initializes an instance of this class with the given master.
	@param		sender
				The brush utility that will control the contents of this view.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithMaster:(id)sender;

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		mouseDown:
	@discussion	Handles mouse down events inside the view.
	@param		theEvent
				The event triggering this method.
*/
- (void)mouseDown:(NSEvent *)event;

/*!
	@method		drawRect:
	@discussion	Draws the contents of the view within the given rectangle.
	@param		rect
				The rectangle containing the contents to be drawn.
*/
- (void)drawRect:(NSRect)rect;

/*!
	@method		update
	@discussion	Updates the view to reflect the brushes currently available for
				selection.
*/
- (void)update;

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
	@result		Returns YES indicating that the view is opaque.
*/
- (BOOL)isOpaque;

@end
