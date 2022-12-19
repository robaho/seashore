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

- (void)awakeFromNib {
    options = [[CloneOptions alloc] init:document];
}

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
    CGContextRelease(srcCtx);
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

- (IntRect)plotBrushAt:(NSPoint)where pressure:(int)pressure
{
    IntRect r = [super plotBrushAt:where pressure:pressure];

    CGContextRef overlayCtx = [[document whiteboard] overlayCtx];

    SeaLayer *layer = [[document contents] activeLayer];
    IntPoint w = IntMakePoint(r.origin.x+[layer xoff],r.origin.y+[layer yoff]);

    cloneFill(overlayCtx,srcCtx,r,IntMakePoint(sourcePoint.x+(w.x-startPoint.x),sourcePoint.y+(w.y-startPoint.y)),srcRect);

    return r;
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

        CGContextRelease(srcCtx);

        // srcRect 0,0 globally is the upper left of the image

        if([options mergedSample]) {
            int w = [[document contents] width];
            int h = [[document contents] height];
            CGImageRef img = [[document whiteboard] bitmap];
            srcCtx = CGBitmapContextCreate(NULL,w,h,8,w*4,rgbCS,kCGImageAlphaPremultipliedFirst);
            CGContextDrawImage(srcCtx,CGRectMake(0,0,w,h),img);
            CGImageRelease(img);
            srcRect = IntMakeRect(0,0,w,h);
            srcName = NULL;
        } else {
            int w = [layer width];
            int h = [layer height];
            CGImageRef img = [layer bitmap];
            srcCtx = CGBitmapContextCreate(NULL,w,h,8,w*4,rgbCS,kCGImageAlphaPremultipliedFirst);
            CGContextDrawImage(srcCtx,CGRectMake(0,0,w,h),img);
            CGImageRelease(img);
            srcRect = IntMakeRect([layer xoff],[layer yoff], w, h);
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
