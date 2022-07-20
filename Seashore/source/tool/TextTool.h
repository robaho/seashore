#import "Seashore.h"
#import "TextOptions.h"
#import "AbstractScaleTool.h"

/*!
	@class		TextTool
	@abstract	The text tool's role is much the same as in any paint program.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface TextTool : AbstractScaleTool {

    // The point where the selection begun
    IntPoint startPoint;

    // The rectangle used for cropping
    IntRect textRect;

    // Are we using the one-to-one ratio?
    BOOL oneToOne;

    TextOptions *options;
	
}

- (IntRect)textRect;

/*!
	@method		mouseUpAt:withEvent:
	@discussion	Handles mouse up events.
	@param		iwhere
				Where in the document the mouse up event occurred (in terms of
				the document's pixels).
	@param		event
				The mouse up event.
*/
- (void)mouseUpAt:(IntPoint)iwhere withEvent:(NSEvent *)event;

- (IBAction)addAsNewLayer:(id)sender;
- (IBAction)mergeWithLayer:(id)sender;

/*!
 @method        drawText
 @discussion    draw the text into the provided  graphics context. The drawing uses 'document' coordinates.
 */
- (void)drawText:(CGContextRef)ctx;

- (bool)canResize;
@end
