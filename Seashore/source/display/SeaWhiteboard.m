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

    unsigned char *pixelData = data + (width*y+x) * spp;

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
    if (data) free(data);
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

- (void)mergeOverlay0:(unsigned char *)dest rect:(IntRect)r
{
    SeaLayer *layer = [[document contents] activeLayer];
    int lw = [layer width];
    int lh = [layer height];
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
        unsigned char *lpos = [layer data]+(offset)*spp;
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

//    CGImageRef img = CGBitmapContextCreateImage(overlayCtx);

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

- (void)drawLayerWithOverlay:(CGContextRef) ctx layer:(SeaLayer*)layer
{
    int lw = [layer width];
    int lh = [layer height];

    int xoff = [layer xoff];
    int yoff = [layer yoff];

    if(![temp length])
        return;

    unsigned char *data = [temp bytes];

    if(!IntRectIsEmpty(tempOverlayModifiedRect)) {
        tempOverlayModifiedRect = IntConstrainRect(tempOverlayModifiedRect,IntMakeRect(0,0,lw,lh));
        [self mergeOverlay:data rect:tempOverlayModifiedRect];
        tempOverlayModifiedRect = IntZeroRect;
    }

    CGContextSaveGState(ctx);

    CGDataProviderRef dp = CGDataProviderCreateWithData(NULL,data,lw*lh*spp,NULL);
    CGImageRef img = CGImageCreate(lw,lh,8,8*spp,lw*spp,COLOR_SPACE,kCGImageAlphaLast,dp,nil,false,0);
    CGDataProviderRelease(dp);

    CGContextSetAlpha(ctx,[layer opacity_float]);
    CGContextSetBlendMode(ctx,[layer mode]);
    CGContextTranslateCTM(ctx,xoff,yoff+lh);
    CGContextScaleCTM(ctx,1,-1);
    CGContextDrawImage(ctx,CGRectMake(0,0,lw,lh), img);
    CGImageRelease(img);
    CGContextRestoreGState(ctx);
}

- (BOOL)overlayModified
{
    return !IntRectIsEmpty(overlayModifiedRect);
}

- (void)drawRect:(NSRect)viewDirtyRect
{
    viewDirtyRect = NSIntegralRect(viewDirtyRect);

    CGContextRef nsCtx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextClipToRect(nsCtx, viewDirtyRect);
    [self drawInContext:nsCtx dirty:viewDirtyRect];
    [[document histogram] performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
}

- (void)drawInContext:(CGContextRef)nsCtx dirty:(NSRect)viewDirtyRect
{
    long start = LOG_PERFORMANCE ? getCurrentMillis() : 0;

    CGContextSaveGState(dataCtx);
    CGContextClipToRect(dataCtx, viewDirtyRect);
    CGContextClearRect(dataCtx, viewDirtyRect);

    SeaContent *contents = [document contents];

    int layerCount = [contents layerCount];

    SeaLayer* activeLayer = [[document contents] activeLayer];

    for (int i = layerCount-1; i>=0; i--) {
        SeaLayer *layer = [[document contents] layer:i];
        if ([layer visible]) {
            if (layer == activeLayer) {
                if([self overlayModified]) {
                    [self drawLayerWithOverlay:dataCtx layer:layer];
                } else {
                    [layer drawLayer:dataCtx];
                }
            } else {
                [layer drawLayer:dataCtx];
            }
        }
    }

    CGContextRestoreGState(dataCtx);

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

    if(![self whiteboardIsLayerSpecific]) {
        CGContextTranslateCTM(nsCtx,0,height);
        CGContextScaleCTM(nsCtx,1,-1);

        CGImageRef img = CGBitmapContextCreateImage(dataCtx);
        if(proofProfile){
            CGImageRef section = CGImageCreateWithImageInRect(img, viewDirtyRect);
            CGColorSpaceRef csr = [proofProfile.cs CGColorSpace];
            int bitmapMode = CGColorSpaceGetModel(csr)==kCGColorSpaceModelCMYK ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast;
            CGContextRef pctx = CGBitmapContextCreate(nil,viewDirtyRect.size.width,viewDirtyRect.size.height,8,0,csr,bitmapMode);
            CGContextDrawImage(pctx, CGRectMake(0,0,viewDirtyRect.size.width,viewDirtyRect.size.height),section);
            CGImageRelease(section);
            CGImageRef img0 = CGBitmapContextCreateImage(pctx);
            CGRect txr = CGRectMake(viewDirtyRect.origin.x,height-viewDirtyRect.origin.y-viewDirtyRect.size.height,viewDirtyRect.size.width,viewDirtyRect.size.height);
            CGContextDrawImage(nsCtx,txr,img0);
            CGImageRelease(img0);
            CGContextRelease(pctx);
        } else {
            CGContextDrawImage(nsCtx, CGRectMake(0,0,width,height), img);
        }
        CGImageRelease(img);
    } else {
        if([self overlayModified]) {
            [activeLayer drawChannelLayer:nsCtx withImage:[temp bytes]];
        }
        else {
            [activeLayer drawChannelLayer:nsCtx withImage:nil];
        }
    }

    if(LOG_PERFORMANCE)
        NSLog(@"whiteboard draw %ld %@",getCurrentMillis()-start,NSStringFromRect(viewDirtyRect));
}

- (void)applyOverlay {
  SeaLayer *layer = [[document contents] activeLayer];

  int lw = [layer width];
  int lh = [layer height];

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

  [self mergeOverlay:[layer data] rect:r];

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

  int width = [layer width];
  int height = [layer height];

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

  // Revise the data
  if (data) free(data);
  data = malloc(make_128(width * height * spp));
  CHECK_MALLOC(data);

    CGContextRelease(dataCtx);
    dataCtx = CGBitmapContextCreateWithData(data, width, height, 8, width*spp, COLOR_SPACE, kCGImageAlphaPremultipliedLast, NULL, NULL);

    CGContextTranslateCTM(dataCtx, 0, height);
    CGContextScaleCTM(dataCtx, 1, -1);

  [self readjustLayer];
  [self update];
}

- (void)readjustLayer {
    SeaLayer *layer = [[document contents] activeLayer];

    int lw = [layer width];
    int lh = [layer height];

    if (overlay) free(overlay);

    int len = lw*lh*spp;
    
    if(len==0) {
        lw=lh=1;
        len=1;
    }

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

    unsigned char *data = [layer data];
    if(data) {
        temp = [NSData dataWithBytes:[layer data] length:lw*lh*spp];
    } else {
        temp = [NSData data];
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

- (NSBitmapImageRep*) sampleImage
{
    CGContextRef ctx = CGBitmapContextCreate(NULL,160,160,8,0,rgbCS,kCGImageAlphaPremultipliedLast);
    CGContextScaleCTM(ctx,1,-1);
    CGContextTranslateCTM(ctx,0,-160);

    CGContextTranslateCTM(ctx,-(width/2),-(height/2));
    [[self layer] renderInContext:ctx];

    CGImageRef img = CGBitmapContextCreateImage(ctx);

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];

    CGImageRelease(img);
    CGContextRelease(ctx);

    return rep;
}

- (NSBitmapImageRep*) bitmap
{
    CGImageRef img = CGBitmapContextCreateImage(dataCtx);
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];

    CGImageRelease(img);

    return rep;
}

- (unsigned char *)data {
    return data;
}

- (NSData*)layerData
{
    if(![self overlayModified])
        return [[[document contents] activeLayer] layerData];
    return temp;
}

- (CGContextRef)overlayCtx
{
    return overlayCtx;
}

@end

