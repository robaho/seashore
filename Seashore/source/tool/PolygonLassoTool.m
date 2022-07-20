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

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int first_down = !intermediate;

    [super downHandler:where withEvent:event];

	if(![super isMovingOrScaling]){
		if (first_down){
            [self initializePoints:where];
            startPoint = where;

            if ([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode){
                [[document selection] clearSelection];
            }
		}
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    [super dragHandler:where withEvent:event];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    float anchorRadius = 4.0 / [[document docView] zoom];

    if (intermediate && ![super isMovingOrScaling]) {
        if(!(abs(startPoint.x - where.x) < anchorRadius && abs(startPoint.y - where.y) < anchorRadius)) {
            [self addPoint:where];
        } else {
            [self createMaskFromPoints];

            // Also, we universally float the selection if alt is down
            if([[self getOptions] modifier] == kAltModifier) {
                [[document contents] layerFromSelection:NO];
            }
        }
    } else {
        [super upHandler:where withEvent:event];
    }
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if(pos>0) {
        if(IntPointInRect(p,[cursors handleRect:points[0]])) {
            [[cursors closeCursor] set];
            return;
        }
    }
    [super updateCursor:p cursors:cursors];
}

@end
