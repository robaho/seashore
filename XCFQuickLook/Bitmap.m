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

/*
	Gray -> Gray
	RGB -> RGB
	CMYK -> RGB
	CMYK -> Gray
	Gray -> RGB
	RGB -> Gray
*/

void covertBitmapColorSync(unsigned char *dbitmap, int dspp, int dspace, unsigned char *ibitmap, int width, int height, int ispp, int ispace, int ibps, CMProfileLocation *iprofile)
{
	CMProfileRef srcProf, destProf;
	CMBitmap srcBitmap, destBitmap;
	CMWorldRef cw;
	BOOL mustClose;
	
	if (ispace == kGrayColorSpace && dspace == kGrayColorSpace) {
	
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		if (ibps == 8)
			srcBitmap.space = (ispp == 1) ? cmGray8Space : cmGrayA16Space;
		else
			srcBitmap.space = (ispp == 1) ? cmGray16Space : cmGrayA32Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 2;
		destBitmap.pixelSize = 8 * 2;
		destBitmap.space = cmGrayA16Space;
		
		// Execute the conversion
		CMOpenProfile(&srcProf, iprofile);
		CMGetDefaultProfileBySpace(cmGrayData, &destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CMCloseProfile(srcProf);
	
	}
	else if (ispace == kRGBColorSpace && dspace == kRGBColorSpace) {
		
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		if (ibps == 8)
			srcBitmap.space = (ispp == 3) ? cmRGB24Space : cmRGBA32Space;
		else
			srcBitmap.space = (ispp == 3) ? cmRGB48Space : cmRGBA64Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmRGBA32Space;
		
		// Execute the conversion
		CMOpenProfile(&srcProf, iprofile);
		OpenDisplayProfile(&destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CloseDisplayProfile(destProf);
		CMCloseProfile(srcProf);
		
	}
	else if (ispace == kCMYKColorSpace && dspace == kRGBColorSpace) {
	
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		srcBitmap.space = (ibps == 8) ? cmCMYK32Space : cmCMYK64Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmRGBA32Space;
		
		// Execute the conversion
		if (iprofile == NULL) {
			CMGetDefaultProfileBySpace(cmCMYKData, &srcProf);
			mustClose = NO;
		}
		else {
			CMOpenProfile(&srcProf, iprofile);
			mustClose = YES;
		}
		OpenDisplayProfile(&destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CloseDisplayProfile(destProf);
		if (mustClose) {
			CMCloseProfile(srcProf);
		}
	
	}
	else if (ispace == kCMYKColorSpace && dspace == kGrayColorSpace) {
	
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		srcBitmap.space = (ibps == 8) ? cmCMYK32Space : cmCMYK64Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 2;
		destBitmap.pixelSize = 8 * 2;
		destBitmap.space = cmGrayA16Space;
		
		// Execute the conversion
		if (iprofile == NULL) {
			CMGetDefaultProfileBySpace(cmCMYKData, &srcProf);
			mustClose = NO;
		}
		else {
			CMOpenProfile(&srcProf, iprofile);
			mustClose = YES;
		}
		OpenDisplayProfile(&destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CloseDisplayProfile(destProf);
		if (mustClose) {
			CMCloseProfile(srcProf);
		}
	
	}
	else if (ispace == kGrayColorSpace && dspace == kRGBColorSpace) {
		
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		if (ibps == 8)
			srcBitmap.space = (ispp == 1) ? cmGray8Space : cmGrayA16Space;
		else
			srcBitmap.space = (ispp == 1) ? cmGray16Space : cmGrayA32Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 4;
		destBitmap.pixelSize = 8 * 4;
		destBitmap.space = cmRGBA32Space;
		
		// Execute the conversion
		CMOpenProfile(&srcProf, iprofile);
		OpenDisplayProfile(&destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CloseDisplayProfile(destProf);
		CMCloseProfile(srcProf);
		
	}
	else if (ispace == kRGBColorSpace && dspace == kGrayColorSpace) {
		
		// Define the source
		srcBitmap.image = ibitmap;
		srcBitmap.width = width;
		srcBitmap.height = height;
		srcBitmap.rowBytes = width * ispp * (ibps / 8);
		srcBitmap.pixelSize = ispp * ibps;
		if (ibps == 8)
			srcBitmap.space = (ispp == 3) ? cmRGB24Space : cmRGBA32Space;
		else
			srcBitmap.space = (ispp == 3) ? cmRGB48Space : cmRGBA64Space;
		
		// Define the destination
		destBitmap.image = dbitmap;
		destBitmap.width = width;
		destBitmap.height = height;
		destBitmap.rowBytes = width * 2;
		destBitmap.pixelSize = 8 * 2;
		destBitmap.space = cmGrayA16Space;
		
		// Execute the conversion
		CMOpenProfile(&srcProf, iprofile);
		CMGetDefaultProfileBySpace(cmGrayData, &destProf);
		NCWNewColorWorld(&cw, srcProf, destProf);
		CWMatchBitmap(cw, &srcBitmap, NULL, 0, &destBitmap);
		CWDisposeColorWorld(cw);
		CMCloseProfile(srcProf);
		
	}
}

/*
	Gray -> Gray
	RGB -> RGB
	Gray -> RGB
	RGB -> Gray
*/

void covertBitmapNoColorSync(unsigned char *dbitmap, int dspp, int dspace, unsigned char *ibitmap, int width, int height, int ispp, int ispace, int ibps)
{
	int i, j;
	
	if (ispace == kGrayColorSpace && dspace == kGrayColorSpace) {
		
		if (ibps == 8) {
			if (ispp == 2) {
				memcpy(dbitmap, ibitmap, width * height * 2);
			}
			else {
				for (i = 0; i < width * height; i++) {
					dbitmap[i * 2] = ibitmap[i * 1];
				}
			}
		}
		else if (ibps == 16) {
			for (i = 0; i < width * height; i++) {
				for (j = 0; j < ispp; j++) {
					dbitmap[i * 2 + j] = ibitmap[i * ispp * 2 + j * 2 + MSB];
				}
			}
		}
	
	}
	else if (ispace == kRGBColorSpace && dspace == kRGBColorSpace) {
	
		if (ibps == 8) {
			if (ispp == 4) {
				memcpy(dbitmap, ibitmap, width * height * 4);
			}
			else {
				for (i = 0; i < width * height; i++) {
					memcpy(&(dbitmap[i * 4]), &(ibitmap[i * 3]), 3);
				}
			}
		}
		else if (ibps == 16) {
			for (i = 0; i < width * height; i++) {
				for (j = 0; j < ispp; j++) {
					dbitmap[i * 4 + j] = ibitmap[i * ispp * 2 + j * 2 + MSB];
				}
			}
		}
				
	}
	else if (ispace == kGrayColorSpace && dspace == kRGBColorSpace) {
		
		if (ibps == 8) {
			for (i = 0; i < width * height; i++) {
				dbitmap[i * 4] = dbitmap[i * 4 + 1] = dbitmap[i * 4 + 2] = ibitmap[i * ispp];
				if (ispp == 2) dbitmap[i * 4 + 3] = ibitmap[i * ispp + 1];
			}
		}
		else if (ibps == 16) {
			for (i = 0; i < width * height; i++) {
				dbitmap[i * 4] = dbitmap[i * 4 + 1] = dbitmap[i * 4 + 2] = ibitmap[i * ispp * 2 + MSB];
				if (ispp == 2) dbitmap[i * 4 + 3] = ibitmap[i * 4 + 2 + MSB];
			}
		}
				
	}
	else if (ispace == kRGBColorSpace && dspace == kGrayColorSpace) {
	
		if (ibps == 8) {
			for (i = 0; i < width * height; i++) {
				dbitmap[i * 2] = ((int)ibitmap[i * ispp] + (int)ibitmap[i * ispp + 1] + (int)ibitmap[i * ispp + 2]) / 3;
				if (ispp == 4) dbitmap[i * 2 + 1] = ibitmap[i * 4 + 3];
			}
		}
		else if (ibps == 16) {
			for (i = 0; i < width * height; i++) {
				dbitmap[i * 2] = ((int)ibitmap[i * ispp * 2 + MSB] + (int)ibitmap[i * ispp * 2 + 2 + MSB] + (int)ibitmap[i * ispp * 2 + 4 + MSB]) / 3;
				if (ispp == 4) dbitmap[i * 2 + 1] = ibitmap[i * 8 + 6 + MSB];
			}
		}
				
	}
	
}

unsigned char *convertBitmap(int dspp, int dspace, int dbps, unsigned char *ibitmap, int width, int height, int ispp, int ibipp, int ibypr, int ispace, CMProfileLocation *iprofile, int ibps, int iformat)
{
	PtrRecord ptrs;
	unsigned char *bitmap, *pbitmap;
	int pos;
	BOOL s_hasalpha;
	NSString *fail;
	int i, j, k, l;

#ifdef DEBUG
	if (!iprofile) {
		NSLog(@"No ColorSync profile!");
	}
#endif
	
	iprofile = NULL;
	
	// Point out conversions that are not possible
	fail = NULL;
	if (dbps != 8) fail = @"Only converts to 8 bps";
	if (dspace == kCMYKColorSpace) fail = @"Cannot convert to CMYK color space";
	if (dspace == kInvertedGrayColorSpace) fail = @"Cannot convert to inverted gray color space";
	if (dspace == kRGBColorSpace && dspp != 4) fail = @"Can only convert to 4 spp for RGB color space";
	if (dspace == kGrayColorSpace && dspp != 2) fail = @"Can only convert to 2 spp for RGB color space";
	if (fail) { NSLog(fail); return NULL; }
	
	// Create initial pointer
	ptrs = initPtrs(ibitmap, ibypr * height);
	
	// Convert to from 1-, 2- or 4-bit to 8-bit
	if (ibps < 8) {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * ispp); 
		for (j = 0; j < height; j++) {
			for (i = 0; i < width; i++) {
				for (k = 0; k < ispp; k++) {
					pos = (j * width + i) * ispp + k;
					bitmap[pos] = 0;
					for (l = 0; l < ibps; l++) {
						if (bit_test(&pbitmap[j * ibypr + (i * ibipp + l) / 8], 7 - ((i * ibipp + l) % 8))) {
							bit_set(&bitmap[pos], l);
						}
						bitmap[pos] *= (255 / ((1 << ibps) - 1));
					}
				}
			}
		}
		ibps = 8;
		ibipp = ispp * 8;
		ibypr = width * ispp;
		iprofile = NULL; /* Sorry no ColorSync profiles for less than 8 bits */
	}
	
	// Remove redundant bits and bytes
	if (ibps == 8) {
		if (ibipp != ispp * 8 || ibypr != width * ispp) {
			pbitmap = getPtr(ptrs);
			bitmap = mallocPtr(&ptrs, width * height * ispp);
			for (j = 0; j < height; j++) {
				for (i = 0; i < width; i++) {
					for (k = 0; k < ispp; k++) {
						bitmap[(j * width + i) * ispp + k] = pbitmap[j * ibypr + i * (ibipp / 8) + k];
					}
				}
			}
			ibipp = ispp * 8;
			ibypr = width * ispp;
		}
	}
	else if (ibps == 16) {
		if (ibipp != ispp * 16 || ibypr != width * ispp * 2) {
			pbitmap = getPtr(ptrs);
			bitmap = mallocPtr(&ptrs, width * height * ispp * 2);
			for (j = 0; j < height; j++) {
				for (i = 0; i < width; i++) {
					for (k = 0; k < ispp; k++) {
						bitmap[((j * width + i) * ispp + k) * 2] = pbitmap[j * ibypr + i * (ibipp / 8) + k * 2];
						bitmap[((j * width + i) * ispp + k) * 2 + 1] = pbitmap[j * ibypr + i * (ibipp / 8) + k * 2 + 1];
					}
				}
			}
			ibipp = ispp * 16;
			ibypr = width * ispp * 2;
		}
	}
	
	// Swap alpha (if necessary)
	if (iformat & kAlphaFirstFormat) {
		pbitmap = getPtr(ptrs); /* Note: transform is destructive (other destructive transforms follow) */
		if (ibps == 8) {
			for (i = 0; i < width * height; i++) {
				rotate_bytes(pbitmap, i * ispp, (i + 1) * ispp - 1);
			}
		}
		else if (ibps == 16) {
			pbitmap = getPtr(ptrs);
			for (i = 0; i < width * height; i++) {
				rotate_bytes(pbitmap, i * ispp * 2, i * ispp * 2 - 1);
				rotate_bytes(pbitmap, i * ispp * 2, i * ispp * 2 - 1);
			}
		}
		iformat = iformat & ~(kAlphaFirstFormat);
	}

	// Convert inverted gray color space
	if (ispace == kInvertedGrayColorSpace) {
		pbitmap = getPtr(ptrs);
		if (ibps == 8) {
			for (i = 0; i < width * height; i++) {
				pbitmap[i * ispp] = ~pbitmap[i * ispp];
			}
		}
		else if (ibps == 16) {
			for (i = 0; i < width * height; i++) {
				pbitmap[i * ispp * 2] = ~pbitmap[i * ispp * 2];
				pbitmap[i * ispp * 2 + 1] = ~pbitmap[i * ispp * 2 + 1];
			}
		}
		ispace = kGrayColorSpace;
	}

	// Convert colour space
	if (iprofile || ispace == kCMYKColorSpace) {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * dspp);
		covertBitmapColorSync(bitmap, dspp, dspace, pbitmap, width, height, ispp, ispace, ibps, iprofile);
	}
	else {
		pbitmap = getPtr(ptrs);
		bitmap = mallocPtr(&ptrs, width * height * dspp);
		covertBitmapNoColorSync(bitmap, dspp, dspace, pbitmap, width, height, ispp, ispace, ibps);
	}
	
	// Add in alpha (not 16-bit friendly)
	s_hasalpha = (ispace == kRGBColorSpace && ispp == 4) || (ispace == kGrayColorSpace && ispp == 2);
	if (!s_hasalpha) {
		for (i = 0; i < width * height; i++) {
			pbitmap = getPtr(ptrs);
			pbitmap[(i + 1) * dspp - 1] = 255;
		}
	}
	
	// Return result
	freePtrs(ptrs);
	
	return getFinalPtr(ptrs);
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

 void OpenDisplayProfile(CMProfileRef *profile)
{
	CMDeviceID device;
	CMDeviceProfileID deviceID;
	CMProfileLocation profileLoc;
	
	CMGetDefaultDevice(cmDisplayDeviceClass, &device);
	CMGetDeviceDefaultProfileID(cmDisplayDeviceClass, device, &deviceID);
	CMGetDeviceProfile(cmDisplayDeviceClass, device, deviceID, &profileLoc);
	CMOpenProfile(profile, &profileLoc); 
}

 void CloseDisplayProfile(CMProfileRef profile)
{
	CMCloseProfile(profile);
}

