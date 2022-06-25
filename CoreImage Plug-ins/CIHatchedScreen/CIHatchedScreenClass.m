#import "CIHatchedScreenClass.h"

@implementation CIHatchedScreenClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIHatchedScreen" points:0 properties:kCI_Width,kCI_Angle,kCI_Sharpness,kCI_PointCenter,0];
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
