#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		PencilOptions
	@abstract	Handles the options pane for the pencil tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PencilOptions : AbstractPaintOptions {
	
	// A slider indicating the size of the pencil block
	IBOutlet id sizeSlider;
	
	// Are we erasing stuff?
	BOOL isErasing;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		pencilSize
	@discussion	Returns the current pencil size.
	@result		Returns an integer representing the current pencil size.
*/
- (int)pencilSize;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		pencilIsErasing
	@discussion	Returns whether or not the pencil is erasing.
	@result		Returns YES if the pencil is erasing, NO if the pencil is using
				its normal operation.
*/
- (BOOL)pencilIsErasing;

/*!
	@method		updateModifiers:
	@discussion	Updates the modifier pop-up.
	@param		modifiers
				An unsigned int representing the new modifiers.
*/
- (void)updateModifiers:(unsigned int)modifiers;

/*!
	@method		modifierPopupChanged:
	@discussion	Called when the popup is changed.
	@param		sender
				Needs to be the popup menu.
*/
- (IBAction)modifierPopupChanged:(id)sender;


/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
