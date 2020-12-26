#import "CICMYKHalftoneClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CICMYKHalftoneClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CICMYKHalftone" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"CMYK Halftone" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Halftone" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	if ([gUserDefaults objectForKey:@"CICMYKHalftone.width"])
		dotWidth = [gUserDefaults integerForKey:@"CICMYKHalftone.width"];
	else
		dotWidth = 6;
	if ([gUserDefaults objectForKey:@"CICMYKHalftone.angle"])
		angle = [gUserDefaults floatForKey:@"CICMYKHalftone.angle"];
	else
		angle = 0.0;
	if ([gUserDefaults objectForKey:@"CICMYKHalftone.sharpness"])
		sharpness = [gUserDefaults floatForKey:@"CICMYKHalftone.sharpness"];
	else
		sharpness = 0.7;
	if ([gUserDefaults objectForKey:@"CICMYKHalftone.gcr"])
		gcr = [gUserDefaults floatForKey:@"CICMYKHalftone.gcr"];
	else
		gcr = 1.0;
	if ([gUserDefaults objectForKey:@"CICMYKHalftone.ucr"])
		ucr = [gUserDefaults floatForKey:@"CICMYKHalftone.ucr"];
	else
		ucr = 0.5;
	
	if (dotWidth < 2 || dotWidth > 100)
		dotWidth = 6;
	if (angle < -3.14 || angle > 3.14)
		angle = 0.0;
	if (sharpness < 0.0 || sharpness > 1.0)
		sharpness = 0.7;
	if (gcr < 0.0 || gcr > 1.0)
		gcr = 1.0;
	if (ucr < 0.0 || ucr > 1.0)
		ucr = 0.5;
	
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[dotWidthSlider setIntValue:dotWidth];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[angleSlider setFloatValue:angle * 100.0];
	[sharpnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharpness]];
	[sharpnessSlider setFloatValue:sharpness];
	[gcrLabel setStringValue:[NSString stringWithFormat:@"%.2f", gcr]];
	[gcrSlider setFloatValue:gcr];
	[ucrLabel setStringValue:[NSString stringWithFormat:@"%.2f", ucr]];
	[ucrSlider setFloatValue:ucr];
	
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
		
	[gUserDefaults setInteger:dotWidth forKey:@"CICMYKHalftone.width"];
	[gUserDefaults setFloat:angle forKey:@"CICMYKHalftone.angle"];
	[gUserDefaults setFloat:sharpness forKey:@"CICMYKHalftone.sharpness"];
	[gUserDefaults setFloat:gcr forKey:@"CICMYKHalftone.gcr"];
	[gUserDefaults setFloat:ucr forKey:@"CICMYKHalftone.ucr"];
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
	dotWidth = [dotWidthSlider intValue];
	angle = roundf([angleSlider floatValue]) / 100.0;
	sharpness = [sharpnessSlider floatValue];
	ucr = [ucrSlider floatValue];
	gcr = [gcrSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[dotWidthLabel setStringValue:[NSString stringWithFormat:@"%d", dotWidth]];
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[sharpnessLabel setStringValue:[NSString stringWithFormat:@"%.2f", sharpness]];
	[ucrLabel setStringValue:[NSString stringWithFormat:@"%.2f", ucr]];
	[gcrLabel setStringValue:[NSString stringWithFormat:@"%.2f", gcr]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    int width = [pluginData width];
    int height = [pluginData height];
    
    CIFilter *filter = [CIFilter filterWithName:@"CICMYKHalftone"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CICMYKHalftone"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:dotWidth] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];
    [filter setValue:[NSNumber numberWithFloat:sharpness] forKey:@"inputSharpness"];
    [filter setValue:[NSNumber numberWithFloat:gcr] forKey:@"inputGCR"];
    [filter setValue:[NSNumber numberWithFloat:ucr] forKey:@"inputUCR"];

    applyFilter(pluginData,filter);
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
    if ([pluginData channel] == kAlphaChannel)
        return NO;
    
    if ([pluginData spp] == 2)
        return NO;
	
	return YES;
}

@end
