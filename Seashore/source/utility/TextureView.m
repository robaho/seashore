#import "TextureView.h"
#import "TextureUtility.h"
#import "SeaTexture.h"

@implementation TextureView

- (id)initWithMaster:(id)sender
{
	// Initializes superclass first
	if (![super init])
		return NULL;
	
	// Remember our master
	master = sender;
	
	// Update ourselves
	[self update];
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:NULL];
	int elemNo;
	
	// Make the change and call for an update
	elemNo = ((int)clickPoint.y / kTexturePreviewSize) * kTexturesPerRow + (int)clickPoint.x / kTexturePreviewSize;
	if (elemNo < [[master textures] count]) {
		[master setActiveTextureIndex:elemNo];
		[self setNeedsDisplay:YES];
	}
}

- (void)drawRect:(NSRect)rect
{
	NSArray *textures = [master textures];
	int textureCount =  [textures count];
	int activeTextureIndex = [master activeTextureIndex];
	int i, j, elemNo;
	NSImage *thumbnail;
	NSRect elemRect, tempRect;
	
	// Draw background
	[[NSColor lightGrayColor] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
	
	// Draw each elements
	for (i = rect.origin.x / kTexturePreviewSize; i <= (rect.origin.x + rect.size.width) / kTexturePreviewSize; i++) {
		for (j = rect.origin.y / kTexturePreviewSize; j <= (rect.origin.y + rect.size.height) / kTexturePreviewSize; j++) {
		
			// Determine the element number and rectange
			elemNo = j * kTexturesPerRow + i;
			elemRect = NSMakeRect(i * kTexturePreviewSize, j * kTexturePreviewSize, kTexturePreviewSize, kTexturePreviewSize);
			
			// Continue if we are in range
			if (elemNo < textureCount) {
				
				// Draw the texture background and frame
				[[NSColor whiteColor] set];
				[[NSBezierPath bezierPathWithRect:elemRect] fill];
				if (elemNo != activeTextureIndex) {
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
				thumbnail = [[textures objectAtIndex:elemNo] thumbnail];
				[thumbnail compositeToPoint:NSMakePoint(i * kTexturePreviewSize + kTexturePreviewSize / 2 - [thumbnail size].width / 2, j * kTexturePreviewSize + kTexturePreviewSize / 2 + [thumbnail size].height / 2) operation:NSCompositeSourceOver];
				
			}
			
		}
	}
}

- (void)update
{
	NSArray *textures = [master textures];
	int textureCount =  [textures count];
	NSSize size = NSMakeSize(kTexturePreviewSize * kTexturesPerRow + 1, ((textureCount % kTexturesPerRow == 0) ? (textureCount / kTexturesPerRow) : (textureCount / kTexturesPerRow + 1)) * kTexturePreviewSize);
	
	[self setFrameSize:size];
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
