#import "Globals.h"
#import "AbstractScaleOptions.h"

/*		
	@class		AbstractSelectOptions
	@abstract	Acts as a base class for the options panes of the selection tools.
	@discussion	This class is responsible for keeping track of the mode of the selection,
				since all selection tools share the same modes.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface AbstractSelectOptions : AbstractScaleOptions {
	// The Selection mode
	int mode;
}

/*!
	@method		selectionMode
	@discussion	Returns the mode to be used for the selection.
	@result		Returns an integer indicating the mode (see SeaSelection).
*/
- (int)selectionMode;

/*!
	@method		setSelectionMode
	@discussion	Sets the mode to be used for selection.
	@param		newMode
				The new mode to be set, from the k...Mode enum.
*/
- (void)setSelectionMode:(int)newMode;

/*!
	@method		setModeFromModifier:
	@discussion	Sets the mode, based on a modifier from the keyboard or the popup menu.
	@param		modifier
				The modifier of the new mode to be set, from the k...Modifier enum.
*/
- (void)setModeFromModifier:(unsigned int)modifier;

@end
