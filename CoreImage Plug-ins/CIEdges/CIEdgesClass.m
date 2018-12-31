#import "CIEdgesClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIEdgesClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIEdges" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Color Edges" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Stylize" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"CIEdges.intensity"])
		intensity = [gUserDefaults floatForKey:@"CIEdges.intensity"];
	else
		intensity = 1.0;
	refresh = YES;
	
	if (intensity < 0.0 || intensity > 10.0)
		intensity = 1.0;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	
	[intensitySlider setFloatValue:intensity];
	
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
		
	[gUserDefaults setFloat:intensity forKey:@"CIEdges.intensity"];
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
	
	intensity = [intensitySlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) 
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIEdges"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIEdges"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];

    applyFilter(pluginData,filter);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
