#import "CIBumpClass.h"

@implementation CIBumpClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIBumpDistortion" points:2 properties:kCI_ScaleNeg1,kCI_PointCenter,kCI_PointRadius,0];
}

@end
