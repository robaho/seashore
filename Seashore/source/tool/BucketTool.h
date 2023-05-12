#import "Seashore.h"
#import "BucketOptions.h"
#import "AbstractTool.h"

/*!
	@class		BucketTool
	@abstract	The paintbucket's role is much the same as in any paint program.
	@discussion	Options key - Fills the entire document or selection area
				ignoring tolerance settings.
				<br>
				Shift key - Does not commit the changes after the mouse button
				is released.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BucketTool : AbstractTool <DraggableTool> {
	// The update rectangle associated with the last fill 
	IntRect rect;
    IntPoint startPoint,currentPoint;

	// You can preview by holding down shift, so we need to track that
	BOOL isPreviewing;
    
    BucketOptions *options;
    CGContextRef textureCtx;
}

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
	@method		startPoint
	@discussion	For figuring out where to draw the center
*/
- (IntPoint)start;

/*!
	@method		currentPoint
	@discussion	For figuring out where to draw the outside
*/
- (IntPoint)current;

@end
