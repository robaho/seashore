/*!
	@header		CINoiseReductionClass
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

@interface CINoiseReductionClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the noise
	IBOutlet id noiseLabel;
	
	// The slider for the noise
	IBOutlet id noiseSlider;

	// The label displaying the sharpness
	IBOutlet id sharpLabel;
	
	// The slider for the sharpness
	IBOutlet id sharpSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new noise
	float noise;

	// The new sharpness
	float sharp;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;

}
@end
