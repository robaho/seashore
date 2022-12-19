#import "CIBrightnessClass.h"

@implementation CIBrightnessClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIColorControls" points:0 properties:kCI_Brightness,kCI_Contrast,kCI_Saturation,0];
}

@end
