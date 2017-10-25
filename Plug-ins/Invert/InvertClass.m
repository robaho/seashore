#import "InvertClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation InvertClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Invert" table:NULL];
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
			
			if (channel == kAllChannels) {
				for (k = 0; k < spp - 1; k++)
					overlay[pos * spp + k] = 255 - data[pos * spp + k];
				overlay[(pos + 1) * spp - 1] = data[(pos + 1) * spp - 1];
			}
			
			if (channel == kPrimaryChannels) {
				for (k = 0; k < spp - 1; k++)
					overlay[pos * spp + k] = 255 - data[pos * spp + k];
				overlay[(pos + 1) * spp - 1] = 255;
			}
			
			if (channel == kAlphaChannel) {
				pos = j * width + i;
				for (k = 0; k < spp - 1; k++)
					overlay[pos * spp + k] = 255 - data[(pos + 1) * spp - 1];
				overlay[(pos + 1) * spp - 1] = 255;
			}
			
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
	return YES;
}

@end
