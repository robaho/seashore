#import "CIUnsharpMaskClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIUnsharpMaskClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIUnsharpMask" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Contrast Sharpen" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Enhance" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	if ([gUserDefaults objectForKey:@"CIUnsharpMask.radius"])
		radius = [gUserDefaults floatForKey:@"CIUnsharpMask.radius"];
	else
		radius = 2.5;
	
	if (radius < 0.0 || radius > 1.0)
		radius = 2.5;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	[radiusSlider setFloatValue:radius];
	
	if ([gUserDefaults objectForKey:@"CIUnsharpMask.intensity"])
		intensity = [gUserDefaults floatForKey:@"CIUnsharpMask.intensity"];
	else
		intensity = 0.5;
	
	if (intensity < 0.0 || intensity > 1.0)
		intensity = 0.5;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	[intensitySlider setFloatValue:intensity];
	
	refresh = YES;
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
		
	[gUserDefaults setFloat:radius forKey:@"CIUnsharpMask.radius"];
	[gUserDefaults setFloat:intensity forKey:@"CIUnsharpMask.intensity"];
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
	radius = [radiusSlider floatValue];
	intensity = [intensitySlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) 
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%.1f", radius]];
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CIUnsharpMask"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIUnsharpMask"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];
    
    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
