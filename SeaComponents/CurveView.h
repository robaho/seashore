//
//  CurveView.h
//  SeaComponents
//
//  Created by robert engels on 7/16/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/Listener.h>

NS_ASSUME_NONNULL_BEGIN

@interface CurveView : NSView
{
    CGPoint points[5];
    int npoints;
    int selected_point;
    NSPoint downAt;
    CGPoint starting;
    id<Listener> listener;
}

- (CGPoint)point:(int)index;

- (void)setListener:(id<Listener>)listener;

+ (CurveView*)curveViewWithListener:(id<Listener>)listener;

@end

NS_ASSUME_NONNULL_END
