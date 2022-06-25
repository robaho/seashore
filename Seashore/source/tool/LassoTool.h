#import "Seashore.h"
#import "LassoOptions.h"
#import "AbstractSelectTool.h"

/*!
	@defined	kMaxLTPoints
	@discussion	Specifies the maximum number of points.
*/
#define kMaxLTPoints 16384

/*!
 @struct		LassoPoints
 @discussion	For storing a list of points and a position in the list
 @field			points
				A finite array of points
 @field			pos
				The current location in the array
*/
typedef struct {
	IntPoint *points;
	int pos;
} LassoPoints;

/*!
	@class		LassoTool
	@abstract	The selection tool allows freeform selections of no specific shape
	@discussion	Option key - floats the selection.
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface LassoTool : AbstractSelectTool {

	// The list of points
	IntPoint *points;
	
	// The current position in the list
	int pos;
    IntRect dirty;
    
    LassoOptions *options;
}

/*!
	@method		currentPoints
	@discussion	Returns the current points used by the tool for other classes to use.
	@result		A LassoPoints struct
*/
- (LassoPoints) currentPoints;

- (void) initializePoints:(IntPoint)where;
- (void) addPoint:(IntPoint)where;
- (void) createMaskFromPoints;

@end
