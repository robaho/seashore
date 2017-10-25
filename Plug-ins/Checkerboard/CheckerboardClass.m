#import "CheckerboardClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define make_128(x) (x + 16 - (x % 16))

@implementation CheckerboardClass

- (id)initWithManager:(SeaPlugins *)manager
{
	seaPlugins = manager;
	
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
	return [gOurBundle localizedStringForKey:@"name" value:@"Checkerboard" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)instruction
{
	return [gOurBundle localizedStringForKey:@"instruction" value:@"Needs localization." table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

static inline specmod(int a, int b)
{
	if (a < 0)
		return b + a % b;
	else
		return a % b;
}

- (void)run
{
	int width, height;
	unsigned char *overlay, *replace;
	IntRect selection;
	IntPoint point, apoint;
	BOOL opaque;
	unsigned char backColor[4], backColorAlpha[4], foreColorAlpha[4];
	int amount;
	int spp, channel, pos;
	int i, j, k;
	BOOL black;
	PluginData *pluginData;
	
	// Get plug-in data
	pluginData = [(SeaPlugins *)seaPlugins data];
	width = [pluginData width];
	height = [pluginData height];
	spp = [pluginData spp];
	selection = [pluginData selection];
	point = [pluginData point:0];
	apoint = [pluginData point:1];
	amount = MAX(abs(apoint.x - point.x), abs(apoint.y - point.y));
	overlay = [pluginData overlay];
	channel = [pluginData channel];
	
	// Prepare for drawing
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kNormalBehaviour];
	
	// Get colors
	if (spp == 4) {
		foreColorAlpha[0] = [[pluginData foreColor:YES] redComponent] * 255;
		foreColorAlpha[1] = [[pluginData foreColor:YES] greenComponent] * 255;
		foreColorAlpha[2] = [[pluginData foreColor:YES] blueComponent] * 255;
		foreColorAlpha[3] = [[pluginData foreColor:YES] alphaComponent] * 255;
		backColorAlpha[0] = [[pluginData backColor:YES] redComponent] * 255;
		backColorAlpha[1] = [[pluginData backColor:YES] greenComponent] * 255;
		backColorAlpha[2] = [[pluginData backColor:YES] blueComponent] * 255;
		backColorAlpha[3] = [[pluginData backColor:YES] alphaComponent] * 255;

	}
	else {
		foreColorAlpha[0] = [[pluginData foreColor:YES] whiteComponent] * 255;
		foreColorAlpha[1] = [[pluginData foreColor:YES] alphaComponent] * 255;
		backColorAlpha[0] = [[pluginData backColor:YES] whiteComponent] * 255;
		backColorAlpha[1] = [[pluginData backColor:YES] alphaComponent] * 255;
	}
	
	// Run checkboard
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			pos = j * width + i;
			
			black = YES;
			if (specmod(i - point.x, amount * 2) >= amount) black = NO;
			if (specmod(j - point.y, amount * 2) >= amount) black = !black;
			for (k = 0; k < spp; k++) {
				if (black) {
					memcpy(&(overlay[pos * spp]), foreColorAlpha, spp);
				}
				else {
					memcpy(&(overlay[pos * spp]), backColorAlpha, spp);
				}
			}
			
		}
	}

	// Apply the change and record success
	[pluginData apply];
	success = YES;
}

- (void)reapply
{
	[self run];
}

- (BOOL)canReapply
{
	return NO;
}

- (BOOL)validateMenuItem:(id)menuItem
{
	return YES;
}

@end
