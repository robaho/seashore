//
//  TestAppView.m
//  SeaComponentsTestApp
//
//  Created by robert engels on 11/16/22.
//

#import "TestAppView.h"
#import "SeaSlider.h"

@implementation TestAppView

- (void)awakeFromNib {
    SeaSlider *s1 =[SeaSlider sliderWithTitle:@"My Slider" Min:0 Max:10000 Listener:self];
    SeaSlider *s2 =[SeaSlider sliderWithTitle:@"My Slider" Min:-1 Max:1 Listener:self];
    [s2 setFloatValue:0.0];
    [self addSubviews:s1,s2,0];
}
- (void)componentChanged:(id)component {
}

@end
