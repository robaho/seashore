/*!
	@header		Bitmap
	@abstract	Contains various fuctions relating to bitmap manipulation.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import <CoreGraphics/CoreGraphics.h>
#import "Globals.h"

/*!
	@enum		k...ColorSpace
	@constant	kGrayColorSpace
				Indicates the gray/white colour space.
	@constant	kInvertedGrayColorSpace
				Indicates the gray/black colour space.
	@constant	kRGBColorSpace
				Indicates the RGB colour space.
	@constant	kCMYKColorSpace
				Indicates the CMYK colour space
*/
enum {
	kGrayColorSpace,
	kInvertedGrayColorSpace,
	kRGBColorSpace,
	kCMYKColorSpace
};

/*! copies a bitmap rect into a destination area of the rect size */
CG_INLINE void SAVE_BITMAP(unsigned char *dst,unsigned char *src,IntRect rect,int bitmapWidth){
    for (int i = 0; i < rect.size.height; i++) {
        memcpy(dst, src + ((rect.origin.y + i) * bitmapWidth + rect.origin.x) * SPP, rect.size.width * SPP);
        dst += rect.size.width * SPP;
    }
}

/*! copies a bitmap into a larger bitmap at rect */
CG_INLINE void RESTORE_BITMAP(unsigned char *dst,unsigned char *src,IntRect rect,int bitmapWidth){
    // Replace the image data with that of the record
    for (int i = 0; i < rect.size.height; i++) {
        memcpy(dst + ((rect.origin.y + i) * bitmapWidth + rect.origin.x) * SPP, src, rect.size.width * SPP);
        src += rect.size.width * SPP;
    }
}

/** return a point to a memory block that is a ARGB representation of the imageRep with same width & height*/
unsigned char *convertRepToARGB(NSImageRep *imageRep);
/** return a point to a memory block that is a RGBA representation of the imageRep with same width & height*/
unsigned char *convertRepToRGBA(NSImageRep *imageRep);

CGImageRef convertToGA(CGImageRef src);
CGImageRef convertToAGGG(CGImageRef src);
CGImageRef convertToARGB(CGImageRef src);


/** change RGB pixels to gray in place */
void mapARGBtoAGGG(unsigned char* data,int bytes);

/*!
	@function	premultiplyBitmap
	@discussion	Given a bitmap this function premultiplies the primary channels
				and places the result in the output. The output and input can 
				both point to the same block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
void premultiplyBitmap(int spp, unsigned char *destPtr, unsigned char *srcPtr, int length);

/*!
	@function	unpremultiplyBitmap
	@discussion	Given a bitmap this function tries to reverse the
				premultiplication of the primary channels and places the result
				in the output. The output and input can  both point to the same
				block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
void unpremultiplyBitmap(int spp, unsigned char *destPtr, unsigned char *srcPtr, int length);

void unpremultiplyRGBA(unsigned char *destPtr, unsigned char *srcPtr, int length);

/*!
	@function	averagedComponentValue
	@discussion	Given a point on the bitmap this function finds the average
				value of particular component inside a box about that point.
	@param		spp
				The samples per pixel of the bitmap.
	@param		data
				The block of memory containing the bitmap.
	@param		width
				The width of the bitmap.
	@param		height
				The height of the bitmap.
	@param		component
				The component on which to focus (must be less than the spp of
				the bitmap).
	@param		radius
				The radius of the box on which to focus (a radius of zero simply
				returns the component value at the given point).
	@param		where
				The point at which to centre the box.
*/
unsigned char averagedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where);

/**
    @discussion convert unmultiplied RGBA to ARGB in place
    @param  length the number of RGBA pixels
 */
void convertRGBAtoARGB(unsigned char *buffer, int length);
void convertARGBtoRGBA(unsigned char *buffer, int length);

/**
 @discussion convert unmultiplied GA to ARGB in place
 @param  length the number of GA pixels
 */
unsigned char *convertGAToARGB(unsigned char *buffer, int length);

CGImageRef getTintedCG(CGImageRef src,NSColor *tint);
NSImage *getTinted(NSImage* src,NSColor *tint);
NSRect scaledRect(NSImage *img,NSRect r);

NS_INLINE bool isSameColor(unsigned char *data,int width,int x,int y,int x0,int y0) {
    return *(uint32_t*)(data+(width*y+x)*SPP)==*(uint32_t*)(data+(width*y0+x0)*SPP);
}

CGImageRef CGImageDeepCopy(CGImageRef image);
CGImageRef CGImageScale(CGImageRef image,int width,int height);
float MaxScale(CGAffineTransform tx);
CGRect CGImageGetBounds(CGImageRef image);
CGSize CGImageGetSize(CGImageRef image);
CGContextRef CreateImageContext(IntSize size);
CGContextRef CreateImageContextWithData(unsigned char *data,IntSize size);
CGContextRef CreateAutoFreeImageContext(IntSize size);
unsigned char *ImageContextGetData(CGContextRef ctx);

Margins determineContentMargins(unsigned char *image,int width,int height);

#define COMPONENT(data,x,y,width,component) data[(y*width+x)*SPP+component]
#define ALPHA(data,x,y,width) data[(y*width+x)*SPP+alphaPos]
