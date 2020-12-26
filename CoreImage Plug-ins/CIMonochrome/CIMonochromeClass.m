#import "CIMonochromeClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIMonochromeClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
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
	if ([gUserDefaults objectForKey:@"CIMonochrome.intensity"])
		intensity = [gUserDefaults floatForKey:@"CIMonochrome.intensity"];
	else
		intensity = 1.0;
	refresh = YES;
	
	if (intensity < 0.0 || intensity > 1.0)
		intensity = 1.0;
	
	[intensityLabel setStringValue:[NSString stringWithFormat:@"%.2f", intensity]];
	
	[intensitySlider setFloatValue:intensity];
	
    mainNSColor = [mainColorWell color];
	
	success = NO;
	running = YES;
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
	running = NO;
		
	[gUserDefaults setFloat:intensity forKey:@"CIMonochrome.intensity"];
	[gColorPanel orderOut:self];
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
	running = NO;
	[gColorPanel orderOut:self];
}

- (void)setColor:(NSColor *)color
{
    mainNSColor = color;
	if (running) {
		refresh = YES;
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
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
    int height = [pluginData height];
    IntPoint point = [pluginData point:0];
    IntPoint apoint = [pluginData point:1];
    int radius = (apoint.x - point.x) * (apoint.x - point.x) + (apoint.y - point.y) * (apoint.y - point.y);
    radius = sqrt(radius);
    
    CIColor *mainColor = createCIColor(mainNSColor);
    
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
+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
