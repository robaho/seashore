#import "Globals.h"
#import "AbstractTool.h"

/*!
	@struct		ETPointRecord
	@discussion	Specifies a point to be drawn.
	@param		point
				The point to be drawn.
	@param		pressure
				The presure of the point to be drawn
	@param		special
				0 = normal, 2 = terminate
*/
typedef struct {
	IntPoint point;
	unsigned char pressure;
	unsigned char special;
} ETPointRecord;

/*!
	@defined	kMaxPoints
	@discussion	Specifies the maximum number of points.
*/
#define kMaxETPoints 16384

/*!
	@class		BrushTool
	@abstract	The paintbrush's role in Seashore is much the same as that in
				the GIMP. 
	@discussion	Shift key - Draws straight lines.<br>Control key - Draws lines
				at 45 degree intervals.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface EraserTool : AbstractTool
{

	// The last point we've been and the last point a brush was plotted (there is a difference)
	NSPoint lastPoint, lastPlotPoint;
	
	// The set of pixels upon which to base the brush plot
	unsigned char basePixel[4];
	
	// The distance travelled by the brush so far
	double distance;
	
	// The current position in the list we have drawing
	int drawingPos;
	
	// The current position in the list
	int pos;
	
	// The list of points
	ETPointRecord *points;
	
	// Have we finished drawing?
	BOOL drawingDone;
	
	// Is drawing multithreaded?
	BOOL multithreaded;
		
	// Has the first touch been done?
	BOOL firstTouchDone;

	// The last where recorded
	IntPoint lastWhere;
	
}
/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

/*!
	@method		acceptsLineDraws
	@discussion	Returns whether or not this tool wants to allow line draws.
	@result		Returns YES if the tool does want to allow line draws, NO
				otherwise. The implementation in this class always returns YES.
*/
- (BOOL)acceptsLineDraws;

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
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse down event.
*/
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		drawThread:
	@discussion	Handles drawing.
	@param		object
				Ignored.
*/
- (void)drawThread:(id)object;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		where
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		modifiers
				The state of the modifiers at the time (see NSEvent).
	@param		event
				The mouse dragged event.
*/
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		endLineDrawing
	@discussion	Ends line drawing.
*/
- (void)endLineDrawing;

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
