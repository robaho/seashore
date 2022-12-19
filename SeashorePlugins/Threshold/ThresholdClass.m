#import "ThresholdClass.h"
#import <SeaComponents/SeaComponents.h>

@implementation ThresholdClass

- (id)initWithManager:(id<PluginData>)data
{
    self = [super initWithManager:data];

    panel = [VerticalView view];

    histo = [[HistogramView alloc] init];
    [histo enableBounds];
    
    top = [SeaSlider sliderWithTitle:@"Lower" Min:0 Max:255 Listener:self];
    bottom = [SeaSlider sliderWithTitle:@"Upper" Min:0 Max:255 Listener:self];

    [panel addSubview:histo];
    [panel addSubview:top];
    [panel addSubview:bottom];

    return self;
}

- (NSView*)initialize
{
    [top setIntValue:0];
    [bottom setIntValue:255];
    [self calculateHistogram:pluginData];

    return panel;
}

- (void)componentChanged:(id)slider
{
    [pluginData settingsChanged];
    [histo setLowerBound:[bottom intValue]];
    [histo setUpperBound:[top intValue]];
}

#define SPP 4

- (void)calculateHistogram:(id<PluginData>)pluginData
{
    unsigned char *data;
    int width, height, channel;
    int i, j, mid;

    data = [pluginData data];
    width = [pluginData width];
    height = [pluginData height];
    channel = [pluginData channel];

    int *histogram = calloc(256,sizeof(int));

    if (channel == kAllChannels || channel == kPrimaryChannels) {
        for (i = 0; i < width * height; i++) {
            mid = 0;
            for (j = 0; j < SPP - 1; j++)
                mid += data[i * SPP + j + CR];
            mid /= (SPP - 1);
            histogram[mid]++;
        }
    }
    else if (channel == kAlphaChannel) {
        for (i = 0; i < width * height; i++) {
            mid = data[i*SPP+alphaPos];
            histogram[mid]++;
        }
    }

    [histo updateHistogram:0 histogram:histogram];
}

- (void)execute
{
	IntRect selection;
	int i, j, k, width, channel, mid;
	unsigned char *data, *overlay, *replace;

    int topValue = [top intValue];
    int bottomValue = [bottom intValue];

	[pluginData setOverlayOpacity:255];
	[pluginData setOverlayBehaviour:kReplacingBehaviour];
	
	selection = [pluginData selection];
	width = [pluginData width];
	data = [pluginData data];
	overlay = [pluginData overlay];
	replace = [pluginData replace];
	channel = [pluginData channel];
	
	for (j = selection.origin.y; j < selection.origin.y + selection.size.height; j++) {
		for (i = selection.origin.x; i < selection.origin.x + selection.size.width; i++) {
			
			if (channel == kAllChannels || channel == kPrimaryChannels) {
				
				mid = 0;
				for (k = CR; k <= CB; k++)
					mid += data[(j * width + i) * SPP + k];
				mid /= (SPP - 1);
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * SPP + CR]), 255, SPP - 1);
				else
					memset(&(overlay[(j * width + i) * SPP + CR]), 0, SPP - 1);
				
				overlay[(j * width + i ) * SPP +alphaPos] = data[(j * width + i) * SPP + alphaPos];
				
				replace[j * width + i] = 255;
				
			}
			
			else if (channel == kAlphaChannel) {
			
				mid = data[(j * width + i) * SPP + alphaPos];
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * SPP + CR]), 255, SPP - 1);
				else
					memset(&(overlay[(j * width + i) * SPP + CR]), 0, SPP - 1);
				
				overlay[(j * width + i) * SPP + alphaPos] = 255;
				
				replace[j * width + i] = 255;
				
			}
			
		}
	}
}

+ (BOOL)validatePlugin:(id<PluginData>)pluginData
{
    return YES;
}

@end
