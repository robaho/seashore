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

- (void)awakeFromNib {
    options = [[PencilOptions alloc] init:document];
}

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

- (bool)applyTextures
{
    BrushOptions *options = [self getBrushOptions];
    return [options useTextures] && ![options brushIsErasing];
}

- (CGImageRef)getBrushImage
{
    int size = [options pencilSize];

    CGContextRef ctx = CGBitmapContextCreate(NULL, size, size, 8, 0, rgbCS, kCGImageAlphaPremultipliedFirst);
    CGContextSetFillColorWithColor(ctx, [color CGColor]);
    if([options circularTip]) {
        CGContextFillEllipseInRect(ctx,CGRectMake(0,0,size,size));
    } else {
        CGContextFillRect(ctx,CGRectMake(0,0,size,size));
    }
    CGImageRef image = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return image;
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

    IntRect dirty = IntZeroRect;
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

        IntRect r = [self plotBrushAt:curPoint pressure:255];
        dirty = i==1 ? r : IntSumRects(dirty,r);
	}

    if(!IntRectIsEmpty(dirty)) {
        [[document helpers] overlayChanged:dirty];
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
