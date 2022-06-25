#import "Seashore.h"
#import "CloneOptions.h"
#import "AbstractBrushTool.h"
#import "SeaLayer.h"

@interface CloneTool : AbstractBrushTool {
	// The source point
	IntPoint sourcePoint;

    // The initial point of the draw
    IntPoint startPoint;
	
	// The layer offset of the source point
	IntPoint layerOff;
	
	// Has the source been set?
	BOOL sourceSet;
	
	// How far has the source been setting?
	int fadeLevel;
	
	// A timer to allow the source to set
	id fadingTimer;
	
	// The index of the layer from which the source is drawn
	SeaLayer *sourceLayer;
	
	// YES if the merged data should be used, NO otherwise
	BOOL sourceMerged;
	
	// The merged data from which the clone tool is working (only allocated between mouse clicks)
	unsigned char *mergedData;
    
    CloneOptions *options;
}

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
	@method		fadeLevel
	@discussion	The 'fade level' of source point after being selected.
	@result		Returns an integer between 1 and 0 (gradually decreasing with
				fading).
*/
- (float)fadeLevel;

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
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		where
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;

@end
