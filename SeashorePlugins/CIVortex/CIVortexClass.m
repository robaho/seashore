#import "CIVortexClass.h"

@implementation CIVortexClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIVortexDistortion" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,kCI_Rotations,0];
}

@end
