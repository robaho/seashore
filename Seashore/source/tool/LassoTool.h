#import "Globals.h"
#import "AbstractSelectTool.h"

/*!
	@defined	kMaxLTPoints
	@discussion	Specifies the maximum number of points.
*/
#define kMaxLTPoints 16384

/*!
 @struct		LassoPoints
 @discussion	For storing a list of points and a position in the list
 @field			points
				A finite array of points
 @field			pos
				The current location in the array
*/
typedef struct {
	IntPoint *points;
	int pos;
} LassoPoints;

/*!
	@class		LassoTool
	@abstract	The selection tool allows freeform selections of no specific shape
	@discussion	Option key - floats the selection.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface LassoTool : AbstractSelectTool {

	// The list of points
	IntPoint *points;
	
	// The last point
	NSPoint lastPoint;
	
	// The current position in the list
	int pos;

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

/*!
	@method		isFineTool
	@discussion	Returns whether the tool needs an NSPoint input as opposed to an IntPoint
				input (i.e. whether fineMouse... or mouse... should be called).
	@result		Returns YES if the tool needs an NSPoint input as opposed to an IntPoint
				input, NO otherwise. The implementation in this class always returns YES.
*/
- (BOOL)isFineTool;

/*!
	@method		currentPoints
	@discussion	Returns the current points used by the tool for other classes to use.
	@result		A LassoPoints struct
*/
- (LassoPoints) currentPoints;

@end
