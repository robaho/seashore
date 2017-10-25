#import "Globals.h"
#import "AbstractScaleOptions.h"

/*!
	@enum		k...Layer
	@constant	kMovingLayer
				The tool changes the position of the layer.
	@constant	kScalingLayer
				The tool scales the layer.
	@constant	kRotatingLayer
				If the layer is floating, it rotates it.
	@constant	kAnchoringLayer
				The tool anchors the floating layer.
*/

enum {
	kMovingLayer = 0,
	kScalingLayer = 1,
	kRotatingLayer = 2,
	kAnchoringLayer = 3
};


/*!
	@class		PositionOptions
	@abstract	Handles the options pane for the position tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PositionOptions : AbstractScaleOptions {

	// Checkbox specifying whether the position tool can anchor floating selections
	IBOutlet id canAnchorCheckbox;
	
	// Function of the tool
	int function;
}

/*!
	@method		awakeFromNib
	@discussion	Loads previous options from preferences.
*/
- (void)awakeFromNib;

/*!
	@method		canAnchor
	@discussion	Returns whether the position tool can anchor floating selections.
	@result		Returns YES if the position tool can anchor floating selections,
				NO otherwise.
*/
- (BOOL)canAnchor;

/*!
	@method		setFunctionFromIndex:
	@discussion	For setting the function of the tool from a modifier index (instead of a k...Layer enum).
	@param		index
				The modifier index of the new modifier.
*/
- (void)setFunctionFromIndex:(unsigned int)index;

/*!
	@method		toolFunction
	@discussion	For figuring out what the tool actually does. It changes depending on the appropriate modifiers or the popup menu.
	@result		One of the elements from the k...Layer enum.
*/
- (int)toolFunction;

/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
*/
- (void)shutdown;

@end
