/*!
	@header		CIGammaAdjustClass
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

@interface CIGammaAdjustClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the gamma
	IBOutlet id gammaLabel;
	
	// The slider for the gamma
	IBOutlet id gammaSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new gamma
	float gamma;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
