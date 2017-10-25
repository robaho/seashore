#import "SeaDocument.h"
#import "SeaContent.h"
#import "CocoaLayer.h"
#import "CocoaContent.h"
#import "Bitmap.h"

@implementation CocoaLayer

- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp
{
	int i, space, bps, sspp, format;
	unsigned char *srcPtr;
	CMProfileLocation cmProfileLoc;
	int bipp, bypr;
	id profile;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Fill out variables
	bps = [imageRep bitsPerSample];
	sspp = [imageRep samplesPerPixel];
	srcPtr = [imageRep bitmapData];
	format = 0;
	#ifdef MACOS_10_4_COMPILE
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		format = [imageRep bitmapFormat];
	}
	#endif
	
	// Determine the width and height of this layer
	width = [imageRep pixelsWide];
	height = [imageRep pixelsHigh];
	
	// Determine samples per pixel
	spp = lspp;

	// Determine the color space
	space = -1;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedWhiteColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceWhiteColorSpace])
		space = kGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedBlackColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceBlackColorSpace])
		space = kInvertedGrayColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace] || [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])
		space = kRGBColorSpace;
	if ([[imageRep colorSpaceName] isEqualToString:NSDeviceCMYKColorSpace])
		space = kCMYKColorSpace;
	if (space == -1) {
		NSLog(@"Color space %@ not yet handled.", [imageRep colorSpaceName]);
		[self autorelease];
		return NULL;
	}
	
	// Extract color profile
	profile = [imageRep valueForProperty:NSImageColorSyncProfileData];
	if (profile) {
		cmProfileLoc.locType = cmBufferBasedProfile;
		cmProfileLoc.u.bufferLoc.buffer = (Ptr)[profile bytes];
	}
	
	// Convert data to what we want
	bipp = [imageRep bitsPerPixel];
	bypr = [imageRep bytesPerRow];
	data = convertBitmap(spp, (spp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcPtr, width, height, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, format);
	if (!data) {
		NSLog(@"Required conversion not supported.");
		[self autorelease];
		return NULL;
	}
	
	// Check the alpha
	hasAlpha = NO;
	for (i = 0; i < width * height; i++) {
		if (data[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Unpremultiply the image if required
	#ifdef MACOS_10_4_COMPILE
	if (hasAlpha && !((format & NSAlphaNonpremultipliedBitmapFormat) >> 1)) {
	#endif
		unpremultiplyBitmap(spp, data, data, width * height);
	#ifdef MACOS_10_4_COMPILE
	}
	#endif
		
	return self;
}

@end
