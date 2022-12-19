#import "Seashore.h"
#import "PencilOptions.h"
#import "AbstractBrushTool.h"

/*!
	@class		PencilTool
	@abstract	The pencil tool is a precision tool intended for small
				pixel-by-pixel changes.
	@discussion	Shift key - Draws straight lines.<br>Option key - Changes
				the brush to an eraser.<br>Control key - Draws lines at
				45 degree intervals.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PencilTool : AbstractBrushTool {
    PencilOptions *options;
}
@end
