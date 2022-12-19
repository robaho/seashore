#import "CITorusLensClass.h"

@implementation CITorusLensClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CITorusLensDistortion" points:2 bg:YES properties:kCI_PointCenter,kCI_PointRadius,kCI_Width1000,kCI_Refraction,0];
}

@end
