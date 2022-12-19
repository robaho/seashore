#import "CISepiaClass.h"

@implementation CISepiaClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CISepiaTone" points:0 properties:kCI_Intensity,0];
}

@end
