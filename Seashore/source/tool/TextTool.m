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
#import "SeaSelection.h"

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
    if([options useSelectionAsBounds])
        return;

    [self mouseDownAt: where
              forRect: textRect
         withMaskRect: IntZeroRect
              andMask: NULL];

    textRect = [super postScaledRect];
    [[document helpers] selectionChanged];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    if([options useSelectionAsBounds])
        return;
    IntRect draggedRect = [self mouseDraggedTo: where
                                       forRect: textRect
                                       andMask: NULL];

    IntRect old = textRect;
    textRect = draggedRect;
    [self textRectChanged:IntSumRects(old,textRect)];
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    if([options useSelectionAsBounds])
        return;
    [self mouseDraggedTo:where withEvent:event];
    [self mouseUpAt:where forRect:IntZeroRect andMask:NULL];
    [options activate:document];
    [[document helpers] selectionChanged];
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

- (void)changeFont:(id)sender
{
    [options changeFont:sender];
}

- (IntRect)textRect
{
    if([options useSelectionAsBounds])
        return [[document selection] maskRect];
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
    IntRect tr = [self textRect];

    if(IntRectIsEmpty(tr))
        return;

    NSRect r = IntRectMakeNSRect(tr);

    CGMutablePathRef path=CGPathCreateMutable();
    if([options useSelectionAsBounds]){
        CGPathRef maskPath = [[document selection] maskPath];
        CGAffineTransform tx = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
        tx = CGAffineTransformTranslate(tx,0,-CGPathGetBoundingBox(maskPath).size.height);
        CGPathAddPath(path,&tx,maskPath);
    } else {
        CGPathAddRect(path, NULL,CGRectMake(0,0,r.size.width,r.size.height));
    }

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
    [paraStyle setLineBreakMode:NSLineBreakByWordWrapping];
//    [paraStyle setParagraphSpacingBefore:[options margins]];

    [attrs setValue:paraStyle forKey:NSParagraphStyleAttributeName];
    [attrs setValue:font forKey:NSFontAttributeName];
    [attrs setValue:color forKey:NSForegroundColorAttributeName];

    if(outline)
        [attrs setValue:[NSNumber numberWithInt:outline] forKey:NSStrokeWidthAttributeName];

    CGContextSaveGState(ctx);

    NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paraStyle2 = [[NSMutableParagraphStyle alloc] init];
    [paraStyle2 setLineSpacing:0];
    [paraStyle2 setParagraphSpacing:0];
    [paraStyle2 setMinimumLineHeight:[options verticalMargin]];
    [attrs2 setValue:paraStyle2 forKey:NSParagraphStyleAttributeName];

    CGContextTranslateCTM(ctx,0,r.size.height);
    CGContextScaleCTM(ctx,1,-1);
    CGContextTranslateCTM(ctx,r.origin.x,-r.origin.y);

    NSString *withPara = [NSString stringWithFormat:@"\n%@",text];

    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:withPara attributes:attrs];

    [s setAttributes:attrs2 range:NSMakeRange(0,1)];

    CFAttributedStringRef asf = (__bridge_retained CFAttributedStringRef)s;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(asf);
    CFRelease(asf);

    NSMutableDictionary *frame_attrs = [NSMutableDictionary dictionary];
//    [frame_attrs setValue:@([options margins]) forKey:kCTFramePathWidthAttributeName];

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0, 0),path,(__bridge CFDictionaryRef)frame_attrs);

    CTFrameDraw(frame, ctx);

    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);

    CGContextRestoreGState(ctx);

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
    if(![options useSelectionAsBounds] && !IntRectIsEmpty(textRect)){
        return [cursors handleRectCursors:textRect point:p cursor:[NSCursor IBeamCursor]];
    }
    [[NSCursor IBeamCursor] set];
}

- (bool)canResize
{
    return ![options useSelectionAsBounds];
}

@end
