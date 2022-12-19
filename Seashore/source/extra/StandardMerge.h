#import "Seashore.h"

static inline unsigned char CLAMP(int x) { return (x < 0) ? 0 : ((x > 255) ? 255 : x); }

#define PM(x,a) (((x)&0xFFU) * a + 127)/255

// merge premultiplied top over non-premultiplied bottom into non-premultiplied dest
CG_INLINE void merge_pm(unsigned char *top,unsigned char *bottom,unsigned char *dst,unsigned char topOpacity){
    uint32_t b = *(uint32_t*)bottom;
    uint32_t t = *(uint32_t*)top;

    uint8_t alpha = ((t&0xFFU)*topOpacity + 127)/255;
    uint8_t alpha0 = 255-alpha;

    uint8_t b_a = (b)&0xFFU;

    uint8_t c_a = alpha + (b_a*alpha0+127)/255;

    if(c_a==0) {
        memcpy(dst,bottom,SPP); // can't unpremultiply
        return;
    }

    uint8_t t_r = PM(t>>8,topOpacity);
    uint8_t t_g = PM(t>>16,topOpacity);
    uint8_t t_b = PM(t>>24,topOpacity);

    uint8_t b_r = PM(b>>8,b_a);
    uint8_t b_g = PM(b>>16,b_a);
    uint8_t b_b = PM(b>>24,b_a);

    uint8_t c_r = (((t_r + (b_r*alpha0+127)/255) * 255)/c_a);
    uint8_t c_g = (((t_g + (b_g*alpha0+127)/255) * 255)/c_a);
    uint8_t c_b = (((t_b + (b_b*alpha0+127)/255) * 255)/c_a);

    *(uint32_t*)dst = c_a | (c_r<<8) | (c_g<<16) | (c_b<<24);
}

// replace RGB channels in a premultiplied dest
CG_INLINE void premultiply_pm(unsigned char *src,unsigned char *dest){
    unsigned char opacity = dest[alphaPos];

    uint32_t t = *(uint32_t*)src;

    uint8_t t_r = PM(t>>8,opacity);
    uint8_t t_g = PM(t>>16,opacity);
    uint8_t t_b = PM(t>>24,opacity);

    *(uint32_t*)dest = opacity | (t_r<<8) | (t_g<<16) | (t_b<<24);
}

CG_INLINE void premultiplyPixel(unsigned char *pixel) {
    uint32_t p = *(uint32_t*)pixel;

    uint8_t alpha = p & 0xFF;
    uint8_t r = PM(p>>8,alpha);
    uint8_t g = PM(p>>16,alpha);
    uint8_t b = PM(p>>24,alpha);

    *(uint32_t*)pixel = alpha | (r<<8) | (g<<16) | (b<<24);
}

void erase_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest, unsigned char topOpacity);
void replace_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

void merge_alpha_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity);
void replace_alpha_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

void merge_primary_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity);
void replace_primary_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

/*!
 @function    normalMerge
 @discussion  composite unpremultiplied top with premultiplied bottom
 @param       bottom the bottom pixel (premultiplied)
 @param       top the top pixel (unpremultiplied)
 @param       topOpacity additional opacity to apply to the top
 */

CG_INLINE void normalMerge(unsigned char *bottom, unsigned char *top, int topOpacity)
{
//    uint32_t b = *(uint32_t*)bottom;
//    uint32_t t = *(uint32_t*)top;
//
//    uint32_t alpha = ((t&0xFF)*topOpacity + 127)/255;
//    uint32_t alpha0 = 255-alpha;
//
//    uint32_t t_r = (t>>8)&0xFF;
//    uint32_t b_r = (b>>8)&0xFF;
//    uint32_t t_g = (t>>16)&0xFF;
//    uint32_t b_g = (b>>16)&0xFF;
//    uint32_t t_b = (t>>24)&0xFF;
//    uint32_t b_b = (b>>24)&0xFF;
//    uint32_t b_a = (b)&0xFF;
//
//    uint32_t c_r = (b_r*alpha0 + t_r*alpha +127)/255;
//    uint32_t c_g = (b_g*alpha0 + t_g*alpha +127)/255;
//    uint32_t c_b = (b_b*alpha0 + t_b*alpha +127)/255;
//    uint32_t c_a = alpha + (b_a*alpha0+127)/255;
//
//    *(uint32_t*)bottom = c_a + (c_r <<8) + (c_g<<16)+(c_b<<24);
//
//
//
//
//
    int t1, t2;
    unsigned char alpha = int_mult(top[alphaPos],topOpacity,t1);
    unsigned char alpha0 = 255-alpha;

    if (alpha == 0)
        return;

    if (alpha == 255) {
        memcpy(bottom+1,top+1,SPP-1);
        *bottom = 255;
    }
    else {
        for(int k=1;k<SPP;k++) {
            bottom[k]=int_mult(top[k],alpha,t1)+int_mult(bottom[k],alpha0,t2);
        }
        bottom[0] = alpha + int_mult(bottom[0],alpha0,t1);
    }
}
/*!
 @function    selectMerge
 @discussion    Given two pixels in two bitmaps composites the source pixel on
 to the destination pixel using the selected merge technique.
 Note for XCF_DISSOLVE_MODE you must call srandom(randomTable[y %
 4096]); for (k = 0; k < x; k++)  random();" for the merge to
 work correctly.
 @param        choice
 The selected merge technique (see Constants documentation).
 @param        destPtr
 The block of memory containing the pixel upon which the source
 pixel is being composited.
 @param        destLoc
 The position in that block of the pixel.
 @param        srcPtr
 The block of memory containing the pixel which is being
 composited.
 @param        srcLoc
 The position in that block of the pixel.
 @param        srcOpacity
 The opacity with which the source pixel should be composited.
 */
inline void selectMerge(int choice, unsigned char *destPtr, unsigned char *srcPtr);
