#import "TexturizeClass.h"

extern int render(unsigned char *image_in, int width_in, int height_in, unsigned char *image_out, int width_out, int height_out, int overlap, int channels, char tileable, id progressBar);

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation TexturizeClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"Texturize" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Texturize" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Document" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (void)run
{
	PluginData *pluginData;
	NSString *smallTitle, *smallBody;
	int iwidth, iheight;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	
	iwidth = [pluginData width];
	iheight = [pluginData height];
	
	if (iwidth < 64 || iheight < 64) {
		smallTitle = [gOurBundle localizedStringForKey:@"small title" value:@"Image too small" table:NULL];
		smallBody = [gOurBundle localizedStringForKey:@"small body" value:@"The texturize plug-in can only be used with images that are larger than 64 pixels in both width and height." table:NULL];
		NSRunAlertPanel(smallTitle, smallBody, [gOurBundle localizedStringForKey:@"ok" value:@"OK" table:NULL], NULL, NULL);
		return;
	}
	
	if ([gUserDefaults objectForKey:@"Texturize.overlap"])
		overlap = [gUserDefaults integerForKey:@"Texturize.overlap"];
	else
		overlap = 50.0;
	
	if (overlap < 5.0 || overlap > 100.0)
		overlap = 50.0;
	
	[overlapLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", overlap]];
	[overlapSlider setFloatValue:overlap];
	
	if ([gUserDefaults objectForKey:@"Texturize.width"])
		width = [gUserDefaults integerForKey:@"Texturize.width"];
	else
		width = 200.0;
	
	if (width < 120.0 || width > 500.0)
		width = 200.0;
	
	[widthLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", width]];
	[widthSlider setFloatValue:width];
	
	if ([gUserDefaults objectForKey:@"Texturize.height"])
		height = [gUserDefaults integerForKey:@"Texturize.height"];
	else
		height = 200.0;
	
	if (height < 120.0 || height > 500.0)
		height = 200.0;
	
	[heightLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", height]];
	[heightSlider setFloatValue:height];
	
	if ([gUserDefaults objectForKey:@"Texturize.tileable"])
		tileable = [gUserDefaults boolForKey:@"Texturize.tileable"];
	else
		tileable = YES;
	
	[progressBar setIndeterminate:YES];
	[progressBar setDoubleValue:0.0];
	
	success = NO;
	if ([pluginData window])
		[NSApp beginSheet:panel modalForWindow:[pluginData window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	else
		[NSApp runModalForWindow:panel];
}

- (IBAction)apply:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self texturize];
	[pluginData apply];
	
	[NSApp stopModal];
	if ([pluginData window]) [NSApp endSheet:panel];
	[panel orderOut:self];
	success = YES;
	
	[gUserDefaults setFloat:overlap forKey:@"Texturize.overlap"];
	[gUserDefaults setFloat:width forKey:@"Texturize.width"];
	[gUserDefaults setFloat:height forKey:@"Texturize.height"];
	[gUserDefaults setObject:tileable ? @"YES" : @"NO" forKey:@"Texturize.tileable"];
}

- (void)reapply
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[self texturize];
	[pluginData apply];
}

- (BOOL)canReapply
{
	return success;
}

- (IBAction)cancel:(id)sender
{
	PluginData *pluginData;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData cancel];
	
	[NSApp stopModal];
	[NSApp endSheet:panel];
	[panel orderOut:self];
	success = NO;
}

- (IBAction)update:(id)sender
{
	overlap = roundf([overlapSlider floatValue]);
	width = roundf([widthSlider floatValue]);
	height = roundf([heightSlider floatValue]);
	
	[overlapLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", overlap]];
	[widthLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", width]];
	[heightLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", height]];
}

#define make_128(x) (x + 16 - (x % 16))

- (void)texturize
{
	PluginData *pluginData;
	int i, j, k, spp, iwidth, iheight;
	int foverlap, owidth, oheight;
	unsigned char *tdata, *idata, *odata;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	spp = [pluginData spp];
	iwidth = [pluginData width];
	iheight = [pluginData height];
	tdata = [pluginData whiteboardData];
	idata = (unsigned char *)malloc(make_128(iwidth * iheight * (spp - 1)));
	for (i = 0; i < iwidth * iheight; i++) {
		for (k = 0; k < spp - 1; k++) idata[i * (spp - 1) + k] = tdata[i * spp + k];
	}
	owidth = (int)floorf(iwidth * (width / 100.0f));
	oheight = (int)floorf(iheight * (height / 100.0f));
	odata = (unsigned char *)malloc(make_128(owidth * oheight * spp));
	for (i = 0; i < iheight; i++) {
		memcpy(&(odata[owidth * i * (spp - 1)]), &(idata[iwidth * i * (spp - 1)]), iwidth * (spp - 1));
	}
	foverlap = (int)floorf((overlap / 100.0f) * MIN(iwidth, iheight));
	[progressBar setIndeterminate:NO];
	[progressBar display];
	render(idata, iwidth, iheight, odata, owidth, oheight, foverlap, spp - 1, tileable, progressBar);
	free(idata);
	for (i = owidth * oheight - 1; i >= 0; i--) {
		for (k = 0; k < spp - 1; k++) odata[i * spp + k] = odata[i * (spp - 1) + k];
		odata[(i + 1) * spp - 1] = 0xFF;
	}
	[pluginData applyWithNewDocumentData:odata spp:spp width:owidth height:oheight];
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
