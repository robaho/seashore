#import "CICircleSplashClass.h"

@implementation CICircleSplashClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CICircleSplashDistortion" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,0];
}
@end
