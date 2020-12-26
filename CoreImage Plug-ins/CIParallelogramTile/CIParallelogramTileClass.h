/*!
	@header		CIParallelogramTileClass
	@abstract	Applies a triangle effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIParallelogramTileClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// YES if the application succeeded
	BOOL success;

	// The label displaying the angle
	IBOutlet id acuteLabel;
	
	// The slider for the angle
	IBOutlet id acuteSlider;
	
	// The panel for the plug-in
	IBOutlet id panel;
	
	// YES if the effect must be refreshed
	BOOL refresh;
	
	// The new angle
	float acute;
	
}
@end
