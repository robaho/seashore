#import "CIDisplacementDistortionClass.h"

@implementation CIDisplacementDistortionClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CIDisplacementDistortion" points:0 properties:kCI_Scale1000,0];

    NSString *directory = [NSString stringWithFormat:@"%@/textures/", [[NSBundle mainBundle] resourcePath]];
    texture = [SeaFileChooser chooserWithTitle:@"Texture: %@" types:[NSImage imageTypes] directory:directory Listener:self];
    [panel addSubview:texture];

	return self;
}

- (void)execute
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForImageResource:@"default-distort"];
    NSString *texturePath = [texture path];
    if(texturePath)
        path = texturePath;

    bool opaque = ![pluginData hasAlpha];

    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTile"];
    [filter setDefaults];
    [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:path]] forKey:@"inputImage"];
    [filter setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
    CIImage *texture_output = [filter valueForKey: @"outputImage"];

    filter = [CIFilter filterWithName:@"CIDisplacementDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIDisplacementDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:texture_output forKey:@"inputDisplacementImage"];
    [filter setValue:[NSNumber numberWithFloat:[self floatValue:kCI_Scale1000]] forKey:@"inputScale"];

    if (opaque) {
        [self applyFilterBG:filter];
    }
    else {
        [self applyFilter:filter];
    }
}

@end
