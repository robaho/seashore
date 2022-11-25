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
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (void)layout
{
    [super layout];

    NSView *lastVisible;
    
    NSRect bounds = self.bounds;

    float y = bounds.size.height;
    int height = 0;
    for(NSView* v in self.subviews) {
        if(v.isHidden)
            continue;
        lastVisible = v;
        id temp = v;
        if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
            [temp setPreferredMaxLayoutWidth:(_preferredMaxLayoutWidth-2)]; // -2 is hack for multiline text bug
            [temp invalidateIntrinsicContentSize];
        }
        NSSize size = v.intrinsicContentSize;
        if(size.height==NSViewNoInstrinsicMetric){
            height = v.frame.size.height;
        } else {
            height = size.height;
        }
        y-=height;
        [v setFrame:NSMakeRect(0,y,bounds.size.width,height)];
        y-=GAP; // add some space between components
    }
    if(_lastFills) {
        NSRect r = [lastVisible frame];
        [lastVisible setFrame:NSMakeRect(r.origin.x,0,r.size.width,r.size.height+y)];
    }
}

- (NSSize)intrinsicContentSize
{
    int w=NSViewNoInstrinsicMetric,h=NSViewNoInstrinsicMetric;
    for(NSView* v in self.subviews){
        if(v.isHidden) {
            continue;
        }
        id temp = v;
        if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
            [temp setPreferredMaxLayoutWidth:(_preferredMaxLayoutWidth-2)]; // -2 is hack for multiline text bug
            [temp invalidateIntrinsicContentSize];
        }
        NSSize size = v.intrinsicContentSize;
        if(size.width!=NSViewNoInstrinsicMetric){
            w = MAX(size.width,w);
        }
        if(size.height!=NSViewNoInstrinsicMetric){
            h = MAX(0,h)+size.height;
            h+=GAP;
        }
    }
    return NSMakeSize(w,h);
}

- (void)setNeedsLayout:(BOOL)needsLayout
{
    [super setNeedsLayout:needsLayout];
    if(needsLayout) {
        for(NSView *v in [self subviews]) {
            [v setNeedsLayout:TRUE];
        }
    }
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
