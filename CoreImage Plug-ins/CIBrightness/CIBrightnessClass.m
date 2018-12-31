#import "CIBrightnessClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIBrightnessClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIBrightness" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Brightness and Contrast" table:NULL];
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
	
	brightness = 0.0;
	contrast = 1.0;
	saturation = 1.0;
	
	[brightnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", brightness]];
	[brightnessSlider setFloatValue:brightness];
	[contrastLabel setStringValue:[NSString stringWithFormat:@"%.2f", contrast]];
	[contrastSlider setFloatValue:contrast * 10.0];
	[saturationLabel setStringValue:[NSString stringWithFormat:@"%.2f", saturation]];
	[saturationSlider setFloatValue:saturation];
		
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
		
	[gUserDefaults setFloat:brightness forKey:@"CIBrightness.brightness"];
	[gUserDefaults setFloat:contrast forKey:@"CIBrightness.contrast"];
	[gUserDefaults setFloat:saturation forKey:@"CIBrightness.saturation"];
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
	
	brightness = [brightnessSlider floatValue];
	contrast = [contrastSlider floatValue] / 10.0;
	saturation = [saturationSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[brightnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", brightness]];
	[contrastLabel setStringValue:[NSString stringWithFormat:@"%.2f", contrast]];
	[saturationLabel setStringValue:[NSString stringWithFormat:@"%.2f", saturation]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIColorControls"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:brightness] forKey:@"inputBrightness"];
    [filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputContrast"];
    [filter setValue:[NSNumber numberWithFloat:saturation] forKey:@"inputSaturation"];

    applyFilter([seaPlugins data],filter);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
