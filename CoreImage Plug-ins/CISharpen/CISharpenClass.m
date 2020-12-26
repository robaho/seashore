#import "CISharpenClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CISharpenClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CISharpen" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sharpen" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CISharpen.value"])
		value = [gUserDefaults floatForKey:@"CISharpen.value"];
	else
		value = 0.4;
	refresh = YES;
	
	if (value < 0.0 || value > 5.0)
		value = 0.4;
	
	[valueLabel setStringValue:[NSString stringWithFormat:@"%.2f", value]];
	
	[valueSlider setFloatValue:value];
	
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
		
	[gUserDefaults setFloat:value forKey:@"CISharpen.value"];
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
	value = [valueSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[valueLabel setStringValue:[NSString stringWithFormat:@"%.2f", value]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    CIFilter *filter = [CIFilter filterWithName:@"CISharpenLuminance"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CISharpenLuminance"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithFloat:value] forKey:@"inputSharpness"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
