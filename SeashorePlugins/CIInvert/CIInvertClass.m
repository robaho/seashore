#import "CIInvertClass.h"

@implementation CIInvertClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIColorInvert" points:0 properties:0];
}

@end
