/*!
	@header		ThresholdClass
	@abstract	Runs a threshold operation on the selection.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2005 Mark Pazolli
*/

#import <Cocoa/Cocoa.h>
#import "SeaPlugins.h"
#import "PluginClass.h"

@interface ThresholdClass : NSObject <PluginClass> {

	// The plug-in's manager
	id seaPlugins;

	// The threshold range
	IBOutlet id rangeLabel;
	
	// The top threshold slider
	IBOutlet id topSlider;
	
	// The bottom threshold slider
	IBOutlet id bottomSlider;

	// The panel for the plug-in
	IBOutlet id panel;

	// The view associated with this panel
	IBOutlet id view;

	// The various threshold values
	int topValue, bottomValue;

	// YES if the effect must be refreshed
	BOOL refresh;

	// YES if the application succeeded
	BOOL success;

}

/*!
	@method		adjust
	@discussion	Executes the adjustments.
*/
- (void)adjust;

/*!
	@method		topValue
	@discussion	Returns the value of the top slider.
	@result		Returns an integer representing value of the top slider.
*/
- (int)topValue;

/*!
	@method		bottomValue
	@discussion	Returns the value of the bottom slider.
	@result		Returns an integer representing value of the bottom slider.
*/
- (int)bottomValue;

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
