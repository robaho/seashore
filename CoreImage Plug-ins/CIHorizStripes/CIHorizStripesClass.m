#import "CIHorizStripesClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIHorizStripesClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Horizontal Stripes" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
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
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
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
    PluginData *pluginData = [seaPlugins data];
    
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    int amount = abs(apoint.y - point.y);

    
    CIColor *foreColor = createCIColor([pluginData foreColor]);
    CIColor *backColor = createCIColor([pluginData backColor]);
    
    CIFilter *filter = [CIFilter filterWithName:@"CIStripesGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircleSplash"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:height - point.y Y:point.x] forKey:@"inputCenter"];
    [filter setValue:foreColor forKey:@"inputColor0"];
    [filter setValue:backColor forKey:@"inputColor1"];
    [filter setValue:[NSNumber numberWithInt:amount] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSharpness"];
    CIImage *pre_output = [filter valueForKey: @"outputImage"];
    
    // Run rotation
    filter = [CIFilter filterWithName:@"CIAffineTransform"];
    [filter setDefaults];
    NSAffineTransform *rotateTransform = [NSAffineTransform transform];
    [rotateTransform rotateByDegrees:90.0];
    [filter setValue:pre_output forKey:@"inputImage"];
    [filter setValue:rotateTransform forKey:@"inputTransform"];
    CIImage *output = [filter valueForKey: @"outputImage"];

    renderCIImage(pluginData,output);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
