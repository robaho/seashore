#import "CIPinchClass.h"

@implementation CIPinchClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIPinchDistortion" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,kCI_Scale,0];
}

@end
