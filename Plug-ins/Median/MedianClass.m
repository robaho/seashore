#import "MedianClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation MedianClass

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
	return [gOurBundle localizedStringForKey:@"name" value:@"Median" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Enhance" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

int compar(const void *a, const void *b)
{
	return *((const unsigned char *)a) - *((const unsigned char *)b);
}

- (void)run
{
	PluginData *pluginData;
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, x, y, z, k, width, spp, channel;
	unsigned char vals[4][9];
	
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
			
			if (channel == kAllChannels) {
				
				pos = j * width + i;
				z = -1;
				for (y = j - 1; y < j + 2; y++) {
					for (x = i - 1; x < i + 2; x++) {
						z++;
						if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
							for (k = 0; k < spp; k++)
								vals[k][z] = data[((y * width) + x) * spp + k];
						}
					}
				}
				for (k = 0; k < spp; k++) {
					qsort(vals[k], 9, sizeof(unsigned char), &compar);
					overlay[pos * spp + k] = vals[k][4];
				}
				replace[pos] = 255;
				
			}
			
			if (channel == kPrimaryChannels) {
			
				pos = j * width + i;
				z = -1;
				for (y = j - 1; y < j + 2; y++) {
					for (x = i - 1; x < i + 2; x++) {
						z++;
						if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
							for (k = 0; k < spp - 1; k++)
								vals[k][z] = data[((y * width) + x) * spp + k];
						}
					}
				}
				for (k = 0; k < spp - 1; k++) {
					qsort(vals[k], 9, sizeof(unsigned char), &compar);
					overlay[pos * spp + k] = vals[k][4];
				}
				overlay[(pos + 1) * spp - 1] = 255;
				replace[pos] = 255;
				
			}
			
			if (channel == kAlphaChannel) {
				
				pos = j * width + i;
				z = -1;
				for (y = j - 1; y < j + 2; y++) {
					for (x = i - 1; x < i + 2; x++) {
						z++;
						if (x >= selection.origin.x && y >= selection.origin.y  && x < selection.origin.x + selection.size.width && y < selection.origin.y + selection.size.height) {
							vals[0][z] = data[((y * width) + x + 1) * spp - 1];
						}
					}
				}
				qsort(vals[0], 9, sizeof(unsigned char), &compar);
				for (k = 0; k < spp - 1; k++)
					overlay[pos * spp + k] = vals[0][4];
				overlay[(pos + 1) * spp - 1] = 255;
				replace[pos] = 255;
				
			}
			
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
