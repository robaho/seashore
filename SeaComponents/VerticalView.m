//
//  VerticalView.m
//  Seashore
//
//  Created by robert engels on 3/6/22.
//

#import "VerticalView.h"

@implementation VerticalView

static const int GAP = 5;

- (VerticalView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
//    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout:TRUE];
}

- (void)layout
{
//    NSLog(@"verticalview layout");

    [super layout];

    NSRect bounds = self.frame;

    float y = bounds.size.height;
    int height = 0;
    for(NSView* v in self.subviews) {
        if(v.isHidden)
            continue;
        if(v.class==NSTextField.class){
            NSTextField *tf = (NSTextField*)v;
            int old = tf.preferredMaxLayoutWidth;
            if(old!=bounds.size.width) {
                tf.preferredMaxLayoutWidth = bounds.size.width;
                self.needsLayout=TRUE;
            }
        }
        NSSize size = v.intrinsicContentSize;
        // set width first so proper height can be determined
        if(size.height==NSViewNoInstrinsicMetric){
            height = v.frame.size.height;
        } else {
            height = size.height;
        }
        y-=height;
        v.frame = NSMakeRect(0,y,bounds.size.width,height);
        y-=GAP; // add some space between components
    }
}

- (NSSize)intrinsicContentSize
{
    int w=0,h=0;
    for(NSView* v in self.subviews){
        if(!v.isHidden){
            if(v.class==NSTextField.class){
                NSTextField *tf = (NSTextField*)v;
                tf.preferredMaxLayoutWidth = self.frame.size.width;
            }
            NSSize size = v.intrinsicContentSize;
            if(size.width!=NSViewNoInstrinsicMetric){
                w = MAX(size.width,w);
            }
            if(size.height!=NSViewNoInstrinsicMetric){
                h += size.height;
            } else {
                h += v.frame.size.height;
            }
            h+=GAP;
        }
    }
    return NSMakeSize(w,h);
}

+(VerticalView*)view
{
    return [[VerticalView alloc] initWithFrame:NSZeroRect];
}

- (void)addSubviews:(NSView *)view, ...
{
    if (view)
    {
        [self addSubview:view];
        va_list argumentList;
        va_start(argumentList, view);
        NSView *v;
        while (v = va_arg(argumentList, id))
        {
            [self addSubview:v];
        }
        va_end(argumentList);
    }
}

- (void)addSubviewsAtIndex:(int)index views:(NSView *)view, ...
{
    if (view)
    {
        NSView *v0 = [self.subviews objectAtIndex:index];
        [self addSubview:view positioned:NSWindowAbove relativeTo:v0];

        va_list argumentList;
        va_start(argumentList, view);
        NSView *v;
        while (v = va_arg(argumentList, id))
        {
            [self addSubview:v positioned:NSWindowAbove relativeTo:v0];
        }
        va_end(argumentList);
    }
}

@end
