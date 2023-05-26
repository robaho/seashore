#include "Bucket.h"
#include "StandardMerge.h"
#include <Accelerate/Accelerate.h>

#define kStackSizeIncrement 8192

#define TILE_SIZE 32

#define alphaPos 0

extern dispatch_queue_t queue;

typedef struct {
    int y,xl,xr,dy;
} entry;

typedef struct {
    entry *entries;
    int size;
    int count;
} stack;

void push(stack* s,entry e) {
    if(s->count==s->size) {
        s->size+=kStackSizeIncrement;
        s->entries = realloc(s->entries, sizeof(entry)*(s->size));
    }
    s->entries[s->count]=e;
    s->count++;
}
entry pop(stack* s) {
    s->count--;
    return s->entries[s->count];
}

inline BOOL inTolerance(unsigned char *base,unsigned char *color,unsigned char tolerance,int channel){
    int k,temp;
    if (channel == kAllChannels) {
        if (base[alphaPos] == 0)
            return YES;
        int r = base[CR]-color[CR];
        int b = base[CG]-color[CG];
        int g = base[CB]-color[CB];
        double dist = sqrt(2*r*r + 4*b*b + 3*g*g);
        return dist < tolerance;
        //        for (k = CR; k <= CB; k++) {
        //            temp = abs((int)base[k] - (int)color[k]);
        //            if (temp > tolerance){
        //                return FALSE;
        //            }
        //        }
    } else if (channel == kPrimaryChannels) {
        for (k = CR; k <= CB; k++) {
            temp = abs((int)base[k] - (int)color[k]);
            if (temp > tolerance){
                return FALSE;
            }
        }
    } else if (channel == kAlphaChannel) {
        temp = abs((int)base[alphaPos] - (int)color[alphaPos]);
        if (temp > tolerance){
            return FALSE;
        }
    }
    return TRUE;
}
inline BOOL shouldFill(fillContext *ctx,int x, int y)
{
    int seedIndex;
    int width = ctx->width;

    unsigned char *data = ctx->data;

    int tolerance = ctx->tolerance;
    int channel = ctx->channel;

    if(x<0 || y < 0 || x>=ctx->width || y>=ctx->height)
        return NO;

    int offset = (width * y + x)*SPP;

    if(memcmp(ctx->overlay+offset,ctx->fillColor,SPP)==0) {
        return NO;
    }

    unsigned char *color = data+offset;

    for(seedIndex = 0; seedIndex < ctx->numSeeds; seedIndex++){
        IntPoint seed = ctx->seeds[seedIndex];
        unsigned char *seed_color = data+(width*seed.y + seed.x)*SPP;
        if(inTolerance(seed_color,color,tolerance,channel))
            return YES;
    }
    return NO;
}
typedef struct {
    int min_x,max_x,min_y,max_y;
} boundaries;

void set(fillContext *ctx,int x,int y,boundaries *b) {
    memcpy(ctx->overlay+(y*ctx->width+x)*SPP,ctx->fillColor,SPP);
    b->min_x=MIN(b->min_x,x);
    b->max_x=MAX(b->max_x,x);
    b->min_y=MIN(b->min_y,y);
    b->max_y=MAX(b->max_y,y);
}

IntRect bucketFillAll(fillContext *ctx,IntRect rect,NSOperation *op)
{

    int y = rect.origin.y;
    int maxy = y+rect.size.height;
    int x = rect.origin.x;
    int maxx = x+rect.size.width;

    boundaries b = {maxx,x,maxy,y};

    for(int row=y;row<maxy;row++){
        if([op isCancelled])
            return IntZeroRect;
        for(int col=x;col<maxx;col++){
            if(shouldFill(ctx,col,row)) {
                set(ctx,col,row,&b);
            }
        }
    }
    return IntMakeRect(b.min_x, b.min_y, b.max_x - b.min_x + 1, b.max_y - b.min_y + 1);
}

IntRect bucketFill(fillContext *ctx,IntRect rect,NSOperation *op)
{
    unsigned char *overlay = ctx->overlay;
    int tolerance = ctx->tolerance;
    int width = ctx->width;
    int height = ctx->height;

    IntPoint seed = ctx->seeds[0];

    boundaries b = {seed.x,seed.x,seed.y,seed.y};

    if (!IntContainsRect(IntMakeRect(0, 0, width, height), rect)) NSLog(@"Bad rectangle passed to textureFill()");
    if (ctx->fillColor[alphaPos] == 0) return IntZeroRect;

    if (tolerance < 0) {
        return IntZeroRect;
    }
    if (tolerance >= 255) {
        for (int j = rect.origin.y; j < rect.origin.y + rect.size.height; j++) {
            if([op isCancelled])
                return IntZeroRect;
            for	(int i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
                memcpy(&(overlay[(j * width + i) * SPP]), ctx->fillColor, SPP);
            }
        }
        return rect;
    }

    stack s = { NULL, 0, 0};

    int x = seed.x;
    int y = seed.y;

    push(&s,(entry){y,x,x,1});
    push(&s,(entry){y+1,x,x,-1});

    int l,x1,x2,dy;

    while(s.count>0) {
        if([op isCancelled])
            return IntZeroRect;
        
        entry e = pop(&s);

        y  = e.y + e.dy;
        x1 = e.xl;
        x2 = e.xr;
        dy = e.dy;

        for(x=x1;shouldFill(ctx,x,y);x--)
            set(ctx,x,y,&b);
        if(x>=x1) goto skip;
        l = x+1;
        if(l<x1) push(&s,(entry){y,l,x1-1,-dy});
        x = x1+1;
        do {
            for(;shouldFill(ctx,x,y);x++) {
                set(ctx,x,y,&b);
            }
            push(&s,(entry){y,l,x-1,dy});
            if(x>x2+1) {
                push(&s,(entry){y,x2+1,x-1,-dy});
            }
     skip:
            for(x++;x<=x2 && !shouldFill(ctx,x,y);x++);
            l=x;
        } while(x<=x2);
    }

    free(s.entries);

    return IntMakeRect(b.min_x, b.min_y, b.max_x - b.min_x + 1, b.max_y - b.min_y + 1);
}

void textureFill0(CGContextRef dst,CGContextRef textureCtx,IntRect rect)
{
    unsigned char *data = CGBitmapContextGetData(dst);
    int width = CGBitmapContextGetWidth(dst);
    int height = CGBitmapContextGetHeight(dst);

    unsigned char *texture = CGBitmapContextGetData(textureCtx);
    int textureWidth = CGBitmapContextGetWidth(textureCtx);
    int textureHeight = CGBitmapContextGetHeight(textureCtx);

    rect = IntConstrainRect(rect,IntMakeRect(0,0,width,height));

    for (int row = rect.origin.y; row < rect.size.height + rect.origin.y; row++) {
        int offset = ((row * width)+rect.origin.x)*SPP;
        unsigned char *pos = data + offset;
        for (int col = rect.origin.x; col < rect.origin.x+rect.size.width; col++,pos+=SPP) {
            int src_offset = ((row % textureHeight) * textureWidth + (col % textureWidth)) * SPP;
            premultiply_pm(texture+src_offset,pos);
        }
    }
}

void textureFill(CGContextRef dst, CGContextRef textureCtx, IntRect rect)
{
    int cores = MAX([[NSProcessInfo processInfo] activeProcessorCount],1);

    if(cores==1){
        textureFill0(dst,textureCtx,rect);
        return;
    }

    dispatch_group_t group = dispatch_group_create();
    int h = MAX(rect.size.height/cores,1);
    for(int row=0;row<rect.size.height;row+=h) {
        IntRect rect0 = IntMakeRect(rect.origin.x,row+rect.origin.y,rect.size.width,MIN(h,rect.size.height-row));
        dispatch_group_async(group,queue,^{textureFill0(dst,textureCtx,rect0);});
    }
    dispatch_group_wait(group,DISPATCH_TIME_FOREVER);
}

void cloneFill0(CGContextRef dst,CGContextRef srcCtx,IntRect rect,IntPoint offset,IntRect srcRect)
{
    unsigned char *data = CGBitmapContextGetData(dst);
    int width = CGBitmapContextGetWidth(dst);
    int height = CGBitmapContextGetHeight(dst);

    unsigned char *source = CGBitmapContextGetData(srcCtx);
    int srcWidth = CGBitmapContextGetWidth(srcCtx);
    int srcHeight= CGBitmapContextGetHeight(srcCtx);

    for (int row=0;row<rect.size.height;row++) {
        if(row+rect.origin.y<0 || row+rect.origin.y>=height)
            continue;
        for(int col=0;col<rect.size.width;col++) {
            if(col+rect.origin.x<0 || col+rect.origin.x>=width)
                continue;

            int srow = row+offset.y;
            int scol = col+offset.x;

            unsigned char *dst = data + ((rect.origin.y+row)*width+rect.origin.x+col)*SPP;
            unsigned char *src = source + ((srow-srcRect.origin.y)*srcWidth+scol-srcRect.origin.x)*SPP;

            if(scol < srcRect.origin.x || scol >= srcRect.origin.x+srcRect.size.width || srow < srcRect.origin.y || srow >= srcRect.origin.y + srcRect.size.height) {
                memset(dst,0,SPP);
            } else {
                premultiply_pm(src,dst);
            }
        }
    }
}

void cloneFill(CGContextRef dst,CGContextRef srcCtx,IntRect rect,IntPoint offset,IntRect srcRect)
{
    int cores = MAX([[NSProcessInfo processInfo] activeProcessorCount],1);

    if(cores==1){
        cloneFill0(dst,srcCtx,rect,offset,srcRect);
        return;
    }

    dispatch_group_t group = dispatch_group_create();
    int h = MAX(rect.size.height/cores,1);
    for(int row=0;row<rect.size.height;row+=h) {
        IntRect rect0 = IntMakeRect(rect.origin.x,row+rect.origin.y,rect.size.width,MIN(h,rect.size.height-row));
        dispatch_group_async(group,queue,^{cloneFill0(dst,srcCtx,rect0,IntOffsetPoint(offset,0,row),srcRect);});
    }
    dispatch_group_wait(group,DISPATCH_TIME_FOREVER);
}

void smudgeFill(IntRect rect, unsigned char *layerData, unsigned char *overlay, int width, int height, unsigned char *accum, unsigned char *temp, unsigned char *mask, int brushWidth, int brushHeight, int rate, bool *noMoreBlur)
{
    IntRect r = IntConstrainRect(IntMakeRect(0,0,width,height),rect);

    int brushOffset = (r.origin.y-rect.origin.y)*brushWidth + (r.origin.x-rect.origin.x);
    int layerOffset = ((r.origin.y)*width+r.origin.x) * SPP;

    vImage_Buffer layerB = { .data=layerData+layerOffset,.rowBytes=width*4,.width=r.size.width,.height=r.size.height};
    vImage_Buffer overlayB = layerB; overlayB.data=overlay+layerOffset;
    vImage_Buffer accumB = { .data=accum+brushOffset*SPP,.rowBytes=brushWidth*4,.width=r.size.width,.height=r.size.height};
    vImage_Buffer tempB = accumB; tempB.data = temp+brushOffset*SPP;
    vImage_Buffer maskB = {.data=mask+brushOffset,.rowBytes=brushWidth,.width=r.size.width,.height=r.size.height};

    if(!*noMoreBlur) {
        vImageAlphaBlend_ARGB8888(&accumB,&layerB,&tempB,kvImageNoFlags);
        vImageAlphaBlend_ARGB8888(&tempB,&accumB,&accumB,kvImageNoFlags);
        vImageTentConvolve_ARGB8888(&accumB,&tempB,nil,0, 0,17,17,nil,kvImageCopyInPlace);
        vImageOverwriteChannels_ARGB8888(&maskB, &tempB, &tempB, 0x8,kvImageNoFlags);
        vImagePremultiplyData_ARGB8888(&tempB,&tempB,kvImageNoFlags);
    }

    vImagePremultipliedConstAlphaBlend_ARGB8888(&tempB,rate,&overlayB,&overlayB,kvImageNoFlags);

    if(IntRectIsEqual(r,rect)) {
        *noMoreBlur=TRUE;
    }
}

void blitImage(CGContextRef dstCtx,vImage_Buffer *iBuf,IntRect imageR,unsigned char opacity) {
    unsigned char *dst = CGBitmapContextGetData(dstCtx);

    IntRect dstR = IntMakeRect(0,0,CGBitmapContextGetWidth(dstCtx),CGBitmapContextGetHeight(dstCtx));
    int dstBPR = CGBitmapContextGetBytesPerRow(dstCtx);

    int imageBPR = iBuf->rowBytes;

    IntRect r = IntConstrainRect(dstR,imageR);

    unsigned char *src = iBuf->data;

    unsigned char *dst0 = dst + r.origin.y * dstBPR + r.origin.x * SPP;
    unsigned char *src0 = src + (r.origin.y-imageR.origin.y)*imageBPR + (r.origin.x-imageR.origin.x) * SPP;

    vImage_Buffer dBuf;
    dBuf.data=dst0;
    dBuf.width = r.size.width;
    dBuf.height = r.size.height;
    dBuf.rowBytes = dstBPR;

    vImage_Buffer sBuf;
    sBuf.data=src0;
    sBuf.width = r.size.width;
    sBuf.height = r.size.height;
    sBuf.rowBytes = imageBPR;

    vImagePremultipliedConstAlphaBlend_ARGB8888(&sBuf,opacity, &dBuf, &dBuf,kvImageNoFlags);
}

