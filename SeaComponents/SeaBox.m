#import "SeaBox.h"
#import "Configure.h"

@implementation SeaBox

- (SeaBox*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    initialSize = frameRect.size;
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;

    return self;
}
- (SeaBox*)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    initialSize = self.frame.size;
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (void)awakeFromNib
{
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
}

- (NSSize)intrinsicContentSize
{
    NSSize size = [[self contentView] intrinsicContentSize];
    size.height += [self titleRect].size.height;
    VLOG(@"seabox intrinsic content size %@",NSStringFromSize(size));
    return size;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

-(void)layout
{
    [super layout];

    VLOG(@"seabox layout on %@",[self identifier]);

    NSRect bounds = NSMakeRect(0,0,self.frame.size.width,self.frame.size.height);

    NSRect titleRect = [self titleRect];

    myBorderRect = CGRectInset(bounds, 8, self.borderWidth);
    myBorderRect.size.height -= titleRect.size.height+2;
    if(myBorderRect.size.height<0 || myBorderRect.size.width<0) {
        return;
    }
    [[self contentView] setFrame:myBorderRect];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
    [self layout];
}

-(void)drawRect:(NSRect)dirtyRect
{
    if(@available(macos 10.14, *))
    {
        [NSColor.separatorColor setStroke];
    } else {
        [NSColor.windowFrameColor setStroke];
    }
    bool custom = self.boxType == NSBoxCustom;

    if(custom) {
        [self.borderColor setStroke];
    }

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:myBorderRect xRadius:5 yRadius:5];
    [path setLineWidth:custom ? self.borderWidth : 1];
    [path stroke];

    [[self titleFont] set];
    [[self title] drawInRect:[self titleRect] withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor controlTextColor], NSForegroundColorAttributeName, nil]];
}

- (NSRect)borderRect
{
    return CGRectInset([self frame], 10, 0);
}

@end
