#import "CIGlassDistortionClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIGlassDistortionClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIGlassDistortion" owner:self];
	texturePath = NULL;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Glass Distortion" table:NULL];
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
	PluginData *pluginData;
	
	if ([gUserDefaults objectForKey:@"CIGlassDistortion.scale"])
		scale = [gUserDefaults integerForKey:@"CIGlassDistortion.scale"];
	else
		scale = 200;
	refresh = YES;
	
	if (scale < 1 || scale > 500)
		scale = 200;
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
	[scaleSlider setIntValue:scale];
	
	success = NO;
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self preview:self];
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
	// Nothing to go here
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
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
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self execute];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)preview:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	if (refresh) [self execute];
	[pluginData preview];
	refresh = NO;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData cancel];
	
	[panel setAlphaValue:1.0];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	PluginData *pluginData;
	
	scale = roundf([scaleSlider floatValue]);
	
	[panel setAlphaValue:1.0];
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
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
            texturePath=NULL;
		}
	}
}

- (IBAction)selectTexture:(id)sender
{
	PluginData *pluginData;
	NSOpenPanel *openPanel;
	NSString *path, *localStr, *startPath;
	int retval;

	pluginData = [(SeaPlugins *)seaPlugins data];
	if (texturePath) { [texturePath autorelease]; texturePath = NULL; }
	openPanel = [NSOpenPanel openPanel];
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDelegate:self];
	path = [NSString stringWithFormat:@"%@/textures/", [[NSBundle mainBundle] resourcePath]];
	if ([pluginData window]) [panel setAlphaValue:0.4];
	retval = [openPanel runModalForDirectory:path file:NULL types:[NSImage imageFileTypes]];
	if (texturePath) { [texturePath autorelease]; texturePath = NULL; }
	[panel setAlphaValue:1.0];
	if (retval == NSOKButton) {
		texturePath = [[openPanel filenames] objectAtIndex:0];
		[texturePath retain];
		localStr = [gOurBundle localizedStringForKey:@"texture label" value:@"Texture: %@" table:NULL];
		[textureLabel setStringValue:[NSString stringWithFormat:localStr, [[texturePath lastPathComponent] stringByDeletingPathExtension]]];
	}
	refresh = YES;
	[self preview:NULL];
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    int width = [pluginData width];
    int height = [pluginData height];
    
    NSString *defaultPath = [[NSBundle bundleForClass:[self class]] pathForImageResource:@"default-distort"];
    
    bool opaque = ![pluginData hasAlpha];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGlassDistortion"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIGlassDistortion"] userInfo:NULL];
    }
    [filter setDefaults];
    if (texturePath)
        [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:texturePath]] forKey:@"inputTexture"];
    else
        [filter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:defaultPath]] forKey:@"inputTexture"];
    [filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithInt:scale] forKey:@"inputScale"];
    
    if (opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
