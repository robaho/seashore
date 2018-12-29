/*!
	@header		PixellateClass
	@abstract	Applies the pixellate effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface PixellateClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The number of scale
	int scale;

	// YES if the blurring must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;

}

@end
