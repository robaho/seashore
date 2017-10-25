/*!
	@class		SeaPlugins
	@abstract	A skeleton version of the SeaPlugins class.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import "PluginData.h"

@interface SeaPlugins : NSObject {

}

/*!
	@method		data
	@discussion	Returns the PluginData object shared between Seashore and the plug-in.
	@result		Returns the PluginData object shared between Seashore and the plug-in.
*/
- (PluginData *)data;

/*!
	@method		validateMenuItem:
	@discussion	Determines whether a given menu item should be enabled or
				disabled.
	@param		menuItem
				The menu item to be validated.
	@result		YES if the menu item should be enabled, NO otherwise.
*/
- (BOOL)validateMenuItem:(id)menuItem;

@end
