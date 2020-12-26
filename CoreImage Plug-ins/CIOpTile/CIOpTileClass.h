/*!
	@header		CIOpTileClass
	@abstract	Generates a set of overlapping squares using Core Image.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIOpTileClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the dot width
	IBOutlet id squareWidthLabel;
	
	// The slider for the width
	IBOutlet id squareWidthSlider;

	// The label displaying the angle
	IBOutlet id angleLabel;
	
	// The slider for the angle
	IBOutlet id angleSlider;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new width
	int squareWidth;

	// The new angle
	float angle;
	
	// The new scale
	float scale;
	
	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
}
@end
