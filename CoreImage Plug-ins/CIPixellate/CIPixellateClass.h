/*!
	@header		CIPixellateClass
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

@interface CIPixellateClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The radio boxes for the type
	IBOutlet id typeRadios;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new scale
	int scale;

	// YES if pixellate is centre-based
	BOOL centerBased;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
