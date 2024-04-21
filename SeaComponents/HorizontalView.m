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
            NSSize s = v.fittingSize;
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
    float visible_width=0;
    NSView *widest=NULL;
    for(NSView *v in [self subviews]) {
        if(!v.hidden) {
            visible_count++;
            visible_width+=v.fittingSize.width;
            if(widest==NULL || v.fittingSize.width > widest.fittingSize.width) {
                widest = v;
            }
        }
    }
    if(visible_count==0) {
        return;
    }
    if(_leftJustify) {
        float widestAdj = 0;
        visible_width += (visible_count-1)*_gap + _margin*2;
        if(visible_width > bounds.size.width) {
            widestAdj = visible_width-bounds.size.width;
        }
        float x=_margin;
        for(NSView *v in [self subviews]) {
            if(v.hidden) continue;
            float h = MIN(v.fittingSize.height,bounds.size.height);
            float width = v.fittingSize.width;
            if(v==widest) width -= widestAdj;
            width = MAX(MIN(width,bounds.size.width-x),0);
            [v setFrame:NSMakeRect(x,0+(bounds.size.height-h)/2,width,h)];
            x+=width;
            x+=_gap;
        }
    } else {
        float width = (bounds.size.width - (visible_count-1)*_gap - _margin*2)/visible_count;
        float x=_margin;
        for(NSView *v in [self subviews]) {
            if(v.hidden) continue;
            float h = MIN(v.fittingSize.height,bounds.size.height);
            [v setFrame:NSMakeRect(x,0+(bounds.size.height-h)/2,width,h)];
            x+=width;
            x+=_gap;
        }
    }
}

@end
