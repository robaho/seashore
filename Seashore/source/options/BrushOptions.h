#import "Globals.h"
#import "AbstractPaintOptions.h"

/*!
	@class		BrushOptions
	@abstract	Handles the options pane for the paintbrush tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BrushOptions : AbstractPaintOptions {
	
	// A checkbox indicating whether to fade
	IBOutlet id fadeCheckbox;
	
	// A slider indicating the rate of fading
	IBOutlet id fadeSlider;
	
	// A checkbox indicating whether to listen to pressure information
	IBOutlet id pressureCheckbox;
	
	// A popup menu indicating pressure style
	IBOutlet id pressurePopup;
	
	// A checkbox indicating whether to scale
	IBOutlet id scaleCheckbox;
	
	// A boolean indicating if the user has been warned about the Mac OS 10.4 bug
	BOOL warnedUser;

	// Are we erasing stuff?
	BOOL isErasing;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		update:
	@discussion	Updates the options panel.
	@param		sender
				The object responsible for the change.
*/
- (IBAction)update:(id)sender;

/*!
	@method		fade
	@discussion	Returns whether the brush should fade with use.
	@result		Returns YES if the brush should fade with use, NO otherwise.
*/
- (BOOL)fade;

/*!
	@method		fadeValue
	@discussion	Returns the rate of fading.
	@result		Returns an integer representing the rate of fading.
*/
- (int)fadeValue;

/*!
	@method		fade
	@discussion	Returns whether the brush is pressure sensitive.
	@result		Returns YES if the brush is pressure sensitive, NO otherwise.
*/
- (BOOL)pressureSensitive;

/*!
	@method		pressureValue
	@discussion	Returns the pressure value that should be used for the brush.
	@param		event
				The event encapsulating the current pressure.
	@result		Returns an integer from 0 to 255 indicating the pressure value
				that should be used for the brush.
*/
- (int)pressureValue:(NSEvent *)event;

/*!
	@method		scale
	@discussion	Returns whether the brush should be scaled with pressure.
	@result		Returns YES if the brush should scaled, NO otherwise.
*/
- (BOOL)scale;

/*!
	@method		useTextures
	@discussion	Returns whether or not the tool should use textures.
	@result		Returns YES if the tool should use textures, NO if the tool
				should use the foreground colour.
*/
- (BOOL)useTextures;

/*!
	@method		brushIsErasing
	@discussion	Returns whether or not the brush is erasing.
	@result		Returns YES if the brush is erasing, NO if the brush is using
				its normal operation.
*/
- (BOOL)brushIsErasing;

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

@end
