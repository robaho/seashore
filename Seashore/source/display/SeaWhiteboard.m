#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>

#import "SeaContent.h"
#import "SeaController.h"
#import "SeaDocument.h"
#import "SeaLayer.h"
#import "SeaLayerUndo.h"
#import "SeaSelection.h"
#import "SeaView.h"
#import "SeaWhiteboard.h"
#import "StandardMerge.h"
#import "StatusUtility.h"
#import "ToolboxUtility.h"
#import "SeaPrefs.h"
#import "AlphaToGrayFilter.h"
#import "SeaWindowContent.h"
#import "StandardMerge.h"
#import "DebugView.h"

#import <objc/runtime.h>

dispatch_queue_t queue;
dispatch_group_t group;

#define TILE_SIZE 64

#define SINGLE_THREADED FALSE

/**
 *  Gets a list of all methods on a class (or metaclass)
 *  and dumps some properties of each
 *
 *  @param clz the class or metaclass to investigate
 */
void DumpObjcMethods(Class clz) {

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);

    printf("Found %d methods on '%s'\n", methodCount, class_getName(clz));

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];

        printf("\t'%s' has method named '%s' of encoding '%s'\n",
               class_getName(clz),
               sel_getName(method_getName(method)),
               method_getTypeEncoding(method));

        /**
         *  Or do whatever you need here...
         */
    }

    free(methods);
}

@implementation SeaWhiteboard

- (id)initWithDocument:(id)doc {

  self = [super init];

  document = doc;

  checkerboard = [NSImage imageNamed:@"checkerboard"];

  proofProfile = NULL;

    mutex = [[NSObject alloc] init];

    if (queue == NULL) {
        queue = dispatch_queue_create("SeaWhiteboard", DISPATCH_QUEUE_CONCURRENT);
        group = dispatch_group_create();
    }

    renderSem = dispatch_semaphore_create(0);
    SeaWhiteboard *ref = self;
    dispatch_async(queue, ^{
        [ref renderLoop];
    });

  [self readjust];

  [self setCanDrawConcurrently:TRUE];

  return self;
}

- (NSColor *) getPixelX:(int)x Y:(int)y
{
    if(x<0 || x>=width || y<0 || y>=height)
        return NULL;

    unsigned char *pixelData = CGBitmapContextGetData(dataCtx) + (y*CGBitmapContextGetBytesPerRow(dataCtx)) + x*SPP;
    float alpha = pixelData[alphaPos];

    if(alpha==0)
        return [NSColor colorWithRed:0 green:0 blue:0 alpha:0];

    return [NSColor colorWithRed:pixelData[CR]/alpha green:pixelData[CG]/alpha blue:pixelData[CB]/alpha alpha:pixelData[alphaPos]/255.0];
}

- (BOOL)isFlipped
{
    return TRUE;
}

- (void)dealloc {
    if (overlay) free(overlay);
    if (replace) free(replace);

    CGContextRelease(overlayCtx);
    CGContextRelease(dataCtx);
}

- (void)setOverlayBehaviour:(int)value {
  overlayBehaviour = value;
}

- (void)setOverlayOpacity:(int)value {
  overlayOpacity = value;
  overlayOpacity_float = overlayOpacity / 255.0;
}

- (void)overlayModified:(IntRect)layerRect {
    if(LOG_PERFORMANCE) {
        NSLog(@"overlay modified %@",NSStringFromIntRect(layerRect));
    }
    SeaLayer *layer = [[document contents] activeLayer];

    if (IntRectIsEmpty(overlayModifiedRect)) {
        overlayModifiedRect = layerRect;
    } else {
        overlayModifiedRect = IntSumRects(overlayModifiedRect, layerRect);
    }

    @synchronized(self) {
        if (IntRectIsEmpty(tempOverlayModifiedRect)) {
            tempOverlayModifiedRect = layerRect;
        } else {
            tempOverlayModifiedRect = IntSumRects(tempOverlayModifiedRect, layerRect);
        }
    }

    dispatch_semaphore_signal(renderSem); // will pass tempOverlayModifiedRect to whiteboardModifiedRect when it runs
}

- (BOOL)isOpaque
{
    return TRUE;
}

- (void)setNeedsDisplay:(BOOL)needsDisplay
{
    [super setNeedsDisplay:needsDisplay];
}

- (void)mergeOverlay0:(unsigned char *)dest rect:(IntRect)r
{
    SeaLayer *layer = [[document contents] activeLayer];

    int lw = layer_width;
    int lh = layer_height;

    unsigned char *ld = (unsigned char*)[layer_data bytes];

    int xoff = [layer xoff];
    int yoff = [layer yoff];

    int selectedChannel = [[document contents] selectedChannel];
    bool selectionActive = [[document selection] active];

    IntRect maskRect = [[document selection] maskRect];
    unsigned char *mask = [[document selection] mask];

    for(int row=0;row<r.size.height;row++){
        int offset = (r.origin.y+row)*lw + r.origin.x;

        unsigned char *dpos = dest+(offset)*SPP;
        unsigned char *opos = overlay+(offset)*SPP;
        unsigned char *lpos = ld+(offset)*SPP;
        unsigned char *rpos = replace+offset;

        for(int col=0;col<r.size.width;col++){
            unsigned char opacity = overlayOpacity;

            if(overlayBehaviour==kReplacingBehaviour) {
                opacity = *rpos;
            } else if (overlayBehaviour==kMaskingBehavior) {
                int t1;
                opacity = int_mult(opacity, *rpos, t1);
            }

            IntPoint p = IntMakePoint(col+r.origin.x+xoff,row+r.origin.y+yoff);

            if(selectionActive) {
                if(!IntPointInRect(p,maskRect)) {
                    opacity=0;
                } else {
                    int t1;
                    unsigned char opacity0 = mask[(p.y-maskRect.origin.y)*maskRect.size.width+(p.x-maskRect.origin.x)];
                    opacity = int_mult(opacity,opacity0,t1);
                }
            }

            switch(selectedChannel) {
                case(kAllChannels):
                    switch(overlayBehaviour){
                        case kReplacingBehaviour:
                            replace_pm(opos,lpos,dpos,opacity);
                            break;
                        case kErasingBehaviour:
                            erase_pm(opos,lpos,dpos,opacity);
                            break;
                        default:
                            merge_pm(opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
                case(kAlphaChannel):
                    switch(overlayBehaviour){
                        case kReplacingBehaviour:
                            replace_alpha_pm(opos,lpos,dpos,opacity);
                        default:
                            merge_alpha_pm(opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
                case(kPrimaryChannels):
                    switch(overlayBehaviour){
                        case kReplacingBehaviour:
                            replace_primary_pm(opos,lpos,dpos,opacity);
                        default:
                            merge_primary_pm(opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
            }
            dpos+=SPP;
            opos+=SPP;
            lpos+=SPP;
            rpos++;
        }
    }
}

- (void)mergeOverlay:(unsigned char *)dest rect:(IntRect)r
{
    @synchronized(mutex) {
        int cores = MAX([[NSProcessInfo processInfo] activeProcessorCount],1);

        if(SINGLE_THREADED || cores==1){
            return [self mergeOverlay0:dest rect:r];
        } else {
            dispatch_group_t group = dispatch_group_create();

            int th = MAX(r.size.height / cores,8);
            for(int y=0;y<r.size.height;y+=th) {
                int height = MIN(th,r.size.height-y);
                IntRect r0 = IntMakeRect(r.origin.x,y+r.origin.y,r.size.width,height);
                dispatch_group_async(group, queue, ^{
                    [self mergeOverlay0:dest rect:r0];
                });
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        }
    }
}

- (void)mergeOverlayToTemp
{
    if(![temp length])
        return;

    int lw = layer_width;
    int lh = layer_height;

    IntRect r;

    @synchronized(self) {
        r = tempOverlayModifiedRect;
        tempOverlayModifiedRect = IntZeroRect;
    }

    r = IntConstrainRect(r,IntMakeRect(0,0,lw,lh));

    if(IntRectIsEmpty(r)) {
        return;
    }

    long start = getCurrentMillis();
    [self mergeOverlay:[temp bytes] rect:r];
    if(LOG_PERFORMANCE) {
        NSLog(@"whiteboard merge overlay %ld %@",getCurrentMillis()-start,NSStringFromIntRect(r));
    }
    @synchronized(self) {
        SeaLayer *layer = [[document contents] activeLayer];
        IntRect wr = IntOffsetRect(r, [layer xoff], [layer yoff]);
        if(IntRectIsEmpty(whiteboardModifiedRect)) {
            whiteboardModifiedRect = wr;
        } else {
            whiteboardModifiedRect = IntSumRects(whiteboardModifiedRect,wr);
        }
    }
}

- (void)drawChannelLayer:(CGContextRef)context withImage:(NSData *)data
{
    int channel = [[document contents] selectedChannel];

    int lw = layer_width;
    int lh = layer_height;

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,[data bytes],lw*lh*SPP,NULL);
    CGImageRef image = CGImageCreate(lw,lh,8,8*SPP,lw*SPP,COLOR_SPACE,channel==kAlphaChannelView ? kCGImageAlphaFirst : kCGImageAlphaNoneSkipFirst,dp,nil,false,0);
    CGDataProviderRelease(dp);

    CGContextSaveGState(context);

    CGRect r = CGRectMake(0,0,lw,lh);

    CGContextSetAlpha(context,1.0);

    if(channel==kAlphaChannelView) {
        CGContextSetFillColorWithColor(context, CGColorCreateGenericRGB(1,1,1,1));
        CGContextFillRect(context, r);
        CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    } else {
        CGContextSetBlendMode(context, kCGBlendModeNormal);
    }

    CGContextDrawImage(context,r,image);
    CGImageRelease(image);
    CGContextRestoreGState(context);
}


- (BOOL)overlayModified
{
    return !IntRectIsEmpty(overlayModifiedRect);
}

- (void)drawRect:(NSRect)viewDirtyRect
{
    @synchronized(mutex) {
        viewDirtyRect = NSIntegralRectWithOptions(viewDirtyRect,NSAlignAllEdgesOutward|NSAlignRectFlipped);
        
        CGContextRef nsCtx = [[NSGraphicsContext currentContext] graphicsPort];
        
        [self drawBackground:nsCtx rect:viewDirtyRect];
        
        float magnification = [[document scrollView] magnification];
        
        if ([[SeaController seaPrefs] smartInterpolation]) {
            if (magnification > 2) {
                CGContextSetInterpolationQuality(nsCtx, kCGInterpolationNone);
            } else {
                CGContextSetInterpolationQuality(nsCtx, kCGInterpolationHigh);
            }
        } else {
            CGContextSetInterpolationQuality(nsCtx, kCGInterpolationNone);
        }
        
        [self drawInContext:nsCtx dirty:viewDirtyRect proofing:true];
    }
    [[document histogram] performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

static void patternCallback(void *info, CGContextRef context) {
    CGImageRef imageRef = (CGImageRef)info;
    CGContextDrawImage(context, CGRectMake(0, 0, 32, 32), imageRef);
}

- (void)drawBackground:(CGContextRef)ctx rect:(NSRect)dirtyRect
{
    static const CGPatternCallbacks callbacks = { .drawPattern = patternCallback};
    static CGPatternRef pattern;
    static float pattern_magnification = 0;
    static CGColorSpaceRef patternSpace = nil;

    float magnification = [[document scrollView] magnification];

    CGRect rect = CGRectMake(0,0,[[document contents] width],[[document contents] height]);

    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);

    if ([[document whiteboard] whiteboardIsLayerSpecific]) {
        CGContextSetFillColorWithColor(ctx, [[NSColor windowBackgroundColor] CGColor]);
        CGContextFillRect(ctx,rect);
    }
    else {
        if([(SeaPrefs *)[SeaController seaPrefs] useCheckerboard]){
            CGImageRef image = [checkerboard CGImageForProposedRect:NULL context:NULL hints:NULL];

            if(magnification!=pattern_magnification) {
                CGAffineTransform tx = CGAffineTransformIdentity;
                tx = CGAffineTransformScale(tx, 0.5/magnification,0.5/magnification);
                CGPatternRelease(pattern);
                pattern = CGPatternCreate(image,CGRectMake(0,0,32,32), tx, 32, 32,kCGPatternTilingConstantSpacing,TRUE,&callbacks);
                pattern_magnification = magnification;
            }
            if(patternSpace==nil){
                patternSpace = CGColorSpaceCreatePattern(NULL);
            }
            CGContextSetFillColorSpace(ctx, patternSpace);
            double alpha = 1.0;
            CGContextSetFillPattern(ctx, pattern, &alpha);
            CGContextFillRect(ctx,[self bounds]);
        }else{
            CGContextSetFillColorWithColor(ctx, [[(SeaPrefs *)[SeaController seaPrefs] transparencyColor] CGColor]);
            CGContextFillRect(ctx,rect);
        }
    }
}


- (void)drawInContext:(CGContextRef)nsCtx dirty:(NSRect)viewDirtyRect proofing:(BOOL)proofing
{
    SeaLayer* activeLayer = [[document contents] activeLayer];

    if(proofing && [self whiteboardIsLayerSpecific]) {
        [activeLayer transformContext:nsCtx];
        if([self overlayModified]) {
            [self drawChannelLayer:nsCtx withImage:temp];
        }
        else {
            [self drawChannelLayer:nsCtx withImage:[activeLayer layerData]];
        }
        return;
    }

    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;

    CGContextTranslateCTM(nsCtx,0,height);
    CGContextScaleCTM(nsCtx,1,-1);

    CGImageRef img = CGBitmapContextCreateImage(dataCtx);
    CGRect bounds = CGImageGetBounds(img);

    if(proofing && proofProfile) {
        [self drawProof:viewDirtyRect src:img dst:nsCtx];
    } else {
        CGContextDrawImage(nsCtx, bounds, img);
    }
    CGImageRelease(img);

    if(LOG_PERFORMANCE)
        NSLog(@"whiteboard draw image/proof %ld %@",getCurrentMillis()-start,NSStringFromRect(viewDirtyRect));
}

- (void)drawProof:(NSRect)dirty src:(CGImageRef)src dst:(CGContextRef)dst
{

    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformTranslate(t, 0, height);
    t = CGAffineTransformScale(t, 1, -1);
    CGRect dirtyTX = CGRectApplyAffineTransform(dirty,t);

    CGImageRef img = CGImageCreateWithImageInRect(src, dirty);

    vImage_CGImageFormat format =
    {
        .bitsPerComponent=CGBitmapContextGetBitsPerComponent(proofCtx),
        .bitsPerPixel=CGBitmapContextGetBitsPerPixel(proofCtx),
        .colorSpace = CGBitmapContextGetColorSpace(proofCtx),
        .bitmapInfo = CGBitmapContextGetBitmapInfo(proofCtx),
        .renderingIntent=kCGRenderingIntentDefault
    };

    vImageBuffer_InitWithCGImage(
                                 &proofBuffer,
                                 &format,
                                 nil,
                                 img,
                                 kvImageNoAllocate);

    // Perform image-processing operations on RGB888 `buffer`.

    CGImageRef outImg = vImageCreateCGImageFromBuffer(
                                                           &proofBuffer,
                                                           &format,
                                                           nil,
                                                           nil,
                                                           kvImageNoFlags,
                                                      nil);
    CGContextDrawImage(dst, dirtyTX, outImg);
    CGImageRelease(outImg);
}

- (void)drawInData:(CGRect)viewDirtyRect
{
    CGContextRef ctx = CGBitmapContextCreate(CGBitmapContextGetData(dataCtx),width,height,8, CGBitmapContextGetBytesPerRow(dataCtx),CGBitmapContextGetColorSpace(dataCtx),CGBitmapContextGetBitmapInfo(dataCtx));
    CGContextTranslateCTM(ctx,0,height);
    CGContextScaleCTM(ctx,1,-1);
    CGContextClipToRect(ctx, viewDirtyRect);
    CGContextClearRect(ctx, viewDirtyRect);

    SeaContent *contents = [document contents];
    SeaLayer *activeLayer = [contents activeLayer];

    int layerCount = [contents layerCount];

    IntRect r = NSRectMakeIntRect(viewDirtyRect);

    bool rendered=TRUE;
    for (int i = layerCount-1; i>=0 && rendered; i--) {
        SeaLayer *layer = [[document contents] layer:i];
        if ([layer visible]) {
            if (layer == activeLayer) {
                if([self overlayModified]) {
                    rendered=[self compositeLayer:layer src:[temp bytes] rect:r dest:ctx];
                } else {
                    rendered=[self compositeLayer:layer src:[layer data] rect:r dest:ctx];
                }
            } else {
                rendered=[self compositeLayer:layer src:[layer data] rect:r dest:ctx];
            }
        }
    }

    CGContextRelease(ctx);

    if(rendered) {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            [self setNeedsDisplayInRect:viewDirtyRect];
        });
    }
}

- (void)copyLayerToTemp:(IntRect)r
{
    r = IntConstrainRect(r,IntMakeRect(0,0,layer_width,layer_height));
    int offset = (r.origin.y*layer_width+r.origin.x)*SPP;
    unsigned char *src = (unsigned char*)[layer_data bytes]+offset;
    unsigned char *dst = (unsigned char*)[temp bytes]+offset;
    int width = r.size.width*SPP;
    for(int row=0;row<r.size.height;row++) {
        memcpy(dst,src,width);
        src+=layer_width*SPP;
        dst+=layer_width*SPP;
    }
}

- (void)applyOverlay {
    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;

    @synchronized (mutex) {
        SeaLayer *layer = [[document contents] activeLayer];

        int lw = layer_width;
        int lh = layer_height;

        IntRect r = overlayModifiedRect;
        if(IntRectIsEmpty(r))
            return;

        r = IntConstrainRect(overlayModifiedRect,IntMakeRect(0,0,lw,lh));

        bool isSelectionActive = [[document selection] active];
        IntRect selectionRect = [[document selection] localRect];

        if (isSelectionActive) {
            r = IntConstrainRect(selectionRect, r);
        }

        if (r.size.width == 0 || r.size.height == 0) {
            goto finished;
        }

        [[layer seaLayerUndo] takeSnapshot:r automatic:YES];

        [self mergeOverlay:[layer_data bytes] rect:r];

        [self copyLayerToTemp:r];

        [layer markRasterized];

    finished:

        memset(overlay, 0, lw * lh * SPP);
        memset(replace, 0, lw * lh);

        IntRect temp = overlayModifiedRect;
        overlayModifiedRect = tempOverlayModifiedRect = IntZeroRect;

        overlayOpacity = 0;
        overlayBehaviour = kNormalBehaviour;

        [[document whiteboard] update:IntOffsetRect(temp, [layer xoff], [layer yoff])];
    }

  if(LOG_PERFORMANCE)
      NSLog(@"apply finished %ld",getCurrentMillis()-start);
}

- (void)clearOverlay {
    @synchronized (mutex) {
        SeaLayer *layer = [[document contents] activeLayer];

        int width = layer_width;
        int height = layer_height;

        [self copyLayerToTemp:overlayModifiedRect];

        memset(overlay, 0, width * height * SPP);
        memset(replace, 0, width * height);

        IntRect temp = overlayModifiedRect;
        overlayModifiedRect = tempOverlayModifiedRect = IntZeroRect;
        overlayOpacity = 0;
        overlayBehaviour = kNormalBehaviour;

        [self update:IntOffsetRect(temp, [layer xoff], [layer yoff])];
    }
}

- (unsigned char *)overlay {
  return overlay;
}

- (unsigned char *)replace {
  return replace;
}

- (BOOL)whiteboardIsLayerSpecific {
    SeaContent *content = [document contents];
    int channel = [content selectedChannel];
    bool trueview = [content trueView];

    return (channel == kPrimaryChannelsView || channel == kAlphaChannelView) && !trueview;
}

- (void)readjust {
    @synchronized(mutex) {
        // Resize the memory allocated to the data
        width = [[document contents] width];
        height = [[document contents] height];

        CGContextRelease(dataCtx);
        dataCtx = CGBitmapContextCreateWithData(NULL, width, height, 8, 0, COLOR_SPACE, kCGImageAlphaPremultipliedFirst, NULL, NULL);

        if(proofProfile) {
            CGContextRelease(proofCtx);
            CGColorSpaceRef csr = [proofProfile.cs CGColorSpace];
            int bitmapMode = CGColorSpaceGetModel(csr)==kCGColorSpaceModelCMYK ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast;
            // proofCtx is not used for rendering, only to describe the output format
            proofCtx = CGBitmapContextCreate(nil,width,height,8,0,csr,bitmapMode);
            proofBuffer.data = CGBitmapContextGetData(proofCtx);
            proofBuffer.width = width;
            proofBuffer.height = height;
            proofBuffer.rowBytes = CGBitmapContextGetBytesPerRow(proofCtx);
        }

        [self readjustLayer];
    }
    [self update];
}

- (void)readjustLayer {
    @synchronized (mutex) {
        SeaLayer *layer = [[document contents] activeLayer];

        layer_width = [layer width];
        layer_height = [layer height];
        layer_data = [layer layerData];

        int lw = layer_width;
        int lh = layer_height;

        if (overlay) free(overlay);

        int len = lw*lh*SPP;

        overlay = malloc(make_128(len));
        CHECK_MALLOC(overlay);
        memset(overlay, 0, len);

        CGContextRelease(overlayCtx);
        overlayCtx = CGBitmapContextCreateWithData(overlay, lw, lh, 8, lw*SPP, COLOR_SPACE, kCGImageAlphaPremultipliedFirst, NULL, NULL);
        CGContextTranslateCTM(overlayCtx, 0, lh);
        CGContextScaleCTM(overlayCtx, 1, -1);

        if (replace) free(replace);

        replace = malloc(make_128(lw*lh));
        CHECK_MALLOC(replace);
        memset(replace, 0, lw*lh);

        temp = [NSData dataWithBytes:[layer_data bytes] length:lw*lh*SPP];
    }

    [self update];
}

- (SeaColorProfile *)proofProfile {
  return proofProfile;
}

- (void)toggleSoftProof:(SeaColorProfile *)profile {
    proofProfile = profile;
    [[document docView] setNeedsDisplay:YES];
    [[document toolboxUtility] update:NO];
    [[document statusUtility] update];

    [self readjust];
}

- (void)update {
  [self update:IntMakeRect(0, 0, width, height)];
}

- (void)update:(IntRect)documentRect {
  if (documentRect.size.width == 0 || documentRect.size.height == 0) return;  // nothing to update

    @synchronized (self) {
        if (IntRectIsEmpty(whiteboardModifiedRect))
            whiteboardModifiedRect = documentRect;
        else
            whiteboardModifiedRect = IntSumRects(whiteboardModifiedRect, documentRect);
    }

    dispatch_semaphore_signal(renderSem);
}

- (void)shutdown
{
    exitRender=TRUE;
    dispatch_semaphore_signal(renderSem);
}

- (void)renderLoop
{
    while(!exitRender) {
        dispatch_semaphore_wait(renderSem, DISPATCH_TIME_FOREVER);
        [self render];
    }
}

- (void)render
{
    @synchronized (mutex) {
        [self mergeOverlayToTemp];

        IntRect dirty = IntZeroRect;

        @synchronized(self) {
            if(!IntRectIsEmpty(whiteboardModifiedRect)) {
                dirty = whiteboardModifiedRect;
                whiteboardModifiedRect = IntZeroRect;
            }
        }

        if(IntRectIsEmpty(dirty)) {
            return;
        }

        IntRect r = IntConstrainRect(dirty, IntMakeRect(0,0,width,height));

        long start = getCurrentMillis();

        if(!IntRectIsEmpty(r)) {
            int cores = MAX([[NSProcessInfo processInfo] activeProcessorCount],1);

            if(SINGLE_THREADED || cores==1){
                [self drawInData:IntRectMakeNSRect(r)];
            } else {
                dispatch_group_t group = dispatch_group_create();
                int th = MAX(r.size.height / cores,8);
                for(int y=0;y<r.size.height;y+=th) {
                    int height = MIN(th,r.size.height-y);
                    IntRect r0 = IntMakeRect(r.origin.x,y+r.origin.y,r.size.width,height);
                    dispatch_group_async(group, queue, ^{
                        [self drawInData:IntRectMakeNSRect(r0)];
                    });
                }
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            }

            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
                [[self->document docView] setNeedsDisplayInDocumentRect:dirty:16];
            });

            if(LOG_PERFORMANCE)
                NSLog(@"whiteboard drawInData %ld %@",getCurrentMillis()-start,NSStringFromIntRect(r));
        }
    }
}

- (NSImage *)printableImage
{
    NSBitmapImageRep *imageRep = [self image];

    NSImage *image = [[NSImage alloc] init];

    [imageRep setSize:NSMakeSize(width * (72.0 / [[document contents] xres]),
                               height * (72.0 / [[document contents] yres]))];

    [image addRepresentation:imageRep];

  return image;
}

- (NSBitmapImageRep*)sampleImage
{
    CGImageRef img = [self bitmap];
    CGRect r = NSMakeRect(width/2-80,height/2-80,160,160);
    CGImageRef sub = CGImageCreateWithImageInRect(img, r);

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:sub];

    CGImageRelease(sub);
    CGImageRelease(img);

    return rep;
}

- (NSBitmapImageRep*)image
{
    CGImageRef img = [self bitmap];
    if([[document contents] isGrayscale]){
        CGImageRef gray = convertToGA(img);
        CGImageRelease(img);
        img = gray;
    }
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
    CGImageRelease(img);

    return rep;
}

- (CGImageRef)bitmap
{
    CGContextRef ctx = CreateImageContext(IntMakeSize(width,height));
    CGContextTranslateCTM(ctx,0,height);
    CGContextScaleCTM(ctx,1,-1);
    [self drawInContext:ctx dirty:CGRectMake(0,0,width,height) proofing:false];
    CGImageRef img = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return img;
}

- (NSData*)layerData
{
    if(![self overlayModified])
        return layer_data;
    return temp;
}

- (CGContextRef)dataCtx
{
    return dataCtx;
}

- (CGContextRef)overlayCtx
{
    return overlayCtx;
}

- (BOOL)compositeLayer:(SeaLayer *)layer src:(unsigned char *)srcPtr rect:(IntRect)r dest:(CGContextRef)ctx
{
    if([layer isComplexTransform]) {
        CGContextSetInterpolationQuality(ctx,kCGInterpolationNone);
        [layer drawLayer:ctx];
        return TRUE;
    }

    int opacity = [layer opacity];
    if (opacity == 0)
        return TRUE;

    unsigned char *destPtr = CGBitmapContextGetData(ctx);
    int bytesPerRow = CGBitmapContextGetBytesPerRow(ctx);

    IntRect copy = r;

    IntRect lrect = [layer globalBounds];
    r = IntConstrainRect(lrect,r);

    int lwidth = [layer width], mode = [layer mode];

    unsigned char tempSpace[4], tempSpace2[4];

    unsigned char *src = srcPtr + ((r.origin.y - lrect.origin.y) * lwidth + r.origin.x-lrect.origin.x)*SPP;
    unsigned char *dst = destPtr + (r.origin.y * bytesPerRow) + r.origin.x*SPP;

    for (int row = 0; row < r.size.height; row++) {

        unsigned char *src0 = src;
        unsigned char *dst0 = dst;

        if(row%10==0) {
            @synchronized(self) {
                if(!IntRectIsEmpty(whiteboardModifiedRect) && IntContainsRect(whiteboardModifiedRect, copy)) {
                    return FALSE;
                }
            }
        }

        for(int col=0;col<r.size.width;col++) {

            if(mode==kCGBlendModeNormal) {
                // Then merge the pixel in temporary memory with the destination pixel
                normalMerge(dst0, src0, opacity);
            } else {
                memcpy(tempSpace2,src0,SPP);
                memcpy(tempSpace,dst0,SPP);

                // Apply the appropriate effect using the source pixel
                selectMerge(mode, tempSpace, tempSpace2);

                // Then merge the pixel in temporary memory with the destination pixel
                normalMerge(dst0, tempSpace, opacity);
            }

            src0+=SPP;
            dst0+=SPP;
        }
        src += lwidth * SPP;
        dst += bytesPerRow;
    }
    return TRUE;
}

- (void)debugTempLayer
{
    NSLog(@"creating debugview for temp");
    CGContextRef tmp = CGBitmapContextCreateWithData([temp bytes], layer_width, layer_height, 8, layer_width*SPP, COLOR_SPACE, kCGImageAlphaPremultipliedFirst, NULL, NULL);

    [DebugView createWithContext:tmp];

    CGContextRelease(tmp);
}
- (void)debugDataCtx
{
    NSLog(@"creating debugview for data");
    [DebugView createWithContext:dataCtx];
}
- (void)debugOverlayCtx
{
    NSLog(@"creating debugview for overlay");
    [DebugView createWithContext:overlayCtx];
}


@end

