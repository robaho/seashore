#import "CIGaussianBlurClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGaussianBlurClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIGaussianBlur" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Gaussian Blur" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Blur" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	if ([gUserDefaults objectForKey:@"CIGaussianBlur.radius"])
		radius = [gUserDefaults integerForKey:@"CIGaussianBlur.radius"];
	else
		radius = 10;
	refresh = YES;
	
	if (radius < 1 || radius > 100)
		radius = 10;
	
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
		
	[gUserDefaults setInteger:radius forKey:@"CIGaussianBlur.radius"];
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
    // We need to apply a CIAffineClamp to prevent the black soft fringe we'd normally get from
    // the content outside the borders of the image
    CIFilter *clamp = [CIFilter filterWithName: @"CIAffineClamp"];
    [clamp setDefaults];
    [clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
    
    // Run filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGaussianBlur"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];

    applyFilters(pluginData,clamp,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
