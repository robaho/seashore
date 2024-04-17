#import "CIVibranceClass.h"

@implementation CIVibranceClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIVibrance" points:0 properties:kCI_Vibrance,0];
}

@end
