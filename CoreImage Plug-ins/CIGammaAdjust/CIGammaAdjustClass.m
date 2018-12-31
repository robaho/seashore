#import "CIGammaAdjustClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation CIGammaAdjustClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIGammaAdjust" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gamma" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Adjust" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	gamma = 1.0;
	
	[gammaLabel setStringValue:[NSString stringWithFormat:@"%.2f", gamma]];
	
	[gammaSlider setIntValue:gamma * 100];
	
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
	
	gamma = roundf([gammaSlider floatValue]) / 100.0;
	if (gamma > 1.0 && gamma < 1.02) gamma = 1.0; /* Force one point */
	
	[panel setAlphaValue:1.0];
	
	[gammaLabel setStringValue:[NSString stringWithFormat:@"%.2f", gamma]];
	
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
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGammaAdjust"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGammaAdjust"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:gamma] forKey:@"inputPower"];
    
    applyFilter(pluginData,filter);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
