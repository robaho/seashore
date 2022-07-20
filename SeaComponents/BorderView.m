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

    if(_middle && _middle.superview!=self)
        _middle = nil;
    if(_top && _top.superview!=self)
        _top = nil;
    if(_bottom && _bottom.superview!=self)
        _bottom = nil;

    if(_middle==nil && _top==nil && _bottom==nil){
        int views = [[self subviews] count];
        if(views==1) {
            _middle = [self subviews][0];
        } else if(views==2) {
            _bottom = [self subviews][0];
            _middle = [self subviews][1];
        } else if(views==3) {
            _bottom = [self subviews][0];
            _middle = [self subviews][1];
            _top = [self subviews][2];
        }
    }

    NSRect bounds = self.bounds;

    bounds.origin.x += _borderMargin;
    bounds.origin.y += _borderMargin;
    bounds.size.width -= (_borderMargin*2);
    bounds.size.height -= (_borderMargin*2);

    if(bounds.size.height<=0 || bounds.size.width<=0)
        return;

    if(_bottom!=nil && !_bottom.hidden) {
        NSView *v = _bottom;

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

    if(_top!=nil && !_top.hidden) {
        NSView *v = _top;

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
    if(_middle!=nil && !_middle.hidden){
        _middle.frame = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y,
                                            bounds.size.width,
                                            bounds.size.height);
    }
}

@end
