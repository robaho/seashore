#import "CIAffineTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIAffineTileClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:NULL points:2 properties:NULL];
}

- (void)execute
{
    int width = [pluginData width];
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    int baselen = calculateRadius(point,apoint);
    
    CGRect bounds = determineContentBorders(pluginData);
    
    bool boundsValid = !CGRectIsNull(bounds);
    
    float scale;
    
    if (boundsValid)
        scale = (float)baselen / (float)bounds.size.width;
    else
        scale = (float)baselen / (float)width;
    
    float angle = calculateAngle(point,apoint);
    
    CIImage *inputImage = [self croppedCIImage:bounds];
    
    NSAffineTransform *trueTransform = [NSAffineTransform transform];
    [trueTransform translateXBy:point.x yBy:height - point.y];
    [trueTransform scaleBy:scale];
    [trueTransform rotateByRadians:angle];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTile"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIAffineTile"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:trueTransform forKey:@"inputTransform"];
    CIImage *outputImage = [filter valueForKey: @"outputImage"];
    
    [self renderCIImage:outputImage];
}

@end
