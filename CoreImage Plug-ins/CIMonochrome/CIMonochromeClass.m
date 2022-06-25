#import "CIMonochromeClass.h"

@implementation CIMonochromeClass

- (id)initWithManager:(PluginData *)data
{
    return [self initWithManager:data filter:@"CIColorMonochrome" points:0 properties:kCI_Intensity,kCI_Color,0];
}

@end
