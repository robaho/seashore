#import "CILineScreenClass.h"

@implementation CILineScreenClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CILineScreen" points:0 properties:kCI_PointCenter,kCI_Width,kCI_Angle,kCI_Sharpness,0];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
	return YES;
}

@end
