#import "Seashore.h"
#import "SeaDocument.h"
#import "SeaController.h"

@protocol PluginClass;

/*!
	@enum		k...Plugin
	@constant	kBasicPlugin
				Specifies a basic effects plug-in.
	@constant	kPointPlugin
				Specifies a basic effect plug-in that acts on one or
				more given to it by the effects tool.
*/
enum {
	kBasicPlugin = 0,
	kPointPlugin = 1
};

/*!
	@class		SeaPlugins
	@abstract	Manages all of Seashore's plug-ins.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain<br>
				<b>Copyright:</b> N/A
*/
@interface SeaPlugins : NSObject <SeaTerminate> {

	// The SeaController object
	IBOutlet id controller;

	// An array of all Seahore's plug-ins
	NSArray<id<PluginClass>> *plugins;

	// The submenu to add plug-ins to
	IBOutlet id effectMenu;
}

/*!
	@method		init
	@discussion	Initializes an instance of this class.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)init;

/*!
	@method		awakeFromNib
	@discussion	Adds plug-ins to the menu.
*/
- (void)awakeFromNib;

/*!
	@method		terminate
	@discussion	Saves preferences to disk (this method is called before the
				application exits by the SeaController).
*/
- (void)terminate;


/*!
	@method		data
	@discussion	Returns the address of a record shared between Seashore and the
				plug-in.
	@result		Returns the address of a record shared between Seashore and the
				plug-in.
*/
- (id)data;

/*!
	@method		run:
	@discussion	Runs the plug-in specified by the sender.
	@param		sender
				The menu item for the plug-in.
*/
- (IBAction)run:(id)sender;

/*!
	@method		reapplyEffect
	@discussion	Reapplies the last effect without configuration.
	@param		sender
				Ignored.
*/
- (IBAction)reapplyEffect:(id)sender;

/*!
	@method		cancelReapply
	@discussion	Prevents reapplication of the last effect.
*/
- (void)cancelReapply;

/*!
	@method		hasLastEffect
	@discussion	Returns whether there is a last effect.
	@result		Returns YES if there is a last effect, NO otherwise.
*/
- (BOOL)hasLastEffect;

- (NSMenu*)menu;

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
