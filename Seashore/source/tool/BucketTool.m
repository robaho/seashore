#import "BucketTool.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "Bucket.h"
#import "OptionsUtility.h"
#import "BucketOptions.h"
#import "StandardMerge.h"
#import "SeaTexture.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "SeaSelection.h"
#import "SeaController.h"
#import "TextureUtility.h"
#import "RecentsUtility.h"

@implementation BucketTool

- (void)awakeFromNib {
    options = [[BucketOptions alloc] init:document];

    // use a queue to perform fill operations so we can cancel for smoother preview
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
}

- (int)toolId
{
	return kBucketTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	startPoint = where;

	intermediate = YES;

    if([options useTextures]) {
        CGContextRelease(textureCtx);

        NSImage *pattern = [[[document toolboxUtility] foreground] patternImage];
        int w = pattern.size.width;
        int h = pattern.size.height;

        textureCtx = CGBitmapContextCreate(NULL, w,h, 8, w*SPP, rgbCS, kCGImageAlphaPremultipliedFirst);
        CGImageRef img = [pattern CGImageForProposedRect:NULL context:NULL hints:NULL];
        CGContextDrawImage(textureCtx,CGRectMake(0,0,w,h), img);
        if([[document contents] isGrayscale]) {
            mapARGBtoAGGG(CGBitmapContextGetData(textureCtx),w*h*SPP);
        }
    }

    lastTolerance = 0;
    [self preview:[options tolerance]];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if(!intermediate)
        return;

    currentPoint = where;
    int range = currentPoint.x >= startPoint.x ? [[document contents] width]-startPoint.x : startPoint.x;

    double adj = ((currentPoint.x-startPoint.x)/(double)range)*255;
    double tolerance = MIN(MAX([options tolerance] + adj,0),255);
    [self preview:tolerance];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [queue waitUntilAllOperationsAreFinished];
	[[document whiteboard] applyOverlay];
	intermediate = NO;
    [[document recentsUtility] rememberBucket:options];
}

-(void)preview:(unsigned char)tolerance
{
    if(!IntPointInRect(startPoint, [[[document contents] activeLayer] localRect]))
        return;

    if(tolerance==lastTolerance) {
        return;
    }
    lastTolerance = tolerance;

    [queue cancelAllOperations];
    [queue waitUntilAllOperationsAreFinished];

    NSColor *color = [[document contents] foreground];
    if ([options useTextures]) {
        color = [[NSColor blackColor] colorUsingColorSpace:MyRGBCS];
    }

    NSBlockOperation *op = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation* weakOp = op;

    [op addExecutionBlock:^{
        IntRect dirty = previewRect;

        [[document whiteboard] clearOverlayForUpdate];
        [[document whiteboard] setOverlayOpacity:[options opacity]];

        unsigned char _color[4];
        _color[CR]= [color redComponent]*255;
        _color[CG]= [color greenComponent]*255;
        _color[CB]= [color blueComponent]*255;
        _color[alphaPos] = 255;

        IntRect tmp = [self fillOverlay:startPoint color:_color tolerance:tolerance allRegions:[options fillAllRegions] op:weakOp];
        if(IntRectIsEmpty(tmp))
            return;

        previewRect = tmp;

        if ([options useTextures]) {
            CGContextRef overlayCtx = [[document whiteboard] overlayCtx];
            textureFill(overlayCtx,textureCtx,previewRect);
        }

        dirty = IntRectIsEmpty(dirty) ? previewRect : IntSumRects(dirty,previewRect);
        [[document helpers] overlayChanged:dirty];
    }];

    [queue addOperation:op];
}

- (void)endLineDrawing
{
    if(!intermediate)
        return;

    [queue waitUntilAllOperationsAreFinished];

    [[document helpers] applyOverlay];
    intermediate=NO;

    [[document recentsUtility] rememberBucket:options];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors usePreciseCursor] ? [cursors crosspointCursor] : [cursors bucketCursor];
}

@end
