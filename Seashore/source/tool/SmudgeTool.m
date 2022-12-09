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
#import "DebugView.h"

@implementation SmudgeTool

- (void)awakeFromNib {
    options = [[SmudgeOptions alloc] init:document];
}

- (int)toolId
{
	return kSmudgeTool;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (IntRect)plotBrush:(SeaBrush*)brush at:(NSPoint)where pressure:(int)pressure
{
    SeaLayer *layer = [[document contents] activeLayer];
    int brushWidth = [brush width];
    int brushHeight = [brush height];
    int spp = [[document contents] spp];

    IntRect rect = IntMakeRect(where.x-brushWidth/2,where.y-brushHeight/2,brushWidth,brushHeight);

    smudgeFill(spp,[[document contents] selectedChannel],rect,[layer data],[[document whiteboard] overlay],[layer width],[layer height],accumData,[brush mask],brushWidth,brushHeight,pressure);

    [[document helpers] overlayChanged:rect];
    
    return rect;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	SeaBrush *curBrush = [[document brushUtility] activeBrush];
	int brushWidth = [curBrush width], brushHeight = [curBrush height];
    int spp = [[document contents] spp];

    if(accumData){
        free(accumData);
    }

    rate = [options rate];

    accumData = calloc(brushWidth*brushHeight*spp,1);

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
