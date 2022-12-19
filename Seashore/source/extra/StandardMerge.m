#import "StandardMerge.h"
#import "ColorConversion.h"

#define SPP 4

void merge_alpha_pm(unsigned char *top, unsigned char *bottom, unsigned char *dest,unsigned char topOpacity)
{
    memcpy(dest,bottom,SPP);

    if (topOpacity == 0) {
        return;
    }

    unsigned char alpha = *top;
    unsigned char alpha0 = (top[alphaPos] * topOpacity)/255;

    unsigned char merged = (alpha * topOpacity)/255 + (bottom[alphaPos] * (255-alpha0))/255;

    dest[alphaPos] = merged;
}

// merge pre-multiplied top onto non-premultiplied bottom into non-premultiplied dest
void merge_primary_pm(unsigned char *top, unsigned char *bottom, unsigned char *dest,unsigned char topOpacity)
{
    int t1,t2;

    int alpha = top[alphaPos];

    alpha = int_mult(alpha,topOpacity,t1);

    if (alpha == 0) {
        memcpy(dest,bottom,SPP);
        return;
    }

    unsigned char _top[SPP];
    unpremultiplyBitmap(SPP,_top,top,1);

    for (int k = CR; k <= CB; k++)
        dest[k] = int_mult(bottom[k], 255 - alpha, t1) + int_mult(_top[k], alpha, t2);
    dest[alphaPos]=bottom[alphaPos];
}

void replace_pm(unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    if(topOpacity) {
        memcpy(dest,top,SPP);
    } else {
        memcpy(dest,bottom,SPP);
    }
}

void replace_alpha_pm(unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    int t1,t2;

    if (topOpacity==0) {
        memcpy(dest,bottom,SPP);
        return;
    }

    unpremultiplyBitmap(SPP,dest,bottom,1);

    dest[alphaPos] = int_mult(bottom[alphaPos], 255 - topOpacity, t1) + int_mult(top[alphaPos], topOpacity, t2);

    premultiplyBitmap(SPP,dest,dest,1);
}

void replace_primary_pm(unsigned char *top, unsigned char *bottom, unsigned char *dest, unsigned char topOpacity)
{
    if (topOpacity==0) {
        memcpy(dest,bottom,SPP);
        return;
    }
    unsigned char alpha = bottom[alphaPos];
    unpremultiplyBitmap(SPP,dest,top,1);
    dest[alphaPos] = alpha;
    premultiplyBitmap(SPP,dest,dest,1);
}

void erase_pm(unsigned char *top,unsigned char *bottom,unsigned char *dest,unsigned char topOpacity){
    int t1;
    unsigned char alpha = int_mult(top[alphaPos],topOpacity,t1);
    memcpy(dest+CR,bottom+CR,SPP-1);
    dest[alphaPos]=MAX(bottom[alphaPos]-alpha,0);
}

void dissolveMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int randVal;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++)
        dest[k] = src[k];

    randVal = (random() & 0xff);
    dest[alphaPos] = (randVal > alpha) ? 0 : alpha;
}

void additiveMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        if (src[k] + dest[k] < 255)
            dest[k] = src[k] + dest[k];
        else
            dest[k] = 255;
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void differenceMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        if (src[k] > dest[k])
            dest[k] = src[k] - dest[k];
        else
            dest[k] = dest[k] - src[k];
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void multiplyMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int t1;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++)
        dest[k] = int_mult(src[k], dest[k], t1);

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void overlayMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int val,t1;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        unsigned char s = src[k];
        unsigned char d = dest[k];

        if (d < 128)
            val = (2 * int_mult(s,d,t1));
        else
            val = 255 - 2 * int_mult(255 - d,255-s,t1);

        dest[k] = MAX(0, MIN(255, val));
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void screenMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int t1;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        dest[k] = 255 - int_mult((255 - src[k]), (255 - dest[k]), t1);
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void subtractiveMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        if (dest[k] - src[k] > 0)
            dest[k] = dest[k] - src[k];
        else
            dest[k] = 0;
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void darkenMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        if (src[k] > dest[k])
            dest[k] = dest[k];
        else
            dest[k] = src[k];
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void lightenMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        if (dest[k] > src[k])
            dest[k] = dest[k];
        else
            dest[k] = src[k];
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void divideMerge(unsigned char *dest, unsigned char *src)
{
    unsigned char alpha;
    int temp;
    int k;

    alpha = src[alphaPos];

    for (k = CR; k <= CB; k++) {
        temp = ((dest[k] * 256) / (1 + src[k]));
        dest[k] = MIN (temp, 255);
    }

    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void hueMerge(unsigned char *dest, unsigned char *src)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    alpha = src[alphaPos];

    r1 = dest[CR]; g1 = dest[CG]; b1 = dest[CB];
    r2 = src[CR]; g2 = src[CG]; b2 = src[CB];

    RGBtoHSV(&r1, &g1, &b1);
    RGBtoHSV(&r2, &g2, &b2);

    r1 = r2;

    HSVtoRGB(&r1, &g1, &b1);

    dest[CR] = r1; dest[CG] = g1; dest[CB] = b1;
    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void saturationMerge(unsigned char *dest, unsigned char *src)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    alpha = src[alphaPos];

    r1 = dest[CR]; g1 = dest[CG]; b1 = dest[CB];
    r2 = src[CR]; g2 = src[CG]; b2 = src[CB];

    RGBtoHSV(&r1, &g1, &b1);
    RGBtoHSV(&r2, &g2, &b2);

    g1 = g2;

    HSVtoRGB(&r1, &g1, &b1);

    dest[CR] = r1; dest[CG] = g1; dest[CB] = b1;
    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void valueMerge(unsigned char *dest, unsigned char *src)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    alpha = src[alphaPos];

    r1 = dest[CR]; g1 = dest[CG]; b1 = dest[CB];
    r2 = src[CR]; g2 = src[CG]; b2 = src[CB];

    RGBtoHSV(&r1, &g1, &b1);
    RGBtoHSV(&r2, &g2, &b2);

    b1 = b2;

    HSVtoRGB(&r1, &g1, &b1);

    dest[CR] = r1; dest[CG] = g1; dest[CB] = b1;
    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void colorMerge(unsigned char *dest, unsigned char *src)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    alpha = src[alphaPos];

    r1 = dest[CR]; g1 = dest[CG]; b1 = dest[CB];
    r2 = src[CR]; g2 = src[CG]; b2 = src[CB];

    RGBtoHLS(&r1, &g1, &b1);
    RGBtoHLS(&r2, &g2, &b2);

    r1 = r2;
    b1 = b2;

    HLStoRGB(&r1, &g1, &b1);

    dest[CR] = r1; dest[CG] = g1; dest[CB] = b1;
    dest[alphaPos] = MIN(alpha, dest[alphaPos]);
}

void dodgeMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        t1 = dest[k] << 8;
        t1 /= 256 - src[k];
        dest[k] = MAX(0, MIN(255, t1));
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void burnMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        t1 = (255 - dest[k]) << 8;
        t1 /= src[k] + 1;
        dest[k] = MAX(0, MIN(255, 255 - t1));
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void hardlightMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        if (src[k] > 128) {
            t1 = (255 - dest[k]) * (255 - ((src[k] - 128) << 1));
            dest[k] = MAX(0, MIN(255, 255 - (t1 >> 8)));
        }
        else {
            t1 = dest[k] * (src[k] << 1);
            dest[k] = MAX(0, MIN(255, t1 >> 8));
        }
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void softlightMerge(unsigned char *dest, unsigned char *src)
{
    int t1, t2, tM, tS, k;

    for (k = CR; k <= CB; k++) {
        tM = int_mult(dest[k], src[k], t1);
        tS = 255 - int_mult(255 - dest[k], 255 - src[k], t1);
        dest[k] = int_mult(255 - dest[k], tM, t1) + int_mult(dest[k], tS, t2);
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void grainExtractMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        t1 = dest[k] - src[k] + 128;
        dest[k] = MAX(0, MIN(255, t1));
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void grainMergeMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        t1 = dest[k] + src[k] - 128;
        dest[k] = MAX(0, MIN(255, t1));
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}

void exclusionMerge(unsigned char *dest, unsigned char *src)
{
    int t1, k;

    for (k = CR; k <= CB; k++) {
        t1 = dest[k] + src[k] - 2 * int_mult(dest[k],src[k],t1);
        dest[k] = MAX(0, MIN(255, t1));
    }

    dest[alphaPos] = MIN(src[alphaPos], dest[alphaPos]);
}


void selectMerge(int choice, unsigned char *destPtr, unsigned char *srcPtr)
{
    switch (choice) {
//        case XCF_DISSOLVE_MODE:
//            dissolveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeMultiply:
            multiplyMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeScreen:
            screenMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeOverlay:
            overlayMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeDifference:
            differenceMerge(destPtr, srcPtr);
            break;
        case kCGBlendModePlusLighter:
            additiveMerge(destPtr, srcPtr);
            break;
//        case XCF_SUBTRACT_MODE:
//            subtractiveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeDarken:
            darkenMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeLighten:
            lightenMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeHue:
            hueMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeSaturation:
            saturationMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeLuminosity:
            valueMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeColor:
            colorMerge(destPtr, srcPtr);
            break;
//        case XCF_DIVIDE_MODE:
//            divideMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeColorDodge:
            dodgeMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeColorBurn:
            burnMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeHardLight:
            hardlightMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeSoftLight:
            softlightMerge(destPtr, srcPtr);
            break;
        case kCGBlendModeExclusion:
            exclusionMerge(destPtr, srcPtr);
            break;
//        case XCF_GRAIN_EXTRACT_MODE:
//            grainExtractMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
//        case XCF_GRAIN_MERGE_MODE:
//            grainMergeMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        default:
            normalMerge(destPtr, srcPtr, 255);
#ifdef DEBUG
            NSLog(@"Unknown mode %d passed to selectMerge()",choice);
#endif
            break;
    }
}




