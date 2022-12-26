#import "CIKaleidoscopeClass.h"

@implementation CIKaleidoscopeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIKaleidoscope" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointAngle,0];
}

@end
