/*!
	@header		CIFalseColorClass
	@abstract	Adjusts the white point of the selection using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIFalseColorClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// YES if the application succeeded
	BOOL success;
}
@end
