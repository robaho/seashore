#import "TextTool.h"
#import "SeaLayer.h"
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

@implementation TextTool

- (int)toolId
{
	return kTextTool;
}

- (id)init
{
    if(![super init])
        return NULL;

    textRect.size.width = textRect.size.height = 0;
    return self;
}

- (void)textRectChanged:(IntRect)dirty
{
    [[document helpers] selectionChanged:dirty];
}

- (void)switchingTools:(BOOL)active
{
    if(active) {
        SeaContent *contents = [document contents];

        if(textRect.size.width==0 || textRect.size.height==0){
            textRect.size.width = [contents width]/3;
            textRect.size.height = [contents height]/3;
            textRect.origin.x = textRect.size.width;
            textRect.origin.y = textRect.size.height;
        }
    }
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if(textRect.size.width > 0 && textRect.size.height > 0){
        [self mouseDownAt: where
                  forRect: textRect
             withMaskRect: IntZeroRect
                  andMask: NULL];
    }

    if(![self isMovingOrScaling]){
        SeaLayer *activeLayer;

        // Make where appropriate
        activeLayer = [[document contents] activeLayer];
        where.x += [activeLayer xoff];
        where.y += [activeLayer yoff];

        // Check if location is in existing rect
        startPoint = where;

        textRect.origin.x = startPoint.x;
        textRect.origin.y = startPoint.y;
        textRect.size.width = 0;
        textRect.size.height = 0;

        intermediate = YES;
        [[document helpers] selectionChanged];
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    IntRect draggedRect = [self mouseDraggedTo: where
                                       forRect: textRect
                                       andMask: NULL];

    if(![self isMovingOrScaling]){

        SeaLayer *activeLayer;

        IntRect old = textRect;

        // Make where appropriate
        activeLayer = [[document contents] activeLayer];
        where.x += [activeLayer xoff];
        where.y += [activeLayer yoff];

        if (startPoint.x < where.x) {
            textRect.origin.x = startPoint.x;
            textRect.size.width = where.x - startPoint.x;
        }
        else {
            textRect.origin.x = where.x;
            textRect.size.width = startPoint.x - where.x;
        }

        if (startPoint.y < where.y) {
            textRect.origin.y = startPoint.y;
            textRect.size.height = where.y - startPoint.y;
        }
        else {
            textRect.origin.y = where.y;
            textRect.size.height = startPoint.y - where.y;
        }

        [self textRectChanged:IntSumRects(old,textRect)];
    } else {
        if(translating){
            int xoff = where.x-moveOrigin.x;
            int yoff = where.y-moveOrigin.y;

            [self setTextRect:IntMakeRect(textRect.origin.x +xoff,textRect.origin.y + yoff,textRect.size.width,textRect.size.height)];
            moveOrigin = where;
        } else {
            if(draggedRect.size.width < 0){
                draggedRect.origin.x += draggedRect.size.width;
                draggedRect.size.width *= -1;
            }

            if(draggedRect.size.height < 0){
                draggedRect.origin.y += draggedRect.size.height;
                draggedRect.size.height *= -1;
            }
            [self setTextRect:draggedRect];
        }
    }

}

- (IBAction)mergeWithLayer:(id)sender {
    CGContextRef ctx = [[document whiteboard] overlayCtx];
    CGContextSaveGState(ctx);
    SeaLayer *layer = [[document contents] activeLayer];
    CGContextTranslateCTM(ctx,-[layer xoff],-[layer yoff]);
    [self drawText:ctx];
    CGContextRestoreGState(ctx);

    [[document whiteboard] setOverlayOpacity:255];
    [[document whiteboard] setOverlayBehaviour:kNormalBehaviour];
    [[document helpers] overlayChanged:[layer translateView:textRect]];
    [[document helpers] applyOverlay];

    [options reset];
}

- (IBAction)addAsNewLayer:(id)sender {
    IntRect r = [self textRect];
    int spp = [[document contents] spp];
    unsigned char *data = calloc(r.size.width*r.size.height,spp);
    CGContextRef ctx = CGBitmapContextCreate(data, r.size.width, r.size.height, 8, r.size.width*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(ctx, 0, r.size.height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, -r.origin.x, -r.origin.y);
    [self drawText:ctx];

    unpremultiplyBitmap(spp, data, data, r.size.width*r.size.height);

    SeaLayer *layer = [[SeaLayer alloc] initWithDocument:document rect:r data:data spp:[[document contents] spp]];
    [layer trimLayer];

    NSString *text = [options text];

    NSMutableString *name = [[NSMutableString alloc] initWithString:text];
    for(int i=0;i<[name length];i++) {
        if([name characterAtIndex:i]<=32){
            [name replaceCharactersInRange:NSMakeRange(i,1) withString:@"."];
        }
    }
    [layer setName:name];
    [[document contents] addLayerObject:layer];
    
    [options reset];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [self mouseDraggedTo:where withEvent:event];

    scalingDir = kNoDir;
    translating = NO;
    intermediate = NO;

    [options activate:document];

    [[document helpers] selectionChanged];
}

- (void)changeFont:(id)sender
{
    [options changeFont:sender];
}

- (IntRect)textRect
{
    return textRect;
}

- (void)setTextRect:(IntRect)newTextRect
{
    IntRect old = textRect;
    textRect = newTextRect;
    [self textRectChanged:IntSumRects(old,textRect)];
}

- (void)drawText:(CGContextRef)ctx
{
    NSString *text = [options text];

    if(IntRectIsEmpty(textRect))
        return;

    NSRect r = IntRectMakeNSRect(textRect);

    id activeTexture = [[document textureUtility] activeTexture];

    int outline = [options outline];
    float lineSpacing = [options lineSpacing];
    int spp = [[document contents] spp];

    NSColor *color;
    if ([options useTextures])
        color = [activeTexture textureAsNSColor:(spp == 4)];
    else
        color = [[document contents] foreground];

    id fontManager = [NSFontManager sharedFontManager];

    NSFont *font = [fontManager selectedFont];
    if (font == NULL) {
        return;
    }

    float size = [font pointSize];

    size = size * [[document contents] yres] / 72.0;

    font = [NSFont fontWithDescriptor:[font fontDescriptor] size:size];

    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:[options alignment]];
    [paraStyle setLineHeightMultiple:lineSpacing];

    [attrs setValue:paraStyle forKey:NSParagraphStyleAttributeName];
    [attrs setValue:font forKey:NSFontAttributeName];
    [attrs setValue:color forKey:NSForegroundColorAttributeName];

    if(outline)
        [attrs setValue:[NSNumber numberWithInt:outline] forKey:NSStrokeWidthAttributeName];

    NSGraphicsContext *old = [NSGraphicsContext currentContext];
    NSGraphicsContext *gctx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:TRUE];
    [NSGraphicsContext setCurrentContext:gctx];
    NSRectClip(r);
    NSAffineTransform *tf = [NSAffineTransform transform];
    [tf translateXBy:0 yBy:([font xHeight] * lineSpacing)];
    [tf concat];
    [text drawInRect:r withAttributes:attrs];
    [NSGraphicsContext setCurrentContext:old];
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
    if(!IntRectIsEmpty(textRect)){
        return [cursors handleRectCursors:textRect point:p cursor:[NSCursor IBeamCursor]];
    }
    [[NSCursor IBeamCursor] set];
}

@end
