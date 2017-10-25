#import "Globals.h"
#import "AbstractTool.h"

/*!
	@class		SmudgeTool
	@abstract	The smudge tool allows the user to smudge certain parts of a
				picutre, removing unwanted figures or edges.
	@discussion	The implementation of smudging is not complete.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SmudgeTool : AbstractTool {
	
	// The accumulated data
	unsigned char *accumData;
	
	// The last point we've been and the last point a brush was plotted (there is a difference)
	NSPoint lastPoint, lastPlotPoint;
	
	// The distance travelled by the brush so far
	double distance;
	
	// The last where recorded
	IntPoint lastWhere;
	
}

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		useMouseCoalescing
	@discussion	Returns whether or not this tool should use mouse coalescing.
	@result		Returns YES if this tool should use mouse coalescing, NO
				otherwise.
*/
- (BOOL)useMouseCoalescing;

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
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		startStroke:
	@discussion	Starts a stroke at a specified point.
	@param		where
				Where in the document to start the stroke at.
*/
- (void)startStroke:(IntPoint)where;

/*!
	@method		intermediateStroke:
	@discussion	Specifies an intermediate point in the stroke.
	@param		Where in the document to place the intermediate
				stroke.
*/
- (void)intermediateStroke:(IntPoint)where;

/*!
	@method		endStroke:
	@discussion	Ends a stroke at a specified point.
	@param		where
				Where in the document to end the stroke at.
*/
- (void)endStroke:(IntPoint)where;

@end
