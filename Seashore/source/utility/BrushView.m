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

- (void)dealloc
{
	[super dealloc];
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
}

- (void)drawRect:(NSRect)rect
{
	NSArray *brushes = [master brushes];
	int brushCount =  [brushes count];
	int activeBrushIndex = [master activeBrushIndex];
	int i, j, elemNo;
	NSImage *thumbnail;
	NSRect elemRect, tempRect;
	NSString *pixelTag;
	NSDictionary *attributes;
	NSFont *font;
	IntSize fontSize;
	
	// Draw background
	[[NSColor lightGrayColor] set];
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
				
				// Draw the thumbnail
				thumbnail = [[brushes objectAtIndex:elemNo] thumbnail];
				[thumbnail compositeToPoint:NSMakePoint(i * kBrushPreviewSize + kBrushPreviewSize / 2 - [thumbnail size].width / 2, j * kBrushPreviewSize + kBrushPreviewSize / 2 + [thumbnail size].height / 2) operation:NSCompositeSourceOver];
				
				// Draw the pixel tag if needed
				pixelTag = [[brushes objectAtIndex:elemNo] pixelTag];
				if (pixelTag) {
					font = [NSFont systemFontOfSize:9.0];
					attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSForegroundColorAttributeName, NULL];
					fontSize = NSSizeMakeIntSize([pixelTag sizeWithAttributes:attributes]);
					[pixelTag drawAtPoint:NSMakePoint(elemRect.origin.x + elemRect.size.width / 2 - fontSize.width / 2, elemRect.origin.y + elemRect.size.height / 2 - fontSize.height / 2) withAttributes:attributes];
				}
				
			}
			
		}
	}
}

- (void)update
{
	NSArray *brushes = [master brushes];
	int brushCount =  [brushes count];
	
	[self setFrameSize:NSMakeSize(kBrushPreviewSize * kBrushesPerRow + 1, ((brushCount % kBrushesPerRow == 0) ? (brushCount / kBrushesPerRow) : (brushCount / kBrushesPerRow + 1)) * kBrushPreviewSize)];
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
