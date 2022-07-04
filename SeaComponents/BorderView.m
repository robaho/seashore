//
//  similar to Java BorderLayout but only support Bottom/Middle/Top
//

#import "BorderView.h"

@implementation BorderView

- (BorderView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    top_height=bottom_height=-1;
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if(self.needsLayout){
        [self layout];
    }
    [super drawRect:dirtyRect];
}

- (void)setFrame:(NSRect)frame
{
//    NSLog(@"setframe on BorderView");
    [super setFrame:frame];
}

- (void)layout
{
//    NSLog(@"borderView layout");
    [super layout];

    NSRect bounds = self.bounds;

    bounds.origin.x += _borderMargin;
    bounds.origin.y += _borderMargin;
    bounds.size.width -= (_borderMargin*2);
    bounds.size.height -= (_borderMargin*2);

    if(bounds.size.height<=0 || bounds.size.width<=0)
        return;

    int visibleCount = 0;
    NSView *visibleView;
    for(NSView *v in self.subviews) {
        if(!v.hidden){
            visibleView=v;
            visibleCount++;
        }
    }

    if(visibleCount==1){ // only a single view so fill
        visibleView.frame = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y,
                                            bounds.size.width,
                                            bounds.size.height);
        visibleView.needsLayout = TRUE;
        visibleView.needsDisplay = TRUE;
        return;
    }

    // do the bottom
    if(self.subviews.count >=1 && !self.subviews[0].isHidden) {
        NSView *v = self.subviews[0];

        if(bottom_height==-1) {
            bottom_height = v.frame.size.height;
        }

        float h = [v intrinsicContentSize].height;
        if(h==NSViewNoInstrinsicMetric) {
            h = bottom_height;
        }

        float height = MAX(MIN(h,bounds.size.height),0);

        v.frame = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y,
                                            bounds.size.width,
                                            height);
        bounds.size.height -= height;
        bounds.origin.y+=height;
    }
    // do the top
    if(self.subviews.count >=3 && !self.subviews[2].isHidden) {
        NSView *v = self.subviews[2];

        if(top_height==-1) {
            top_height = v.frame.size.height;
        }

        float h = [v intrinsicContentSize].height;
        if(h==NSViewNoInstrinsicMetric) {
            h = top_height;
        }
        float height = MAX(MIN(h,bounds.size.height),0);

        v.frame = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y+bounds.size.height-height-1,
                                            bounds.size.width,
                                            height);
        bounds.size.height -= height;
    }
    if(self.subviews.count >=2 && !self.subviews[1].isHidden) {
        self.subviews[1].frame = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y,
                                            bounds.size.width,
                                            bounds.size.height);
    }
}

@end
