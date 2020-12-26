#import "CIVortexClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIVortexClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIVortex" owner:self];
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Vortex" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Distort" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CIVortex.angle"])
		angle = [gUserDefaults integerForKey:@"CIVortex.angle"];
	else
		angle = 56.55;
	refresh = YES;
	
	if (angle < -94.25 || angle > 94.25)
		angle = 56.55;
	
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	[angleSlider setFloatValue:abs(angle * 100.0)];
	[reverseCheckbox setState:(angle < 0.0)];
	
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
		
	[gUserDefaults setFloat:angle forKey:@"CIVortex.angle"];
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
	angle = [angleSlider floatValue] / 100.0 * ([reverseCheckbox state] ? -1.0 : 1.0);
	
	[panel setAlphaValue:1.0];
	
	[angleLabel setStringValue:[NSString stringWithFormat:@"%.2f", angle]];
	
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
    
    int radius = calculateRadius(point,apoint);
    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIVortexDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIVortexDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point.x Y:height - point.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:angle] forKey:@"inputAngle"];

    
    if (opaque) {
        applyFilterBG(pluginData,filter);
    }
    else {
        applyFilter(pluginData,filter);
    }
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
