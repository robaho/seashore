/*!
	@header		CIPosterizeClass
	@abstract	Posterizes the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIPosterizeClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the levels
	IBOutlet id levelsLabel;
	
	// The slider for the posterize
	IBOutlet id levelsSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new number of levels
	int levels;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;

}
@end
