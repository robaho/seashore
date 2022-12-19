#import "CIMotionBlurClass.h"

@implementation CIMotionBlurClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIMotionBlur" points:2 properties:kCI_PointRadius,kCI_PointAngle,0];
}


- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque){
        [self applyFilterBG:filter];
    } else {
        [self applyFilter:filter];
    }
    
}

@end
