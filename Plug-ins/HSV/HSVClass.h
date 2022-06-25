/*!
	@header		HSVClass
	@abstract	Adjusts the hue, saturation and value of the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2004 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>
#import <SeaComponents/SeaComponents.h>

@interface HSVClass : NSObject <PluginClass> {

	PluginData *pluginData;

    SeaSlider *hue,*saturation,*value;
    VerticalView *panel;
}

@end
