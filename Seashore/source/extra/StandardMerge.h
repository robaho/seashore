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

