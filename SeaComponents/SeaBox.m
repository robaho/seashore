#import "SeaBox.h"

@implementation SeaBox

- (SeaBox*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.autoresizesSubviews = TRUE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (NSSize)intrinsicContentSize
{
    return self.frame.size;
}

- (void)layout
{
//    NSLog(@"layout seabox");
    [super layout];
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [[self contentView] layout];
}

@end
