/*
	Brushed 0.8.1
	
	This header is included by all project header files, its contents
	are available throughout the project.
	
	Copyright (c) 2002 Mark Pazolli
	Distributed under the terms of the GNU General Public License
*/

#import <Cocoa/Cocoa.h>

#define INT_MULT(a,b,t)  ((t) = (a) * (b) + 0x80, ((((t) >> 8) + (t)) >> 8))

// Premultiplies the alpha channel of an image - destPtr's memory may intersect srcPtr's

static inline void premultiplyAlpha(int spp, unsigned char *destPtr, unsigned char *srcPtr, int length)
{
	int i, j, alphaPos, temp;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (srcPtr[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				destPtr[i * spp + j] = srcPtr[i * spp + j];
		}
		else {
			if (srcPtr[alphaPos] != 0) {
				for (j = 0; j < spp - 1; j++)
					destPtr[i * spp + j] = INT_MULT(srcPtr[i * spp + j], srcPtr[alphaPos], temp);
				destPtr[alphaPos] = srcPtr[alphaPos];
			}
			else {
				for (j = 0; j < spp; j++)
					destPtr[i * spp + j] = 0;
			}
		}
	}
}

// Unpremultiplies the alpha channel of an image - destPtr's memory may intersect srcPtr's

static inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
	int i, j, alphaPos, newValue;
	double alphaRatio;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		}
		else {
			if (input[alphaPos] != 0) {
				alphaRatio = 255.0 / input[alphaPos];
				for (j = 0; j < spp - 1; j++) {
					newValue = 0.5 + input[i * spp + j] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * spp + j] = newValue;
				}
				output[alphaPos] = input[alphaPos];
			}
			else {
				for (j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}
