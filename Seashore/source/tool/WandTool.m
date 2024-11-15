#import "WandTool.h"
#import "SeaTools.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "Bucket.h"
#import "SeaWhiteboard.h"
#import "WandOptions.h"
#import "SeaSelection.h"
#import "SeaHelpers.h"
#import "SeaPrefs.h"
#import <SeaLibrary/Bitmap.h>

@implementation WandTool

- (void)awakeFromNib {
    options = [[WandOptions alloc] init:document];

    // use a queue to perform fill operations so we can cancel for smoother preview
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
}

- (int)toolId
{
	return kWandTool;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super downHandler:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		currentPoint = startPoint = where;
        lastTolerance = 0;
        [self preview:[options tolerance]];
	}
}

int signum(int n) { return (n < 0) ? -1 : (n > 0) ? +1 : 0; }

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super dragHandler:where withEvent:event];
	
	if(![super isMovingOrScaling]){
        currentPoint = where;
        int range = currentPoint.x >= startPoint.x ? [[document contents] width]-startPoint.x : startPoint.x;

        double adj = ((currentPoint.x-startPoint.x)/(double)range)*255;
        double tolerance = MIN(MAX([options tolerance] + adj,0),255);
        [self preview:tolerance];
	}
}

-(void)preview:(unsigned char)tolerance
{
    if(!IntPointInRect(startPoint, [[[document contents] activeLayer] localRect]))
        return;

    if(tolerance==lastTolerance) {
        return;
    }
    lastTolerance = tolerance;

    NSColor *color = [[SeaController seaPrefs] selectionColor:.75];

    [queue cancelAllOperations];
    [queue waitUntilAllOperationsAreFinished];

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

        IntRect tmp = [self fillOverlay:startPoint color:_color tolerance:tolerance allRegions:[options selectAllRegions] op:weakOp];
        if(IntRectIsEmpty(tmp))
            return;
        previewRect = tmp;

        dirty = IntRectIsEmpty(dirty) ? previewRect : IntSumRects(dirty,previewRect);
        [[document helpers] overlayChanged:dirty];
    }];

    [queue addOperation:op];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int old = intermediate;
    bool wasMovingOrScaling = [super isMovingOrScaling];

	[super upHandler:where withEvent:event];

    [queue waitUntilAllOperationsAreFinished];

    if(!old || wasMovingOrScaling)
        goto done;
    
    if([options selectionMode] == kDefaultMode || [options selectionMode] == kForceNewMode)
        [[document selection] clearSelection];

    int mode = [options selectionMode];

    IntRect rect = previewRect;
    [[document selection] selectOverlay:rect mode:mode];

    if([[self getOptions] modifier] == kAltModifier) {
        [[document contents] layerFromSelection:NO];
    }
done:
    [[document whiteboard] clearOverlay];

    return;
}

- (IntPoint)start
{
	return startPoint;
}

-(IntPoint)current
{
	return currentPoint;
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    if(!IntPointInRect(p, [[[document contents] activeLayer] globalRect])) {
        [[cursors noopCursor] set];
        return;
    }
    return [super updateCursor:p cursors:cursors];
}

@end
