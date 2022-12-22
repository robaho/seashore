#import "SmudgeTool.h"
#import "SeaTools.h"
#import "SeaBrush.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "BrushUtility.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaHelpers.h"
#import "SeaWhiteboard.h"
#import "SmudgeOptions.h"
#import "Bucket.h"
#import <Accelerate/Accelerate.h>

@implementation SmudgeTool

- (void)awakeFromNib {
    options = [[SmudgeOptions alloc] init:document];
}

- (void)dealloc
{
    if(accumData){
        free(accumData);
        free(tempData);
    }
}

- (int)toolId
{
	return kSmudgeTool;
}

- (bool)applyTextures
{
    return FALSE;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (IntRect)plotBrushAt:(NSPoint)where pressure:(int)pressure
{
    SeaLayer *layer = [[document contents] activeLayer];

    int brushWidth = [brush width];
    int brushHeight = [brush height];

    IntRect rect = IntMakeRect(where.x-brushWidth/2,where.y-brushHeight/2,brushWidth,brushHeight);
    smudgeFill(rect,[layer data],[[document whiteboard] overlay],[layer width],[layer height],accumData,tempData,[brush mask],brushWidth,brushHeight,pressure);

    return rect;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    brush = [[document brushUtility] activeBrush];

	int brushWidth = [brush width], brushHeight = [brush height];

    if(accumData){
        free(accumData);
        free(tempData);
    }

    rate = [options rate];

    accumData = calloc(brushWidth*brushHeight*SPP,1);
    tempData = calloc(brushWidth*brushHeight*SPP,1);

    [super mouseDownAt:where withEvent:event];
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    [[document whiteboard] setOverlayOpacity:rate];
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;

    [[document helpers] applyOverlay];
    intermediate=NO;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (BrushOptions*)getBrushOptions
{
    return options;
}

- (int)getBrushSpacing
{
    return 1; // must use 1 spacing for smudge to work properly
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors usePreciseCursor] ? [cursors crosspointCursor] : [cursors smudgeCursor];
}


@end
