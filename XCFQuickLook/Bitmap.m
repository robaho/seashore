#include "Bitmap.h"
#import "bitstring.h"

#define kMaxPtrsInPtrRecord 8

typedef struct {
	unsigned char *ptrs[kMaxPtrsInPtrRecord];
	int n;
	int init_size;
} PtrRecord;

 PtrRecord initPtrs(unsigned char *initial, int init_size)
{
	PtrRecord ptrs;
	
	ptrs.ptrs[0] = initial;
	ptrs.n = 1;
	ptrs.init_size = init_size;
	
	return ptrs;
}

 unsigned char *getPtr(PtrRecord ptrs)
{
	return ptrs.ptrs[ptrs.n - 1];
}

 unsigned char *getFinalPtr(PtrRecord ptrs)
{
	unsigned char *result;
	
	if (ptrs.n == 0) {
		result = malloc(make_128(ptrs.init_size));
		memcpy(result, ptrs.ptrs[0], ptrs.init_size);
	}
	else {
		result = ptrs.ptrs[ptrs.n - 1];
	}
	
	return result;
}

unsigned char *mallocPtr(PtrRecord *ptrs, int size)
{
	unsigned char *result;
	
	if (ptrs->n < kMaxPtrsInPtrRecord) {
		ptrs->ptrs[ptrs->n] = malloc(make_128(size));
		result = ptrs->ptrs[ptrs->n];
		ptrs->n++;
	}
	else {
		NSLog(@"Cannot add more pointers to pointer record");
		result = NULL;
	}
	
	return result;
}

 void freePtrs(PtrRecord ptrs)
{
	int i;
	
	for (i = 1; i < ptrs.n - 1; i++) {
		free(ptrs.ptrs[i]);
	}
}

 void rotate_bytes(unsigned char *data, int pos1, int pos2)
{
	unsigned char tmp;
	int i;
	
	tmp = data[pos1];
	for (i = pos1; i < pos2 - 1; i++) data[i] = data[i + 1];
	data[pos2] = tmp;
}

 void stripAlphaToWhite(int spp, unsigned char *output, unsigned char *input, int length)
{
	const int alphaPos = spp - 1;
	const int outputSPP = spp - 1;
	unsigned char alpha;
	double alphaRatio;
	int t1, t2, newValue;
	int i, k;
	
	memset(output, 255, length * outputSPP);
	
	for (i = 0; i < length; i++) {
		
		alpha = input[i * spp + alphaPos];
		
		if (alpha == 255) {
			for (k = 0; k < outputSPP; k++)
				output[i * outputSPP + k] = input[i * spp + k];
		}
		else {
			if (alpha != 0) {

				alphaRatio = 255.0 / alpha;
				for (k = 0; k < outputSPP; k++) {
					newValue = 0.5 + input[i * spp + k] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * outputSPP + k] = int_mult(newValue, alpha, t1) + int_mult(255, (255 - alpha), t2);
				}
				
			}
		}
	
	} 
}

 void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
	int i, j, alphaPos, temp;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		}
		else {
			if (input[alphaPos] != 0) {
				for (j = 0; j < spp - 1; j++)
					output[i * spp + j] = int_mult(input[i * spp + j], input[alphaPos], temp);
				output[alphaPos] = input[alphaPos];
			}
			else {
				for (j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}

 void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
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

 unsigned char averagedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where)
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
		
	return (total / count);
}
