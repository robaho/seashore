/*!
	@header		ThresholdClass
	@abstract	Runs a threshold operation on the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>
#import <SeaComponents/SeaComponents.h>

@interface ThresholdClass : NSObject <PluginClass> {
	PluginData *pluginData;

    HistogramView *histo;
    NSView *panel;
    SeaSlider *top,*bottom;
}
@end
