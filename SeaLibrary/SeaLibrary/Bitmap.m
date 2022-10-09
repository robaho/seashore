#include "Bitmap.h"
#import "bitstring.h"

#import <Accelerate/Accelerate.h>

CGColorSpaceRef rgbCS;
CGColorSpaceRef grayCS;

void convertRGBA2GrayA(unsigned char *dbitmap, unsigned char *ibitmap, int width, int height)
{
    int i, ispp=4;
    
    for (i = 0; i < width * height; i++) {
        dbitmap[i * 2] = ((int)ibitmap[i * ispp] + (int)ibitmap[i * ispp + 1] + (int)ibitmap[i * ispp + 2]) / 3;
        if (ispp == 4) dbitmap[i * 2 + 1] = ibitmap[i * 4 + 3];
    }
}

/*
 convert NSImageRep to a format Seashore can work with, which is RGBA, or GrayA. If spp is 4, then RGBA, if 2, the GrayA
 */
unsigned char *convertImageRep(NSImageRep *imageRep,int spp) {
    
    int width = (int)[imageRep pixelsWide];
    int height = (int)[imageRep pixelsHigh];
    
    unsigned char *buffer = calloc(width*height*spp,sizeof(unsigned char));
    
    if(!buffer){
        return NULL;
    }
    
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:(spp == 4 ? MyRGBSpace : MyGraySpace)
                                                                                     bytesPerRow:width*spp
                                                                                     bitsPerPixel:8*spp];
    
    [bitmapWhoseFormatIKnow setSize:[imageRep size]];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow];
    [NSGraphicsContext setCurrentContext:ctx];
    [imageRep draw];
    [NSGraphicsContext restoreGraphicsState];

    unpremultiplyBitmap(spp,buffer,buffer,width*height);

    return buffer;
}

unsigned char *stripAlpha(unsigned char *srcData,int width,int height,int spp) {
    int i,j;
    bool hasAlpha = false;
    unsigned char *destData;
    
    // Determine whether or not an alpha channel would be redundant
    for (i = 0; i < width * height && hasAlpha == NO; i++) {
        if (srcData[(i + 1) * spp - 1] != 255)
            hasAlpha = YES;
    }
    
    // Strip the alpha channel if necessary
    if (!hasAlpha) {
        spp--;
        destData = malloc(width * height * spp);
        for (i = 0; i < width * height; i++) {
            for (j = 0; j < spp; j++)
                destData[i * spp + j] = srcData[i * (spp + 1) + j];
        }
        return destData;
    }
    else
        return srcData;

}

inline void stripAlphaToWhite(int spp, unsigned char *output, unsigned char *input, int length)
{
	const int alphaPos = spp - 1;
	const int outputSPP = spp - 1;
	unsigned char alpha;
	double alphaRatio;
	int t1, t2, newValue;
	int i, k;
	
	memset(output, 255, length * outputSPP);
	
	for (i = 0; i < length; i++) {
		
		alpha = input[i * spp + alphaPos];
		
		if (alpha == 255) {
			for (k = 0; k < outputSPP; k++)
				output[i * outputSPP + k] = input[i * spp + k];
		}
		else {
			if (alpha != 0) {

				alphaRatio = 255.0 / alpha;
				for (k = 0; k < outputSPP; k++) {
					newValue = 0.5 + input[i * spp + k] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * outputSPP + k] = int_mult(newValue, alpha, t1) + int_mult(255, (255 - alpha), t2);
				}
				
			}
		}
	
	} 
}

inline void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImagePremultiplyData_RGBA8888(&ibuf,&obuf,0);
    } else { // spp==2 which is grayscale with alpha
        int temp;
        for(int i=0;i<length;i++) {
            *output = int_mult(*input,*(input+1), temp);
            output+=2;
            input+=2;
        }
    }
}

inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImageUnpremultiplyData_RGBA8888(&ibuf,&obuf,0);
    } else {
        for(int i=0;i<length;i++) {
            unsigned char alpha = *(input+1);
            if(alpha==0)
                *output = 0;
            else
                *output = MIN(*input * 255 / alpha,255);
            output+=2;
            input+=2;
        }
    }
}

inline unsigned char averagedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where)
{
	int total, count;
	int i, j;
	
	if (radius == 0) {
		return data[(where.y * width + where.x) * spp + component];
	}

	total = 0;
	count = 0;
	for (j = where.y - radius; j <= where.y + radius; j++) {
		for (i = where.x - radius; i <= where.x + radius; i++) {
			if (i >= 0 && i < width && j >= 0 && j < height) {
				total += data[(j * width + i) * spp + component];
				count++;
			}
		}
	}
    if(count==0)
        return 0;
		
	return (total / count);
}

CGImageRef getTintedCG(CGImageRef src,NSColor *tint){
    int w = (int)CGImageGetWidth(src);
    int h = (int)CGImageGetHeight(src);

    CGContextRef ctx = CGBitmapContextCreateWithData(NULL, w, h, 8, 0, rgbCS, kCGImageAlphaPremultipliedLast, NULL, NULL);
    CGRect r = CGRectMake(0,0,w,h);
    CGContextClearRect(ctx, r);
    CGContextClipToMask(ctx, r, src);
    CGContextSetFillColorWithColor(ctx, [tint CGColor]);
    CGContextFillRect(ctx, r);
    CGImageRef i = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    return i;
}

NSImage *getTinted(NSImage *src,NSColor *tint){
    NSImage *copy = [src copy];
    NSRect imageRect = NSMakeRect(0,0,[copy size].width,[copy size].height);
    [copy lockFocus];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceAtop];
    [tint set];
    [NSBezierPath fillRect:imageRect];
    [copy unlockFocus];
    return copy;
}

CGImageRef CGImageDeepCopy(CGImageRef image) {
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0,0,width,height),image);
    CGImageRef copy = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return copy;
}

float MaxScale(CGAffineTransform t) {
    float xscale = sqrt(t.a * t.a + t.c * t.c);
    float yscale = sqrt(t.b * t.b + t.d * t.d);
    return MAX(xscale,yscale);
}

CGRect CGImageGetBounds(CGImageRef img) {
    return CGRectMake(0,0,CGImageGetWidth(img),CGImageGetHeight(img));
}
