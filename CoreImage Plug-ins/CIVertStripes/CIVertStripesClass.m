#import "CIVertStripesClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIVertStripesClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Vertical Stripes" table:NULL];
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
    
    CIColor *foreColor = [CIColor colorWithCGColor:[[pluginData foreColor] CGColor]];
    CIColor *backColor = [CIColor colorWithCGColor:[[pluginData backColor] CGColor]];
    
    int amount = abs(apoint.x - point.x);

    CIFilter *filter = [CIFilter filterWithName:@"CIStripesGenerator"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircleSplash"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:backColor forKey:@"inputColor0"];
    [filter setValue:foreColor forKey:@"inputColor1"];
    [filter setValue:[NSNumber numberWithInt:amount] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSharpness"];
    
    CIImage *output = [filter valueForKey: @"outputImage"];
    
    renderCIImage(pluginData,output);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
