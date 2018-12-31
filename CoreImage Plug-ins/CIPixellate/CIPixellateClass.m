#import "CIPixellateClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation CIPixellateClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	[NSBundle loadNibNamed:@"CIPixellate" owner:self];
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Pixellate" table:NULL];
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
	
	if ([gUserDefaults objectForKey:@"CIPixellate.scale"])
		scale = [gUserDefaults floatForKey:@"CIPixellate.scale"];
	else
		scale = 8;
	
	if ([gUserDefaults objectForKey:@"CIPixellate.centerBased"])
		centerBased = [gUserDefaults boolForKey:@"CIPixellate.centerBased"];
	else
		centerBased = YES;
	
	if (scale < 1 || scale > 100)
		scale = 8;
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
	[scaleSlider setIntValue:scale];

	[typeRadios setState:scale atRow:0 column:(centerBased) ? 1 : 0];
	
	refresh = YES;
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
		
	[gUserDefaults setInteger:scale forKey:@"CIPixellate.scale"];
	[gUserDefaults setObject:(centerBased) ? @"YES" : @"NO" forKey:@"CIPixellate.scale"];
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
	
	scale = [scaleSlider intValue];
	centerBased = ([typeRadios selectedColumn] == 1);
	[panel setAlphaValue:1.0];
	
	[scaleLabel setStringValue:[NSString stringWithFormat:@"%d", scale]];
	
	refresh = YES;
	if ([[NSApp currentEvent] type] == NSLeftMouseUp) { 
		[self preview:self];
		pluginData = [(SeaPlugins *)seaPlugins data];
		if ([pluginData window]) [panel setAlphaValue:0.4];
	}
}

- (void)execute
{
    PluginData *pluginData = [seaPlugins data];
    
    int width = [pluginData width];
    int height = [pluginData height];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIPixellate"];
    if (filter == NULL) {
        @throw [NSException exceptionWithName:@"CoreImageFilterNotFoundException" reason:[NSString stringWithFormat:@"The Core Image filter named \"%@\" was not found.", @"CIPixellate"] userInfo:NULL];
    }
    [filter setDefaults];
    [filter setValue:[NSNumber numberWithInt:scale] forKey:@"inputScale"];
    if (centerBased)
        [filter setValue:[CIVector vectorWithX:width / 2 Y:height / 2] forKey:@"inputCenter"];
    else
        [filter setValue:[CIVector vectorWithX:scale Y:height - scale] forKey:@"inputCenter"];
    
    bool opaque = ![pluginData hasAlpha];
    if(opaque){
        applyFilterBG(pluginData,filter);
    } else {
        applyFilter(pluginData,filter);
    }
    
    [self finishing];
}

- (void)finishing
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace, newPixel[4];
	int pos, i, j, k, i2, j2, width, height, spp, channel;
	int total[4], n, x_stblk, x_endblk, y_stblk, y_endblk;
	int loop;
	
	if (centerBased) return;
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	height = [pluginData height];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (loop = 0; loop < 2; loop++) {
	
		if (loop == 0) {
		
			if ((selection.origin.x + selection.size.width) % scale != 0) {
				x_stblk = (selection.origin.x + selection.size.width) / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + 1;
				y_stblk = selection.origin.y / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + ((selection.origin.y + selection.size.height) % scale != 0);
			}
			else {
				continue;
			}
		
		}
		else {
		
			if ((selection.origin.y + selection.size.height) % scale != 0) {
				x_stblk = selection.origin.x / scale;
				x_endblk = (selection.origin.x + selection.size.width) / scale + ((selection.origin.x + selection.size.width) % scale != 0);
				y_stblk = (selection.origin.y + selection.size.height) / scale;
				y_endblk = (selection.origin.y + selection.size.height) / scale + 1;
			}
			else {
				continue;
			}
			
		}
		
		for (j = y_stblk; j < y_endblk; j++) {
			for (i = x_stblk; i < x_endblk; i++) {
			
				// Sum and count the present pixels in the  block
				total[0] = total[1] = total[2] = total[3] = 0;
				n = 0;
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								total[k] += data[pos * spp + k];
							}
							n++;
						}
					}
				}
				
				// Determine the revised pixel
				switch (channel) {
					case kAllChannels:
						for (k = 0; k < spp; k++) {
							newPixel[k] = total[k] / n;
						}
					break;
					case kPrimaryChannels:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[k] / n;
						}
						newPixel[spp - 1] = 255;
					break;
					case kAlphaChannel:
						for (k = 0; k < spp - 1; k++) {
							newPixel[k] = total[spp - 1] / n;
						}
						newPixel[spp - 1] = 255;
					break;
				}
				
				// Fill the block with this pixel
				for (j2 = 0; j2 < scale; j2++) {
					for (i2 = 0; i2 < scale; i2++) {
						pos = (j * scale + j2) * width + (i * scale + i2);
						if (i * scale + i2 < width && j * scale + j2 < height) {
							pos = (j * scale + j2) * width + (i * scale + i2);
							for (k = 0; k < spp; k++) {
								overlay[pos * spp + k] = newPixel[k];
							}
							replace[pos] = 255;
						}
					}
				}
				
			}
		}
		
	}
}


- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
