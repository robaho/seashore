#import "PositionTool.h"
#import "PositionOptions.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "SeaWhiteboard.h"
#import "SeaView.h"
#import "SeaHelpers.h"
#import "SeaTools.h"
#import "SeaSelection.h"
#import "SeaLayerUndo.h"
#import "SeaOperations.h"
#import "SeaRotation.h"
#import "SeaScale.h"

@interface TransformUndoRecord : NSObject
{
    @public
    int index;
    LayerSnapshot *snapshot;
    IntRect rect;
    float scaleX,scaleY;
    float rotation;
    int x,y;
}
@end
@implementation TransformUndoRecord
@end

@implementation PositionTool

- (void)awakeFromNib {
    options = [[PositionOptions alloc] init:document];
}

- (int)toolId
{
	return kPositionTool;
}

- (id)init
{
	if(![super init])
		return NULL;
	
    scaleX = 1; tempScaleX = 1;
    scaleY = 1; tempScaleY = 1;
    rotation = 0.0; tempRotation = 0.0;
    x = 0; y = 0; tempX = 0; tempY = 0;

	return self;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    initialPoint = where;

    function = -1;

    IntRect r = [self bounds:layer];
    
    r.origin.x -= [layer xoff];
    r.origin.y -= [layer yoff];

    handle = getHandle(where,r,[[document scrollView] magnification]);
    switch(handle){
        case kNoDir:
            if(IntPointInRect(where, r))
                function = kMovingLayer;
            break;
        case kULDir:
        case kURDir:
        case kDRDir:
        case kDLDir:
            function = kRotatingLayer; break;

        case kUDir:
        case kRDir:
        case kDDir:
        case kLDir:
            function = kScalingLayer; break;
    }

    switch (function) {
        case kMovingLayer:
            break;
        case kRotatingLayer:
            tempRotation = 0.0;
            break;
        case kScalingLayer:
            tempScaleX = 1.0; tempScaleY = 1.0;
            break;
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    IntRect dirty = [self bounds:layer];

    // If the active layer is linked we have to move all associated layers
    if ([layer linked]) {
        for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
            SeaLayer *layer = [contents layer:whichLayer];
            if ([layer linked]) {
                dirty = IntSumRects(dirty,[self bounds:layer]);
            }
        }
    }

    switch (function) {
        case kMovingLayer:

            tempX = where.x - initialPoint.x;
            tempY = where.y - initialPoint.y;

            break;
        case kRotatingLayer: {

            int xdiff = initialPoint.x - where.x;
            int ydiff = initialPoint.y - where.y;

            tempRotation = sqr(xdiff/(float)[layer width]) + sqr(ydiff/(float)[layer height]);

            switch(handle){
                case kULDir:
                case kDLDir:
                    tempRotation = tempRotation * -1;
                    break;
                case kURDir:
                case kDRDir:
                    tempRotation = tempRotation * 1;
                    break;
            }

            break;
        }
        case kScalingLayer: {

            float diff;
            float base;

            bool maintainAspect = [options maintainAspectRatio];

            switch(handle){
                case kUDir:
                    diff = initialPoint.y-where.y; base = [layer height];
                    tempScaleY = (diff+base)/base;
                    if(maintainAspect)
                        tempScaleX = (diff+base)/base;
                    break;
                case kLDir:
                    diff = initialPoint.x-where.x; base = [layer width];
                    tempScaleX = (diff+base)/base;
                    if(maintainAspect)
                        tempScaleY = (diff+base)/base;
                    break;
                case kDDir:
                    diff = where.y-initialPoint.y; base = [layer height];
                    tempScaleY = (diff+base)/base;
                    if(maintainAspect)
                        tempScaleX = (diff+base)/base;
                    break;
                case kRDir:
                    diff = where.x-initialPoint.x; base = [layer width];
                    tempScaleX = (diff+base)/base;
                    if(maintainAspect)
                        tempScaleY = (diff+base)/base;
                    break;
            }

            break;
        }
    }

    dirty = IntSumRects(dirty,[self bounds:layer]);

    if ([layer linked]) {
        for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
            SeaLayer *layer = [contents layer:whichLayer];
            if ([layer linked]) {
                dirty = IntSumRects(dirty,[self bounds:layer]);
            }
        }
    }

    [[document helpers] layerOffsetsChanged:dirty];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    scaleX = scaleX*tempScaleX;
    scaleY = scaleY*tempScaleY;
    rotation = rotation+tempRotation;
    x = x+tempX;
    y = y+tempY;

    tempScaleX = tempScaleY = 1;
    tempRotation = 0.0;
    tempX = tempY = 0;

    [[document helpers] selectionChanged];
    [self updateButtons];
}

- (void)adjustOffset:(IntPoint)offset
{
    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    IntRect dirty = [self bounds:layer];

    x += offset.x;
    y += offset.y;

    dirty = IntSumRects(dirty,[self bounds:layer]);

    [self updateButtons];
    
    [[document helpers] layerOffsetsChanged:dirty];
}

- (BOOL)isChanged
{
    return x!=0 || y!=0 || scaleX !=1.0 || scaleY != 1.0 || rotation!=0;
}

- (void)maybeAutoApply
{
    if([options autoApply] && [self isChanged]) {
        [self apply:self];
    }
}

- (IntRect)bounds
{
    return [self bounds:[[document contents] activeLayer]];
}

- (IntRect)bounds:(SeaLayer*)layer
{
    IntRect r = [layer globalRect];

    int lw = r.size.width;
    int lh = r.size.height;
    int xoff = r.origin.x;
    int yoff = r.origin.y;

    NSRect r0 = NSMakeRect(0,0, lw, lh);
    NSBezierPath *tempPath = [NSBezierPath bezierPathWithRect:r0];
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:-(lw/2) yBy:-(lh/2)];
    [tx appendTransform:[self transform]];
    [tempPath transformUsingAffineTransform:tx];
    tx = [NSAffineTransform transform];
    [tx translateXBy:(lw/2) yBy:(lh/2)];
    [tx translateXBy:xoff yBy:yoff];
    [tempPath transformUsingAffineTransform:tx];

    return NSRectMakeIntRect(NSIntegralRect([tempPath bounds]));
}

- (IBAction)scaleToFit:(id)sender {
    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    int width = [contents width];
    int height = [contents height];

    IntRect bounds = [self bounds:layer];
    IntRect dirty = bounds;

    NSLog(@"bounds %@",NSStringFromIntRect(bounds));

    if(bounds.size.width > width || bounds.size.height > height) {
        // need scale
        float sX = width / (float)bounds.size.width;
        float sY = height / (float)bounds.size.height;
        if([options maintainAspectRatio]){
            float scale = MIN(sX,sY);
            sX = sY = scale;
        }
        if(sX<1) {
            scaleX = scaleX * sX;
        }
        if(sY<1) {
            scaleY = scaleY * sY;
        }

        bounds = [self bounds:layer];
    }

    // might need to reposition

    if(bounds.origin.x<0) {
        x = x - bounds.origin.x;
    } else if(bounds.origin.x+bounds.size.width > width) {
        x = x + (width - (bounds.origin.x+bounds.size.width));
    }
    if(bounds.origin.y<0) {
        y = y - bounds.origin.y;
    } else if(bounds.origin.y + bounds.size.height> height) {
        y = y + (height - (bounds.origin.y+bounds.size.height));
    }

    bounds = [self bounds:layer];
    dirty = IntSumRects(dirty,bounds);

    [[document helpers] layerOffsetsChanged:dirty];
    [self updateButtons];

}

- (IBAction)zoomToFitBoundary:(id)sender {
    SeaContent *contents = [document contents];
    SeaLayer *activeLayer = [contents activeLayer];

    NSRect r = IntRectMakeNSRect(IntSumRects([self bounds],[activeLayer globalRect]));

    float adjust = ceilf(MAX(r.size.width,r.size.height)*.03); // add 3% border

    r = NSGrowRect(r,adjust);
    [[document scrollView] magnifyToFitRect:r];
    [[document docView] setNeedsDisplay:YES];
    [[document helpers] zoomChanged];
}

- (IBAction)reset:(id)sender {
    x = y = 0;
    rotation = 0;
    scaleX = scaleY = 1;

    [[document helpers] selectionChanged];
    [self updateButtons];
}

- (IBAction)apply:(id)sender {

    if(![self isChanged])
        return;

    SeaContent *contents = [document contents];
    SeaLayer *activeLayer = [contents activeLayer];

    bool translateOnly = scaleX==1 && scaleY==1 && rotation==0;

    if([activeLayer linked]) {
        for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
            SeaLayer *layer = [contents layer:whichLayer];
            if ([layer linked]) {
                if(translateOnly || (![options scaleAndRotateLinked] && layer!=activeLayer)) {
                    [self applyTranslateOnly:layer];
                } else {
                    [self applyTransform:layer];
                }
            }
        }
    } else {
        if(translateOnly){
            [self applyTranslateOnly:activeLayer];
        } else {
            [self applyTransform:activeLayer];
        }
    }

    [[document helpers] layerBoundariesChanged:kActiveLayer];

    scaleX = scaleY = 1;
    rotation = 0;
    x = y = 0;

    [self updateButtons];
}

- (void)applyTranslateOnly:(SeaLayer*)layer
{
    IntPoint oldOffsets = IntMakePoint([layer xoff],[layer yoff]);
    [[[document undoManager] prepareWithInvocationTarget:self] undoTranslateOnly:oldOffsets forLayer:[layer index]];
    [layer setOffsets:IntMakePoint([layer xoff]+x,[layer yoff]+y)];
}

- (void)applyTransform:(SeaLayer*)layer
{
    int w = [layer width];
    int h = [layer height];

    int xoff = [layer xoff];
    int yoff = [layer yoff];

    IntRect bounds = [self bounds:layer];

    TransformUndoRecord *undoRecord = [[TransformUndoRecord alloc] init];

    // Record the undo details
    undoRecord->index = [layer index];
    undoRecord->snapshot = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, w, h) automatic:NO];
    undoRecord->rect = IntMakeRect(xoff, yoff, w, h);
    undoRecord->scaleX = scaleX;
    undoRecord->scaleY = scaleY;
    undoRecord->rotation = rotation;
    undoRecord->x = x;
    undoRecord->y = y;

    [[[document undoManager] prepareWithInvocationTarget:self] undoApplyTransform:undoRecord];

    [layer scaleX:scaleX scaleY:scaleY rotate:rotation];
    [layer setOffsets:IntMakePoint(bounds.origin.x,bounds.origin.y)];
}

- (void)undoTranslateOnly:(IntPoint)origin forLayer:(int)index
{
    IntPoint oldOffsets;
    id layer = [[document contents] layer:index];

    oldOffsets.x = [layer xoff]; oldOffsets.y = [layer yoff];
    [[[document undoManager] prepareWithInvocationTarget:self] undoTranslateOnly:oldOffsets forLayer:index];
    [layer setOffsets:origin];
    [[document helpers] layerOffsetsChanged:index from:oldOffsets];
    [self updateButtons];
}

- (void)undoApplyTransform:(TransformUndoRecord*)undoRecord
{
    SeaContent *contents = [document contents];
    SeaLayer *layer;

    TransformUndoRecord *redoRecord = [[TransformUndoRecord alloc] init];
    layer = [contents layer:undoRecord->index];

    int w = [layer width];
    int h = [layer height];

    int xoff = [layer xoff];
    int yoff = [layer yoff];

    redoRecord->index = undoRecord->index;
    redoRecord->snapshot = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, w, h) automatic:NO];
    redoRecord->rect = IntMakeRect(xoff, yoff, w, h);
    redoRecord->scaleX = scaleX;
    redoRecord->scaleY = scaleY;
    redoRecord->rotation = rotation;
    redoRecord->x = x;
    redoRecord->y = y;

    [[[document undoManager] prepareWithInvocationTarget:self] undoApplyTransform:redoRecord];

    [layer setOffsets:IntMakePoint(undoRecord->rect.origin.x, undoRecord->rect.origin.y)];
    [layer setMarginLeft:0 top:0 right:undoRecord->rect.size.width - [layer width] bottom:undoRecord->rect.size.height - [layer height]];
    [[layer seaLayerUndo] restoreSnapshot:undoRecord->snapshot automatic:NO];

    scaleX = scaleY = 1;
    rotation = 0;
    x = y = 0;

    [self updateButtons];
    [[document helpers] layerBoundariesChanged:undoRecord->index];
}

- (NSAffineTransform*)transform
{
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:x+tempX yBy:y+tempY];
    [tx rotateByRadians:(rotation + tempRotation)];
    [tx scaleXBy:(scaleX * tempScaleX) yBy:(scaleY * tempScaleY)];
    return tx;
}

- (void)updateButtons
{
    SeaContent *contents = [document contents];
    SeaLayer *layer = [contents activeLayer];

    int width = [contents width];
    int height = [contents height];

    bool changed = scaleX != 1.0 || scaleY !=1.0 || rotation != 0.0 || x!=0 || y!=0;

    IntRect bounds = [self bounds:layer];

    bool needsFit = bounds.origin.x<0 || bounds.origin.y<0 || bounds.origin.x+bounds.size.width>width || bounds.origin.y+bounds.size.height>height;

    [scaleToFitButton setEnabled:needsFit];

    [mergeButton setEnabled:changed && [contents canLower:kActiveLayer]];
    [applyButton setEnabled:changed];
    [resetButton setEnabled:changed];
}

- (void)switchingTools:(BOOL)active
{
    if(active){
        [self updateButtons];
    } else {
        [self maybeAutoApply];
    }
}

- (void)endLineDrawing
{
    [self maybeAutoApply];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors*)cursors
{
    IntRect bounds = [self bounds];
    if(!IntPointInRect(p, bounds)) {
        [[cursors noopCursor] set];
        return;
    }
    [cursors handleRectCursors:bounds point:p cursor:[cursors noopCursor] ignoresMove:false];
    return;
}

- (void)aspectChanged
{
    // nothing to do
}


@end
