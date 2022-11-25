//
//  HorizontalView.m
//  SeaComponents
//
//  Created by robert engels on 11/25/22.
//

#import "HorizontalView.h"

static const int GAP = 5;

@implementation HorizontalView

- (HorizontalView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    return self;
}

- (NSSize)intrinsicContentSize{
    int width=0,height=0;
    for(NSView *v in [self subviews]) {
        if(!v.hidden) {
            NSSize s = v.intrinsicContentSize;
            height = MAX(height,s.height);
            if(s.width!=NSViewNoIntrinsicMetric) {
                if(width!=0)
                    width+=GAP;
                width+=s.width;
            }
        }
    }
    return NSMakeSize(width,height);
}

- (void)layout
{
    int visible_count=0;
    for(NSView *v in [self subviews]) {
        if(!v.hidden) {
            visible_count++;
        }
    }
    if(visible_count==0) {
        return;
    }
    NSRect bounds = [self bounds];
    float width = (bounds.size.width - (visible_count-1)*GAP)/visible_count;
    float x=0;
    for(NSView *v in [self subviews]) {
        if(v.hidden) continue;
        if(x!=0) {
            x+=GAP;
        }
        [v setFrame:NSMakeRect(x,0,width,bounds.size.height)];
        x+=width;
    }
}

@end
