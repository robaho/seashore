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

    [layer applyTransform:[NSAffineTransform transform]];
}

- (void)switchingTools:(BOOL)active
{
    if(active) {
        SeaLayer *layer = [[document contents] activeLayer];
        if([layer isKindOfClass:SeaTextLayer.class]){
            SeaTextLayer *textLayer = (SeaTextLayer*)layer;
            [options setProperties:[textLayer properties]];
        } else {
            [options setProperties:[[TextProperties alloc] init]];
        }
    } else {
        hasUndo=FALSE;
        SeaTextLayer *layer = [self textLayer];
        if(layer) {
            // ensure bitmap is up to date for other tools
            [layer applyTransform:[NSAffineTransform transform]];
        }
    }
}

- (void)setBounds:(IntRect)bounds
{
    [[self textLayer] setBounds:bounds];
    [[document helpers] layerBoundariesChanged:[[self textLayer] index]];
}

- (NSBezierPath*)textPath
{
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return NULL;
    return layer.properties.textPath;
}

- (SeaTextLayer*)textLayer
{
    SeaLayer *layer = [[document contents] activeLayer];
    if([layer isKindOfClass:SeaTextLayer.class])
        return (SeaTextLayer*)layer;
    return NULL;
}

- (IntRect)bounds
{
    SeaTextLayer *layer = [self textLayer];
    if(!layer || [layer isRasterized])
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

    hasUndo = FALSE;
    
    [[document helpers] selectionChanged];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    SeaTextLayer *textLayer = [self textLayer];

    if(textLayer && IntPointInRect(where,[textLayer localRect])) {
        //editing text layer
        edittingLayer=TRUE;
        [options setProperties:textLayer.properties];
    }

    IntRect textRect = [self bounds];

    [self mouseDownAt: where
              forRect: textRect
         withMaskRect: IntZeroRect
              andMask: NULL];

    if(![super isMovingOrScaling]){
        SeaLayer *layer = [[document contents] activeLayer];
        IntPoint p = IntOffsetPoint(where,[layer xoff],[layer yoff]);
        edittingLayer=FALSE;
        SeaTextLayer *textLayer = [[SeaTextLayer alloc] initWithDocument:document];
        [textLayer setOffsets:p];
        [[document contents] addLayerObject:textLayer atIndex:[[document contents] activeLayerIndex]];
        [options setProperties:[textLayer properties]];
    }

    [[document helpers] selectionChanged];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect draggedRect = [self mouseDraggedTo: where
                                       forRect: [self bounds]
                                       andMask: NULL];

    [self setBounds:draggedRect];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self mouseUpAt:where forRect:IntZeroRect andMask:NULL];

    SeaTextLayer *layer = [self textLayer];
    IntRect textRect = [self bounds];

    if(!edittingLayer) {
        SeaContent *contents = [document contents];
        if(layer && (textRect.size.width<8 && textRect.size.height<8)){
            textRect.size.width = MIN([contents width]/3,[contents width]-textRect.origin.x);
            textRect.size.height = MIN([contents height]/3,[contents height]-textRect.origin.y);
            [self setBounds:textRect];
        }
        [self textLayer].properties = [options properties];
    } else {
        [[[document undoManager] prepareWithInvocationTarget:self] undoTextLayerBounds:layer bounds:textRect];
    }
    [options activate:document];
    [[document helpers] selectionChanged];
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
        textLayer.properties.textPath = [NSBezierPath bezierPathWithCGPath:path];
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
- (void)setOptions:(AbstractOptions*)newoptions
{
    options = (TextOptions*)newoptions;
}

- (void)updateCursor:(IntPoint)p cursors:(SeaCursors *)cursors
{
//    if(![options useSelectionAsBounds] && !IntRectIsEmpty([self bounds])){
//        return [cursors handleRectCursors:[self bounds] point:p cursor:[NSCursor IBeamCursor]];
//    }
    [[NSCursor IBeamCursor] set];
}

- (void)updateLayer
{
    SeaTextLayer *layer = [self textLayer];
    if(!layer)
        return;

    TextProperties *props = [options properties];

    NSString *oldText = layer.properties.text;
    if(!hasUndo && ![[layer properties] isEqualToProperties:props]) {
        hasUndo = TRUE;
        [[[document undoManager] prepareWithInvocationTarget:self] undoTextProperties:layer properties:[layer properties]];
    }
    layer.properties = props;

    if(![layer.properties.text isEqualToString:oldText]){
        [[document helpers] layerTitleChanged];
    }
}

@end
