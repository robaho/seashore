#import "CISepiaClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CISepiaClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CISepia" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sepia" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CISepia.intensity"])
		intensity = [gUserDefaults integerForKey:@"CISepia.intensity"];
	else
		intensity = 1.0;
	
	if (intensity < 0.0 || intensity > 1.0)
		intensity = 1.0;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f",	intensity]];
	
	[intensitySlider setIntValue:intensity];
	
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
	intensity = [intensitySlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISepiaTone"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];
    
    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
