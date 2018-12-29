/*!
	@header		MedianClass
	@abstract	Adjusts the selection so that all pixels are the median 
				value of them and their neighbours.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli and
				Copyright (c) 1997-1998 Michael Sweet
*/

#import <Cocoa/Cocoa.h>
#import <Plugins/PluginClass.h>

@interface MedianClass : NSObject {

	// The plug-in's manager
	SeaPlugins *seaPlugins;
}
@end
