/*!
	@header		Bitmap
	@abstract	Contains various fuctions relating to bitmap manipulation.
	@discussion	N/A
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

#import <CoreGraphics/CoreGraphics.h>
#import <SeaLibrary/Globals.h>

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

unsigned char *convertImageRep(NSImageRep *imageRep, int spp);

/*!
	@function	stripAlphaToWhite
	@discussion	Given a bitmap this function strips the alpha channel making it
				appear as though the image is on a white background and places
				the result in the output. The output and input can both point to
				the same block of memory.
	@param		spp
				The samples per pixel of the original bitmap.
	@param		output
				The block of memory in which to place the bitmap once its alpha
				channel has been stripped.
	@param		input
				The block of memory containing the original bitmap.
	@param		length
				The length of the bitmap in terms of pixels (not bytes).
*/
void stripAlphaToWhite(int spp, unsigned char *output, unsigned char *input, int length);

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

/*
 return data with alpha stripped if alpha not used, otherwise just return the source data
 */
unsigned char *stripAlpha(unsigned char *srcData,int width,int height,int spp);

CGImageRef getTintedCG(CGImageRef src,NSColor *tint);
NSImage *getTinted(NSImage* src,NSColor *tint);

NS_INLINE bool isSameColor(unsigned char *data,int width,int spp,int x,int y,int x0,int y0) {
    for(int i=0;i<spp;i++) {
        if(data[(width*y+x)*spp+i]!=data[(width*y0+x0)*spp+i]){
            return false;
        }
    }
    return true;
}
