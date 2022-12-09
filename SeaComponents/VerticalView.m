//
//  VerticalView.m
//  Seashore
//
//  Created by robert engels on 3/6/22.
//

#import "VerticalView.h"
#import "Configure.h"

IB_DESIGNABLE
@implementation VerticalView

- (VerticalView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.margin = 5;
    self.gap = 2;
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;

    return self;
}

- (void)awakeFromNib
{
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
}

- (void)setFrameSize:(NSSize)size
{
    [super setFrameSize:size];
    [self layout];
}

- (void)setLastFills:(bool)lastFills
{
    _lastFills=lastFills;
    [self setNeedsLayout:TRUE];
}

- (void)layout
{
    VLOG(@"verticalview layout on %@",[self identifier]);

    NSView *lastVisible;
    
    NSRect bounds = NSMakeRect(0,0,self.frame.size.width,self.frame.size.height);
    if(bounds.size.width<=0 || bounds.size.height<=0) {
        return;
    }

    float y = bounds.size.height-_margin;
    for(NSView* v in self.subviews) {
        if(v.isHidden)
            continue;
        lastVisible = v;
        int height = 0;
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
        VLOG(@"vv set frame on %@ to %@",v,NSStringFromRect(v.frame));
        y-=_gap; // add some space between components
    }
    if(_lastFills) {
        NSRect r = [lastVisible frame];
        [lastVisible setFrame:NSMakeRect(r.origin.x,_margin,r.size.width,r.size.height+y)];
    }
}

- (NSSize)intrinsicContentSize
{
    int w=NSViewNoInstrinsicMetric,h=NSViewNoInstrinsicMetric;
    int visible_count=0;
    for(NSView* v in self.subviews){
        if(v.isHidden) {
            continue;
        }
        visible_count++;
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
        }
    }
    h+=(_margin*2);
    h+=(visible_count*_gap);
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
