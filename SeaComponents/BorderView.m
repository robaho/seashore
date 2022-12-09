//
//  similar to Java BorderLayout but only support Bottom/Middle/Top
//

#import "BorderView.h"
#import "Configure.h"

IB_DESIGNABLE
@implementation BorderView

- (BorderView*)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    top_height=bottom_height=left_width=right_width=-1;
    return self;
}

- (void)awakeFromNib
{
    self.autoresizesSubviews = FALSE;
    self.translatesAutoresizingMaskIntoConstraints = FALSE;
    top_height=bottom_height=left_width=right_width=-1;
}

- (void)setFrameSize:(NSSize)size
{
    [super setFrameSize:size];
    [self layout];
}

- (void)layout
{
    NSString *name = [self identifier];

    if(_middle && _middle.superview!=self)
        _middle = nil;
    if(_top && _top.superview!=self)
        _top = nil;
    if(_bottom && _bottom.superview!=self)
        _bottom = nil;
    if(_left && _left.superview!=self)
        _left = nil;
    if(_right && _right.superview!=self)
        _right = nil;

    if(_middle==nil && _top==nil && _bottom==nil && _left==nil && _right==nil){
        int views = (int)[[self subviews] count];
        if(views==1) {
            _middle = [self subviews][0];
        }
    }

    NSRect bounds = NSMakeRect(0,0,self.frame.size.width,self.frame.size.height);

    VLOG(@"borderview layout %@ %@",name,NSStringFromRect(bounds));

    bounds = CGRectInset(bounds, _outerInset, _outerInset);

    if(bounds.size.height<=0 || bounds.size.width<=0)
        return;

    id temp = _top;
    if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
        [temp setPreferredMaxLayoutWidth:bounds.size.width];
        [temp invalidateIntrinsicContentSize];
    }
    temp = _bottom;
    if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
        [temp setPreferredMaxLayoutWidth:bounds.size.width];
        [temp invalidateIntrinsicContentSize];
    }
    temp = _left;
    if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
        [temp setPreferredMaxLayoutWidth:bounds.size.width];
        [temp invalidateIntrinsicContentSize];
    }
    temp = _right;
    if([temp respondsToSelector:@selector(setPreferredMaxLayoutWidth:)]) {
        [temp setPreferredMaxLayoutWidth:bounds.size.width];
        [temp invalidateIntrinsicContentSize];
    }

    if(_left!=nil && !_left.hidden) {
        NSView *v = _left;

        if(left_width==-1) {
            left_width = v.frame.size.width;
        }

        float w = [v intrinsicContentSize].width;
        if(w==NSViewNoInstrinsicMetric) {
            w = left_width;
        }

        float width = MAX(MIN(w,bounds.size.width),0);

        NSRect r = NSMakeRect( bounds.origin.x,
                             bounds.origin.y,
                             width,
                             bounds.size.height);
        v.frame = r;
        VLOG(@"top %@ %@",name,NSStringFromRect(r));

        bounds.size.width -= width;
        bounds.origin.x+=width;
    }

    if(_right!=nil && !_right.hidden) {
        NSView *v = _right;

        if(right_width==-1) {
            right_width = v.frame.size.width;
        }

        float w = [v intrinsicContentSize].width;
        if(w==NSViewNoInstrinsicMetric) {
            w = right_width;
        }

        float width = MAX(MIN(w,bounds.size.width),0);

        NSRect r = NSMakeRect( bounds.origin.x+bounds.size.width-width,
                             bounds.origin.y,
                             width,
                             bounds.size.height);
        v.frame = r;
        VLOG(@"right %@ %@",name,NSStringFromRect(r));

        bounds.size.width -= width;
    }

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

        NSRect r = NSMakeRect( bounds.origin.x,
                             bounds.origin.y,
                             bounds.size.width,
                             height);
        v.frame = r;
        VLOG(@"bottom %@ %@",name,NSStringFromRect(r));

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

        NSRect r = NSMakeRect( bounds.origin.x,
                                            bounds.origin.y+bounds.size.height-height,
                                            bounds.size.width,
                                            height);
        v.frame = r;
        VLOG(@"top %@ %@ height %f",name,NSStringFromRect(r),height);

        bounds.size.height -= (height);
    }
    if(_middle!=nil && !_middle.hidden){
        NSRect r = CGRectInset(bounds,_innerInset,_innerInset);
        if(CGRectIsEmpty(r)) {
            r = bounds;
        }
        VLOG(@"middle %@ %@",name,NSStringFromRect(r));
        _middle.frame = r;
    }
}

+(BorderView*)view {
    return [[BorderView alloc] init];
}

@end
