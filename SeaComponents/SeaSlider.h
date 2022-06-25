//
//  SeaSlider.h
//  Seashore
//
//  Created by robert engels on 3/6/22.
//

#import <Cocoa/Cocoa.h>
#import <SeaComponents/Label.h>
#import <SeaComponents/Listener.h>

NS_ASSUME_NONNULL_BEGIN

@interface SeaSlider : NSView
{
    NSSlider *slider;
    Label *title,*value;
    int valueType;
    id<Listener> listener;
    int format;
}

- (void)setIntValue:(int)value;
- (int)intValue;
- (void)setFloatValue:(float)value;
- (float)floatValue;

+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(id<Listener>)listener;

@end


NS_ASSUME_NONNULL_END
