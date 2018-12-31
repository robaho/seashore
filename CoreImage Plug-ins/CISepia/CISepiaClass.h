/*!
	@header		CISepiaClass
	@abstract	Crystallize the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CISepiaClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the intensity
	IBOutlet id intensityLabel;
	
	// The slider for the intensity
	IBOutlet id intensitySlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new intensity
	float intensity;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
