#import "Globals.h"
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

@interface BucketTool : AbstractTool {
	// The point where to start the selection
	IntPoint startPoint;

	// The update rectangle associated with the last fill 
	IntRect rect;

	// The inital point of the selection
	NSPoint startNSPoint;
		
	// The end point of the selection (at the moment)
	NSPoint currentNSPoint;
	
	// You can preview by holding down shift, so we need to track that
	BOOL isPreviewing;
}

/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
*/
- (void)dealloc;

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
	@method		fillAtPoint:useTolerance:delay:
	@param		point
				The point from which to fill.
	@param		useTolerance
				YES if the tolerance settings should be use, NO if the tolerance
				settings should be ignored the bucket should fill all of the
				selected area or document. 
	@param		delay
				YES if the application of the filled overlay should be postponed
				until the caller calls applyOverlay, NO otherwise.
*/
- (void)fillAtPoint:(IntPoint)point useTolerance:(BOOL)useTolerance delay:(BOOL)delay;

/*!
	@method		startPoint
	@discussion	For figuring out where to draw the center
	@result		Returns an NSPoint
*/
- (NSPoint)start;

/*!
	@method		currentPoint
	@discussion	For figuring out where to draw the outside
	@result		Returns an NSPoint
*/
- (NSPoint)current;

@end
