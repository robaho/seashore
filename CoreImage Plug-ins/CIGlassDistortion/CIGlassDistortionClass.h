/*!
	@header		CIGlassDistortionClass
	@abstract	Crystallize the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				Default texture from Apple with permission to use "without restriction"
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIGlassDistortionClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The label displaying the current texture
	IBOutlet id textureLabel;

	// The panel for the plug-in
	IBOutlet id panel;

	// The scale of the crystallize
	int scale;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// The path of the texture to be used
	NSString *texturePath;

}
@end
