#import "Globals.h"
#import "AbstractSelectTool.h"

/*!
	@class		EllipseSelectTool
	@abstract	The elliptical selection tool allows selections to be made as an 
				ellipse.
	@discussion	Shift key - ensures a circular selection.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EllipseSelectTool : AbstractSelectTool {

	// The inital point of the selection
	IntPoint startPoint;
	
	// The selection rectangle
	IntRect selectionRect;
	
	// Make the selection one-to-one
	BOOL oneToOne;
}

/*!
	@method		selectionRect
	@discussion	The rectangle of the current selection.
	@result		Returns the rectangle in the overlay's coordinates.
*/
- (IntRect) selectionRect;

/*!
	@method		mouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		cancelSelection
	@discussion	Stops making the selection
*/

- (void)cancelSelection;

@end
