#import "CICircularScreenClass.h"

@implementation CICircularScreenClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CICircularScreen" points:1 properties:kCI_Width,kCI_Sharpness,kCI_PointCenter,0];
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
