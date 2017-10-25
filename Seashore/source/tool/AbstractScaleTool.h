#import "Globals.h"

/*!
 @enum		k...Dir
 @constant	kNoDir
 @constant	kULDir
 @constant	kUDir
 @constant	kURDir
 @constant	kRDir
 @constant	kDRDir
 @constant	kDDir
 @constant	kDLDir
 @constant	kLDir 
 */
enum {
	kNoDir = -1,
	kULDir,
	kUDir,
	kURDir,
	kRDir,
	kDRDir,
	kDDir,
	kDLDir,
	kLDir
};

/*!
	@class		AbstractScaleTool
	@abstract	Acts as a base class for all scaling/translating actions.
	@discussion	This is because this functionality is shared between all
				of the various selection tools.
	<br><br>
	<b>License:</b> GNU General Public License<br>
	<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import "AbstractTool.h"

@interface AbstractScaleTool : AbstractTool {
	// Are we moving
	BOOL translating;
	
	// The origin of moving
	IntPoint moveOrigin;
	
	// The old origin
	IntPoint oldOrigin;
	
	// The direction of currently scaling (if any)
	int scalingDir;
	
	// The mask of the selection before it was scaled
	unsigned char * preScaledMask;
	
	// The rectangle of the selection before it was scaled
	IntRect preScaledRect;
	
	// The rectangle after it's being scaled
	IntRect postScaledRect;

}

/*!
	@method		isMovingOrScaling
	@discussion	If the thing is being translated or transformed
	@result		Returns a BOOL: YES of it is moving / scaling
*/
- (BOOL) isMovingOrScaling;

/*!
	@method		mouseDownAt:forRect:andMask:
	@discussion	Handles mouse down events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
*/
- (void)mouseDownAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		mouseDraggedTo:withEvent:
	@discussion	Handles mouse dragging events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
	@result		Returns an IntRect with the new coordinates
*/
- (IntRect)mouseDraggedTo:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		localPoint
				Where in the document the mouse down event occurred (in terms of
				the document's pixels).
	@param		globalRect
				The rectangle that we might be scaling or moving
	@param		mask
				If the rectangle is just a bounding box this is the internal mask
*/
- (void)mouseUpAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask;

/*!
	@method		point:isInHandleFor:
	@discussion	Tests to see if the point is in a handle for the given rectangle.
	@param		point
				The point to be tested.
	@param		rect
				The specified rectangle to check for handles.
*/
- (int)point:(NSPoint) point isInHandleFor:(IntRect)rect;

/*!
	@method		preScaledRect
	@discussion	For determining the previous rect for scaling.
	@result		An IntRect
*/
- (IntRect) preScaledRect;

/*!
	@method		preScaledMask
	@discussion	For determining the old mask.
	@result		An bitmap
*/
- (unsigned char *) preScaledMask;

/*!
	@method		postScaledRect
	@discussion	For determining the rect to draw.
	@result		An IntRect
*/
- (IntRect) postScaledRect;

@end
