#import "CICrystallizeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CICrystallizeClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CICrystallize" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Crystallize" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CICrystallize.radius"])
		radius = [gUserDefaults integerForKey:@"CICrystallize.radius"];
	else
		radius = 20;
	refresh = YES;
	
	if (radius < 1 || radius > 60)
		radius = 20;
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	
	[radiusSlider setIntValue:radius];
	
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
		
	[gUserDefaults setInteger:radius forKey:@"CICrystallize.radius"];
}

- (void)reapply
{
	[self execute];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return NO;
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
	radius = roundf([radiusSlider floatValue]);
	
	[panel setAlphaValue:1.0];
	
	[radiusLabel setStringValue:[NSString stringWithFormat:@"%d", radius]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    int width = [pluginData height];
    int height = [pluginData height];
    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CICrystallize"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICrystallize"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    
    if (opaque) {
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
