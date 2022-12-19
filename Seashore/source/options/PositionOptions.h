#import "Seashore.h"
#import "AbstractScaleOptions.h"

/*!
	@enum		k...Layer
	@constant	kMovingLayer
				The tool changes the position of the layer.
	@constant	kScalingLayer
				The tool scales the layer.
	@constant	kRotatingLayer
				If the layer is floating, it rotates it.
*/

enum {
	kMovingLayer = 0,
	kScalingLayer = 1,
	kRotatingLayer = 2
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

    id maintainAspectCheckbox;
    id scaleAndRotateLinkedCheckbox;
}

- (BOOL)maintainAspectRatio;
- (BOOL)scaleAndRotateLinked;

@end
