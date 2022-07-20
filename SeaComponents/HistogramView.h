//
//  HistogramView.h
//  SeaComponents
//
//  Created by robert engels on 7/12/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HistogramView : NSView
{
    float histogram[256*3]; // 3 planes
    bool useBounds;
    int lower,upper;
    int mode;
}

- (void)updateHistogram:(int)mode histogram:(int*)histogram;
- (void)enableBounds;
- (void)setLowerBound:(int)bound;
- (void)setUpperBound:(int)bound;
@end

NS_ASSUME_NONNULL_END
