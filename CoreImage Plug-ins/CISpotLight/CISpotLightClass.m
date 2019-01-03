#import "CISpotLightClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CISpotLightClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CISpotLight" owner:self];
	mainNSColor = NULL;
	running = NO;
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Spotlight" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CISpotLight.brightness"])
		brightness = [gUserDefaults floatForKey:@"CISpotLight.brightness"];
	else
		brightness = 3.0;
	
	if (brightness < 0.0 || brightness > 10.0)
		brightness = 3.0;
	
	if ([gUserDefaults objectForKey:@"CISpotLight.concentration"])
		concentration = [gUserDefaults floatForKey:@"CISpotLight.concentration"];
	else
		concentration = 0.4;
	
	if (concentration < 0.0 || concentration > 2.0)
		concentration = 0.4;
	
	if ([gUserDefaults objectForKey:@"CISpotLight.srcHeight"])
		srcHeight = [gUserDefaults floatForKey:@"CISpotLight.srcHeight"];
	else
		srcHeight = 150;
	
	if (srcHeight < 50 || srcHeight > 500)
		srcHeight = 150;
	
	if ([gUserDefaults objectForKey:@"CISpotLight.destHeight"])
		destHeight = [gUserDefaults floatForKey:@"CISpotLight.destHeight"];
	else
		destHeight = 0;
	
	if (destHeight < -100 || destHeight > 400)
		destHeight = 0;
	
	[brightnessLabel setStringValue:[NSString stringWithFormat:@"%.1f", brightness]];
	[brightnessSlider setFloatValue:brightness];
	[concentrationLabel setStringValue:[NSString stringWithFormat:@"%.2f", concentration]];
	[concentrationSlider setFloatValue:concentration];
	[srcHeightLabel setStringValue:[NSString stringWithFormat:@"%d", srcHeight]];
	[srcHeightSlider setIntValue:srcHeight];
	[destHeightLabel setStringValue:[NSString stringWithFormat:@"%d", destHeight]];
	[destHeightSlider setIntValue:destHeight];
	
    mainNSColor = [mainColorWell color];
	
	refresh = YES;
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
		
	[gUserDefaults setFloat:brightness forKey:@"CISpotLight.brightness"];
	[gUserDefaults setFloat:concentration forKey:@"CISpotLight.concentration"];
	[gUserDefaults setInteger:srcHeight forKey:@"CISpotLight.srcHeight"];
	[gUserDefaults setInteger:destHeight forKey:@"CISpotLight.destHeight"];
	
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
	running = NO;
	[gColorPanel orderOut:self];
}

- (void)setColor:(NSColor *)color
{
	PluginData *pluginData;
	
    mainNSColor = color;
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
	
	brightness = [brightnessSlider floatValue];
	concentration = [concentrationSlider floatValue];
	destHeight = [destHeightSlider intValue];
	srcHeight = [srcHeightSlider intValue];
	
	[panel setAlphaValue:1.0];
	
	[brightnessLabel setStringValue:[NSString stringWithFormat:@"%.1f", brightness]];
	[concentrationLabel setStringValue:[NSString stringWithFormat:@"%.2f", concentration]];
	[srcHeightLabel setStringValue:[NSString stringWithFormat:@"%d", srcHeight]];
	[destHeightLabel setStringValue:[NSString stringWithFormat:@"%d", destHeight]];
	
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
    
    CIColor *mainColor = createCIColor(mainNSColor);
    
    CIFilter *filter = [CIFilter filterWithName:@"CISpotLight"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISpotLight"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:mainColor forKey:@"inputColor"];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y Z:srcHeight] forKey:@"inputLightPosition"];
    [filter setValue:[CIVector vectorWithX:apoint.x Y:height - apoint.y Z:destHeight] forKey:@"inputLightPointsAt"];
    [filter setValue:[NSNumber numberWithFloat:concentration] forKey:@"inputConcentration"];
    [filter setValue:[NSNumber numberWithFloat:brightness] forKey:@"inputBrightness"];
    
    bool opaque = ![pluginData hasAlpha];
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
