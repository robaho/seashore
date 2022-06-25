#import "ThresholdView.h"
#import "ThresholdClass.h"

#import <SeaComponents/SeaComponents.h>

#define gOurBundle [NSBundle bundleForClass:[self class]]

#define gUserDefaults [NSUserDefaults standardUserDefaults]

@implementation ThresholdClass

- (id)initWithManager:(PluginData *)data
{
	pluginData = data;

    panel = [VerticalView view];

    histo = [[ThresholdView alloc] initWithClass:self];
    top = [SeaSlider sliderWithTitle:@"Lower" Min:0 Max:255 Listener:self];
    bottom = [SeaSlider sliderWithTitle:@"Upper" Min:0 Max:255 Listener:self];

    [panel addSubview:histo];
    [panel addSubview:top];
    [panel addSubview:bottom];

    return self;
}

- (int)points
{
    return 0;
}

- (NSString *)name
{
	return [gOurBundle localizedStringForKey:@"name" value:@"Threshold" table:NULL];
}

- (NSString *)groupName
{
	return [gOurBundle localizedStringForKey:@"groupName" value:@"Color Effect" table:NULL];
}

- (NSString *)sanity
{
	return @"Seashore Approved (Bobo)";
}

- (NSView*)initialize
{
    [top setIntValue:0];
    [bottom setIntValue:255];
    [histo calculateHistogram:pluginData];

    return panel;
}

- (void)componentChanged:(id)slider
{
    [pluginData settingsChanged];
    [histo setNeedsDisplay:TRUE];
}

- (void)execute
{
	IntRect selection;
	int i, j, k, spp, width, channel, mid;
	unsigned char *data, *overlay, *replace;

    int topValue = [top intValue];
    int bottomValue = [bottom intValue];

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
			
			if (channel == kAllChannels || channel == kPrimaryChannels) {
				
				mid = 0;
				for (k = 0; k < spp - 1; k++)
					mid += data[(j * width + i) * spp + k];
				mid /= (spp - 1);
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = data[(j * width + i + 1) * spp - 1];
				
				replace[j * width + i] = 255;
				
			}
			
			else if (channel == kAlphaChannel) {
			
				mid = data[(j * width + i + 1) * spp - 1];
				
				if (MIN(topValue, bottomValue) <= mid && mid <= MAX(topValue, bottomValue))
					memset(&(overlay[(j * width + i) * spp]), 255, spp - 1);
				else
					memset(&(overlay[(j * width + i) * spp]), 0, spp - 1);
				
				overlay[(j * width + i + 1) * spp - 1] = 255;
				
				replace[j * width + i] = 255;
				
			}
			
		}
	}
}

- (int)topValue
{
	return [top intValue];
}

- (int)bottomValue
{
	return [bottom intValue];
}

+ (BOOL)validatePlugin:(PluginData*)pluginData
{
	return YES;
}

@end
