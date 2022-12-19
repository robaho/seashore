#import "CIHoleClass.h"

@implementation CIHoleClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIHoleDistortion" points:2 properties:kCI_PointCenter,kCI_PointRadius,0];
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
