#import "CIGlassDistortionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGlassDistortionClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data filter:@"CIGlassDistortion" points:0 properties:kCI_Scale1000,0];

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
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGlassDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGlassDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:path]] forKey:@"inputTexture"];
    [filter setValue:[self centerPointValue] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:[self intValue:kCI_Scale1000]] forKey:@"inputScale"];
    
    if (opaque){
        [self applyFilterBG:filter];
    } else {
        [self applyFilter:filter];
    }
}


@end
