#import "CICircularWrapClass.h"

@implementation CICircularWrapClass

- (id)initWithManager:(PluginData *)data
{
    return [super initWithManager:data filter:@"CICircularWrap" points:2 properties:kCI_Angle,kCI_PointCenter,kCI_PointRadius,0];
}

- (void)execute
{
    CGRect bounds = determineContentBorders(pluginData);
    
    CIImage *inputImage = croppedCIImage(pluginData,bounds);

    float rads = [self radiansValue:kCI_Angle];

    CIFilter *filter = [CIFilter filterWithName:@"CICircularWrap"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircularWrap"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[self centerPointValue] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:[self radiusValue]] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:rads] forKey:@"inputAngle"];
    CIImage *outputImage = [filter valueForKey:@"outputImage"];
    
    bool opaque = ![pluginData hasAlpha];
    
    if (opaque) {
        CIColor *backColor = createCIColor([pluginData backColor]);

        filter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
        [filter setDefaults];
        [filter setValue:backColor forKey:@"inputColor"];
        CIImage *background = [filter valueForKey: @"outputImage"];
        filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [filter setDefaults];
        [filter setValue:background forKey:@"inputBackgroundImage"];
        [filter setValue:outputImage forKey:@"inputImage"];
        outputImage = [filter valueForKey:@"outputImage"];
    }
    
    renderCIImage(pluginData,outputImage);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
