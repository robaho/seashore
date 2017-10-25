#import "Globals.h"
#import "AbstractSelectTool.h"

/*!
	@class		WandTool
	@abstract	The wand tool allows selections to be made based upon colour
				that are confined to a given tolerance range.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface WandTool : AbstractSelectTool {
	// The point where to start the selection
	IntPoint startPoint;
	
	// The inital point of the selection
	NSPoint startNSPoint;
	
	// The end point of the selection (at the moment)
	NSPoint currentNSPoint;
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
