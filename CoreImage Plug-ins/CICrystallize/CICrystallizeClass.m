#import "CICrystallizeClass.h"

@implementation CICrystallizeClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CICrystallize" points:0 properties:kCI_Radius,kCI_PointCenter,0];
}

- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];

    if (opaque) {
        applyFilterBG(pluginData,filter);
    }
    else {
        applyFilter(pluginData,filter);
    }
}

@end
