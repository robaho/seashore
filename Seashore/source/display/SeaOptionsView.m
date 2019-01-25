#import "SeaOptionsView.h"

@implementation SeaOptionsView

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    NSColor *fillColor;
    NSBezierPath *path;

    if([window isMainWindow]){
        fillColor = [NSColor windowBackgroundColor];
        [fillColor set];
        path = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 1.0, [self frame].size.width, [self frame].size.height)];
        [path fill];
    }
}

@end
