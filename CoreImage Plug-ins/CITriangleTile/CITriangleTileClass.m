#import "CITriangleTileClass.h"

@implementation CITriangleTileClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CITriangleTile" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointAngle,kCI_PointWidth,0];
}

@end
