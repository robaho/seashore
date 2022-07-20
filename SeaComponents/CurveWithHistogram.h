//
//  CurveWithHistogram.h
//  SeaComponents
//
//  Created by robert engels on 7/16/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/SeaComponents.h>

NS_ASSUME_NONNULL_BEGIN

@interface CurveWithHistogram : NSView
{
    CurveView *cv;
    HistogramView *histo;
}

- (HistogramView*)histogram;
- (CurveView*)curve;

@end

NS_ASSUME_NONNULL_END
