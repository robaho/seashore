/*!
	@header		CIUnsharpMaskClass
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

@interface CIUnsharpMaskClass : NSObject <PluginClass>{

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the radius
	IBOutlet id radiusLabel;
	
	// The slider for the radius
	IBOutlet id radiusSlider;

	// The label displaying the intensity
	IBOutlet id intensityLabel;
	
	// The slider for the intensity
	IBOutlet id intensitySlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new radius
	float radius;

	// The new intensity
	float intensity;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
