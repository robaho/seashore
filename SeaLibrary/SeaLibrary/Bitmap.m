#include "Bitmap.h"
#import "bitstring.h"

#import <Accelerate/Accelerate.h>

CGColorSpaceRef rgbCS;
CGColorSpaceRef grayCS;

CGImageRef CGImageScale(CGImageRef image,int width,int height) {
    CGContextRef ctx = CGBitmapContextCreate(NULL,width,height,8,0,CGImageGetColorSpace(image),kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(ctx, CGRectMake(0,0,width,height),image);
    CGImageRef scaled = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return scaled;
}

CGImageRef convertToGA(CGImageRef src)
{
    CGContextRef ctx = CGBitmapContextCreate(NULL,CGImageGetWidth(src),CGImageGetHeight(src),8,0,grayCS,kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx,CGImageGetBounds(src),src);
    CGImageRef dst=CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return dst;
}

CGImageRef convertToARGB(CGImageRef src)
{
    CGContextRef ctx = CGBitmapContextCreate(NULL,CGImageGetWidth(src),CGImageGetHeight(src),8,0,rgbCS,kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(ctx,CGImageGetBounds(src),src);
    CGImageRef dst=CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return dst;
}

CGImageRef convertToAGGG(CGImageRef src)
{
    CGImageRef gray = convertToGA(src);
    CGImageRef aggg = convertToARGB(gray);
    CGImageRelease(gray);
    return aggg;
}

void mapARGBtoAGGG(unsigned char *data,int length) {
    for(int i=0;i<length;i+=4) {
        int gray = ((int)data[i+1] + (int)data[i+2] + (int)data[i+3]) / 3;
        memset(data+i+1,gray,3);
    }
}

/*
 convert NSImageRep to a format Seashore can work with, which is ARGB
 */
unsigned char *convertRepToARGB(NSImageRep *imageRep) {
    
    int width = (int)[imageRep pixelsWide];
    int height = (int)[imageRep pixelsHigh];
    
    unsigned char *buffer = calloc(width*height*4,sizeof(unsigned char));
    
    if(!buffer){
        return NULL;
    }
    
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:MyRGBSpace
                                                                                    bitmapFormat:NSBitmapFormatAlphaFirst
                                                                                     bytesPerRow:width*4
                                                                                     bitsPerPixel:8*4];
    
    [bitmapWhoseFormatIKnow setSize:[imageRep size]];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow];
    [NSGraphicsContext setCurrentContext:ctx];
    [imageRep draw];
    [NSGraphicsContext restoreGraphicsState];

    unpremultiplyBitmap(4,buffer,buffer,width*height);

    return buffer;
}

void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImagePremultiplyData_ARGB8888(&ibuf,&obuf,0);
    } else { // spp==2 which is grayscale with alpha
        int temp;
        for(int i=0;i<length;i++) {
            *output = int_mult(*input,*(input+1), temp);
            output+=2;
            input+=2;
        }
    }
}

void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
    if(spp==4) {
        vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*spp};
        vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*spp};

        vImageUnpremultiplyData_ARGB8888(&ibuf,&obuf,0);
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

void unpremultiplyRGBA(unsigned char *output, unsigned char *input, int length)
{
    vImage_Buffer obuf = {.data=output,.height=1,.width=length,.rowBytes=length*4};
    vImage_Buffer ibuf = {.data=input,.height=1,.width=length,.rowBytes=length*4};

    vImageUnpremultiplyData_RGBA8888(&ibuf,&obuf,0);
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
    NSRect r = NSMakeRect(0,0,src.size.width,src.size.height);
    CGImageRef img = getTintedCG([src CGImageForProposedRect:&r context:NULL hints:NULL], tint);
    NSImage *tinted = [[NSImage alloc] initWithCGImage:img size:[src size]];
    CGImageRelease(img);
    return tinted;
}

CGImageRef CGImageDeepCopy(CGImageRef image) {
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(image), CGImageGetBytesPerRow(image), CGImageGetColorSpace(image), kCGImageAlphaPremultipliedFirst);
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

CGSize CGImageGetSize(CGImageRef img) {
    return CGSizeMake(CGImageGetWidth(img),CGImageGetHeight(img));
}

CGContextRef CreateImageContext(IntSize size) {
    unsigned char *data = calloc(size.width*size.height*4,1);
    return CreateImageContextWithData(data,size);
}

CGContextRef CreateImageContextWithData(unsigned char *data,IntSize size) {
    return CGBitmapContextCreate(data,size.width,size.height,8,size.width*4,COLOR_SPACE,kCGImageAlphaPremultipliedFirst);
}

unsigned char *ImageContextGetData(CGContextRef ctx) {
    return (unsigned char*)CGBitmapContextGetData(ctx);
}

Margins determineContentMargins(unsigned char *data,int width,int height)
{
    int i,j,k;
    int top=-1,left=-1,bottom=-1,right=-1;

    // Determine left content margin
    for (i = 0; i < width && left == -1; i++) {
        for (j = 0; j < height && left == -1; j++) {
            if (ALPHA(data,i,j,width) != 0) {
                left = i;
            }
        }
    }

    // Determine right content margin
    for (i = width - 1; i >= 0 && right == -1; i--) {
        for (j = 0; j < height && right == -1; j++) {
            if (ALPHA(data,i,j,width) != 0) {
                right = width - 1 - i;
            }
        }
    }

    // Determine top content margin
    for (j = 0; j < height && top == -1; j++) {
        for (i = 0; i < width && top == -1; i++) {
            if (ALPHA(data,i,j,width) != 0) {
                top = j;
            }
        }
    }

    // Determine bottom content margin
    for (j = height - 1; j >= 0 && bottom == -1; j--) {
        for (i = 0; i < width && bottom == -1; i++) {
            if (ALPHA(data,i,j,width) != 0) {
                bottom = height - 1 - j;
            }
        }
    }

    Margins m = {.left=left,.right=right,.top=top,.bottom=bottom};
    return m;
}
