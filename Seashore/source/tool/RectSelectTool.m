#import "RectSelectTool.h"
#import "SeaDocument.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "RectSelectOptions.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaTools.h"
#import "AspectRatio.h"

@implementation RectSelectTool

- (int)toolId
{
	return kRectSelectTool;
}

- (IntRect)selectionRect
{
    return [super postScaledRect];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [options setOneToOne:([options modifier] == kShiftModifier)];

	[super downHandler:where withEvent:event];
    if(![super isMovingOrScaling]) {
        if ([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode){
            [[document selection] clearSelection];
            [[document helpers] selectionChanged];
        }
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect old = [self postScaledRect];

	[super dragHandler:where withEvent:event];
	
	if (intermediate && ![super isMovingOrScaling]) {
        [[document helpers] selectionChanged:IntSumRects(old,[self postScaledRect])];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if(intermediate && ![super isMovingOrScaling] && !IntRectIsEmpty([self selectionRect])){
        [self createMask];
        // Also, we universally float the selection if alt is down
        if([[self getOptions] modifier] == kAltModifier) {
            [[document contents] layerFromSelection:NO];
        }
    }

	[super upHandler:where withEvent:event];
}

- (void)createMask {
    if([options radius]){
        [[document selection] selectRoundedRect:[self selectionRect] radius:[options radius] mode:[options selectionMode]];
    }else{
        [[document selection] selectRect:[self selectionRect] mode:[options selectionMode]];
    }
}

- (void)cancelSelection
{
	[super cancelSelection];
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (RectSelectOptions*)newoptions;
}

@end
