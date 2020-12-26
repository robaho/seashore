/*!
	@header		CIVortexClass
	@abstract	Applies a zoom blur effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIVortexClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the angle
	IBOutlet id angleLabel;
	
	// The slider for the angle
	IBOutlet id angleSlider;

	// The checkbox for whether reverse directions
	IBOutlet id reverseCheckbox;

	// The panel for the plug-in
	IBOutlet id panel;

	// YES if the application succeeded
	BOOL success;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// The angle of the twirl
	float angle;

}
@end
