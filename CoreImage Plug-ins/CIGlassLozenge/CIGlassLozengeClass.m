#import "CIGlassLozengeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGlassLozengeClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIGlassLozenge" owner:self];
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Glass Lozenge" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Distort" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CIGlassLozenge.refraction"])
		refraction = [gUserDefaults floatForKey:@"CIGlassLozenge.refraction"];
	else
		refraction = 1.7;
	
	if (refraction < -5.0 || refraction > 5.0)
		refraction = 1.7;
		
	if ([gUserDefaults objectForKey:@"CIGlassLozenge.radius"])
		radius = [gUserDefaults integerForKey:@"CIGlassLozenge.radius"];
	else
		radius = 100;
	
	if (radius < 0 || radius > 1000)
		radius = 100;
	
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	[refractionSlider setFloatValue:refraction];
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	[radiusSlider setIntValue:radius % 200];
	[radiusStepper setIntValue:radius - radius % 200];
	
	refresh = YES;
	success = NO;
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
		
	[gUserDefaults setFloat:refraction forKey:@"CIGlassLozenge.refraction"];
	[gUserDefaults setInteger:radius forKey:@"CIGlassLozenge.radius"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self execute];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	refraction = [refractionSlider floatValue];
	radius = [radiusSlider intValue] + [radiusStepper intValue];
	
	[panel setAlphaValue:1.0];
	
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp || [sender tag] == 99) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGlassLozenge"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGlassLozengeDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputPoint0"];
    [filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y] forKey:@"inputPoint1"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:refraction] forKey:@"inputRefraction"];
    
    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
