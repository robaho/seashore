#import "CIGloomClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGloomClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIGloom" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gloom" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CIGloom.radius"])
		radius = [gUserDefaults integerForKey:@"CIGloom.radius"];
	else
		radius = 10;
	refresh = YES;
	
	if (radius < 0 || radius > 0.1)
		radius = 10;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	[radiusSlider setFloatValue:radius];
	
	if ([gUserDefaults objectForKey:@"CIGloom.intensity"])
		intensity = [gUserDefaults floatForKey:@"CIGloom.intensity"];
	else
		intensity = 1.0;
	refresh = YES;
	
	if (intensity < 0.0 || intensity > 1.0)
		intensity = 1.0;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", intensity * 100.0]];
	[intensitySlider setFloatValue:intensity];
	
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
	if (refresh) [self execute];
	[pluginData apply];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
		
	[gUserDefaults setFloat:radius forKey:@"CIGloom.radius"];
	[gUserDefaults setFloat:intensity forKey:@"CIGloom.intensity"];
}

- (void)reapply
{
	[self execute];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	radius = [radiusSlider intValue];
	intensity = [intensitySlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) 
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", intensity * 100.0]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CIGloom"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGloom"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
