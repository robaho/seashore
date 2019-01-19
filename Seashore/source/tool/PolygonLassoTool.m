#import "PolygonLassoTool.h"
#import "LassoTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "PolygonLassoOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"

@implementation PolygonLassoTool

- (int)toolId
{
	return kPolygonLassoTool;
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
    SeaLayer *layer = [[document contents] activeLayer];
    where.x -= [layer xoff];
    where.y -= [layer yoff];

	[super mouseDownAt:IntMakePoint(where.x, where.y) withEvent:event];
	
	if(![super isMovingOrScaling]){
		int modifier;
		
		// Get mode
		modifier = [(AbstractOptions*)options modifier];

		float anchorRadius = 4.0 / [[document docView] zoom];
		
		// Behave differently depending on condtions
		if (!intermediate){
            [self initializePoints:where];
            startPoint = where;
		}
		else if ([[NSApp currentEvent] clickCount] == 1 && intermediate && !(abs(startPoint.x - where.x) < anchorRadius && abs(startPoint.y - where.y) < anchorRadius)) {
            [self addPoint:where];
		}
		else if (intermediate) {
             [self createOverlayFromPoints];
		}
	}
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	[super mouseDraggedTo:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
	id layer = [[document contents] activeLayer];
	[super mouseUpAt:IntMakePoint(where.x - [layer xoff], where.y - [layer yoff]) withEvent:event];

	translating = NO;
	scalingDir = kNoDir;
}

@end
