#import "CIBloomClass.h"

@implementation CIBloomClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIBloom" points:0 properties:kCI_Radius,kCI_Intensity,0];
}

@end
