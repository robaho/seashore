#import "CIExposureClass.h"

@implementation CIExposureClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIExposureAdjust" points:0 properties:kCI_Exposure,0];
}


@end
