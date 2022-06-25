#import "StandardMerge.h"
#import "ColorConversion.h"

#define alphaPos (spp - 1)

void merge_alpha_pm(int spp, unsigned char *top, unsigned char *bottom, unsigned char *dest,unsigned char topOpacity)
{
    memcpy(dest,bottom,spp);

    if (topOpacity == 0) {
        return;
    }

    unsigned char alpha = *top;
    unsigned char alpha0 = (top[alphaPos] * topOpacity)/255;

    unsigned char merged = (alpha * topOpacity)/255 + (bottom[alphaPos] * (255-alpha0))/255;

    dest[alphaPos] = merged;
}


// merge pre-multiplied top onto non-premultiplied bottom into non-premultiplied dest
void merge_primary_pm(int spp, unsigned char *top, unsigned char *bottom, unsigned char *dest,unsigned char topOpacity)
{
    int t1,t2;

    int alpha = top[alphaPos];

    alpha = int_mult(alpha,topOpacity,t1);

    if (alpha == 0) {
        memcpy(dest,bottom,spp);
        return;
    }

    unsigned char _top[spp];
    unpremultiplyBitmap(spp,_top,top,1);

    for (int k = 0; k < spp - 1; k++)
        dest[k] = int_mult(bottom[k], 255 - alpha, t1) + int_mult(_top[k], alpha, t2);
    dest[spp-1]=bottom[spp-1];
}

void replace_pm(int spp, unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    if(topOpacity) {
        memcpy(dest,top,spp);
    } else {
        memcpy(dest,bottom,spp);
    }
}

void replace_alpha_pm(int spp, unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    int t1,t2;

    if (topOpacity==0) {
        memcpy(dest,bottom,spp);
        return;
    }

    unpremultiplyBitmap(spp,dest,bottom,1);

    dest[spp - 1] = int_mult(bottom[spp - 1], 255 - topOpacity, t1) + int_mult(top[0], topOpacity, t2);

    premultiplyBitmap(spp,dest,dest,1);
}

void replace_primary_pm(int spp, unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    if (topOpacity==0) {
        memcpy(dest,bottom,spp);
        return;
    }
    unsigned char alpha = bottom[alphaPos];
    unpremultiplyBitmap(spp,dest,top,1);
    dest[alphaPos] = alpha;
    premultiplyBitmap(spp,dest,dest,1);
}

void erase_pm(int spp,unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity){
    int t1;
    unsigned char alpha = int_mult(top[alphaPos],topOpacity,t1);
    memcpy(dest,bottom,spp-1);
    dest[alphaPos]=MAX(bottom[alphaPos]-alpha,0);
}



