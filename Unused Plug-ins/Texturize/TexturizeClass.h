/*!
	@header		TexturizeClass
	@abstract	Generate a texture from the active document.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b>
				Copyright (c) 2004-2005 Manu Cornet and Jean-Baptise Rouquier
*/

#import <Cocoa/Cocoa.h>
#import "SeaPlugins.h"

@interface TexturizeClass : NSObject {

	// The plug-in's manager
	id seaPlugins;

	// The label displaying the overlap
	IBOutlet id overlapLabel;
	
	// The slider for the overlap
	IBOutlet id overlapSlider;

	// The label displaying the width
	IBOutlet id widthLabel;
	
	// The slider for the width
	IBOutlet id widthSlider;
	
	// The label displaying the height
	IBOutlet id heightLabel;
	
	// The slider for the height
	IBOutlet id heightSlider;
	
	// The checkbox indicating whether the resulting texture should be tileable
	IBOutlet id tileableCheckbox;
	
	// The panel for the plug-in
	IBOutlet id panel;
	
	// The progress bar to indicate progress
	IBOutlet id progressBar;

	// The overlap
	float overlap;
	
	// The width
	float width;
	
	// The height
	float height;
	
	// Should the resulting texture be tileable?
	BOOL tileable;

	// YES if the application succeeded
	BOOL success;

}

/*!
	@method		initWithManager:
	@discussion	Initializes an instance of this class with the given manager.
	@param		manager
				The SeaPlugins instance responsible for managing the plug-ins.
	@result		Returns instance upon success (or NULL otherwise).
*/
- (id)initWithManager:(SeaPlugins *)manager;

/*!
	@method		type
	@discussion	Returns the type of plug-in so Seashore can correctly interact
				with the plug-in.
	@result		Returns an integer indicating the plug-in's type.
*/
- (int)type;

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
	@method		apply:
	@discussion	Applies the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)apply:(id)sender;

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
	@method		cancel:
	@discussion	Cancels the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		update:
	@discussion	Updates the panel's labels.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		texturize
	@discussion	Executes the texturize.
*/
- (void)texturize;

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
