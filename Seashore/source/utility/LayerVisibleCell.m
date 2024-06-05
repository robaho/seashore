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

    cellFrame = NSGrowRect(cellFrame,2);

    SeaLayer *layer = (SeaLayer*)[self representedObject];
    if([layer visible]) {
        NSImage *img = getTinted(image, [NSColor alternateSelectedControlColor]);
        [img drawInRect:scaledRect(img,cellFrame)];
    } else {
        NSImage *img = getTinted(image, [NSColor controlTextColor]);
        [img drawInRect:scaledRect(img,cellFrame) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:.5];
    }
}
@end
