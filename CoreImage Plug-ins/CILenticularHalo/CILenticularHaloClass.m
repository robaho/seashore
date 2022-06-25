#import "CILenticularHaloClass.h"

@implementation CILenticularHaloClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CILenticularHalo" points:2 properties:kCI_PointCenter,kCI_PointRadius,kCI_Width,kCI_Overlap,kCI_Strength,kCI_Contrast,kCI_Color0,0];

    return self;
}

- (void)execute
{
    [pluginData setOverlayBehaviour:0];
    CIFilter *filter = [CIFilter filterWithName:@"CILenticularHaloGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CILenticularHaloGenerator"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[self centerPointValue] forKey:@"inputCenter"];
    [filter setValue:[self colorValue:kCI_Color0] forKey:@"inputColor"];
    [filter setValue:[NSNumber numberWithInt:[self radiusValue]] forKey:@"inputHaloRadius"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Width]] forKey:@"inputHaloWidth"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Overlap]] forKey:@"inputHaloOverlap"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Strength]] forKey:@"inputStriationStrength"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Contrast]] forKey:@"inputStriationContrast"];
    [filter setValue:[NSNumber numberWithInt:0] forKey:@"inputTime"];

    applyFilterAsOverlay(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
    if ([pluginData spp] == 2)
        return NO;
    
    return YES;
}

@end
