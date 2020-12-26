/*!
	@header		BrightnessClass
	@abstract	Adjusts the brightness and contrast of the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2004 Mark Pazolli and
				Copyright (c) 1995 Spencer Kimball and Peter Mattis
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface BrightnessClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the brightness
	IBOutlet id brightnessLabel;
	
	// The slider for the brightness
	IBOutlet id brightnessSlider;

	// The label displaying the contrast
	IBOutlet id contrastLabel;
	
	// The slider for the contrast
	IBOutlet id contrastSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The brightness
	float brightness;

	// The contrast
	float contrast;

	// YES if the effect must be refreshed
	BOOL refresh;

	// YES if the application succeeded
	BOOL success;

}

/*!
	@method		adjust
	@discussion	Executes the adjustments.
*/
- (void)adjust;

@end
