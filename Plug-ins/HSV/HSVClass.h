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

@interface HSVClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the hue
	IBOutlet id hueLabel;
	
	// The slider for the hue
	IBOutlet id hueSlider;

	// The label displaying the saturation
	IBOutlet id saturationLabel;
	
	// The slider for the saturation
	IBOutlet id saturationSlider;

	// The label displaying the value
	IBOutlet id valueLabel;
	
	// The slider for the value
	IBOutlet id valueSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The hue
	float hue;

	// The saturation
	float saturation;

	// The value
	float value;

	// YES if the effect must be refreshed
	BOOL refresh;

	// YES if the application succeeded
	BOOL success;

}

@end
