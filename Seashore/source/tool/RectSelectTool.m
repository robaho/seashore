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

// this is a local rect
- (IntRect)selectionRect
{
    SeaLayer *layer = [[document contents] activeLayer];
    return IntOffsetRect([super postScaledRect],-[layer xoff],-[layer yoff]);
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [options setOneToOne:([options modifier] == kShiftModifier)];

	[super downHandler:where withEvent:event];
	
	// Do the following rect select specific behvior
	if (![super isMovingOrScaling]) {
        // Clear the active selection and start the selection
        if ([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode){
            [[document selection] clearSelection];
        }
        intermediate = YES;
		[[document helpers] selectionChanged];
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
    if(intermediate && ![super isMovingOrScaling]){
        [self createMask];
        // Also, we universally float the selection if alt is down
        if([[self getOptions] modifier] == kAltModifier) {
            [[document contents] layerFromSelection:NO];
        }
    }

	[super upHandler:where withEvent:event];
	
	scalingDir = kNoDir;
	translating = NO;
}

- (void)createMask {
    intermediate = NO;

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
