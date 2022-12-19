#import "CICircularScreenClass.h"

@implementation CICircularScreenClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICircularScreen" points:1 properties:kCI_Width,kCI_Sharpness,kCI_PointCenter,0];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
	return YES;
}

@end
