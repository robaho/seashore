#import "CIHoleClass.h"

@implementation CIHoleClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIHoleDistortion" points:2 properties:kCI_PointCenter,kCI_PointRadius,0];
}

- (void)applyFilter:(CIFilter*)filter
{
    bool opaque = ![pluginData hasAlpha];

    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
}

@end
