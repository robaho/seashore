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
    NSButton *checkbox;
    Label *title;
    Label *value;
    int valueType;
    __weak id<Listener> listener;
    int format;
    bool compact;
    bool checkable;
    int value_width;
}

- (void)setIntValue:(int)value;
- (int)intValue;
- (void)setFloatValue:(float)value;
- (void)setMaxValue:(double)value;
- (float)floatValue;
- (bool)isChecked;
- (void)setChecked:(bool)b;

+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double)max Listener:(nullable id<Listener>)listener;
+ (SeaSlider*)sliderWithTitle:(NSString*)title Min:(double)min Max:(double)max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;
+ (SeaSlider*)sliderWithCheck:(NSString*)title Min:(double)min Max:(double)max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;
+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double)max Listener:(nullable id<Listener>)listener;
+ (SeaSlider*)compactSliderWithTitle:(NSString*)title Min:(double)min Max:(double) max Listener:(nullable id<Listener>)listener Size:(NSControlSize)size;


@end


NS_ASSUME_NONNULL_END
