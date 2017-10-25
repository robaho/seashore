#import "Globals.h"
#import "AbstractScaleTool.h"
#import "LassoTool.h"

/*!
	@class		PolygonLassoTool
	@abstract	The polygon lasso tool allows polygonal selections of no specific shape
	@discussion	Option key - floats the selection.
				This is a subclass of the LassoTool, because some of the functionality
				is shared and it reduces duplicate code.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PolygonLassoTool : LassoTool {
	// The beginning point of the polygonal lasso tool.
	// Represented by the white dot in the view.
	NSPoint startPoint;
}

/*!
	@method		fineMouseDownAt:withEvent:
	@discussion	Handles mouse down events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse down event.
*/
- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse dragged event.
*/
- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;

/*!
	@method		fineMouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;

@end
