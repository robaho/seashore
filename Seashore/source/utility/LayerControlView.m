#import "LayerControlView.h"
#import "StatusUtility.h"

@implementation LayerControlView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		statusUtility = nil;
    }
    return self;
}

- (void)resetCursorRects
{
	if(drawThumb){
		[self addCursorRect:NSMakeRect([self frame].size.width -20, 0, 20 , [self frame].size.height) cursor:[NSCursor resizeLeftRightCursor]];
	}
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[[NSImage imageNamed:@"layer-gradient"] drawInRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0]; 
	
	if(drawThumb){
	
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
		
		NSBezierPath *tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 4.5 ,[self frame].size.height - 7.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 4.5, 6.5)];
		[tempPath stroke];

		
		tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 7.5 ,[self frame].size.height - 7.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 7.5, 6.5)];
		[tempPath stroke];

		tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 10.5 ,[self frame].size.height - 7.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 10.5, 6.5)];
		[tempPath stroke];

		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];

		tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 3.5 ,[self frame].size.height - 8.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 3.5, 5.5)];
		[tempPath stroke];
		
		tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 6.5 ,[self frame].size.height - 8.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 6.5, 5.5)];
		[tempPath stroke];
		
		tempPath = [NSBezierPath bezierPath];
		[tempPath moveToPoint: NSMakePoint([self frame].size.width - 9.5 ,[self frame].size.height - 8.5)];
		[tempPath lineToPoint:NSMakePoint([self frame].size.width - 9.5, 5.5)];
		[tempPath stroke];
	}else{
		[statusUtility update];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if(!drawThumb) return;
	oldPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	if(oldPoint.x > [self frame].size.width - 20)
		intermediate = YES;
	else
		intermediate = NO;
	oldWidth = [self frame].size.width;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint localPoint;
	localPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	if(intermediate && drawThumb){
		float diff = localPoint.x - oldPoint.x;
		float newWidth = oldWidth + diff;
		// Minimum width
		if(newWidth < 64)
			newWidth = 64;
		
		[delButton setHidden:(newWidth < 75)];
		[dupButton setHidden:(newWidth < 107)];
		[shButton setHidden:(newWidth < 138)];
			
		[leftPane setFrame:NSMakeRect(0, [leftPane frame].origin.y, newWidth, [leftPane frame].size.height)];
		[rightPane setFrame:NSMakeRect(newWidth, [rightPane frame].origin.y, [[rightPane superview] frame].size.width - newWidth, [rightPane frame].size.height)];
		
		[divider setFrame:NSMakeRect(newWidth - 3, [divider frame].origin.y, [divider frame].size.width, [divider frame].size.height)];
		[divider setNeedsDisplay: YES];
		
		[self setNeedsDisplay:YES];
		[leftPane setNeedsDisplay:YES];
		[rightPane setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	intermediate = NO;
}

- (void)setHasResizeThumb:(BOOL)hasThumb
{
	drawThumb = hasThumb;
}

@end
