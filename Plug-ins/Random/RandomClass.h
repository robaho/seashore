/*!
	@header		RandomClass
	@abstract	Adds random noise to the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface RandomClass : NSObject <PluginClass> {

	// The plug-in's manager
	SeaPlugins *seaPlugins;
}
@end
