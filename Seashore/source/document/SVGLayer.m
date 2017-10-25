#import "SeaDocument.h"
#import "SeaContent.h"
#import "SVGLayer.h"
#import "SVGContent.h"
#import "Bitmap.h"

@implementation SVGLayer

- (id)initWithImageRep:(id)imageRep document:(id)doc spp:(int)lspp
{
	int i, space, bps = [imageRep bitsPerSample], sspp = [imageRep samplesPerPixel];
	unsigned char *srcPtr = [imageRep bitmapData];
	CMProfileLocation cmProfileLoc;
	int bipp, bypr;
	id profile;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
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
	data = convertBitmap(spp, (spp == 4) ? kRGBColorSpace : kGrayColorSpace, 8, srcPtr, width, height, sspp, bipp, bypr, space, (profile) ? &cmProfileLoc : NULL, bps, 0);
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
	
	// Unpremultiply the image
	if (hasAlpha)
		unpremultiplyBitmap(spp, data, data, width * height);

	return self;
}

@end
