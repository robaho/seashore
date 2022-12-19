#import "CIEdgesClass.h"

@implementation CIEdgesClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIEdges" points:0 properties:kCI_Intensity1000,0];
}

@end
