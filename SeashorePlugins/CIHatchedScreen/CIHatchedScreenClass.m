#import "CIHatchedScreenClass.h"

@implementation CIHatchedScreenClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIHatchedScreen" points:0 properties:kCI_Width,kCI_Angle,kCI_Sharpness,kCI_PointCenter,0];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
	return YES;
}

@end
