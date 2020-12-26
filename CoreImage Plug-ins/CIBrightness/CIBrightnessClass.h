/*!
	@header		CIBrightnessClass
	@abstract	Adjusts brightness and contrast the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIBrightnessClass : NSObject <PluginClass> {

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
	
	// The label displaying the value
	IBOutlet id saturationLabel;
	
	// The slider for the value
	IBOutlet id saturationSlider;
	
	// The panel for the plug-in
	IBOutlet id panel;

	// The value of the brightness
	float brightness;
	
	// The value of the contrast
	float contrast;
	
	// The value of the saturation
	float saturation;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
