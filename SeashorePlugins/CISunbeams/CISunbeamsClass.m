#import "CISunbeamsClass.h"

@implementation CISunbeamsClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CISunbeamsGenerator" points:2 bg:FALSE properties:kCI_PointCenter,kCI_PointRadius,kCI_Width,kCI_Strength,kCI_Contrast,0];
    [self setFilterProperty:kCI_PointRadius property:@"inputSunRadius"];
    [self setFilterProperty:kCI_Width property:@"inputMaxStriationRadius"];
    [self setFilterProperty:kCI_Strength property:@"inputStriationStrength"];
    [self setFilterProperty:kCI_Contrast property:@"inputStriationContrast"];
    return self;
}

- (void)execute
{
    CIFilter *filter = [super createFilter];
    [self applyFilterAsOverlay:filter];
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    if (pluginData != NULL) {

        if ([pluginData channel] == kAlphaChannel)
            return NO;
    }
    
    return YES;
}

@end
