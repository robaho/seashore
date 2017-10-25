#import "ThresholdView.h"
#import "ThresholdClass.h"

@implementation ThresholdView

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
		histogram[i] = (int)(((float)histogram[i] / (float)max) * 120.0);
	}
}

- (void)drawRect:(NSRect)rect
{
	int i;
	
	[[NSColor blackColor] set];
	for (i = 0; i < 256; i++) {
		[NSBezierPath fillRect:NSMakeRect(i, 0, 1, histogram[i])];
	}
	
	[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.4] set];
	[NSBezierPath fillRect:NSMakeRect(MIN([thresholdClass topValue], [thresholdClass bottomValue]), 0, abs([thresholdClass topValue] - [thresholdClass bottomValue]) + 1, 120)];
}

@end
