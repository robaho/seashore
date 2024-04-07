#import "TextTool.h"
#import "SeaLayer.h"
#import "SeaTextLayer.h"
#import "SeaWhiteboard.h"
#import "SeaDocument.h"
#import "SeaContent.h"
#import "StandardMerge.h"
#import "SeaTools.h"
#import "SeaHelpers.h"
#import "TextOptions.h"
#import "SeaController.h"
#import "SeaPrefs.h"
#import "TextureUtility.h"
#import "SeaTexture.h"
#import "Bucket.h"
#import "OptionsUtility.h"
#import "SeaSelection.h"
#import "NSBezierPath_Extensions.h"

@implementation TextTool

- (void)awakeFromNib {
    options = [[TextOptions alloc] init:document];
}

- (int)toolId
{
	return kTextTool;
}

- (id)init
{
    if(![super init])
        return NULL;

    return self;
}

- (void)endLineDrawing
{
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return;

    [layer updateBitmap];
}

- (void)switchingTools:(BOOL)active
{
    if(active) {
        SeaLayer *layer = [[document contents] activeLayer];
        if([layer isTextLayer]){
            SeaTextLayer *textLayer = (SeaTextLayer*)layer;
            [options setProperties:[textLayer properties]];
        } else {
            [options setProperties:NULL];
        }
    } else {
        hasUndo=FALSE;
        SeaTextLayer *layer = [self textLayer];
        if(layer) {
            [layer updateBitmap];
        }
    }
}

- (void)setBounds:(IntRect)bounds
{
    IntRect dirty = textRect;
    if(edittingLayer) {
        dirty = [[self textLayer] globalRect];
        [[self textLayer] setBounds:bounds];
    }
    textRect = bounds;
    dirty = IntSumRects(dirty,textRect);
    [[document helpers] layerOffsetsChanged:dirty];
}

- (NSBezierPath*)textPath
{
    if(intermediate && !edittingLayer)
        return NULL;
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return NULL;
    return layer.properties.textPath;
}

- (SeaTextLayer*)textLayer
{
    SeaLayer *layer = [[document contents] activeLayer];
    if([layer isTextLayer])
        return (SeaTextLayer*)layer;
    return NULL;
}

- (IntRect)bounds
{
    if(intermediate) {
        return textRect;
    }
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return IntZeroRect;
    return [layer globalRect];
}

- (void)undoTextLayerBounds:(SeaTextLayer*)layer bounds:(IntRect)r
{
    if(!layer)
        return;

    [[[document undoManager] prepareWithInvocationTarget:self] undoTextLayerBounds:[self textLayer] bounds:[self bounds]];

    [layer setBounds:r];
    [[document helpers] layerBoundariesChanged:[layer index]];
}

- (void)undoTextProperties:(SeaTextLayer*)layer properties:(TextProperties*)props
{
    if(!layer)
        return;

    TextProperties* current = [layer properties];

    [[[document undoManager] prepareWithInvocationTarget:self] undoTextProperties:layer properties:current];

    layer.properties = props;
    [options setProperties:props];

    [self updateLayer];

    hasUndo = FALSE;
    
    [[document helpers] selectionChanged];
    [[document helpers] layerTitleChanged];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self mouseDownAt: where
              forRect: [self bounds]
         withMaskRect: IntZeroRect
              andMask: NULL];

    if(![super isMovingOrScaling]) {
        SeaLayer *layer = [[document contents] activeLayer];
        IntPoint p = IntOffsetPoint(where,[layer xoff],[layer yoff]);
        textRect = IntEmptyRect(p);
        edittingLayer=FALSE;
    } else {
        edittingLayer=TRUE;
        SeaTextLayer *textLayer = [self textLayer];
        [options setProperties:textLayer.properties];
        textRect = [textLayer globalRect];
    }

    [[document helpers] selectionChanged];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect dragged = [self mouseDraggedTo: where
                                       forRect: textRect
                                       andMask: NULL];

    IntRect dirty = textRect;
    textRect = dragged;
    dirty = IntSumRects(dirty,textRect);

    [[document helpers] selectionChanged:dirty];

    if(edittingLayer) {
        if(textRect.size.width == [[self textLayer] globalRect].size.width &&
           textRect.size.height == [[self textLayer] globalRect].size.height) {
            [self setBounds:textRect];
        } else {
            // only resize on interval to allow smoother dragging
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateBounds) object:nil];
            [self performSelector:@selector(updateBounds) withObject:nil afterDelay:.05 inModes:@[NSRunLoopCommonModes]];
        }
    }

}

- (void)updateBounds
{
    [self setBounds:textRect];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self mouseUpAt:where forRect:IntZeroRect andMask:NULL];
    [self setBounds:textRect];

    SeaTextLayer *layer = [self textLayer];

    if(!edittingLayer) {
        edittingLayer=TRUE;
        SeaContent *contents = [document contents];
        SeaTextLayer *textLayer = [[SeaTextLayer alloc] initWithDocument:document];
        if(textRect.size.width<8 && textRect.size.height<8){
            textRect.size.width = MIN([contents width]/3,[contents width]-textRect.origin.x);
            textRect.size.height = MIN([contents height]/3,[contents height]-textRect.origin.y);
        }
        textLayer.properties = [options properties];
        textLayer.properties.text = [[NSAttributedString alloc] init];
        [textLayer setBounds:textRect];
        [[document contents] addLayerObject:textLayer atIndex:[[document contents] activeLayerIndex]];
    } else {
        [[[document undoManager] prepareWithInvocationTarget:self] undoTextLayerBounds:layer bounds:textRect];
    }
    [options activate:document];
    [[document helpers] selectionChanged];
}

static void CGPathToBezierPathApplierFunction(void *info, const CGPathElement *element) {
    NSBezierPath *bezierPath = (__bridge NSBezierPath *)info;
    CGPoint *points = element->points;
    switch(element->type) {
        case kCGPathElementMoveToPoint: [bezierPath moveToPoint:points[0]]; break;
        case kCGPathElementAddLineToPoint: [bezierPath lineToPoint:points[0]]; break;
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = bezierPath.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [bezierPath curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
        case kCGPathElementAddCurveToPoint: [bezierPath curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]]; break;
        case kCGPathElementCloseSubpath: [bezierPath closePath]; break;
    }
}

static NSBezierPath* bezierPathWithCGPath(CGPathRef cgPath) {
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    CGPathApply(cgPath, (__bridge void *)bezierPath, CGPathToBezierPathApplierFunction);
    return bezierPath;
}

- (IBAction)setTextBoundsFromSelection:(id)sender {
    SeaTextLayer *textLayer = [self textLayer];
    if([self textLayer]==NULL) {
        if(![[document selection] active]) {
            return;
        }
        textLayer = [[SeaTextLayer alloc] initWithDocument:document];
        [[document contents] addLayerObject:textLayer atIndex:[[document contents] activeLayerIndex]];
        [options setProperties:[textLayer properties]];
    }
    if([[document selection] active]) {
        CGPathRef path = [[document selection] maskPath];
        if (@available(macOS 14.0, *)) {
            textLayer.properties.textPath = [NSBezierPath bezierPathWithCGPath:path];
        } else {
            textLayer.properties.textPath = bezierPathWithCGPath(path);
        }
        [self setBounds:[[document selection] maskRect]];
    } else {
        textLayer.properties.textPath = NULL;
    }
    [options setProperties:[textLayer properties]];
    [[document helpers] selectionChanged];
}

- (void)changeFont:(id)sender
{
    [options changeFont:sender];
}

- (AbstractOptions*)getOptions
{
    return options;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors *)cursors
{
    if(!IntRectIsEmpty([self bounds])){
        [cursors handleRectCursors:[self bounds] point:p cursor:[NSCursor IBeamCursor] ignoresMove:false];
        return;
    }
    [[NSCursor IBeamCursor] set];
}

- (void)updateLayer
{
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return;

    TextProperties *props = [options properties];
    NSString *oldText = [layer.properties.text string];

    NSLog(@"old %@ current %@",oldText,[props.text string]);

    if(!hasUndo && ![[layer properties] isEqualToProperties:props]) {
        hasUndo = TRUE;
        [[[document undoManager] prepareWithInvocationTarget:self] undoTextProperties:layer properties:[layer properties]];
    }
    layer.properties = props;

    [layer updateBitmap];
    [[document whiteboard] update:[layer globalRect]];

    if(![[layer.properties.text string] isEqualToString:oldText]){
        [[document helpers] layerTitleChanged];
    }
}

@end
