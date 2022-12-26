#import "CIGlassLozengeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGlassLozengeClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIGlassLozenge" points:2 bg:TRUE properties:kCI_Radius,kCI_Refraction,kCI_Point0,kCI_Point1,0];
}

- (void)execute
{
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGlassLozenge"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGlassLozengeDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputPoint0"];
    [filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y] forKey:@"inputPoint1"];
    [filter setValue:[NSNumber numberWithInt:[self intValue:kCI_Radius]] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Refraction]] forKey:@"inputRefraction"];
    
    [self applyFilter:filter];
}

@end
