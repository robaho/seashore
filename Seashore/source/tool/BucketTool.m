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
	[[document whiteboard] applyOverlay];
	intermediate = NO;
    [[document recentsUtility] rememberBucket:options];
}

-(IntRect)fillOverlay:(IntPoint)start color:(unsigned char*)color tolerance:(int)tolerance op:(NSOperation*)op
{
    SeaLayer *layer = [[document contents] activeLayer];
    int width = [layer width], height = [layer height];
    unsigned char *overlay = [[document whiteboard] overlay], *data = [layer data];

    bool fillAllRegions = [options fillAllRegions];
    int channel = [[document contents] selectedChannel];

    fillContext ctx;
    ctx.overlay = overlay;
    ctx.data = data;
    ctx.width = width;
    ctx.height = height;
    ctx.start = start;
    ctx.tolerance = tolerance;
    ctx.channel = channel;

    memcpy(ctx.fillColor,color,4);

    IntRect rect;

    if(fillAllRegions) {
        memset(overlay,0,width*height*SPP);
        rect = IntMakeRect(0,0,width,height);
        for(int row=0;row<height;row++){
            if([op isCancelled])
                return IntZeroRect;
            for(int col=0;col<width;col++){
                if(shouldFill(&ctx,col,row)) {
                    memcpy(&(overlay[(row * width + col) * SPP]), color, SPP);
                }
            }
        }
    } else {
        rect = bucketFill(&ctx, IntMakeRect(0, 0, width, height),op);
    }
    return rect;
}

-(void)preview:(unsigned char)tolerance
{
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
        [[document whiteboard] setOverlayOpacity:200];
        [[document whiteboard] ignoreSelection:true];

        unsigned char _color[4];
        _color[CR]= [color redComponent]*255;
        _color[CG]= [color greenComponent]*255;
        _color[CB]= [color blueComponent]*255;
        _color[alphaPos] = 255;

        IntRect tmp = [self fillOverlay:startPoint color:_color tolerance:tolerance op:weakOp];
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
