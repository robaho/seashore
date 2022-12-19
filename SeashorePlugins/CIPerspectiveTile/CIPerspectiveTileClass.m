#import "CIPerspectiveTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIPerspectiveTileClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIPerspectiveTile" points:4 properties:0];
}

- (void)execute
{
    CGRect bounds = determineContentBorders(pluginData);
    CIImage *inputImage = [self croppedCIImage:bounds];
    
    CIFilter *filter = [super createFilter];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[self pointValue:0] forKey:@"inputTopLeft"];
    [filter setValue:[self pointValue:1] forKey:@"inputTopRight"];
    [filter setValue:[self pointValue:2] forKey:@"inputBottomRight"];
    [filter setValue:[self pointValue:3] forKey:@"inputBottomLeft"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    [self renderCIImage:outputImage];
}

@end
