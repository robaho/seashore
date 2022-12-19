#import "CIHorizStripesClass.h"

@implementation CIHorizStripesClass

- (id)initWithManager:(id<PluginData>)data
{
    return [super initWithManager:data filter:@"CIStripesGenerator" points:2 properties:kCI_PointCenter,kCI_PointWidth,kCI_Color0,kCI_Color1,kCI_Sharpness,0];
}

- (void)applyFilter:(CIFilter*)filter
{
    CIImage *pre_output = [filter valueForKey: @"outputImage"];

    // Run rotation
    filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setDefaults];
    NSAffineTransform *rotateTransform = [NSAffineTransform transform];
    [rotateTransform rotateByDegrees:90.0];
    [filter setValue:pre_output forKey:@"inputImage"];
    [filter setValue:rotateTransform forKey:@"inputTransform"];
    CIImage *output = [filter valueForKey: @"outputImage"];

    [self renderCIImage:output];
}


@end
