#import "CloneTool.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaController.h"
#import "SeaLayer.h"
#import "StandardMerge.h"
#import "SeaWhiteboard.h"
#import "SeaLayerUndo.h"
#import "SeaView.h"
#import "SeaBrush.h"
#import "BrushUtility.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaTexture.h"
#import "BrushOptions.h"
#import "TextureUtility.h"
#import "Bucket.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "CloneOptions.h"

@implementation CloneTool

- (int)toolId
{
	return kCloneTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	sourceSet = NO;
	return self;
}

- (void)dealloc
{
    CGImageRelease(srcImg);
}

- (BOOL)acceptsLineDraws
{
	return NO;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (NSColor*)brushColor
{
    // always use black since we fill
    return [NSColor blackColor];
}

- (void)plotBrush:(SeaBrush*)brush at:(NSPoint)where pressure:(int)pressure
{
    int brushWidth = [brush width];
    int brushHeight = [brush height];

    SeaLayer *layer = [[document contents] activeLayer];

    CGRect rect = NSMakeRect(where.x-brushWidth/2.0,where.y-brushHeight/2.0,brushWidth,brushHeight);
    CGRect global = CGRectOffset(rect,[layer xoff],[layer yoff]);

    CGContextRef overlayCtx = [[document whiteboard] overlayCtx];

    CGContextSaveGState(overlayCtx);

    // everything is done in global coordinates for clone since it is easier
    CGContextTranslateCTM(overlayCtx, -[layer xoff],-[layer yoff]);

    CGRect srcRect0 = CGRectOffset(srcRect,startPoint.x-sourcePoint.x,startPoint.y-sourcePoint.y);

    CGContextClipToRect(overlayCtx,srcRect0);
    CGContextClipToRect(overlayCtx,global);

    CGContextTranslateCTM(overlayCtx, [layer xoff],[layer yoff]);

    [super plotBrush:brush at:where pressure:pressure];

    CGContextTranslateCTM(overlayCtx, -[layer xoff],-[layer yoff]);

    CGContextSetBlendMode(overlayCtx, kCGBlendModeSourceIn);

    CGContextTranslateCTM(overlayCtx,srcRect0.origin.x,srcRect0.origin.y+srcRect0.size.height);
    CGContextScaleCTM(overlayCtx,1,-1);

    CGContextDrawImage(overlayCtx, CGRectMake(0,0,srcRect0.size.width,srcRect0.size.height), srcImg);

    CGContextRestoreGState(overlayCtx);
}

- (BOOL)sourceSet
{
	return sourceSet;
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    [[document whiteboard] setOverlayOpacity:[options opacity]];
    // need to use replace, since drawing may be outside source bounds
//    [[document whiteboard] setOverlayBehaviour:kMaskingBehavior];
}

- (float)fadeLevel
{
	return fadeLevel/100.0;
}

- (IntPoint)sourcePoint:(BOOL)local
{
	IntPoint outPoint;
	
	if (local) {
		outPoint.x = sourcePoint.x - srcRect.origin.x;
        outPoint.y = sourcePoint.y - srcRect.origin.y;
	}
	else {
        outPoint.x = sourcePoint.x;
        outPoint.y = sourcePoint.y;
	}
	
	return outPoint;
}

- (NSString *)sourceName
{
    return srcName;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	int modifier = [options modifier];

    SeaLayer *layer = [[document contents] activeLayer];
	
	if (modifier == kAltModifier) {
        sourcePoint = IntOffsetPoint(where,[layer xoff],[layer yoff]);

		if (fadeLevel > 0) {
			fadeLevel = 0;
            [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(sourcePoint):26];
		}

        CGImageRelease(srcImg);
        srcImg=NULL;

        if([options mergedSample]) {
            int w = [[document contents] width];
            int h = [[document contents] height];
            CGImageRef img = [[document whiteboard] bitmapCG];
            srcImg = CGImageDeepCopy(img);
            CGImageRelease(img);
            srcRect = NSMakeRect(0,0,w,h);
            srcName = NULL;
        } else {
            CGImageRef img = [layer bitmap];
            srcImg = CGImageDeepCopy(img);
            CGImageRelease(img);
            srcRect = IntRectMakeNSRect([layer globalRect]);
            srcName = [layer name];
        }
        sourceSet = YES;
        fadeLevel = 100;

        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(sourcePoint):26];
	}
	else if (sourceSet) {
        startPoint = IntOffsetPoint(where,[layer xoff],[layer yoff]);
        [super mouseDownAt:where withEvent:event];
        fadeLevel=0;
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	if (sourceSet) {
        [super mouseDraggedTo:where withEvent:event];
    }
}

- (IBAction)fade:(id)sender
{
	if (fadeLevel > 0) {
		fadeLevel -= 20;
		fadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(sourcePoint):26];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	if (fadeLevel) {
		// Start the source setting
		fadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(sourcePoint):26];
        [options update:self];
    } else {
        [super mouseUpAt:where withEvent:event];
    }
}

- (void)endLineDrawing
{
    [options update:self];

    if(!intermediate)
        return;

    [[document helpers] applyOverlay];
    intermediate=NO;
}

- (AbstractOptions*)getOptions
{
    return options;
}
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (CloneOptions*)newoptions;
}

- (BrushOptions*)getBrushOptions
{
    return options;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if(!sourceSet || [options modifier]==kAltModifier) {
        IntRect r;
        if([options mergedSample]) {
            r = [[document contents] rect];
        } else {
            r = [[[document contents] activeLayer] globalRect];
        }
        if(!IntPointInRect(p, r)) {
            [[cursors noopCursor] set];
            return;
        }
        return [[self toolCursor:cursors] set];
    }
    return [super updateCursor:p cursors:cursors];
}

- (NSCursor*)toolCursor:(SeaCursors *)cursors
{
    return [cursors usePreciseCursor] ? [cursors crosspointCursor] : [cursors cloneCursor];
}

@end
