#import "Seashore.h"
#import "CloneOptions.h"
#import "AbstractBrushTool.h"
#import "SeaLayer.h"

@interface CloneTool : AbstractBrushTool {
	// The source point
	IntPoint sourcePoint;

    // The initial point of the draw
    IntPoint startPoint;
	
	// Has the source been set?
	BOOL sourceSet;
	
	// How far has the source been setting?
	int fadeLevel;
	
	// A timer to allow the source to set
	id fadingTimer;
	
    CGImageRef srcImg;
    CGRect srcRect;
    NSString *srcName;
    
    CloneOptions *options;
}
/*!
	@method		sourceSet
	@discussion	Returns whether the source point has been set.
	@result		Returns YES if the source point is set, NO otherwise.
*/
- (BOOL)sourceSet;

/*!
	@method		fadeLevel
	@discussion	The 'fade level' of source point after being selected.
	@result		Returns an integer between 1 and 0 (gradually decreasing with
				fading).
*/
- (float)fadeLevel;

/*!
	@method		sourcePoint
	@discussion	Returns the source point.
	@param		local
				YES if the point should be returned in the layer's co-ordinates,
				NO if it should be returned in the document's co-ordinates.
	@result		Returns an IntPoint representing the source point.
*/
- (IntPoint)sourcePoint:(BOOL)local;

/*!
	@method		sourceName
	@discussion	Returns the name of the source.
	@result		Returns a string indicating the source's name (e.g. the name of
				the source layer)
*/
- (NSString *)sourceName;
@end
