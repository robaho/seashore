#import "CIPointillizeClass.h"

@implementation CIPointillizeClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIPointillize" points:0 bg:TRUE properties:kCI_PointCenter,kCI_Radius,0];
}

@end
