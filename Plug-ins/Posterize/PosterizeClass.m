#import "PosterizeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation PosterizeClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"Posterize" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Posterize" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;

	if ([gUserDefaults objectForKey:@"Posterize.posterize"])
		posterize = [gUserDefaults integerForKey:@"Posterize.posterize"];
	else
		posterize = 2;
	refresh = YES;
	
	if (posterize < 2 || posterize > 255)
		posterize = 1;
	
	[posterizeLabel setStringValue:[NSString stringWithFormat:@"%d", posterize]];
	
	[posterizeSlider setIntValue:posterize];
	
	refresh = YES;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	
	success = NO;
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
	if (refresh) [self posterize];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[gUserDefaults setInteger:posterize forKey:@"Posterize.posterize"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self posterize];
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
	if (refresh) [self posterize];
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
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	posterize = [posterizeSlider intValue];
	[posterizeLabel setStringValue:[NSString stringWithFormat:@"%d", posterize]];
	[panel setAlphaValue:1.0];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)posterize
{
	PluginData *pluginData;
	IntRect selection;
	int i, j, k, t1, t2, spp, width, channel, value;
	unsigned char *data, *overlay, *replace;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			if (channel == kAllChannels || channel == kPrimaryChannels) {
				
				for (k = 0; k < spp - 1; k++) {
					value = data[(j * width + i) * spp + k];
					value = (float)value * (float)posterize / 255.0;
					value = (float)value * 255.0 / (float)(posterize - 1);
					if (value > 255) value = 255;
					if (value < 0) value = 0;
					overlay[(j * width + i) * spp +	k] = value;
				}
				overlay[(j * width + i + 1) * spp - 1] = data[(j * width + i + 1) * spp - 1];
				replace[j * width + i] = 255;
				
			}
			
			else if (channel == kAlphaChannel) {
			
				value = data[(j * width + i + 1) * spp - 1];
				value = (float)value * (float)posterize / 255.0;
				value = (float)value * 255.0 / (float)(posterize - 1);
				if (value > 255) value = 255;
				if (value < 0) value = 0;
				memset(&(overlay[(j * width + i) * spp]), value, spp - 1);
				overlay[(j * width + i + 1) * spp - 1] = 255;
				replace[j * width + i] = 255;
				
			}
			
		}
	}
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
