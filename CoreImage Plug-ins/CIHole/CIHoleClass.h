/*!
	@header		CIHoleClass
	@abstract	Places a big hole at the specified point.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <PLugins/PluginClass.h>

@interface CIHoleClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

	// YES if the application succeeded
	BOOL success;
}
@end
