#import "LassoTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "LassoOptions.h"
#import "SeaContent.h"
#import "SeaTools.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "SeaView.h"
#import "SeaLayer.h"
#import "SeaWhiteboard.h"
#import "SeaController.h"
#import "ToolboxUtility.h"

@implementation LassoTool

- (void)awakeFromNib {
    options = [[LassoOptions alloc] init:document];
}

- (int)toolId
{
	return kLassoTool;
}

- (void)initializePoints:(IntPoint)where
{
    if(points) {
        free(points);
    }
    // Create the points list
    points = malloc(kMaxLTPoints * sizeof(IntPoint));
    pos = 0;
    points[0] = where;
    dirty = IntEmptyRect(points[0]);
    [[document docView] setNeedsDisplayInLayerRect:dirty:4];
    intermediate = YES;
}

- (void)addPoint:(IntPoint)where
{
    if (points[pos].x != where.x || points[pos].y != where.y) {
        // Add the point to the list
        pos++;
        points[pos] = where;
        dirty = IntSumRects(dirty,IntEmptyRect(points[pos]));

        [[document docView] setNeedsDisplayInLayerRect:dirty:4];
    }
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super downHandler:IntMakePoint(where.x, where.y) withEvent:event];
		
	if(![super isMovingOrScaling]){
        [self initializePoints:where];
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super dragHandler:IntMakePoint(where.x, where.y) withEvent:event];
	
	if(intermediate && ![super isMovingOrScaling]){
		// Check we have a valid start point
		// Check this point is different to the last
		if (pos < kMaxLTPoints - 1) {
            [self addPoint:where];
		}
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    // Check we have a valid start point
    if (intermediate && ![super isMovingOrScaling]) {
        [self createMaskFromPoints];

        // Also, we universally float the selection if alt is down
        if([[self getOptions] modifier] == kAltModifier) {
            [[document contents] layerFromSelection:NO];
        }
    }

	[super upHandler:where withEvent:event];
}

- (void)createMaskFromPoints
{
    // Redraw canvas
    [[document docView] setNeedsDisplay:YES];
    
    // Clear last selection
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];
    
    // No single-pixel loops
    if (pos <= 1) return;
    
    // Reconnect the loop
    pos++;
    points[pos] = points[0];
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    
    for (int tpos = 0; tpos <= pos; tpos++) {
        if(tpos==0) {
            [path moveToPoint:NSMakePoint(points[tpos].x,points[tpos].y)];
        } else {
            [path lineToPoint:NSMakePoint(points[tpos].x,points[tpos].y)];
        }
    }

    SeaLayer *layer = [[document contents] activeLayer];

    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:[layer xoff] yBy:[layer yoff]];
    [path transformUsingAffineTransform:tx];

    [[document selection] selectPath:path mode:[options selectionMode]];

    intermediate = NO;
}

- (LassoPoints)currentPoints
{
	LassoPoints result;
	result.points = points;
	result.pos = pos;
	return result;
}

- (AbstractOptions*)getOptions
{
    return options;
}

@end
