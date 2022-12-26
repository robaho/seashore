#import "CIMotionBlurClass.h"

@implementation CIMotionBlurClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIMotionBlur" points:2 bg:TRUE properties:kCI_PointRadius,kCI_PointAngle,0];
}

@end
