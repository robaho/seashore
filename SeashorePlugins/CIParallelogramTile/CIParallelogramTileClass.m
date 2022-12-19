#import "CIParallelogramTileClass.h"

@implementation CIParallelogramTileClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIParallelogramTile" points:2 bg:TRUE properties:kCI_AcuteAngle,kCI_PointCenter,kCI_PointWidth,kCI_PointAngle,0 ];
}

@end
