/*!
	@header		InvertClass
	@abstract	Inverts the current selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface InvertClass : NSObject <PluginClass> {

	// The plug-in's manager
	PluginData *pluginData;

}
@end
