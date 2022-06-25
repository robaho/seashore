#import "ThresholdView.h"
#import "ThresholdClass.h"

@implementation ThresholdView

#define HEIGHT 80

- (ThresholdView*)initWithClass:(id)class
{
    self = [super init];
    thresholdClass = class;
    return self;
}

- (void)calculateHistogram:(PluginData *)pluginData
{
	unsigned char *data;
	int spp, width, height, channel;
	int i, j, mid, max;
	
	data = [pluginData data];
	spp = [pluginData spp];
	width = [pluginData width];
	height = [pluginData height];
	channel = [pluginData channel];
	
	for (i = 0; i < 256; i++)
		histogram[i] = 0;
	
	if (channel == kAllChannels || channel == kPrimaryChannels) {
		for (i = 0; i < width * height; i++) {
			mid = 0;
			for (j = 0; j < spp - 1; j++)
				mid += data[i * spp + j];
			mid /= (spp - 1);
			histogram[mid]++; 
		}
	}
	else if (channel == kAlphaChannel) {
		for (i = 0; i < width * height; i++) {
			mid = data[(i + 1) * spp - 1];
			histogram[mid]++; 
		}
	}
	
	max = 1;
	for (i = 0; i < 256; i++) {
		max = (histogram[i] > max) ? histogram[i] : max;
	}
	
	for (i = 0; i < 256; i++) {
		histogram[i] = (int)(((float)histogram[i] / (float)max) * HEIGHT);
	}
}

- (void)drawRect:(NSRect)rect
{
	int i;

    NSSize size = [self bounds].size;
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx scaleXBy:size.width/256.0 yBy:size.height/HEIGHT];
    [tx concat];
	
	[[NSColor controlTextColor] set];
	for (i = 0; i < 256; i++) {
        NSRectFill(NSMakeRect(i, 0, 1, histogram[i]));
	}

    NSColor *accent = [[NSColor selectedControlTextColor] colorUsingColorSpace:MyRGBCS];
    [[accent colorWithAlphaComponent:.4] set];
    NSRectFillUsingOperation(NSMakeRect(MIN([thresholdClass topValue], [thresholdClass bottomValue]), 0, abs([thresholdClass topValue] - [thresholdClass bottomValue]) + 1, HEIGHT),NSCompositeSourceOver);
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(256,HEIGHT);
}

@end
