#import "Seashore.h"

#define alphaPos (spp - 1)

// merge premultiplied top over non-premultiplied bottom into non-premultiplied dest
static inline void merge_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity){
    double ta = top[alphaPos]/255.0;
    double ba = bottom[alphaPos]/255.0;

    double aa = ta * (topOpacity/255.0);

    double a0 = aa  + ba * (1 - aa);

    if(aa==0 || ta==0) {
        memcpy(dest,bottom,spp);
        return;
    }

    for(int k=0;k<spp-1;k++) {
        double b = (*bottom++ / 255.0); // not premultiplied
        double t = (*top++ / 255.0) / ta; // top is premultiplied

        *dest++ = ((t*aa + b*ba * (1 - aa))/a0) * 255.0;
    }
    *dest++ = a0 * 255;
}

// premultiply, changing the opacity
static inline void premultiply_pm(int spp,unsigned char *src,unsigned char *dest,unsigned char opacity){
    int t1;
    for(int k=0;k<spp-1;k++) {
        *dest++ = int_mult(*src++,opacity,t1);
    }
    *dest++ = opacity;
}


// merge non-premultiplied top over premultiplied bottom into premultiplied dest
static inline void merge_pm2(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity){
    double ta = top[alphaPos]/255.0;
    double ba = bottom[alphaPos]/255.0;

    double aa = ta * (topOpacity/255.0);

    double a0 = aa  + ba * (1 - aa);

    if(aa==0 || ta==0) {
        memcpy(dest,bottom,spp);
        return;
    }

    for(int k=0;k<spp-1;k++) {
        double b = (*bottom++ / 255.0); //  premultiplied
        double t = (*top++ / 255.0); // top is non-premultiplied

        *dest++ = (t*aa + b * (1 - aa)) * 255.0;
    }
    *dest++ = a0 * 255;
}


void erase_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest, unsigned char topOpacity);
void replace_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

void merge_alpha_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity);
void replace_alpha_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

void merge_primary_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity);
void replace_primary_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char replace);

/*!
 @function    normalMerge
 @discussion    Given two pixels in two bitmaps composites the source pixel on
 to the destination pixel using the normal merge technique.
 @param        spp
 The samples per pixel of the bitmaps (can be 2 or 4).
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
inline void normalMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity);

/*!
 @function    selectMerge
 @discussion    Given two pixels in two bitmaps composites the source pixel on
 to the destination pixel using the selected merge technique.
 Note for XCF_DISSOLVE_MODE you must call srandom(randomTable[y %
 4096]); for (k = 0; k < x; k++)  random();" for the merge to
 work correctly.
 @param        choice
 The selected merge technique (see Constants documentation).
 @param        spp
 The samples per pixel of the bitmaps (can be 2 or 4).
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
inline void selectMerge(int choice, int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc);

