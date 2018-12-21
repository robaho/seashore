#include "Bitmap.h"
#import "bitstring.h"

/*
 convert NSImageRep to a format Seashore can work with, which is RGBA, or GrayA. If spp is 4, then RGBA, if 2, the GrayA
 */
unsigned char *convertImageRep(NSImageRep *imageRep,int spp) {
    
    NSColorSpaceName csname = NSDeviceRGBColorSpace;
    if (spp==2) {
        csname = NSCalibratedWhiteColorSpace;
    }
    
    int width = (int)[imageRep pixelsWide];
    int height = (int)[imageRep pixelsHigh];
    
    unsigned char *buffer = malloc(width*height*spp);
    
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:csname bytesPerRow:width*spp
                                                                                     bitsPerPixel:8*spp];
    
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow];
    [NSGraphicsContext setCurrentContext:ctx];
    [imageRep draw];
    [NSGraphicsContext restoreGraphicsState];
    return [bitmapWhoseFormatIKnow bitmapData];
}

inline void stripAlphaToWhite(int spp, unsigned char *output, unsigned char *input, int length)
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

inline void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
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

inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
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

inline unsigned char averagedComponentValue(int spp, unsigned char *data, int width, int height, int component, int radius, IntPoint where)
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

inline void OpenDisplayProfile(CMProfileRef *profile)
{
	CMDeviceID device;
	CMDeviceProfileID deviceID;
	CMProfileLocation profileLoc;

	// Actually, maybe we don't need the generic profile after all
    /*OSStatus StatusError = noErr;
    
    // build up a profile location for ColorSync
    profileLoc.locType        = cmPathBasedProfile;
    strcpy(profileLoc.u.pathLoc.path, "/System/Library/ColorSync/Profiles/Generic RGB Profile.icc");
    
    // Open the pro	file with ColourSync
    StatusError = CMOpenProfile(profile, &profileLoc);
	
	if (StatusError != noErr) {*/
		CMGetDefaultDevice(cmDisplayDeviceClass, &device);
		CMGetDeviceDefaultProfileID(cmDisplayDeviceClass, device, &deviceID);
		CMGetDeviceProfile(cmDisplayDeviceClass, device, deviceID, &profileLoc);
		CMOpenProfile(profile, &profileLoc);
	//}
}

void CloseDisplayProfile(CMProfileRef profile)
{
	CMCloseProfile(profile);
}

void CMFlattenProfile(CMProfileRef pref, int flags, CMFlattenUPP *cmFlattenUPP, void * refcon, Boolean *cmmNotFound){
    
}
