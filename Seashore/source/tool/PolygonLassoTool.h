#import "Seashore.h"
#import "AbstractScaleTool.h"
#import "LassoTool.h"

/*!
	@class		PolygonLassoTool
	@abstract	The polygon lasso tool allows polygonal selections of no specific shape
	@discussion	Option key - floats the selection.
				This is a subclass of the LassoTool, because some of the functionality
				is shared and it reduces duplicate code.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface PolygonLassoTool : LassoTool {
	// The beginning point of the polygonal lasso tool.
	// Represented by the white dot in the view.
	IntPoint startPoint;
}

@end
