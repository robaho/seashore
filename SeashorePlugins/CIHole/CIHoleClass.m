#import "CIHoleClass.h"

@implementation CIHoleClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIHoleDistortion" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,0];
}

@end
