#import <Cocoa/Cocoa.h>
#import "SeaPlugins.h"
#import "PluginData.h"

/*!
	@class		PluginClass
	@abstract	A basic class from which to build plug-ins.
	@discussion	This class is in the public domain allowing plug-ins of any
				license to be made compatible with Seashore.
				<br><br>
				<b>License:</b> Public Domain 2004<br>
				<b>Copyright:</b> N/A
*/

@interface PluginClass : NSObject {

}

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		data
				The Plugin services callback.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithManager:(PluginData *)data;

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact
				with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
- (int)type;

/*!
	@method		points
	@discussion	Returns the number of points that the plug-in requires from the
				effect tool to operate.
	@result		Returns an integer indicating the number of points the plug-in
				requires to operate.
*/
- (int)points;

/*!
	@method		name
	@discussion	Returns the plug-in's name.
	@result		Returns an NSString indicating the plug-in's name.
*/
- (NSString *)name;

/*!
	@method		groupName
	@discussion	Returns the plug-in's group name.
	@result		Returns an NSString indicating the plug-in's group name.
*/
- (NSString *)groupName;

/*!
	@method		instruction
	@discussion	Returns the plug-in's instructions.
	@result		Returns a NSString indicating the plug-in's instructions
				(127 chars max).
*/
- (NSString *)instruction;

/*!
	@method		sanity
	@discussion	Returns a string to indicate this is a Seashore plug-in.
	@result		Returns the NSString "Seashore Approved (Bobo)".
*/
- (NSString *)sanity;

/*!
	@method		run
	@discussion	Runs the plug-in.
*/
- (void)run;

/*!
	@method		reapply
	@discussion	Applies the plug-in with previous settings.
*/
- (void)reapply;

/*!
	@method		canReapply
	@discussion Returns whether or not the plug-in can be applied again.
	@result		Returns YES if the plug-in can be applied again, NO otherwise.
*/
- (BOOL)canReapply;

/*!
 @method        validatePlugin:
 @discussion    Determines whether a given plugin should be enabled or
 disabled.
 @param        pluginData
 @result        YES if the plugin should be enabled, NO otherwise.
 */
+ (BOOL)validatePlugin:(PluginData*)pluginData;

@end
