#import "CIAffineTileClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIAffineTileClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 2;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Scale and Rotate" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Tile" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	[self execute];
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
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
    
    CIImage *inputImage = croppedCIImage(pluginData,bounds);
    
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
    
    renderCIImage(pluginData,outputImage);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
