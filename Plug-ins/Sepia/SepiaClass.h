/*!
	@header		SepiaClass
	@abstract	Converts the current selection  to sepia tone.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface SepiaClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;
}
@end
