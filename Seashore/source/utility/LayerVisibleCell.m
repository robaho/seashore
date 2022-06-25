#import "LayerVisibleCell.h"
#import "SeaLayer.h"
#import <SeaLibrary/Bitmap.h>

@implementation LayerVisibleCell

- (NSCell*)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    image = [NSImage imageNamed:@"trueviewTemplate"];
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    int h = [image size].height;
    int h0 = cellFrame.size.height - h;

    NSRect r = NSMakeRect(cellFrame.origin.x,cellFrame.origin.y+h0/2,[image size].width,[image size].height);

    SeaLayer *layer = (SeaLayer*)[self representedObject];
    if([layer visible]) {
        NSImage *img = getTinted(image, [NSColor alternateSelectedControlColor]);
        [img drawInRect:r];
    } else {
        NSImage *img = getTinted(image, [NSColor controlTextColor]);
        [img drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:.5];
    }
}
@end
