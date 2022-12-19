#import "CIStarshineClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIStarshineClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CIStarShineGenerator" points:2 bg:TRUE properties:kCI_PointCenter,kCI_PointRadius,kCI_PointAngle,kCI_Scale100,kCI_Opacity,kCI_Width,kCI_Color,0];
    [self setFilterProperty:kCI_PointAngle property:@"inputCrossAngle"];
    [self setFilterProperty:kCI_Scale100 property:@"inputCrossScale"];
    [self setFilterProperty:kCI_Opacity property:@"inputCrossOpacity"];
    [self setFilterProperty:kCI_Width property:@"inputCrossWidth"];
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
