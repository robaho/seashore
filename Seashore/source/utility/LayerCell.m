#import "LayerCell.h"
#import "NSBezierPath_Extensions.h"

@implementation LayerCell

- (id)init
{
    if (self = [super init]) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
        [self setSelectable:YES];
    }
    return self;
}

- (void)dealloc
{
    [image release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    LayerCell *cell = (LayerCell *)[super copyWithZone:zone];
    // The image ivar will be directly copied; we need to retain or copy it.
    cell->image = [image retain];
    return cell;
}

- (void)setImage:(NSImage *)anImage
{
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (NSImage *)image
{
    return image;
}

- (NSRect)imageRectForBounds:(NSRect)cellFrame
{
    NSRect result;
    if (image != nil) {
        result.size = [image size];
        result.origin = cellFrame.origin;
        result.origin.x += 3;
        result.origin.y += ceil((cellFrame.size.height - result.size.height) / 2);
    } else {
        result = NSZeroRect;
    }
    return result;
}

// We could manually implement expansionFrameWithFrame:inView: and drawWithExpansionFrame:inView: or just properly implement titleRectForBounds to get expansion tooltips to automatically work for us
- (NSRect)titleRectForBounds:(NSRect)cellFrame
{
    NSRect result;
    if (image != nil) {
        float imageWidth = [image size].width;
        result = cellFrame;
        result.origin.x += (3 + imageWidth);
        result.size.width -= (3 + imageWidth);
    } else {
        result = NSZeroRect;
    }
    return result;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (image != nil) {
		[NSGraphicsContext saveGraphicsState];
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset: NSMakeSize(1, 1)];
		[shadow setShadowBlurRadius:2];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow set];
		
		NSRect	imageFrame;
        NSSize imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 8 + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
		
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [[NSImage imageNamed:@"checkerboard"] drawInRect:NSMakeRect(imageFrame.origin.x, imageFrame.origin.y - imageSize.height, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];

		cellFrame.size.height = 18;
		cellFrame.origin.y += 10;
		NSDictionary *attrs;
		if(selected){
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
			[[self stringValue] drawInRect:cellFrame withAttributes:attrs];
			[NSGraphicsContext restoreGraphicsState];
		}else{
			[NSGraphicsContext restoreGraphicsState];
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, nil];
			[[self stringValue] drawInRect:cellFrame withAttributes:attrs];
		}
		
        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}else{
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}

- (void) setSelected:(BOOL)isSelected
{
	selected = isSelected;
}

@end
