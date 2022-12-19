#import "CIRandomClass.h"

@implementation CIRandomClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIRandomGenerator" points:0 bg:TRUE properties:0];
}


@end
