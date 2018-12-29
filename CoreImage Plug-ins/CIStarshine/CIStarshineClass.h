/*!
	@header		CIStarshineGeneratorClass
	@abstract	Generates a colourful halo using CoreImage.
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

@interface CIStarshineClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The label displaying the opacity
	IBOutlet id opacityLabel;
	
	// The slider for the opacity
	IBOutlet id opacitySlider;
	
	// The label displaying the width
	IBOutlet id widthLabel;
	
	// The slider for the width
	IBOutlet id widthSlider;
	
	// The main color to use
	IBOutlet id mainColorWell;

	// The color to be used
	NSColor *mainNSColor;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new scale
	int scale;
	
	// The new opacity
	float opacity;
	
	// The new width
	float star_width;
	
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
