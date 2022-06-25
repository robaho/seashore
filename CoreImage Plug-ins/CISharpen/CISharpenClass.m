#import "CISharpenClass.h"

@implementation CISharpenClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CISharpenLuminance" points:0 properties:kCI_Sharpness,0];
}

@end
