#import "Seashore.h"
#import "AbstractPaintOptions.h"

enum {
    kQuadratic,
    kLinear,
    kSquareRoot
};

/*!
	@class		BrushOptions
	@abstract	Handles the options pane for the paintbrush tool.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface BrushOptions : AbstractPaintOptions {
	IBOutlet id fadeSlider;
	IBOutlet id pressurePopup;
	IBOutlet id scalingCheckbox;
	
	BOOL isErasing;
}

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
	@method		pressureValue
	@discussion	Returns the pressure value that should be used for the brush.
	@param		event
				The event encapsulating the current pressure.
	@result		Returns an integer from 0 to 255 indicating the pressure value
				that should be used for the brush. If pressure sensitive is disabled
                255 is returned.
*/
- (int)pressureValue:(NSEvent *)event;

/*!
	@method		scale
	@discussion	Returns whether the brush should be scaled with based on dpi.
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

@end
