/*!
	@header		CISpotLightClass
	@abstract	Applies a pinch at the specified point.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

#define gColorPanel [NSColorPanel sharedColorPanel]

@interface CISpotLightClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the brightness
	IBOutlet id brightnessLabel;
	
	// The slider for the brightness
	IBOutlet id brightnessSlider;
	
	// The label displaying the concentration
	IBOutlet id concentrationLabel;
	
	// The slider for the concentration
	IBOutlet id concentrationSlider;
	
	// The label displaying the destHeight
	IBOutlet id destHeightLabel;
	
	// The slider for the destHeight
	IBOutlet id destHeightSlider;
	
	// The label displaying the srcHeight
	IBOutlet id srcHeightLabel;
	
	// The slider for the scale
	IBOutlet id srcHeightSlider;
	
	// The main color to use
	IBOutlet id mainColorWell;

	// The color to be used
	NSColor *mainNSColor;

	// The panel for the plug-in
	IBOutlet id panel;

	// YES if the application succeeded
	BOOL success;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// The brightness
	float brightness;
	
	// The concentration
	float concentration;
	
	// The srcHeight and destHeight
	int srcHeight, destHeight;

	// YES if the plug-in is running
	BOOL running;

}
@end
