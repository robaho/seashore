#import "CIDisplacementDistortionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIDisplacementDistortionClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	[NSBundle loadNibNamed:@"CIDisplacementDistortion" owner:self];
	texturePath = NULL;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Displacement Distortion" table:NULL];
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
	if ([gUserDefaults objectForKey:@"CIDisplacementDistortion.scale"])
		scale = [gUserDefaults integerForKey:@"CIDisplacementDistortion.scale"];
	else
		scale = 50;
	refresh = YES;
	
	if (scale < 1 || scale > 350)
		scale = 50;
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
	[scaleSlider setIntValue:scale];
	
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
		
	[gUserDefaults setInteger:scale forKey:@"CICrystallize.scale"];
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
	scale = roundf([scaleSlider floatValue]);
	
	[panel setAlphaValue:1.0];
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)panelSelectionDidChange:(id)openPanel
{
	if ([[openPanel filenames] count] > 0) {
		texturePath = [[openPanel filenames] objectAtIndex:0];
		if (texturePath) {
			refresh = YES;
			[self preview:NULL];
            texturePath = NULL;
		}
	}
}

- (IBAction)selectTexture:(id)sender
{
	NSOpenPanel *openPanel;
	NSString *path, *localStr;
	int retval;

	openPanel = [NSOpenPanel openPanel];
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDelegate:self];
	path = [NSString stringWithFormat:@"%@/textures/", [[NSBundle mainBundle] resourcePath]];
	if ([pluginData window]) [panel setAlphaValue:0.4];
	retval = [openPanel runModalForDirectory:path file:NULL types:[NSImage imageFileTypes]];
	[panel setAlphaValue:1.0];
	if (retval == NSOKButton) {
		texturePath = [[openPanel filenames] objectAtIndex:0];
		localStr = [gOurBundle localizedStringForKey:@"texture label" value:@"Texture: %@" table:NULL];
		[textureLabel setStringValue:[NSString stringWithFormat:localStr, [[texturePath lastPathComponent] stringByDeletingPathExtension]]];
	}
	refresh = YES;
	[self preview:NULL];
}

- (void)execute
{
    NSString *defaultPath = [[NSBundle bundleForClass:[self class]] pathForImageResource:@"default-distort"];

    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTile"];
    [filter setDefaults];
    if (texturePath)
        [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:texturePath]] forKey:@"inputImage"];
    else
        [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:defaultPath]] forKey:@"inputImage"];
    [filter setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
    CIImage *texture_output = [filter valueForKey: @"outputImage"];
    
    // Run filter
    filter = [CIFilter filterWithName:@"CIDisplacementDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIDisplacementDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:texture_output forKey:@"inputDisplacementImage"];
    [filter setValue:[NSNumber numberWithInt:scale] forKey:@"inputScale"];

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
