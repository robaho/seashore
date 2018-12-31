/*!
	@header		CIKaleidoscopeClass
	@abstract	Applies a kaleidoscope effect to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Plugins/PluginClass.h>

@interface CIKaleidoscopeClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;

	// YES if the application succeeded
	BOOL success;
}
@end
