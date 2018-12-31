#import "CIMonochromeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIMonochromeClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIMonochrome" owner:self];
	mainNSColor = NULL;
	running = NO;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Monochrome" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CIMonochrome.intensity"])
		intensity = [gUserDefaults floatForKey:@"CIMonochrome.intensity"];
	else
		intensity = 1.0;
	refresh = YES;
	
	if (intensity < 0.0 || intensity > 1.0)
		intensity = 1.0;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	
	[intensitySlider setFloatValue:intensity];
	
	if (mainNSColor) [mainNSColor autorelease];
	mainNSColor = [[mainColorWell color] colorUsingColorSpaceName:MyRGBSpace];
	[mainNSColor retain];
	
	success = NO;
	running = YES;
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
	running = NO;
		
	[gUserDefaults setFloat:intensity forKey:@"CIMonochrome.intensity"];
	[gColorPanel orderOut:self];
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
	running = NO;
	[gColorPanel orderOut:self];
}

- (void)setColor:(NSColor *)color
{
	PluginData *pluginData;
	
	if (mainNSColor) [mainNSColor autorelease];
	mainNSColor = [color colorUsingColorSpaceName:MyRGBSpace];
	[mainNSColor retain];
	if (running) {
		refresh = YES;
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	intensity = [intensitySlider floatValue];
	
	[panel setAlphaValue:1.0];
	
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
    
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    int radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
    radius = sqrt(radius);
    
    CIColor *mainColor = [CIColor colorWithRed:[mainNSColor redComponent] green:[mainNSColor greenComponent] blue:[mainNSColor blueComponent]];
    
    // Run filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIColorMonochrome"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];
    [filter setValue:mainColor forKey:@"inputColor"];
    
    applyFilter(pluginData,filter);
}
- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
