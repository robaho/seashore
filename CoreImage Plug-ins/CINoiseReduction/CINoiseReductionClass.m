#import "CINoiseReductionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CINoiseReductionClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CINoiseReduction" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Noise Reduction" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CINoiseReduction.noise"])
		noise = [gUserDefaults floatForKey:@"CINoiseReduction.noise"];
	else
		noise = 0.02;
	
	if (noise < 0.0 || noise > 0.1)
		noise = 0.02;
	
	[noiseLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", noise * 100.0]];
	[noiseSlider setFloatValue:noise * 100.0];
	
	if ([gUserDefaults objectForKey:@"CINoiseReduction.sharp"])
		sharp = [gUserDefaults floatForKey:@"CINoiseReduction.sharp"];
	else
		sharp = 0.4;
	
	if (sharp < 0.0 || sharp > 2.0)
		sharp = 0.4;
	
	[sharpLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharp]];
	[sharpSlider setFloatValue:sharp * 100.0];
	
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
		
	[gUserDefaults setFloat:sharp forKey:@"CINoiseReduction.noise"];
	[gUserDefaults setFloat:sharp forKey:@"CINoiseReduction.sharp"];
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
	noise = [noiseSlider floatValue] / 100.0;
	sharp = [sharpSlider floatValue] / 100.0;
	
	[panel setAlphaValue:1.0];
	
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) 
	[noiseLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", noise * 100.0]];
	[sharpLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharp]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CINoiseReduction"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CINoiseReduction"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:noise] forKey:@"inputNoiseLevel"];
    [filter setValue:[NSNumber numberWithFloat:sharp] forKey:@"inputSharpness"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
