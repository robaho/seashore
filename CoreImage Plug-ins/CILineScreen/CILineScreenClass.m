#import "CILineScreenClass.h"

@implementation CILineScreenClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CILineScreen" points:0 properties:kCI_PointCenter,kCI_Width,kCI_Angle,kCI_Sharpness,0];
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
    if ([pluginData spp] == 2)
        return NO;
	
	return YES;
}

@end
