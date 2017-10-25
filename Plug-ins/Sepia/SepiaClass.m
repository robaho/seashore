#import "SepiaClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

@implementation SepiaClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Sepia" table:NULL];
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
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, k, width, spp, channel;
	int t[5];
	
	pluginData = [(SeaPlugins *)seaPlugins data];
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			pos = j * width + i;
			overlay[pos * spp] = MIN(int_mult(data[pos * spp], 100, t[0]) + int_mult(data[pos * spp + 1], 196, t[1]) + int_mult(data[pos * spp + 2], 48, t[2]), 255);
			overlay[pos * spp + 1] = MIN(int_mult(data[pos * spp], 89, t[0]) + int_mult(data[pos * spp + 1], 175, t[1]) + int_mult(data[pos * spp + 2], 43, t[2]), 255);
			overlay[pos * spp + 2] = MIN(int_mult(data[pos * spp], 69, t[0]) + int_mult(data[pos * spp + 1], 136, t[1]) + int_mult(data[pos * spp + 2], 33, t[2]), 255);
			
			if (channel == kAllChannels) 
				overlay[(pos + 1) * spp - 1] = data[(pos + 1) * spp - 1];
			else
				overlay[(pos + 1) * spp - 1] = 255;
			replace[pos] = 255;
			
		}
	}
	[pluginData apply];
}

- (IBAction)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return YES;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	PluginData *pluginData;

	pluginData = [(SeaPlugins *)seaPlugins data];
	if ([pluginData spp] != 4 || [pluginData channel] == kAlphaChannel)
		return NO;

	return YES;
}

@end
