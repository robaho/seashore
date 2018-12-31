#import "CICircularScreenClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

#define make_128(x) (x + 16 - (x % 16))

@implementation CICircularScreenClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CICircularScreen" owner:self];
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 1;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Circular Screen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CICircularScreen.width"])
		dotWidth = [gUserDefaults integerForKey:@"CICircularScreen.width"];
	else
		dotWidth = 6;
	if ([gUserDefaults objectForKey:@"CICircularScreen.sharpness"])
		sharpness = [gUserDefaults floatForKey:@"CICircularScreen.sharpness"];
	else
		sharpness = 0.7;
			
	if (dotWidth < 2 || dotWidth > 100)
		dotWidth = 6;
	if (sharpness < 0.0 || sharpness > 1.0)
		sharpness = 0.7;
			
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[dotWidthSlider setIntValue:dotWidth];
	[sharpnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharpness]];
	[sharpnessSlider setFloatValue:sharpness];
	
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
		
	[gUserDefaults setInteger:dotWidth forKey:@"CICircularScreen.width"];
	[gUserDefaults setFloat:sharpness forKey:@"CICircularScreen.sharpness"];
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
	return NO;
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
	
	dotWidth = [dotWidthSlider intValue];
	sharpness = [sharpnessSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[sharpnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharpness]];
	
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
    
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    
    CIFilter *filter = [CIFilter filterWithName:@"CICircularScreen"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICircularScreen"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:dotWidth] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:sharpness] forKey:@"inputSharpness"];

    applyFilter(pluginData,filter);
}

- (BOOL)validateMenuItem:(id)menuItem
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	
	if (pluginData != NULL) {

		if ([pluginData channel] == kAlphaChannel)
			return NO;
		
		if ([pluginData spp] == 2)
			return NO;
	
	}
	
	return YES;
}

@end
