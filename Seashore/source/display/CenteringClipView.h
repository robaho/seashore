#import "Seashore.h"

/*!
	@class		CenteringClipView
	@discussion	Essentially NSClipView now, using built-in magnification support of NSScrollView
*/

@interface CenteringClipView : NSClipView {
    NSView *overlay;
}

/*!
	@method		centerPoint:
	@result		Returns a NSPoint indicating the point relative to the document
				contents at the centre of the clip view.
*/
- (NSPoint)centerPoint;

@end
