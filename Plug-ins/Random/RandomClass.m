#import "RandomClass.h"

#define gOurBundle [NSBundle bundleForClass:[self class]]

@implementation RandomClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;
	
	return self;
}

- (int)type
{
	return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Random Generator" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Generate" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

#define int_mult(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))
#define alphaPos (spp - 1)
	
static inline void specialMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char multi, alpha;
	int t1, t2;
	int k;
	
	if (srcPtr[srcLoc + alphaPos] == 0)
		return;
	
	alpha = srcPtr[srcLoc + alphaPos];
	for (k = 0; k < spp - 1; k++) {
		destPtr[destLoc + k] = int_mult(srcPtr[srcLoc + k], alpha, t1) + int_mult(destPtr[destLoc + k], 255 - alpha, t2);
	}
}


- (void)run
{
	IntRect selection;
	unsigned char *data, *overlay, *replace;
	int pos, i, j, k, width, spp, channel;
	unsigned char background[4], random[4];
	BOOL opaque;
	
	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	selection = [pluginData selection];
	spp = [pluginData spp];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	opaque = ![pluginData hasAlpha];
	if (opaque) {
		if (spp == 2) {
			background[0] = [[pluginData backColor] whiteComponent] * 255;
			background[1] = 255;
		}
		else {
			background[0] = [[pluginData backColor] redComponent] * 255;
			background[1] = [[pluginData backColor] greenComponent] * 255;
			background[2] = [[pluginData backColor] blueComponent] * 255;
			background[3] = 255;
		}
	}
	
	srand(time(nil));
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			pos = j * width + i;
			if (opaque) {
				memcpy(&overlay[pos * spp], background, spp);
				for (k = 0; k < spp; k++)
					random[k] = (rand() << 8) >> 20;
				specialMerge(spp, overlay, pos * spp, random, 0); 
			}
			else {
				for (k = 0; k < spp; k++)
					overlay[pos * spp + k] = (rand() << 8) >> 20;
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

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
