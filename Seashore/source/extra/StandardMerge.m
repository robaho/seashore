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

#define alphaPos (spp - 1)

void normalMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
    unsigned char alpha;
    int t1, t2;

    unsigned char *sPtr = srcPtr+srcLoc;
    unsigned char *sPtrEnd = sPtr+alphaPos;
    unsigned char *dPtr = destPtr+destLoc;

    alpha = int_mult(*(sPtrEnd), srcOpacity, t1);
    unsigned char alpha0 = 255-alpha;

    if (alpha == 0)
        return;

    if (alpha == 255) {
        while(sPtr<sPtrEnd) {
            *dPtr++ = *sPtr++;
        }
        *dPtr = 255;
    }
    else {
        while(sPtr<sPtrEnd) {
            *dPtr = int_mult (*sPtr, alpha, t1) + int_mult (*dPtr,alpha0, t2);
            sPtr++;
            dPtr++;
        }
        *dPtr = alpha + int_mult(alpha0, *dPtr, t1);
    }
}

void blendPixel(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int blend)
{
    const int blend1 = 256 - blend;
    const int blend2 = blend + 1;
    int a1, a2, a;

    unsigned char *sPtr = srcPtr+srcLoc;
    unsigned char *sPtrEnd = sPtr+alphaPos;
    unsigned char *dPtr = destPtr+destLoc;
    unsigned char *dPtrEnd = dPtr+alphaPos;

    a1 = blend1 * *sPtrEnd;
    a2 = blend2 * *dPtrEnd;
    a = a1 + a2;

    if (a == 0) {
        memset(dPtr,0,spp);
    }
    else {
        for (;sPtr<sPtrEnd;dPtr++,sPtr++)
            *dPtr = (*sPtr * a1 + *dPtr * a2) / a;
        *dPtrEnd = a >> 8;
    }
}

void dissolveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int randVal;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++)
        destPtr[destLoc + k] = srcPtr[srcLoc + k];

    randVal = (random() & 0xff);
    destPtr[destLoc + alphaPos] = (randVal > alpha) ? 0 : alpha;
}

void additiveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        if (srcPtr[srcLoc + k] + destPtr[destLoc + k] < 255)
            destPtr[destLoc + k] = srcPtr[srcLoc + k] + destPtr[destLoc + k];
        else
            destPtr[destLoc + k] = 255;
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void differenceMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        if (srcPtr[srcLoc + k] > destPtr[destLoc + k])
            destPtr[destLoc + k] = srcPtr[srcLoc + k] - destPtr[destLoc + k];
        else
            destPtr[destLoc + k] = destPtr[destLoc + k] - srcPtr[srcLoc + k];
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void multiplyMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int t1;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++)
        destPtr[destLoc + k] = int_mult(srcPtr[srcLoc + k], destPtr[destLoc + k], t1);

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void overlayMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int val,t1;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        unsigned char src = srcPtr[k];
        unsigned char dst = destPtr[k];

        if (dst < 128)
            val = (2 * int_mult(src,dst,t1));
        else
            val = 255 - 2 * int_mult(255 - dst,255-src,t1);

        destPtr[k] = MAX(0, MIN(255, val));
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void screenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int t1;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        destPtr[destLoc + k] = 255 - int_mult((255 - srcPtr[srcLoc + k]), (255 - destPtr[destLoc + k]), t1);
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void subtractiveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        if (destPtr[destLoc + k] - srcPtr[srcLoc + k] > 0)
            destPtr[destLoc + k] = destPtr[destLoc + k] - srcPtr[srcLoc + k];
        else
            destPtr[destLoc + k] = 0;
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void darkenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        if (srcPtr[srcLoc + k] > destPtr[destLoc + k])
            destPtr[destLoc + k] = destPtr[destLoc + k];
        else
            destPtr[destLoc + k] = srcPtr[srcLoc + k];
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void lightenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        if (destPtr[destLoc + k] > srcPtr[srcLoc + k])
            destPtr[destLoc + k] = destPtr[destLoc + k];
        else
            destPtr[destLoc + k] = srcPtr[srcLoc + k];
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void divideMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    unsigned char alpha;
    int temp;
    int k;

    alpha = srcPtr[srcLoc + alphaPos];

    for (k = 0; k < alphaPos; k++) {
        temp = ((destPtr[destLoc + k] * 256) / (1 + srcPtr[srcLoc + k]));
        destPtr[destLoc + k] = MIN (temp, 255);
    }

    destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

void hueMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    if (spp > 2) {

        alpha = srcPtr[srcLoc + alphaPos];

        r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
        r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];

        RGBtoHSV(&r1, &g1, &b1);
        RGBtoHSV(&r2, &g2, &b2);

        r1 = r2;

        HSVtoRGB(&r1, &g1, &b1);

        destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;

        destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);

    }
    else
        normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

void saturationMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    if (spp > 2) {

        alpha = srcPtr[srcLoc + alphaPos];

        r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
        r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];

        RGBtoHSV(&r1, &g1, &b1);
        RGBtoHSV(&r2, &g2, &b2);

        g1 = g2;

        HSVtoRGB(&r1, &g1, &b1);

        destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;

        destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);

    }
    else
        normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

void valueMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    if (spp > 2) {

        alpha = srcPtr[srcLoc + alphaPos];

        r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
        r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];

        RGBtoHSV(&r1, &g1, &b1);
        RGBtoHSV(&r2, &g2, &b2);

        b1 = b2;

        HSVtoRGB(&r1, &g1, &b1);

        destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;

        destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);

    }
    else
        normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

void colorMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int r1, g1, b1, r2, g2, b2;
    int alpha;

    if (spp > 2) {

        alpha = srcPtr[srcLoc + alphaPos];

        r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
        r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];

        RGBtoHLS(&r1, &g1, &b1);
        RGBtoHLS(&r2, &g2, &b2);

        r1 = r2;
        b1 = b2;

        HLStoRGB(&r1, &g1, &b1);

        destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;

        destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);

    }
    else
        normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

void dodgeMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        t1 = destPtr[k] << 8;
        t1 /= 256 - srcPtr[k];
        destPtr[k] = MAX(0, MIN(255, t1));
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void burnMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        t1 = (255 - destPtr[k]) << 8;
        t1 /= srcPtr[k] + 1;
        destPtr[k] = MAX(0, MIN(255, 255 - t1));
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void hardlightMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        if (srcPtr[k] > 128) {
            t1 = (255 - destPtr[k]) * (255 - ((srcPtr[k] - 128) << 1));
            destPtr[k] = MAX(0, MIN(255, 255 - (t1 >> 8)));
        }
        else {
            t1 = destPtr[k] * (srcPtr[k] << 1);
            destPtr[k] = MAX(0, MIN(255, t1 >> 8));
        }
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void softlightMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, t2, tM, tS, k;

    for (k = 0; k < alphaPos; k++) {
        tM = int_mult(destPtr[k], srcPtr[k], t1);
        tS = 255 - int_mult(255 - destPtr[k], 255 - srcPtr[k], t1);
        destPtr[k] = int_mult(255 - destPtr[k], tM, t1) + int_mult(destPtr[k], tS, t2);
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void grainExtractMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        t1 = destPtr[k] - srcPtr[k] + 128;
        destPtr[k] = MAX(0, MIN(255, t1));
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void grainMergeMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        t1 = destPtr[k] + srcPtr[k] - 128;
        destPtr[k] = MAX(0, MIN(255, t1));
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

void exclusionMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    int t1, k;

    for (k = 0; k < alphaPos; k++) {
        t1 = destPtr[k] + srcPtr[k] - 2 * int_mult(destPtr[k],srcPtr[k],t1);
        destPtr[k] = MAX(0, MIN(255, t1));
    }

    destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}


void selectMerge(int choice, int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
    switch (choice) {
//        case XCF_DISSOLVE_MODE:
//            dissolveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeMultiply:
            multiplyMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeScreen:
            screenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeOverlay:
            overlayMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeDifference:
            differenceMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModePlusLighter:
            additiveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
//        case XCF_SUBTRACT_MODE:
//            subtractiveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeDarken:
            darkenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeLighten:
            lightenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeHue:
            hueMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeSaturation:
            saturationMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeLuminosity:
            valueMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeColor:
            colorMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
//        case XCF_DIVIDE_MODE:
//            divideMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        case kCGBlendModeColorDodge:
            dodgeMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeColorBurn:
            burnMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeHardLight:
            hardlightMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeSoftLight:
            softlightMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
            break;
        case kCGBlendModeExclusion:
            exclusionMerge(spp,destPtr,destLoc,srcPtr,srcLoc);
            break;
//        case XCF_GRAIN_EXTRACT_MODE:
//            grainExtractMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
//        case XCF_GRAIN_MERGE_MODE:
//            grainMergeMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
//            break;
        default:
            normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
#ifdef DEBUG
            NSLog(@"Unknown mode %d passed to selectMerge()",choice);
#endif
            break;
    }
}




