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
	NSRect elemRect;

	// Draw each elements
	for (i = rect.origin.x / kBrushPreviewSize; i <= (rect.origin.x + rect.size.width) / kBrushPreviewSize; i++) {
		for (j = rect.origin.y / kBrushPreviewSize; j <= (rect.origin.y + rect.size.height) / kBrushPreviewSize; j++) {
		
			// Determine the element number and rectange
			elemNo = j * kBrushesPerRow + i;
			elemRect = NSMakeRect(i * kBrushPreviewSize, j * kBrushPreviewSize, kBrushPreviewSize, kBrushPreviewSize);

            NSRect drawRect = NSInsetRect(elemRect,3,3);
			
            [[NSColor controlBackgroundColor] set];
            [[NSBezierPath bezierPathWithRect:elemRect] fill];
            
			// Continue if we are in range
			if (elemNo < brushCount) {
                
                [[brushes objectAtIndex:elemNo] drawBrushAt:drawRect];
                
				if (elemNo == activeBrushIndex) {
                    [NSBezierPath setDefaultLineWidth:2];
					[[NSColor selectedControlColor] set];
                } else {
                    [NSBezierPath setDefaultLineWidth:2];
                    [[NSColor gridColor] set];
                }
                [[NSBezierPath bezierPathWithRect:NSInsetRect(elemRect,2,2)] stroke];

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
