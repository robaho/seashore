//
//  HistogramView.m
//  SeaComponents
//
//  Created by robert engels on 7/12/22.
//
#import "HistogramView.h"

@implementation HistogramView

#define HEIGHT 80
#define GAP 5

- (void)drawRect:(NSRect)rect
{
    NSArray *colors = [NSArray arrayWithObjects:[NSColor redColor],[NSColor greenColor],[NSColor blueColor],nil];

    int series = 1;
    if(mode==4)
        series=3;

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];

    [ctx saveGraphicsState];
    [ctx setCompositingOperation:NSCompositeOverlay];
    [ctx setShouldAntialias:TRUE];

    NSRect bounds = [self bounds];

    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx scaleXBy:(bounds.size.width-GAP*2)/256 yBy:(bounds.size.height-GAP)];
    [tx translateXBy:GAP yBy:0];
    [tx concat];

    for(int j=0;j<series;j++) {
        int offset = j * 256;

        NSColor *color;
        switch(mode) {
            case 0:
                color = [NSColor controlTextColor]; break;
            case 1:
            case 2:
            case 3:
                color = [colors objectAtIndex:mode-1]; break;
            case 4:
                color = [colors objectAtIndex:j]; break;
        }

        for (int i = 0; i < 256; i++) {
            float val = histogram[i+offset];
            if(val==0.0)
                continue;
            [[color colorWithAlphaComponent:.33] setStroke];
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line moveToPoint:NSMakePoint(i,0)];
            [line lineToPoint:NSMakePoint(i,val)];
            [line setLineWidth:1];
            [line stroke];
            [[color colorWithAlphaComponent:1] setFill];
            NSRectFill(NSMakeRect(i, val, 1, .01));
        }
    }

    if(useBounds) {
        NSColor *accent = [NSColor selectedControlTextColor];
        [[accent colorWithAlphaComponent:.3] set];
        NSRectFillUsingOperation(NSMakeRect(MIN(upper,lower), 0, abs(upper - lower) + 1, 1),NSCompositeSourceOver);
    }

    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

//- (NSRect)bounds
//{
//    return NSMakeRect(-10,0,266,1);
//}

- (void)setLowerBound:(int)bound
{
    lower = bound;
    [self setNeedsDisplay:TRUE];
}
- (void)setUpperBound:(int)bound
{
    upper = bound;
    [self setNeedsDisplay:TRUE];
}

- (void)enableBounds
{
    upper=255;
    lower=0;
    useBounds=TRUE;
    [self setNeedsDisplay:TRUE];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(256,HEIGHT);
}

- (void)updateHistogram:(int)mode histogram:(int*)histo
{
    // mode 0 = value
    // mode 1-3 = red, green, blue
    // mode 4 = rgb

    self->mode = mode;
    int series = 1;
    if(mode==4){
        series = 3;
    }

    for(int j=0;j<series;j++) {
        int offset = j * 256;
        float max = 1;
        for (int i = 0; i < 256; i++) {
            max = (histo[i+offset] > max) ? histo[i+offset] : max;
        }

        for (int i = 0; i < 256; i++) {
            histogram[i+offset] = histo[i+offset] / max;
        }
    }

    free(histo);

    [self setNeedsDisplay:TRUE];
}

@end
