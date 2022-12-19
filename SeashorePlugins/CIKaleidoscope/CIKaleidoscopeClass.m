#import "CIKaleidoscopeClass.h"

@implementation CIKaleidoscopeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIKaleidoscope" points:2 properties:kCI_PointCenter,kCI_PointAngle,0];
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
