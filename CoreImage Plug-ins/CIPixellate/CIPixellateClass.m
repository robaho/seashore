#import "CIPixellateClass.h"

@implementation CIPixellateClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIPixellate" points:0 bg:TRUE properties:kCI_PointCenter,kCI_Scale1000,0];
}

@end
