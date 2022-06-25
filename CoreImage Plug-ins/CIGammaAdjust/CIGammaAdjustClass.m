#import "CIGammaAdjustClass.h"

@implementation CIGammaAdjustClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIGammaAdjust" points:0 properties:kCI_Gamma,0];
}

@end
