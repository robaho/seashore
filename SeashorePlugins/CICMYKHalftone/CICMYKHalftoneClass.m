#import "CICMYKHalftoneClass.h"

@implementation CICMYKHalftoneClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICMYKHalftone" points:0 properties:kCI_Width,kCI_Angle,kCI_Sharpness,kCI_GCR,kCI_UCR,kCI_PointCenter,0];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
	return YES;
}

@end
