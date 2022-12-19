/*!
	@header		ThresholdClass
	@abstract	Runs a threshold operation on the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/CoreImagePlugin.h>
#import <SeaComponents/SeaComponents.h>

@interface ThresholdClass : PluginClassImpl <PluginClass> {
    HistogramView *histo;
    NSView *panel;
    SeaSlider *top,*bottom;
}
@end
