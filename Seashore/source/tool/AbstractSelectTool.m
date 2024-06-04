#import "AbstractSelectTool.h"

#import "SeaDocument.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "AbstractOptions.h"
#import "SeaContent.h"
#import "AbstractSelectOptions.h"
#import "SeaLayer.h"

@implementation AbstractSelectTool

- (void)downHandler:(IntPoint)localPoint withEvent:(NSEvent *)event
{	
    [self mouseDownAt: localPoint
              forRect: [[document selection] maskRect]
         withMaskRect: [[document selection] maskRect]
              andMask: [[document selection] mask]];
}

- (AbstractSelectOptions*)selectOptions
{
    return (AbstractSelectOptions*)[self getOptions];
}

- (BOOL)ignoresMove {
    return [[self selectOptions] selectionMode] != kDefaultMode;
}

- (void)dragHandler:(IntPoint)localPoint withEvent:(NSEvent *)event
{
    IntRect newRect = [self mouseDraggedTo: localPoint
                                   forRect: [[document selection] maskRect] // TODO
                                   andMask: [[document selection] mask]];
    if(scalingDir > kNoDir && !translating){
        [[document selection] scaleSelectionTo: newRect
                                          from: [self preScaledRect]
                                     usingMask: [self preScaledMask]];
    }else if (translating && scalingDir == kNoDir){
        SeaLayer *layer = [[document contents] activeLayer];
        IntPoint globalPoint = IntOffsetPoint(localPoint,[layer xoff],[layer yoff]);
        [[document selection] moveSelection:globalPoint fromOrigin:moveOrigin];
        moveOrigin = globalPoint;
    }
}

- (void)upHandler:(IntPoint)localPoint withEvent:(NSEvent *)event
{
    [self mouseUpAt: localPoint
            forRect: [[document selection] maskRect] // TODO
            andMask: [[document selection] mask]];

}

- (void)cancelSelection
{
	translating = NO;
	scalingDir = kNoDir;
	intermediate = NO;
	[[document helpers] selectionChanged];
}

- (void)switchingTools:(BOOL)active
{
    intermediate=FALSE;
    [super switchingTools:active];
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if([[document selection] active]){
        IntRect selectionRect = [[document selection] maskRect];
        NSCursor *c = [cursors handleRectCursors:selectionRect point:p cursor:NULL ignoresMove:[self ignoresMove]];
        if(c) {
            return;
        }
    }

    int selectionMode = [[self selectOptions] selectionMode];

    if(selectionMode == kAddMode){
        [[cursors addCursor] set];
        return;
    }else if (selectionMode == kSubtractMode) {
        [[cursors subtractCursor] set];
        return;
    }

    [[cursors crosspointCursor] set];
    return;
}

@end
