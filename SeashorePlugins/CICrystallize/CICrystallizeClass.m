#import "CICrystallizeClass.h"

@implementation CICrystallizeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICrystallize" points:0 properties:kCI_Radius,kCI_PointCenter,0];
}

- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];

    if (opaque) {
        [self applyFilterBG:filter];
    }
    else {
        [self applyFilter:filter];
    }
}

@end
