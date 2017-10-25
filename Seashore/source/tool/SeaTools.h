#import "Globals.h"

/*!
	@enum		k...Tool
	@constant	kRectSelectTool
				The rectangular selection tool.
	@constant	kEllipseSelectTool
				The elliptical selection tool.
	@constant	kLassoTool
				The lasso tool.
	@constant	kPolygonLassoTool
				The polygon lasso tool.
	@constant   kWandTool
				The wand selection tool.
	@constant	kPencilTool
				The pencil tool.
	@constant	kBrushTool
				The paintbrush tool.
	@constant	kEyedropTool
				The colour sampling tool.
	@constant	kTextTool
				The text tool.
	@constant	kEraserTool
				The eraser tool.
	@constant	kBucketTool
				The paint bucket tool.
	@constant	kGradientTool
				The gradient tool.
	@constant	kCropTool
				The crop tool.
	@constant	kCloneTool
				The clone tool.
	@constant	kSmudgeTool
				The smudging tool.
	@constant	kEffectTool
				The effect tool.
	@constant	kZoomTool
				The zoom tool.
	@constant	kPositionTool
				The layer positioning tool.
	@constant	kFirstSelectionTool
				The first selection tool.
	@constant	kLastSelectionTool
				The last selection tool.
*/
enum {
	kRectSelectTool = 0,
	kEllipseSelectTool = 1,
	kLassoTool = 2,
	kPolygonLassoTool = 3,
	kWandTool = 4,
	kPencilTool = 5, 
	kBrushTool = 6,
	kEyedropTool = 7,
	kTextTool = 8,
	kEraserTool = 9,
	kBucketTool = 10,
	kGradientTool = 11,
	kCropTool = 12,
	kCloneTool = 13,
	kSmudgeTool = 14,
	kEffectTool = 15,
	kZoomTool = 16,
	kPositionTool = 17,
	kFirstSelectionTool = 0,
	kLastSelectionTool = 4,
	kLastTool = 17
};

@class AbstractTool;

/*!
	@class		SeaTools
	@abstract	Acts as a gateway to all the tools of Seashore.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface SeaTools : NSObject {

	// Various objects representing various tools
	IBOutlet id rectSelectTool;
	IBOutlet id ellipseSelectTool;	
	IBOutlet id lassoTool;
	IBOutlet id polygonLassoTool;
	IBOutlet id wandTool;
	IBOutlet id pencilTool;
	IBOutlet id brushTool;
	IBOutlet id bucketTool;
	IBOutlet id textTool;
	IBOutlet id eyedropTool;
	IBOutlet id eraserTool;
    IBOutlet id positionTool;
	IBOutlet id gradientTool;
	IBOutlet id smudgeTool;
	IBOutlet id cloneTool;
	IBOutlet id cropTool;
	IBOutlet id effectTool;
	
}

/*!
	@method		currentTool
	@discussion	Returns the currently active tool according to the toolbox
				utility.
	@result		Returns an object that is a subclass of AbstractTool.
*/
- (id)currentTool;

/*!
	@method		getTool:
	@discussion	Given a tool type returns the corresponding tool.
	@param		whichOne
				The tool type for the tool you are seeking.
	@result		Returns an object that is a subclass of AbstractTool.
*/
- (id)getTool:(int)whichOne;

/*!
	@method		allTools
	@discussion	This is purely for initialization to connect the options to the tools.
	@result		Returns an array of AbstractTools.
*/
- (NSArray *)allTools;

@end
