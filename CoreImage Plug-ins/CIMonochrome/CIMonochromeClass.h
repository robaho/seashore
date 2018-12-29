/*!
	@header		CIMonochromeClass
	@abstract	Monochrome the selection using CoreImage.
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

@interface CIMonochromeClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the intensity
	IBOutlet id intensityLabel;
	
	// The slider for the intensity
	IBOutlet id intensitySlider;

	// The main color to use
	IBOutlet id mainColorWell;

	// The panel for the plug-in
	IBOutlet id panel;

	// The value of the intensity
	float intensity;
	
	// The color to be used
	NSColor *mainNSColor;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
	// YES if the plug-in is running
	BOOL running;

}
@end
