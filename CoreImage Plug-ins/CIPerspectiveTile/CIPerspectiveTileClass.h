/*!
	@header		CIPerspectiveTileClass
	@abstract	Applies a perspective transform to the selection and then tiles the result.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIPerspectiveTileClass : NSObject <PluginClass>{

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// YES if the application succeeded
	BOOL success;

	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
	// Determines the boundaries of the layer
	CGRect bounds;
	
	// Signals whether the bounds rectangle is valid
	BOOL boundsValid;

}
@end
