//
//  SeaTextLayer.m
//  Seashore
//
//  Created by robert engels on 7/23/22.
//

#import "SeaDocument.h"
#import "SeaTextLayer.h"
#import "SeaTools.h"
#import "PositionTool.h"
#import "NSAffineTransform_Extensions.h"
#import "NSBezierPath_Extensions.h"
#import "SeaHelpers.h"

@implementation TextProperties
- (id)init
{
    self = [super init];
    _lineSpacing = 1;
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    TextProperties *copy = [[TextProperties alloc] init];
    copy.text = _text;
    copy.color = _color;
    copy.font = _font;
    copy.textPath = _textPath;
    copy.outline = _outline;
    copy.lineSpacing = _lineSpacing;
    copy.alignment = _alignment;
    copy.verticalMargin = _verticalMargin;

    return copy;
}

- (BOOL)isEqualToProperties:(TextProperties*)props
{
    return
        [_text isEqualToString:props.text] &&
        [_color isEqualTo:props.color] &&
        [_font isEqualTo:props.font] &&
        _outline == props.outline &&
        _lineSpacing == props.lineSpacing &&
        _alignment == props.alignment &&
        _verticalMargin == props.verticalMargin;
}

@end

@implementation SeaTextLayer

- (SeaTextLayer*)initWithDocument:(SeaDocument *)document
{
    self = [super initWithDocument:document];
    _properties = [[TextProperties alloc] init];
    return self;
}

- (SeaTextLayer*)initWithDocument:(SeaDocument *)document layer:(SeaLayer*)layer properties:(nonnull TextProperties *)props
{
    self = [super initWithDocument:document];
    _properties = [props copy];
    [self setBounds:[layer globalRect]];
    return self;
}

- (NSString*)name
{
    if([self isRasterized]) {
        return [super name];
    }
    if(!_properties.text || [_properties.text length]==0)
        return @"Empty text layer";
    return _properties.text;
}

- (void)updateBitmap
{

    if([self isRasterized])
        return;
    
    IntRect local = IntMakeRect(0,0,width,height);
    if(IntRectIsEmpty(local) || !_properties.text)
        return;

    CGContextRef bm = CGBitmapContextCreate([nsdata bytes],width,height,8, width*spp,COLOR_SPACE, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(bm,CGRectMake(0,0,width,height));

    CGMutablePathRef path=CGPathCreateMutable();
    if(_properties.textPath){
        CGPathRef maskPath = [_properties.textPath cgPath];
        CGRect bb =CGPathGetBoundingBox(maskPath);
        CGAffineTransform tx = CGAffineTransformScale(CGAffineTransformIdentity, width/bb.size.width,height/bb.size.height);
        tx = CGAffineTransformScale(tx, 1, -1);
        tx = CGAffineTransformTranslate(tx,0,-bb.size.height);
        CGPathAddPath(path,&tx,maskPath);
        CGPathRelease(maskPath);
    } else {
        CGPathAddRect(path, NULL,CGRectMake(0,0,local.size.width,local.size.height));
    }

    NSFont *font = _properties.font;
    float fontSize = [font pointSize] * ([[document contents] yres] / 72.0);
    font = [NSFont fontWithName:[font displayName] size:fontSize];

    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:_properties.alignment];
    [paraStyle setLineHeightMultiple:_properties.lineSpacing];
    [paraStyle setLineBreakMode:NSLineBreakByWordWrapping];

    [attrs setValue:paraStyle forKey:NSParagraphStyleAttributeName];
    [attrs setValue:font forKey:NSFontAttributeName];

//    [attrs setValue:_properties.color forKey:NSForegroundColorAttributeName];
//    [attrs setValue:_properties.color forKey:NSStrokeColorAttributeName];

    if(_properties.outline)
        [attrs setValue:[NSNumber numberWithInt:_properties.outline] forKey:NSStrokeWidthAttributeName];

    NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paraStyle2 = [[NSMutableParagraphStyle alloc] init];
    [paraStyle2 setLineSpacing:0];
    [paraStyle2 setParagraphSpacing:0];
    [paraStyle2 setMinimumLineHeight:_properties.verticalMargin];
    [attrs2 setValue:paraStyle2 forKey:NSParagraphStyleAttributeName];

    NSString *withPara = [NSString stringWithFormat:@"\n%@",_properties.text];
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:withPara attributes:attrs];

    [s setAttributes:attrs2 range:NSMakeRange(0,1)];

    CFMutableAttributedStringRef asf = (__bridge_retained CFMutableAttributedStringRef)s;

    // need to set color here for older OSX versions due to bug
    CFAttributedStringSetAttribute(asf,CFRangeMake(1,_properties.text.length),kCTForegroundColorAttributeName,_properties.color.CGColor);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(asf);
    CFRelease(asf);

    NSMutableDictionary *frame_attrs = [NSMutableDictionary dictionary];

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0, 0),path,(__bridge CFDictionaryRef)frame_attrs);

    CTFrameDraw(frame, bm);

    CGImageRef t = CGBitmapContextCreateImage(bm);
    CGImageRelease(t);

    CGContextRelease(bm);

    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);

    unpremultiplyBitmap(spp,[nsdata bytes],[nsdata bytes],width*height);

    image = NULL;
}

- (NSImage*)thumbnail
{
    if(rasterized) {
        return [super thumbnail];
    } else {
        return getTinted([NSImage imageNamed:@"textLayerTemplate"], [NSColor controlTextColor]);
    }
}

- (BOOL)canToggleAlpha
{
    return FALSE;
}

- (void)markRasterized
{
    [self setIsRasterized:TRUE];
}

- (bool)isRasterized
{
    return rasterized;
}

- (void)setIsRasterized:(bool)isRasterized
{
    if(rasterized!=isRasterized) {
        rasterized = isRasterized;
        if(rasterized) {
            [self setName:_properties.text];
        }
        [[[document undoManager] prepareWithInvocationTarget:self] setIsRasterized:!isRasterized];
    }
}

- (void)applyTransform:(NSAffineTransform *)tx
{
    [super applyTransform:tx];

    NSAffineTransformStruct s = [tx transformStruct];
    if(s.m11!=1 || s.m12!=0 || s.m21!=0 || s.m22!=1)
    {
        [self setIsRasterized:TRUE];
    }
}

- (void)setBounds:(IntRect)bounds
{
    int oldWidth = width;
    int oldHeight = height;

    xoff = bounds.origin.x;
    yoff = bounds.origin.y;
    width = MAX(bounds.size.width,1);
    height = MAX(bounds.size.height,1);

    if(oldWidth!=width || oldHeight!=height) {
        unsigned char *new_data = calloc(width*height*spp,1);
        CHECK_MALLOC(new_data);

        nsdata = [NSData dataWithBytesNoCopy:new_data length:width*height*spp];
        [self updateBitmap];
        [[document whiteboard] readjustLayer];
    }
}

- (bool)isTextLayer
{
    return true;
}

@end
