#import "Globals.h"
#import "AbstractTool.h"

/*!
	@struct		CTPointRecord
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
} CTPointRecord;

/*!
	@defined	kMaxBTPoints
	@discussion	Specifies the maximum number of points.
*/
#define kMaxBTPoints 16384

/*!
	@class		CloneTool
	@abstract	The paintbrush's role in Seashore is much the same as that in
				the GIMP. 
	@discussion	Shift key - Draws straight lines.<br>Option key - Changes
				the brush to an eraser.<br>Control key - Draws lines at
				45 degree intervals.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface CloneTool : AbstractTool {

	// The last point we've been and the last point a brush was plotted (there is a difference)
	NSPoint lastPoint, lastPlotPoint;
	
	// The initial point of the draw
	IntPoint startPoint;
	
	// The set of pixels upon which to base the brush plot
	unsigned char basePixel[4];
	
	// The distance travelled by the brush so far
	double distance;
	
	// Are we erasing stuff?
	BOOL isErasing;
	
	// The current position in the list we have drawing
	int drawingPos;
	
	// The current position in the list
	int pos;
	
	// The list of points
	CTPointRecord *points;
	
	// Have we finished drawing?
	BOOL drawingDone;
	
	// Is drawing multithreaded?
	BOOL multithreaded;
	
	// Has the first touch been done?
	BOOL firstTouchDone;
	
	// The last where recorded
	IntPoint lastWhere;
	
	// The last pressure value
	int lastPressure;
	
	// The source point
	IntPoint sourcePoint;
	
	// The layer offset of the source point
	IntPoint layerOff;
	
	// Has the source been set?
	BOOL sourceSet;
	
	// How far has the source been setting?
	int sourceSetting;
	
	// A timer to allow the source to set
	id fadingTimer;
	
	// The index of the layer from which the source is drawn
	id sourceLayer;
	
	// YES if the merged data should be used, NO otherwise
	BOOL sourceMerged;
	
	// The merged data from which the clone tool is working (only allocated between mouse clicks)
	unsigned char *mergedData;
	
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
	@method		sourceSet
	@discussion	Returns whether the source point has been set.
	@result		Returns YES if the source point is set, NO otherwise.
*/
- (BOOL)sourceSet;

/*!
	@method		sourceSetting
	@discussion	Is the source point setting?
	@result		Returns an integer between 0 and 100 (gradually decreasing with
				fading).
*/
- (int)sourceSetting;

/*!
	@method		sourcePoint
	@discussion	Returns the source point.
	@param		local
				YES if the point should be returned in the layer's co-ordinates,
				NO if it should be returned in the document's co-ordinates.
	@result		Returns an IntPoint representing the source point.
*/
- (IntPoint)sourcePoint:(BOOL)local;

/*!
	@method		sourceName
	@discussion	Returns the name of the source.
	@result		Returns a string indicating the source's name (e.g. the name of
				the source layer)
*/
- (NSString *)sourceName;

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
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

/*!
	@method		unset
	@discussion Unsets the source point (also updates the options).
*/
- (void)unset;

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
