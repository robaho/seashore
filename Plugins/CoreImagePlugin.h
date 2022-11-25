#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "PluginClass.h"
#import "PluginData.h"
#import <SeaComponents/SeaComponents.h>
#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kCI_EndOfList,
    kCI_Radius,
    kCI_Intensity,
    kCI_Intensity1000,
    kCI_Angle,
    kCI_AcuteAngle,
    kCI_Width,
    kCI_Width1000,
    kCI_Sharpness,
    kCI_Brightness,
    kCI_Brightness100,
    kCI_Contrast,
    kCI_Saturation,
    kCI_Scale,
    kCI_Scale1,
    kCI_Scale100,
    kCI_Scale1000,
    kCI_ScaleNeg1,
    kCI_Strength,
    kCI_Overlap,
    kCI_NoiseLevel,
    kCI_Levels,
    kCI_Concentration,
    kCI_Opacity,
    kCI_Rotations,
    kCI_PointCenter,
    kCI_PointRadius,
    kCI_PointWidth,
    kCI_PointAngle,
    kCI_GCR,
    kCI_UCR,
    kCI_Exposure,
    kCI_Color,
    kCI_Color0,
    kCI_Color1,
    kCI_Gamma,
    kCI_Refraction,
    kCI_Point0,
    kCI_Point1,
    kCI_Point2,
    kCI_Point3,
} CIProperty;

@interface CoreImagePlugin : NSObject <PluginClass>
{
    PluginData *pluginData;
    NSMutableArray *properties;
    VerticalView *panel;
    int points;
    NSString *filterName;
    bool bg;
}

-(NSView*)initialize;
-(void)execute;
-(void)apply:(id)sender;
-(CoreImagePlugin*)initWithManager:(PluginData*)pluginData filter:(NSString* _Nullable)filterName points:(int)points properties:(CIProperty)property,...;
-(CoreImagePlugin*)initWithManager:(PluginData*)pluginData filter:(NSString* _Nullable)filterName points:(int)points bg:(BOOL)bg properties:(CIProperty)property,...;
-(int)intValue:(CIProperty)property;
-(float)floatValue:(CIProperty)property;
-(float)radiansValue:(CIProperty)property;
-(CIVector*)centerPointValue;
-(int)radiusValue;
-(float)angleValue;

-(CIVector*)pointValue:(int)index;
-(CIColor*)colorValue:(CIProperty)property;

-(void)setFilterProperty:(CIProperty)property property:(NSString*)filterProperty;
-(CIFilter*)createFilter;
-(CIFilter*)getFilterInstance:(NSString*)name;
-(void)applyFilter:(CIFilter*)filter;

@end

NS_ASSUME_NONNULL_END
