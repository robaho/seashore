/*!
	@header		CIInvertClass
	@abstract	Adjusts the selection so that all pixels are the median value of them
				and their neighbours using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIInvertClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// YES if the application succeeded
	BOOL success;

	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;
	
}
@end
