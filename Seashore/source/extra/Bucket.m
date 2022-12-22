#include "Bucket.h"
#include "StandardMerge.h"
#include <Accelerate/Accelerate.h>

#define kStackSizeIncrement 8192

#define TILE_SIZE 32

#define alphaPos 0

extern dispatch_queue_t queue;
extern dispatch_group_t group;

inline BOOL shouldFill(fillContext *ctx,IntPoint point)
{
	int seedIndex;
    int width = ctx->width;
    unsigned char *overlay = ctx->overlay;
    unsigned char *data = ctx->data;
    int tolerance = ctx->tolerance;
    int channel = ctx->channel;
	
	for(seedIndex = 0; seedIndex < ctx->numSeeds; seedIndex++){
		
		IntPoint seed = ctx->seeds[seedIndex];
		BOOL outsideTolerance = NO;
		int k, temp;
		
		int offset = (width * point.y + point.x)*SPP;
        int offset0 = (width *seed.y + seed.x)*SPP;
		
		if (overlay[offset + alphaPos] > 0){
			outsideTolerance = YES;
			continue;
		}
		
		if (channel == kAllChannels) {
            if (data[offset + alphaPos] == 0)
                return YES;

			for (k = CR; k <= CB; k++) {
				temp = abs((int)data[offset + k] - (int)data[offset0 + k]);
				if (temp > tolerance){
					outsideTolerance = YES;
					break;
				}
			}
		} else if (channel == kPrimaryChannels) {
		
			for (k = CR; k <= CB; k++) {
				temp = abs((int)data[offset + k] - (int)data[offset0 + k]);
				if (temp > tolerance){
					outsideTolerance = YES;
					break;
				}
			}
		
		} else if (channel == kAlphaChannel) {
			temp = abs((int)data[offset + alphaPos] - (int)data[offset0+alphaPos]);
			if (temp > tolerance){
				outsideTolerance = YES;
			}
		}
		
		if(!outsideTolerance){
			return YES;
		}
	}
	
	return NO;
}

IntRect bucketFill(fillContext *ctx,IntRect rect,unsigned char *fillColor)
{
	int seedIndex;
	// We know at the very least that this point is in the rect
	IntRect result = IntMakeRect(ctx->seeds[0].x, ctx->seeds[0].y, 1, 1);

    unsigned char *overlay = ctx->overlay;
    unsigned char *data = ctx->data;
    int tolerance = ctx->tolerance;
    int width = ctx->width;
    int height = ctx->height;

	for(seedIndex = 0; seedIndex < ctx->numSeeds; seedIndex++){
		IntPoint point, newPoint, seed = ctx->seeds[seedIndex];
		IntPoint *stack;
		int stackSize, stackPos, k;
		int minLeft = seed.x, maxRight = seed.x, minTop = seed.y, maxBottom = seed.y;
		int i, j;
		unsigned char firstPixel[4];
		int origTolerance = tolerance;

		// If the overlay alread contains this point, then our work is already done
		BOOL visited = YES;
		for (k = 0; k < SPP; k++){
			// Compare to see if the fill exists at this point in the overlay
			if(overlay[(seed.y * width + seed.x) * SPP + k] != fillColor[k]){
				visited = NO;
			}
		}
		if(visited){
			// We have in fact already filled this point so there's no reason 
			// to do another bucket fill from this point
			continue;
		}

		if (!IntContainsRect(IntMakeRect(0, 0, width, height), rect)) NSLog(@"Bad rectangle passed to textureFill()");
		if (fillColor[alphaPos] == 0) return IntMakeRect(0, 0, 0, 0);
		
		if (tolerance > 0 && tolerance < 255) {
			tolerance = 255;
			memcpy(firstPixel, data, SPP);
			for (j = rect.origin.y; j < rect.origin.y + rect.size.height && tolerance != origTolerance; j++) {
				for	(i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
					if (memcmp(firstPixel, &data[(j * width + i) * SPP], SPP) != 0) {
						tolerance = origTolerance;
						break;
					}
				}
			}
		}
		
		if (tolerance < 0) {
			result = IntMakeRect(0, 0, 0, 0);
		}
		else if (tolerance >= 255) {
			for (j = rect.origin.y; j < rect.origin.y + rect.size.height; j++) {
				for	(i = rect.origin.x; i < rect.origin.x + rect.size.width; i++) {
					memcpy(&(overlay[(j * width + i) * SPP]), fillColor, SPP);
				}
			}
			
			result = rect;
		}
		else {
			stack = malloc(sizeof(IntPoint) * kStackSizeIncrement);
			stackSize = kStackSizeIncrement;
			stackPos = 0;
			point = seed;
			do {
				
				if (stackPos == stackSize) {
					stackSize += kStackSizeIncrement;
					stack = realloc(stack, sizeof(IntPoint) * stackSize);
				}
				
				if (overlay[(point.y * width + point.x) * SPP + alphaPos] == 0)  {
					for (k = 0; k < SPP; k++)
						overlay[(point.y * width + point.x) * SPP + k] = fillColor[k];
				}
				
				newPoint = point;
				newPoint.y++;
				if (IntPointInRect(newPoint, rect) && shouldFill(ctx,newPoint)) {
					stack[stackPos] = point;
					stackPos++;
					point = newPoint;
					if (point.y > maxBottom) maxBottom = point.y;
				}
				else {
				
					newPoint = point;
					newPoint.y--;
					if (IntPointInRect(newPoint, rect) && shouldFill(ctx,newPoint)) {
						stack[stackPos] = point;
						stackPos++;
						point = newPoint;
						if (point.y < minTop) minTop = point.y;
					}
					else {
					
						newPoint = point;
						newPoint.x++;
						if (IntPointInRect(newPoint, rect) && shouldFill(ctx,newPoint)) {
							stack[stackPos] = point;
							stackPos++;
							point = newPoint;
							if (point.x > maxRight) maxRight = point.x;
						}
						else {
							
							newPoint = point;
							newPoint.x--;
							if (IntPointInRect(newPoint, rect) && shouldFill(ctx,newPoint)) {
								stack[stackPos] = point;
								stackPos++;
								point = newPoint;
								if (point.x < minLeft) minLeft = point.x;
							}
							else {
								stackPos--;
								if (stackPos > -1)
									point = stack[stackPos];
							}
				
						}
						
					}
					
				}
				
			} while (stackPos > -1);
			
			free(stack);
			result = IntSumRects(result, IntMakeRect(minLeft, minTop, maxRight - minLeft + 1, maxBottom - minTop + 1));
		}
	}
	
	return result;
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
        for(int col=0;col<rect.size.width;col++) {

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

    int h = MAX(rect.size.height/cores,1);
    for(int row=0;row<rect.size.height;row+=h) {
        IntRect rect0 = IntMakeRect(rect.origin.x,row+rect.origin.y,rect.size.width,MIN(h,rect.size.height-row));
        dispatch_group_async(group,queue,^{cloneFill0(dst,srcCtx,rect0,IntOffsetPoint(offset,0,row),srcRect);});
    }
    dispatch_group_wait(group,DISPATCH_TIME_FOREVER);
}

void smudgeFill(IntRect rect, unsigned char *layerData, unsigned char *overlay, int width, int height, unsigned char *accum, unsigned char *temp, unsigned char *mask, int brushWidth, int brushHeight, int rate)
{
    int t1;

    IntRect r = IntConstrainRect(IntMakeRect(0,0,width,height),rect);

    int brushOffset = (r.origin.y-rect.origin.y)*brushWidth + (r.origin.x-rect.origin.x);
    int layerOffset = ((r.origin.y)*width+r.origin.x) * SPP;

    unsigned char *maskPtr = mask+brushOffset;
    unsigned char *accumPtr = accum+brushOffset*SPP;
    unsigned char *tempPtr = temp+brushOffset*SPP;
    unsigned char *overlayPtr = overlay+layerOffset;
    unsigned char *layerPtr = layerData+layerOffset;

    unsigned char *maskPtr0 = maskPtr;
    unsigned char *accumPtr0 = accumPtr;
    unsigned char *layerPtr0 = layerPtr;

    bool changed=false;
    for(int row=0;row<r.size.height;row++) {
        for(int col=0;col<r.size.width;col++) {
            int col0 = col*SPP;
            int alpha = int_mult(maskPtr0[col],layerPtr0[col0+alphaPos],t1);
            if(alpha && accumPtr0[col0+alphaPos]==0) {
                accumPtr0[col0+alphaPos]=alpha;
                premultiply_pm(layerPtr0+col0,accumPtr0+col0);
                changed=true;
            }
        }
        accumPtr0 += brushWidth*SPP;
        maskPtr0 += brushWidth;
        layerPtr0 += width*SPP;
    }

    vImage_Buffer top;
    top.data = accumPtr;
    top.width = r.size.width;
    top.height = r.size.height;
    top.rowBytes = brushWidth * SPP;

    vImage_Buffer tempB;
    tempB.data = tempPtr;
    tempB.width = r.size.width;
    tempB.height = r.size.height;
    tempB.rowBytes = brushWidth * SPP;

    if(changed) {
        vImageTentConvolve_ARGB8888(&top,&tempB,nil,0, 0,17,17,nil,kvImageEdgeExtend);
    }

    vImage_Buffer bottom;
    bottom.data = overlayPtr;
    bottom.width = r.size.width;
    bottom.height = r.size.height;
    bottom.rowBytes = width * SPP;

    vImagePremultipliedConstAlphaBlend_ARGB8888(&tempB,rate,&bottom,&bottom,kvImageNoFlags);
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

//    vImageAlphaBlend_ARGB8888(&sBuf,&dBuf,&dBuf,kvImageNoFlags);
    vImagePremultipliedConstAlphaBlend_ARGB8888(&sBuf,opacity, &dBuf, &dBuf,kvImageNoFlags);
}

