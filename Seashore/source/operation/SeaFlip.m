#import "SeaFlip.h"
#import "SeaHelpers.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaSelection.h"
#import "SeaLayer.h"
#import "SeaSelection.h"

@implementation SeaFlip


- (void)standardFlip:(int)type
{
    SeaSelection *selection = [document selection];
    if (![selection active])
        return;

    IntRect r = [[document selection] localRect];

    SeaLayer *layer = [[document contents] activeLayer];

    CGImageRef cutImage = [layer copyBitmap:r];

    [selection deleteSelection];

    [selection flipSelection:type];

    CGContextRef ctx = [[document whiteboard] overlayCtx];
    CGContextSaveGState(ctx);

    CGContextTranslateCTM(ctx,0,r.origin.y+r.size.height);
    CGContextScaleCTM(ctx,1,-1);
    CGContextTranslateCTM(ctx,r.origin.x,0);

    if(type==kHorizontalFlip) {
        CGContextTranslateCTM(ctx, r.size.width, 0);
        CGContextScaleCTM(ctx, -1, 1);
    } else if(type==kVerticalFlip) {
        CGContextTranslateCTM(ctx, 0, r.size.height);
        CGContextScaleCTM(ctx, 1, -1);
    }

    CGContextDrawImage(ctx, NSMakeRect(0,0,r.size.width,r.size.height), cutImage);

    CGImageRelease(cutImage);

    CGContextRestoreGState(ctx);

    unsigned char *replace = [[document whiteboard] replace];
    memset(replace,0xFF,[layer width]*[layer height]);

	[[document whiteboard] setOverlayOpacity:255];
	[[document whiteboard] setOverlayBehaviour:kReplacingBehaviour];
    
    [[document helpers] overlayChanged:r];
	[[document helpers] applyOverlay];
}

- (void)flipSelectionHorizontally
{
    [[document helpers] endLineDrawing];
    [self standardFlip:kHorizontalFlip];
}

- (void)flipSelectionVertically
{
    [[document helpers] endLineDrawing];
    [self standardFlip:kVerticalFlip];
}


- (void)flipLayerHorizontally
{
    [[document helpers] endLineDrawing];

    [[[document undoManager] prepareWithInvocationTarget:self] flipLayerHorizontally];

    SeaLayer *layer = [[document contents] activeLayer];
    [layer flipHorizontally];

    [[document helpers] boundariesAndContentChanged];
}

- (void)flipLayerVertically
{
    [[document helpers] endLineDrawing];

    [[[document undoManager] prepareWithInvocationTarget:self] flipLayerVertically];

    SeaLayer *layer = [[document contents] activeLayer];
    [layer flipVertically];

    [[document helpers] boundariesAndContentChanged];
}


@end
