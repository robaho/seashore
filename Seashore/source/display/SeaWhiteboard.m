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

#import <objc/runtime.h>

dispatch_queue_t queue;
dispatch_group_t group;

#define TILE_SIZE 64

#define SINGLE_THREADED false

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

  proofProfile = NULL;

  [self readjust];

  if (queue == NULL) {
    queue = dispatch_queue_create("SeaWhiteboard", DISPATCH_QUEUE_CONCURRENT);
    group = dispatch_group_create();
  }

  [self setCanDrawConcurrently:TRUE];

  return self;
}

- (NSColor *) getPixelX:(int)x Y:(int)y
{
    if(x<0 || x>=width || y<0 || y>=height)
        return NULL;

    unsigned char *pixelData = CGBitmapContextGetData(dataCtx) + (y*CGBitmapContextGetBytesPerRow(dataCtx)) + x*spp;
    float alpha = pixelData[spp-1];

    if(alpha==0)
        return [NSColor colorWithRed:0 green:0 blue:0 alpha:0];

    if(spp==2){
        return [NSColor colorWithRed:pixelData[0]/alpha green:pixelData[0]/alpha blue:pixelData[0]/alpha alpha:pixelData[1]/255.0];
    } else {
        return [NSColor colorWithRed:pixelData[0]/alpha green:pixelData[1]/alpha blue:pixelData[2]/alpha alpha:pixelData[3]/255.0];
    }

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
    SeaLayer *layer = [[document contents] activeLayer];

    if (IntRectIsEmpty(overlayModifiedRect)) {
        overlayModifiedRect = layerRect;
    } else {
        overlayModifiedRect = IntSumRects(overlayModifiedRect, layerRect);
    }
    if (IntRectIsEmpty(tempOverlayModifiedRect)) {
        tempOverlayModifiedRect = layerRect;
    } else {
        tempOverlayModifiedRect = IntSumRects(tempOverlayModifiedRect, layerRect);
    }

    layerRect.origin.x += [layer xoff];
    layerRect.origin.y += [layer yoff];
    [self setNeedsDisplayInRect:IntRectMakeNSRect(layerRect)];
}

- (BOOL)isOpaque
{
    return FALSE;
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

        unsigned char *dpos = dest+(offset)*spp;
        unsigned char *opos = overlay+(offset)*spp;
        unsigned char *lpos = ld+(offset)*spp;
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
                            replace_pm(spp,opos,lpos,dpos,opacity);
                            break;
                        case kErasingBehaviour:
                            erase_pm(spp,opos,lpos,dpos,opacity);
                            break;
                        default:
                            merge_pm(spp,opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
                case(kAlphaChannel):
                    switch(overlayBehaviour){
                        case kReplacingBehaviour:
                            replace_alpha_pm(spp,opos,lpos,dpos,opacity);
                        default:
                            merge_alpha_pm(spp,opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
                case(kPrimaryChannels):
                    switch(overlayBehaviour){
                        case kReplacingBehaviour:
                            replace_primary_pm(spp,opos,lpos,dpos,opacity);
                        default:
                            merge_primary_pm(spp,opos,lpos,dpos,opacity);
                            break;
                    }
                    break;
            }
            dpos+=spp;
            opos+=spp;
            lpos+=spp;
            rpos++;
        }
    }
}

- (void)mergeOverlay:(unsigned char *)dest rect:(IntRect)r
{
    if(SINGLE_THREADED || (r.size.height <= TILE_SIZE && r.size.width <= TILE_SIZE)){
        return [self mergeOverlay0:dest rect:r];
    }
    int rows = (r.size.height-1) / TILE_SIZE + 1;
    int cols = (r.size.width-1) / TILE_SIZE + 1;

    for(int row=0;row<rows;row++)
        for(int col=0;col<cols;col++){
            int x = col*TILE_SIZE;
            int y = row*TILE_SIZE;
            int width = MIN(TILE_SIZE,r.size.width-x);
            int height = MIN(TILE_SIZE,r.size.height-y);
            IntRect r0 = IntMakeRect(x+r.origin.x,y+r.origin.y,width,height);
            dispatch_group_async(group, queue, ^{
                [self mergeOverlay0:dest rect:r0];
            });
        }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)mergeOverlayToTemp
{
    if(![temp length])
        return;

    int lw = layer_width;
    int lh = layer_height;

    if(!IntRectIsEmpty(tempOverlayModifiedRect)) {
        tempOverlayModifiedRect = IntConstrainRect(tempOverlayModifiedRect,IntMakeRect(0,0,lw,lh));
        [self mergeOverlay:[temp bytes] rect:tempOverlayModifiedRect];
        tempOverlayModifiedRect = IntZeroRect;
    }
}

- (void)drawChannelLayer:(CGContextRef)context withImage:(NSData *)data
{
    int channel = [[document contents] selectedChannel];

    int lw = layer_width;
    int lh = layer_height;

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,[data bytes],lw*lh*spp,NULL);
    CGImageRef image = CGImageCreate(lw,lh,8,8*spp,lw*spp,COLOR_SPACE,channel==kAlphaChannelView ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast,dp,nil,false,0);
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
    viewDirtyRect = NSIntegralRectWithOptions(viewDirtyRect,NSAlignAllEdgesOutward|NSAlignRectFlipped);

    CGContextRef nsCtx = [[NSGraphicsContext currentContext] graphicsPort];

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

    CGContextClipToRect(nsCtx, viewDirtyRect);
    [self drawInContext:nsCtx dirty:viewDirtyRect proofing:true];
    [[document histogram] performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

- (void)drawInContext:(CGContextRef)nsCtx dirty:(NSRect)viewDirtyRect proofing:(BOOL)proofing
{
    SeaLayer* activeLayer = [[document contents] activeLayer];

//    viewDirtyRect = NSIntegralRect(viewDirtyRect);

    [self mergeOverlayToTemp];

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

    CGRect r = viewDirtyRect;

    if(SINGLE_THREADED || (r.size.height <= TILE_SIZE && r.size.width <= TILE_SIZE)){
        [self drawInData:r];
    } else {
        int cores = [[NSProcessInfo processInfo] activeProcessorCount];
        cores = MAX(cores,1);

        int tw = MAX(r.size.width / cores,TILE_SIZE);
        int th = MAX(r.size.height / cores,TILE_SIZE);

        int y=0;
        while(y<r.size.height) {
            int x=0;
            int height = MIN(th,r.size.height-y);
            if(r.size.height-y-th<TILE_SIZE) {
                height = r.size.height-y;
            }
            while(x<r.size.width){
                int width = MIN(tw,r.size.width-x);
                if(width<=0 || height <=0)
                    continue;
                if(r.size.width-x-tw<TILE_SIZE) {
                    width = r.size.width-x;
                }
                IntRect r0 = IntMakeRect(x+r.origin.x,y+r.origin.y,width,height);
                dispatch_group_async(group, queue, ^{
                    [self drawInData:IntRectMakeNSRect(r0)];
                });
                x+=width;
            }
            y+=height;
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }

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
        NSLog(@"whiteboard draw %ld %@",getCurrentMillis()-start,NSStringFromRect(viewDirtyRect));
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

    for (int i = layerCount-1; i>=0; i--) {
        SeaLayer *layer = [[document contents] layer:i];
        if ([layer visible]) {
            if (layer == activeLayer) {
                if([self overlayModified]) {
                    [self compositeLayer:layer src:[temp bytes] rect:r dest:ctx];
                } else {
                    [self compositeLayer:layer src:[layer data] rect:r dest:ctx];
                }
            } else {
                [self compositeLayer:layer src:[layer data] rect:r dest:ctx];
            }
        }
    }

    CGContextRelease(ctx);
}

- (void)applyOverlay {
  SeaLayer *layer = [[document contents] activeLayer];

  int lw = layer_width;
  int lh = layer_height;

  IntRect r = overlayModifiedRect;
  if(IntRectIsEmpty(r))
      return;

  long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;

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

  [layer markRasterized];

finished:

  memset(overlay, 0, lw * lh * spp);
//  memset([temp bytes], 0, lw * lh * spp);
  memset(replace, 0, lw * lh);

  IntRect temp = overlayModifiedRect;
  overlayModifiedRect = tempOverlayModifiedRect = IntZeroRect;

  overlayOpacity = 0;
  overlayBehaviour = kNormalBehaviour;

  [[document whiteboard] update:IntOffsetRect(temp, [layer xoff], [layer yoff])];

  if(LOG_PERFORMANCE)
      NSLog(@"apply finished %ld",getCurrentMillis()-start);
}

- (void)clearOverlay {
  SeaLayer *layer = [[document contents] activeLayer];

  int width = layer_width;
  int height = layer_height;

  memset(overlay, 0, width * height * spp);
  memset(replace, 0, width * height);

  IntRect temp = overlayModifiedRect;
  overlayModifiedRect = tempOverlayModifiedRect = IntZeroRect;
  overlayOpacity = 0;
  overlayBehaviour = kNormalBehaviour;

  [self update:IntOffsetRect(temp, [layer xoff], [layer yoff])];
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
    // Resize the memory allocated to the data
    width = [[document contents] width];
    height = [[document contents] height];

    // Change the samples per pixel if required
    if (spp != [[document contents] spp]) {
        spp = [[document contents] spp];
    }

    CGContextRelease(dataCtx);
    dataCtx = CGBitmapContextCreateWithData(NULL, width, height, 8, 0, COLOR_SPACE, kCGImageAlphaPremultipliedLast, NULL, NULL);

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
    [self update];
}

- (void)readjustLayer {
    SeaLayer *layer = [[document contents] activeLayer];

    layer_width = [layer width];
    layer_height = [layer height];
    layer_data = [layer layerData];

    int lw = layer_width;
    int lh = layer_height;

    if (overlay) free(overlay);

    int len = lw*lh*spp;

    overlay = malloc(make_128(len));
    CHECK_MALLOC(overlay);
    memset(overlay, 0, len);

    CGContextRelease(overlayCtx);
    overlayCtx = CGBitmapContextCreateWithData(overlay, lw, lh, 8, lw*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast, NULL, NULL);
    CGContextTranslateCTM(overlayCtx, 0, lh);
    CGContextScaleCTM(overlayCtx, 1, -1);

    if (replace) free(replace);

    replace = malloc(make_128(lw*lh));
    CHECK_MALLOC(replace);
    memset(replace, 0, lw*lh);

    temp = [NSData dataWithBytes:[layer_data bytes] length:lw*lh*spp];

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

  if (IntRectIsEmpty(whiteboardModifiedRect))
    whiteboardModifiedRect = documentRect;
  else
    whiteboardModifiedRect = IntSumRects(whiteboardModifiedRect, documentRect);

  [self setNeedsDisplayInRect:IntRectMakeNSRect(documentRect)];
  [[document docView] setNeedsDisplayInDocumentRect:(documentRect):16];
}

- (NSImage *)printableImage
{
    NSBitmapImageRep *imageRep = [self bitmap];

    NSImage *image = [[NSImage alloc] init];

    [imageRep setSize:NSMakeSize(width * (72.0 / [[document contents] xres]),
                               height * (72.0 / [[document contents] yres]))];

    [image addRepresentation:imageRep];

  return image;
}

- (NSBitmapImageRep*)sampleImage
{
    CGImageRef img = [self bitmapCG];
    CGRect r = NSMakeRect(width/2-80,height/2-80,160,160);
    CGImageRef sub = CGImageCreateWithImageInRect(img, r);

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:sub];

    CGImageRelease(sub);
    CGImageRelease(img);

    return rep;
}

- (NSBitmapImageRep*)bitmap
{
    CGImageRef img = [self bitmapCG];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
    CGImageRelease(img);

    return rep;
}

- (CGImageRef)bitmapCG
{
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, spp*width, COLOR_SPACE, kCGImageAlphaPremultipliedLast);
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

- (CGContextRef)overlayCtx
{
    return overlayCtx;
}

- (void)compositeLayer:(SeaLayer *)layer src:(unsigned char *)srcPtr rect:(IntRect)r dest:(CGContextRef)ctx
{
    if([layer isComplexTransform]) {
        [layer drawLayer:ctx];
        return;
    }

    int opacity = [layer opacity];
    if (opacity == 0)
        return;

    unsigned char *destPtr = CGBitmapContextGetData(ctx);
    int bytesPerRow = CGBitmapContextGetBytesPerRow(ctx);

    IntRect lrect = [layer globalBounds];
    r = IntConstrainRect(lrect,r);

    int lwidth = [layer width], mode = [layer mode];
    unsigned char *ldata = srcPtr;

    unsigned char tempSpace[4], tempSpace2[4];

    unsigned char *src = ldata + ((r.origin.y - lrect.origin.y) * lwidth + r.origin.x-lrect.origin.x)*spp;
    unsigned char *dst = destPtr + (r.origin.y * bytesPerRow) + r.origin.x*spp;

    for (int row = 0; row < r.size.height; row++) {

        unsigned char *src0 = src;
        unsigned char *dst0 = dst;

        for(int col=0;col<r.size.width;col++) {

            memcpy(tempSpace2,src0,spp);
            memcpy(tempSpace,dst0,spp);

            if(mode==kCGBlendModeNormal) {
                // Then merge the pixel in temporary memory with the destination pixel
                normalMerge(spp, dst0, 0, tempSpace2, 0, opacity);
            } else {
                // Apply the appropriate effect using the source pixel
                selectMerge(mode, spp, tempSpace, 0, tempSpace2, 0);

                // Then merge the pixel in temporary memory with the destination pixel
                normalMerge(spp, dst0, 0, tempSpace, 0, opacity);
            }

            src0+=spp;
            dst0+=spp;
        }
        src += lwidth * spp;
        dst += bytesPerRow;
    }
}

@end

