#import "SeaTools.h"
#import "ToolboxUtility.h"
#import "SeaController.h"
#import "UtilitiesManager.h"
#import "AbstractTool.h"

@implementation SeaTools

- (id)currentTool
{
	return [self getTool:[[[SeaController utilitiesManager] toolboxUtilityFor:gCurrentDocument] tool]];
}

- (id)getTool:(int)whichOne
{
	switch (whichOne) {
		case kRectSelectTool:
			return rectSelectTool;
		break;
		case kEllipseSelectTool:
			return ellipseSelectTool;
		break;
		case kLassoTool:
			return lassoTool;
		break;
		case kPolygonLassoTool:
			return polygonLassoTool;
		break;
		case kWandTool:
			return wandTool;
		break;
		case kPencilTool:
			return pencilTool;
		break;
		case kBrushTool:
			return brushTool;
		break;
		case kBucketTool:
			return bucketTool;
		break;
		case kTextTool:
			return textTool;
		break;
		case kEyedropTool:
			return eyedropTool;
		break;
		case kEraserTool:
			return eraserTool;
		break;
		case kPositionTool:
			return positionTool;
		break;
		case kGradientTool:
			return gradientTool;
		break;
		case kSmudgeTool:
			return smudgeTool;
		break;
		case kCloneTool:
			return cloneTool;
		break;
		case kCropTool:
			return cropTool;
		break;
		case kEffectTool:
			return effectTool;
		break;
	}
	
	return NULL;
}

- (NSArray *)allTools
{
	return [NSArray arrayWithObjects: rectSelectTool, ellipseSelectTool, lassoTool, polygonLassoTool, wandTool, pencilTool, brushTool, bucketTool, textTool, eyedropTool, eraserTool, positionTool, gradientTool, smudgeTool, cloneTool, cropTool, effectTool, nil];
}
@end
