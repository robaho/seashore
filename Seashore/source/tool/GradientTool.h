#import "Globals.h"
#import "GradientOptions.h"
#import "AbstractTool.h"

/*!
	@class		GradientTool
	@abstract	The gradient tool allows the user to fill the selected area with
				the selected gradient.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface GradientTool : AbstractTool
{
	
	// The point where to start the gradient
	IntPoint startPoint;
	NSPoint startNSPoint;
	
	// The temporary point we've dragged to
	NSPoint tempNSPoint;
    
    GradientOptions *options;
	
}

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		start
	@discussion	Returns the start point.
	@result		Returns an NSPoint of the start of the tool.
*/
- (NSPoint)start;

/*!
	@method		current
	@discussion	Returns the current point.
	@result		Returns the NSPoint of where the mouse is currently dragged to.
*/
- (NSPoint)current;

@end
