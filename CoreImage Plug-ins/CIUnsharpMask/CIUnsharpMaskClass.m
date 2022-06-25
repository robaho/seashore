#import "CIUnsharpMaskClass.h"

@implementation CIUnsharpMaskClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIUnsharpMask" points:0 properties:kCI_Radius,kCI_Intensity,0];
}

@end
