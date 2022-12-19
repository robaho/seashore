#import "CINoiseReductionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CINoiseReductionClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CINoiseReduction" points:0 properties:kCI_NoiseLevel,kCI_Sharpness,0];
}

@end
