/*!
	@header		CISharpenClass
	@abstract	Sharpens the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CISharpenClass : NSObject <PluginClass>{

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the value
	IBOutlet id valueLabel;
	
	// The slider for the value
	IBOutlet id valueSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The value of the crystallize
	float value;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
}
@end
