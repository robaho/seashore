/*!
	@header		CIStarshineGeneratorClass
	@abstract	Generates a colourful halo using CoreImage.
	@discussion	N/A
				<br><br>
				<b>License:</b> Public Domain 2007<br>
				<b>Copyright:</b> N/A
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SeaPlugins.h"

#define gColorPanel [NSColorPanel sharedColorPanel]

@interface CIStarshineClass : NSObject {

	// The plug-in's manager
	id seaPlugins;

	// The label displaying the scale
	IBOutlet id scaleLabel;
	
	// The slider for the scale
	IBOutlet id scaleSlider;

	// The label displaying the opacity
	IBOutlet id opacityLabel;
	
	// The slider for the opacity
	IBOutlet id opacitySlider;
	
	// The label displaying the width
	IBOutlet id widthLabel;
	
	// The slider for the width
	IBOutlet id widthSlider;
	
	// The main color to use
	IBOutlet id mainColorWell;

	// The color to be used
	NSColor *mainNSColor;

	// The panel for the plug-in
	IBOutlet id panel;

	// The new scale
	int scale;
	
	// The new opacity
	float opacity;
	
	// The new width
	float star_width;
	
	// YES if the effect must be refreshed
	BOOL refresh;
	
	// YES if the application succeeded
	BOOL success;
	
	// Some temporary space we need preallocated for greyscale data
	unsigned char *newdata;

	// YES if the plug-in is running
	BOOL running;

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
	@discussion	Returns the type of plug-in so Seashore can correctly interact with the plug-in.
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
	@method		preview:
	@discussion	Previews the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)preview:(id)sender;

/*!
	@method		cancel:
	@discussion	Cancels the plug-in's changes.
	@param		sender
				Ignored.
*/
- (IBAction)cancel:(id)sender;

/*!
	@method		setColor:
	@discussion	Sets the color of the receiver.
	@param		color
				The new color for the color well.
*/
- (void)setColor:(NSColor *)color;

/*!
	@method		update:
	@discussion	Updates the panel's labels.
	@param		sender
				Ignored.
*/
- (IBAction)update:(id)sender;

/*!
	@method		execute
	@discussion	Executes the effect.
*/
- (void)execute;

/*!
	@method		executeGrey
	@discussion	Executes the effect for greyscale images.
	@param		pluginData
				The PluginData object.
*/
- (void)executeGrey:(PluginData *)pluginData;

/*!
	@method		executeGrey
	@discussion	Executes the effect for colour images.
	@param		pluginData
				The PluginData object.
*/
- (void)executeColor:(PluginData *)pluginData;

/*!
	@method		executeChannel:withBitmap:
	@discussion	Executes the effect with any necessary changes depending on channel selection
				(called by either executeGrey or executeColor). 
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)executeChannel:(PluginData *)pluginData withBitmap:(unsigned char *)data;

/*!
	@method		starshine:withBitmap:
	@discussion	Called by execute once preparation is complete.
	@param		pluginData
				The PluginData object.
	@param		data
				The bitmap data to work with (must be 8-bit ARGB).
	@result		Returns the resulting bitmap.
*/
- (unsigned char *)starshine:(PluginData *)pluginData withBitmap:(unsigned char *)data;

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
