#import "CITorusLensClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CITorusLensClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CITorusLens" owner:self];
	
	return self;
}

- (int)type
{
	return 1;
}

- (int)points
{
	return 3;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Torus Lens" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CITorusLens.refraction"])
		refraction = [gUserDefaults floatForKey:@"CITorusLens.refraction"];
	else
		refraction = 1.7;
	
	if (refraction < -5.0 || refraction > 5.0)
		refraction = 1.7;
		
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	[refractionSlider setFloatValue:refraction];
	
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
		
	[gUserDefaults setFloat:refraction forKey:@"CITorusLens.refraction"];
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
	refraction = [refractionSlider floatValue];
	
	[panel setAlphaValue:1.0];
	
	[refractionLabel setStringValue:[NSString stringWithFormat:@"%.1f", refraction]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp || [sender tag] == 99) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    int height = [pluginData height];
    
    IntPoint point1 = [pluginData point:0];
    IntPoint point2 = [pluginData point:1];
    IntPoint point3 = [pluginData point:2];
    
    int lens_radius = calculateRadius(point1,point2);
    int lens_width = abs(calculateRadius(point1,point3)-lens_radius);
    lens_radius += lens_width;
    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CITorusLensDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CITorusLensDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[CIVector vectorWithX:point1.x Y:height - point1.y] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithFloat:lens_radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:lens_width] forKey:@"inputWidth"];
    [filter setValue:[NSNumber numberWithFloat:refraction] forKey:@"inputRefraction"];
    
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
