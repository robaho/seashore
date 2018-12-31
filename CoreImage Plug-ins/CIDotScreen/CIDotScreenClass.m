#import "CIDotScreenClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIDotScreenClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIDotScreen" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Dot Screen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"CIDotScreen.width"])
		dotWidth = [gUserDefaults integerForKey:@"CIDotScreen.width"];
	else
		dotWidth = 6;
	if ([gUserDefaults objectForKey:@"CIDotScreen.angle"])
		angle = [gUserDefaults floatForKey:@"CIDotScreen.angle"];
	else
		angle = 0.0;
	if ([gUserDefaults objectForKey:@"CIDotScreen.sharpness"])
		sharpness = [gUserDefaults floatForKey:@"CIDotScreen.sharpness"];
	else
		sharpness = 0.7;
			
	if (dotWidth < 2 || dotWidth > 100)
		dotWidth = 6;
	if (angle < -1.57 || angle > 1.57)
		angle = 0.0;
	if (sharpness < 0.0 || sharpness > 1.0)
		sharpness = 0.7;
			
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[dotWidthSlider setIntValue:dotWidth];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[angleSlider setFloatValue:angle * 100.0];
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
		
	[gUserDefaults setInteger:dotWidth forKey:@"CIDotScreen.width"];
	[gUserDefaults setFloat:angle forKey:@"CIDotScreen.angle"];
	[gUserDefaults setFloat:sharpness forKey:@"CIDotScreen.sharpness"];
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
	
	dotWidth = [dotWidthSlider intValue];
	angle = roundf([angleSlider floatValue]) / 100.0;
	sharpness = [sharpnessSlider floatValue];
	if (angle > -0.015 && angle < 0.00) angle = 0.00; /* Force a zero point */
	
	[panel setAlphaValue:1.0];
	
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
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
    
    int width = [pluginData width];
    int height = [pluginData height];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIDotScreen"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIDotScreen"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:dotWidth] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [filter setValue:[NSNumber numberWithFloat:sharpness] forKey:@"inputSharpness"];

    applyFilter([seaPlugins data],filter);
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
