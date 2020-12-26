/*!
	@header		CISunbeamsGeneratorClass
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

@interface CISunbeamsClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the strength
	IBOutlet id strengthLabel;
	
	// The slider for the strength
	IBOutlet id strengthSlider;

	// The label displaying the contrast
	IBOutlet id contrastLabel;
	
	// The slider for the contrast
	IBOutlet id contrastSlider;

	// The main color to use
	IBOutlet id mainColorWell;

	// The color to be used
	NSColor *mainNSColor;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new strength
	float strength;
	
	// The new contrast
	float contrast;
	
	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;

	// YES if the plug-in is running
	BOOL running;

}

@end
