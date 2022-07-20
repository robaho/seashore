//
//  CurveView.m
//  SeaComponents
//
//  Created by robert engels on 7/16/22.
//

#import "CurveView.h"

#define PSize .03

@implementation CurveView

- (CurveView*)init
{
    self = [super init];
    points[0] = CGPointMake(0,0);
    points[1] = CGPointMake(.25,.25);
    points[2] = CGPointMake(.50,.50);
    points[3] = CGPointMake(.75,.75);
    points[4] = CGPointMake(1,1);

    npoints=5;

    selected_point = -1;

    [super setBoundsSize:NSMakeSize(1,1)];

    return self;
}

- (void)setFrame:(NSRect)r
{
    [super setFrame:r];
    [super setBounds:NSMakeRect(0,0,1,1)];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(-1,200);
}

- (NSRect)rectForPoint:(int)index
{
    NSRect r = NSMakeRect(points[index].x,points[index].y,0,0);
    r = NSInsetRect(r,-PSize,-PSize);
    return r;
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint eventLocation = [event locationInWindow];
    NSPoint center = [self convertPoint:eventLocation fromView:nil];

    downAt = center;

    for(int i=0;i<npoints;i++) {
        if(NSPointInRect(center,[self rectForPoint:i])) {
            selected_point = i;
            starting = points[i];
            return;
        }
    }
    selected_point=-1;
}

- (void)mouseDragged:(NSEvent *)event
{
    if(selected_point<0)
        return;

    NSPoint eventLocation = [event locationInWindow];
    NSPoint center = [self convertPoint:eventLocation fromView:nil];

    NSSize frame = [self frame].size;

    float deltaX = (center.x - downAt.x);
    float deltaY = (center.y - downAt.y);

    CGPoint p = starting;
    p.x += deltaX;
    p.y += deltaY;

    float lower=0;
    float upper=1;

    if(p.y < 0)
        p.y = 0;
    if(p.y > 1)
        p.y = 1;

    if(selected_point==0){
        upper = points[selected_point+1].x;
    } else if(selected_point==npoints-1){
        lower = points[selected_point-1].x;
    } else {
        upper = points[selected_point+1].x;
        lower = points[selected_point-1].x;
    }

    if(p.x < lower)
        p.x = lower;
    if(p.x > upper)
        p.x = upper;

    points[selected_point] = p;

    if(listener) {
        [listener componentChanged:self];
    }

    [self setNeedsDisplay:TRUE];
}

- (void)mouseUp:(NSEvent *)event
{
    selected_point = -1;
}

- (NSBezierPath*)createBezierPathBetweenPoints
{
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path setLineWidth:.005];

    float granularity = 100;

    [path moveToPoint:points[0]];
    int count = npoints;

    for (int index = 1; index < count - 2 ; index++) {

        CGPoint point0 = points[index - 1];
        CGPoint point1 = points[index];
        CGPoint point2 = points[index + 1];
        CGPoint point3 = points[index + 2];

        for (int i = 1; i < granularity ; i++) {
            float t = (float) i * (1.0f / (float) granularity);
            float tt = t * t;
            float ttt = tt * t;

            CGPoint pi;
            pi.x = 0.5 * (2*point1.x+(point2.x-point0.x)*t + (2*point0.x-5*point1.x+4*point2.x-point3.x)*tt + (3*point1.x-point0.x-3*point2.x+point3.x)*ttt);
            pi.y = 0.5 * (2*point1.y+(point2.y-point0.y)*t + (2*point0.y-5*point1.y+4*point2.y-point3.y)*tt + (3*point1.y-point0.y-3*point2.y+point3.y)*ttt);

//            if (pi.y > view.frame.size.height) {
//                pi.y = view.frame.size.height;
//            }
//            else if (pi.y < 0){
//                pi.y = 0;
//            }

            if (pi.x > point0.x) {
                [path lineToPoint:pi];
            }
        }

        [path lineToPoint:point2];
    }

    [path lineToPoint:points[count -1]];

    return path;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath * path = [self createBezierPathBetweenPoints];
    [[NSColor controlTextColor] set];
    [path stroke];
    for(int i=0;i<5;i++) {
        NSRect r = [self rectForPoint:i];
        NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:r];
        [circle fill];
    }
}

- (CGPoint)point:(int)index
{
    return points[index];
}

+ (CurveView*)curveViewWithListener:(id<Listener>)listener
{
    CurveView *v = [[CurveView alloc] init];
    v->listener = listener;
    return v;
}

- (void)setListener:(id<Listener>)listener
{
    self->listener = listener;
}

@end
