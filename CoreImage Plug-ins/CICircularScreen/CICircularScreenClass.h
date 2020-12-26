/*!
	@header		CICircularScreenClass
	@abstract	Applies circular screen effect to the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CICircularScreenClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the dot width
	IBOutlet id dotWidthLabel;
	
	// The slider for the width
	IBOutlet id dotWidthSlider;

	// The label displaying the sharpness
	IBOutlet id sharpnessLabel;
	
	// The slider for the sharpness
	IBOutlet id sharpnessSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new width
	int dotWidth;

	// The new sharpness
	float sharpness;
	
	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
