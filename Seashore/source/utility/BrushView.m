#import "BrushView.h"
#import "BrushUtility.h"
#import "SeaBrush.h"

@implementation BrushView

- (id)initWithMaster:(id)sender
{
	if (![super init])
		return NULL;
	
	master = sender;
	[self update];
	
	return self;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:NULL];
	int elemNo;
	
	// Make the change and call for an update
	elemNo = ((int)clickPoint.y / kBrushPreviewSize) * kBrushesPerRow + (int)clickPoint.x / kBrushPreviewSize;
	if (elemNo < [[master brushes] count]) {
		[master setActiveBrushIndex:elemNo];
		[self setNeedsDisplay:YES];
	}
    
    if(event.clickCount > 1){
        [master closePanel:self];
    }
}

- (void)drawRect:(NSRect)rect
{
	NSArray *brushes = [master brushes];
	int brushCount =  [brushes count];
	int activeBrushIndex = [master activeBrushIndex];
	int i, j, elemNo;
	NSRect elemRect, tempRect;
	
	// Draw background
	[[NSColor controlBackgroundColor] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
		
	// Draw each elements
	for (i = rect.origin.x / kBrushPreviewSize; i <= (rect.origin.x + rect.size.width) / kBrushPreviewSize; i++) {
		for (j = rect.origin.y / kBrushPreviewSize; j <= (rect.origin.y + rect.size.height) / kBrushPreviewSize; j++) {
		
			// Determine the element number and rectange
			elemNo = j * kBrushesPerRow + i;
			elemRect = NSMakeRect(i * kBrushPreviewSize, j * kBrushPreviewSize, kBrushPreviewSize, kBrushPreviewSize);
			
			// Continue if we are in range
			if (elemNo < brushCount) {
				
				// Draw the brush background and frame
				[[NSColor whiteColor] set];
				[[NSBezierPath bezierPathWithRect:elemRect] fill];
				if (elemNo != activeBrushIndex) {
					[[NSColor grayColor] set];
					[NSBezierPath setDefaultLineWidth:1];
					[[NSBezierPath bezierPathWithRect:elemRect] stroke];
				}
				else {
					[[NSColor blackColor] set];
					[NSBezierPath setDefaultLineWidth:2];
					tempRect = elemRect;
					tempRect.origin.x++; tempRect.origin.y++; tempRect.size.width -= 2; tempRect.size.height -= 2;
					[[NSBezierPath bezierPathWithRect:tempRect] stroke];
				}
                
                [[brushes objectAtIndex:elemNo] drawBrushAt:elemRect];
            }
			
		}
	}
}

- (void)update
{
	NSArray *brushes = [master brushes];
	int brushCount =  [brushes count];
	
	[self setFrameSize:NSMakeSize(kBrushPreviewSize * kBrushesPerRow + 1, ((brushCount % kBrushesPerRow == 0) ? (brushCount / kBrushesPerRow) : (brushCount / kBrushesPerRow + 1)) * kBrushPreviewSize)];
    [self setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return YES;
}

@end
