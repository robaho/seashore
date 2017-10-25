#import "BrushView.h"
#import "BrushDocument.h"

@implementation BrushView

- (void)drawRect:(NSRect)rect
{
	NSImage *brushImage = [document brushImage];
	NSPoint where;
	
	// Fill in background
	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] fill];
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] stroke];
	
	// Center and draw the image of the brush
	if (brushImage != NULL) {
		if (([brushImage size].width > [self bounds].size.width - 20.0) && ([brushImage size].height * ([self bounds].size.width - 20.0) / [brushImage size].width <= [self bounds].size.height)) {
			[brushImage setScalesWhenResized:YES];
			[brushImage setSize:NSMakeSize([self bounds].size.width - 20.0, [brushImage size].height * ([self bounds].size.width - 20.0) / [brushImage size].width)];
		}
		else if (([brushImage size].height > [self bounds].size.height - 20.0) && ([brushImage size].width * ([self bounds].size.height - 20.0) / [brushImage size].height <= [self bounds].size.width)) {
			[brushImage setScalesWhenResized:YES];
			[brushImage setSize:NSMakeSize([brushImage size].width * ([self bounds].size.height - 20.0) / [brushImage size].height, [self bounds].size.height - 20.0)];
		}
		where.x = [self bounds].size.width / 2 - [brushImage size].width / 2;
		where.y = [self bounds].size.height / 2 - [brushImage size].height / 2;
		[brushImage compositeToPoint:where operation:NSCompositeSourceOver];
	}
}

@end
