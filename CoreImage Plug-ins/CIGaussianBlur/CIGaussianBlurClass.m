#import "CIGaussianBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGaussianBlurClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CIGaussianBlur" points:0 properties:kCI_Radius,0];
}

- (void)execute
{
    // We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
    // the content outside the borders of the image
    CIFilter *clamp = [CIFilter filterWithName: @"CIAffineClamp"];
    [clamp setDefaults];
    [clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
    
    // Run filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGaussianBlur"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithInt:[self intValue:kCI_Radius]] forKey:@"inputRadius"];

    applyFilters(pluginData,clamp,filter,nil);
}

@end
