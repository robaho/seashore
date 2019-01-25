#import "LayerControlView.h"
#import "StatusUtility.h"
#import "SeaProxy.h"
#import "SeaController.h"

@implementation LayerControlView


- (void)resetCursorRects
{
    [self addCursorRect:[grabberImage frame] cursor:[NSCursor resizeLeftRightCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	oldPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
    NSRect bounds = [grabberImage frame];
    if([self mouse:oldPoint inRect:bounds]) {
		dragging = YES;
    } else
		dragging = NO;
	oldWidth = [self frame].size.width;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint localPoint;
	localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	if(dragging){
		float diff = localPoint.x - oldPoint.x;
		float newWidth = oldWidth + diff;
		// Minimum width
		if(newWidth < 64)
			newWidth = 64;
		
        [leftPane setFrame:NSMakeRect(0, [leftPane frame].origin.y, newWidth, [leftPane frame].size.height)];
        [rightPane setFrame:NSMakeRect(newWidth, [rightPane frame].origin.y, [[rightPane superview] frame].size.width - newWidth, [rightPane frame].size.height)];
        
        NSRect grabberFrame = [grabberImage frame];
        [delButton setHidden:NSIntersectsRect(grabberFrame,[delButton frame])];
        [dupButton setHidden:NSIntersectsRect(grabberFrame,[dupButton frame])];
        [infoButton setHidden:NSIntersectsRect(grabberFrame,[infoButton frame])];
        
		[self setNeedsDisplay:YES];
		[leftPane setNeedsDisplay:YES];
		[rightPane setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	dragging = NO;
}

- (IBAction)newLayer:(id)sender {
    [(SeaProxy*)[SeaController seaProxy] addLayer:sender];
}

- (IBAction)duplicateLayer:(id)sender {
    [(SeaProxy*)[SeaController seaProxy] duplicateLayer:sender];
}

- (IBAction)removeLayer:(id)sender {
    [(SeaProxy*)[SeaController seaProxy] deleteLayer:sender];
}
@end
