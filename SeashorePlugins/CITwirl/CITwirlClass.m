#import "CITwirlClass.h"

@implementation CITwirlClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CITwirlDistortion" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,kCI_PointAngle,0];
}

@end
