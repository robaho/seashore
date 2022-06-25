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
	mergedData = NULL;
	return self;
}

- (BOOL)acceptsLineDraws
{
	return NO;
}

- (BOOL)useMouseCoalescing
{
	return NO;
}

- (void)plotBrush:(SeaBrush*)brush at:(NSPoint)where pressure:(int)pressure
{
    [super plotBrush:brush at:where pressure:pressure];

    int brushWidth = [brush width];
    int brushHeight = [brush height];

    IntRect rect = IntMakeRect(where.x-brushWidth/2,where.y-brushHeight/2,brushWidth,brushHeight);

    unsigned char *sourceData;
    int sourceWidth;
    int sourceHeight;

    if (sourceMerged) {
        sourceData = mergedData;
        sourceWidth = [[document contents] width];
        sourceHeight = [[document contents] height];
    }
    else {
        sourceData = [sourceLayer data];
        sourceWidth = [sourceLayer width];
        sourceHeight = [sourceLayer height];
    }

    int spp = [[document contents] spp];

    IntPoint spt;

    spt.x = sourcePoint.x + (rect.origin.x - startPoint.x);
    spt.y = sourcePoint.y + (rect.origin.y - startPoint.y);

    if(sourceMerged) {
        spt = IntOffsetPoint(spt,layerOff.x,layerOff.y);
    }

    SeaLayer *layer = [[document contents] activeLayer];

    cloneFill(spp, rect, [[document whiteboard] overlay], [[document whiteboard] replace], [layer width], [layer height], sourceData, sourceWidth, sourceHeight, spt);

    [[document helpers] overlayChanged:rect];
}

- (BOOL)sourceSet
{
	return sourceSet;
}

- (void)setOverlayOptions:(BrushOptions*)options
{
    [[document whiteboard] setOverlayOpacity:[options opacity]];
    [[document whiteboard] setOverlayBehaviour:kMaskingBehavior];
}

- (float)fadeLevel
{
	return fadeLevel/100.0;
}

- (IntPoint)sourcePoint:(BOOL)local
{
	IntPoint outPoint;
	
	if (local) {
		outPoint.x = sourcePoint.x;
		outPoint.y = sourcePoint.y;
	}
	else {
		outPoint.x = sourcePoint.x + layerOff.x;
		outPoint.y = sourcePoint.y + layerOff.y;
	}
	
	return outPoint;
}

- (NSString *)sourceName
{
	if (sourceMerged == NO)
		return [sourceLayer name];
	else
		return NULL;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	int spp = [[document contents] spp];
	int modifier = [options modifier];

    SeaLayer *layer = [[document contents] activeLayer];
	
	if (modifier == kAltModifier) {
		if (fadeLevel > 0) {
			fadeLevel = 0;
            [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(sourcePoint,layerOff.x,layerOff.y)):26];
		}

		sourceMerged = [options mergedSample];
        layerOff.x = [layer xoff];
        layerOff.y = [layer yoff];
        sourcePoint = where;
        sourceSet = NO;
        sourceLayer = [[document contents] activeLayer];
        fadeLevel = 100;

        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(sourcePoint,layerOff.x,layerOff.y)):26];
	}
	else if (sourceSet) {
		
		// Find the source
		if (sourceMerged) {
			int sourceWidth = [[document contents] width];
			int sourceHeight = [[document contents] height];
			if (mergedData) {
				free(mergedData);
				mergedData = NULL;
			}
			mergedData = malloc(make_128(sourceWidth * sourceHeight * spp));
			memcpy(mergedData, [[document whiteboard] data], sourceWidth * sourceHeight * spp);
		}

        startPoint = where;

        [super mouseDownAt:where withEvent:event];
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
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(sourcePoint,layerOff.x,layerOff.y)):26];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	if (fadeLevel) {
		// Start the source setting
		fadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fade:) userInfo:NULL repeats:NO];
		sourceSet = YES;
        [[document docView] setNeedsDisplayInDocumentRect:IntEmptyRect(IntOffsetPoint(sourcePoint,layerOff.x,layerOff.y)):26];
        [options update:self];
	
	}
	else if (sourceSet) {
        [super endLineDrawing];
	}
	
	// Free merged data
	if (mergedData) {
		free(mergedData);
		mergedData = NULL;
	}
}

- (void)endLineDrawing
{
	sourceSet = NO;
    [options update:self];
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
