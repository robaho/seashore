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

    ThresholdView *histo;
    NSView *panel;
    SeaSlider *top,*bottom;
}

/*!
	@method		topValue
	@discussion	Returns the value of the top slider.
	@result		Returns an integer representing value of the top slider.
*/
- (int)topValue;

/*!
	@method		bottomValue
	@discussion	Returns the value of the bottom slider.
	@result		Returns an integer representing value of the bottom slider.
*/
- (int)bottomValue;

@end
