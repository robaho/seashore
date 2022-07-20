//
//  CurveWithHistogram.m
//  SeaComponents
//
//  Created by robert engels on 7/16/22.
//

#import "CurveWithHistogram.h"

@implementation CurveWithHistogram

- (CurveWithHistogram*)init
{
    self = [super init];
    cv = [[CurveView alloc] init];
    histo = [[HistogramView alloc] init];

    [self addSubview:cv];
    [self addSubview:histo];

    [self setNeedsLayout:TRUE];

    return self;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self layout];
}

- (NSSize)intrinsicContentSize
{
    NSSize s0 = [cv intrinsicContentSize];
    NSSize s1 = [histo intrinsicContentSize];
    return NSMakeSize(MAX(s0.width,s1.width),MAX(s0.height,s1.height));
}

- (void)layout
{
    [super layout];
    [cv setFrame:[self bounds]];
    [histo setFrame:[self bounds]];
}

- (HistogramView*)histogram
{
    return histo;
}
- (CurveView*)curve
{
    return cv;
}

@end
