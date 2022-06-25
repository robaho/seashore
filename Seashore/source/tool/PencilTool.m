#import "PencilTool.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaWhiteboard.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "PencilOptions.h"
#import "SeaController.h"
#import "OptionsUtility.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaTexture.h"
#import "TextureUtility.h"
#import "Bucket.h"
#import "RecentsUtility.h"

@implementation PencilTool

- (int)toolId
{
	return kPencilTool;
}

- (BOOL)acceptsLineDraws
{
	return YES;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)plotBrush:(SeaBrush*)curBrush at:(NSPoint)where pressure:(int)pressure
{
    SeaLayer *layer = [[document contents] activeLayer];
    int height = [layer height];
    int width = [layer width];
    int spp = [[document contents] spp];
    int size = [options pencilSize];

    IntRect rect = IntMakeRect(where.x-size/2,where.y-size/2,size,size);

    CGRect cgRect = IntRectMakeNSRect(rect);

    CGContextRef overlayCtx = [[document whiteboard] overlayCtx];

    CGContextSetAlpha(overlayCtx, 1.0);
    CGContextSetFillColorWithColor(overlayCtx, [color CGColor]);
    if([options circularTip]) {
        CGContextFillEllipseInRect(overlayCtx,cgRect);
    } else {
        CGContextFillRect(overlayCtx,cgRect);
    }

    if ([options useTextures] && ![options brushIsErasing]) {
        SeaTexture *activeTexture = [[document textureUtility] activeTexture];
        textureFill(spp, rect, [[document whiteboard] overlay], width, height, [activeTexture texture:(spp == 4)], [activeTexture width], [activeTexture height]);
    }
    [[document helpers] overlayChanged:rect];

}

- (void)plotPoints:(IntPoint)where pressure:(int)origPressure
{
	int xMod = (lastPoint.x > where.x) ? -1 : 1, yMod = (lastPoint.y > where.y) ? -1 : 1;
	int xDist = fabs(lastPoint.x - where.x), yDist = fabs(lastPoint.y - where.y);

    if (!intermediate)
        return;
	
	// Only continue if the current point is different from the last point
	if (lastPoint.x == where.x && lastPoint.y == where.y)
		return;
	
	// Draw a line between the last point and this point
	for (int i = 1; i <= MAX(xDist, yDist); i++) {
        NSPoint curPoint;

		if (xDist > yDist) {
			curPoint.x = lastPoint.x + i * xMod;
			curPoint.y = lastPoint.y + (i * yDist) / xDist * yMod;
		}
		else {
			curPoint.x = lastPoint.x + (i * xDist) / yDist * xMod;
			curPoint.y = lastPoint.y + i * yMod;
		}

        [self plotBrush:NULL at:curPoint pressure:255];
	}
	
	lastPoint = IntPointMakeNSPoint(where);
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;

    [[document helpers] applyOverlay];
    intermediate=NO;

    [[document recentsUtility] rememberPencil:[self getBrushOptions]];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (PencilOptions*)newoptions;
}

- (PencilOptions*)getBrushOptions
{
    return options;
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    if([cursors usePreciseCursor]) {
        return [cursors crosspointCursor];
    }
    if([options brushIsErasing]) {
        return [cursors eraserCursor];
    }
    return [cursors pencilCursor];
}

@end
