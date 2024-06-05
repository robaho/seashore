#import "LayerInfoCell.h"
#import "SeaLayer.h"
#import <SeaLibrary/Bitmap.h>

@implementation LayerInfoCell

- (NSCell*)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    info_image = [NSImage imageNamed:@"layer-infoTemplate"];
    link_image = [NSImage imageNamed:@"linkTemplate"];
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect r = NSMakeRect(cellFrame.origin.x,cellFrame.origin.y,cellFrame.size.width,cellFrame.size.height/2);
    NSImage *img = getTinted(info_image, [NSColor controlTextColor]);
    [img drawInRect:scaledRect(img,NSInsetRect(r,2,2)) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:.75 respectFlipped:TRUE hints:NULL];
    r.origin.y += r.size.height;
    SeaLayer *layer = (SeaLayer*)[self representedObject];
    if([layer linked]) {
        img = getTinted(link_image, [NSColor alternateSelectedControlColor]);
        [img drawInRect:scaledRect(img,NSInsetRect(r,2,2))];
    } else {
        img = getTinted(link_image, [NSColor controlTextColor]);
        [img drawInRect:scaledRect(img,NSInsetRect(r,2,2)) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:.5];
    }
}
@end
