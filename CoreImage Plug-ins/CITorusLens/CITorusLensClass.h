/*!
	@header		CITorusLensClass
	@abstract	Applies a pinch at the specified point.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CITorusLensClass : NSObject <PluginClass>{

	// The plug-in's manager
	PluginData *pluginData;

	// The label displaying the refraction
	IBOutlet id refractionLabel;
	
	// The slider for the refraction
	IBOutlet id refractionSlider;
	
	// The panel for the plug-in
	IBOutlet id panel;

	// YES if the application succeeded
	BOOL success;

	// YES if the effect must be refreshed
	BOOL refresh;
	
	// The extent of the refraction
	float refraction;

}
@end
