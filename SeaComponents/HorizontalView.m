//
//  HorizontalView.m
//  SeaComponents
//
//  Created by robert engels on 11/25/22.
//

#import "HorizontalView.h"

IB_DESIGNABLE
@implementation HorizontalView

- (HorizontalView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.gap=5;
    self.margin=5;
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

- (NSSize)intrinsicContentSize{
    int width=0,height=0,visible_count=0;
    for(NSView *v in [self subviews]) {
        if(!v.hidden) {
            visible_count++;
            NSSize s = v.intrinsicContentSize;
            height = MAX(height,s.height);
            if(s.width!=NSViewNoInstrinsicMetric) {
                width+=s.width;
            }
        }
    }
    width += (visible_count-1)*_gap;
    width += _margin*2;
    return NSMakeSize(width,height);
}

- (void)layout
{
    NSRect bounds = NSMakeRect(0,0,self.frame.size.width,self.frame.size.height);
    if(bounds.size.width<=0 || bounds.size.height<=0) {
        return;
    }

    int visible_count=0;
    for(NSView *v in [self subviews]) {
        if(!v.hidden) {
            visible_count++;
        }
    }
    if(visible_count==0) {
        return;
    }
    float width = (bounds.size.width - (visible_count-1)*_gap - _margin*2)/visible_count;
    float x=_margin;
    for(NSView *v in [self subviews]) {
        if(v.hidden) continue;
        [v setFrame:NSMakeRect(x,0,width,bounds.size.height)];
        x+=width;
        x+=_gap;
    }
}

@end
