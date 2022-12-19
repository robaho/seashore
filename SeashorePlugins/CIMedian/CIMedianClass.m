#import "CIMedianClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIMedianClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIMedianFilter" points:0 properties:0];
}

@end
