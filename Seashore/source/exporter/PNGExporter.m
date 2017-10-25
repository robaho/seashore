#import "PNGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"

@implementation PNGExporter

- (BOOL)hasOptions
{
	return NO;
}

- (IBAction)showOptions:(id)sender
{
}

- (NSString *)title
{
	return @"Portable Network Graphics image";
}

- (NSString *)extension
{
	return @"png";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int i, j, width, height, spp;
	unsigned char *srcData, *destData;
	NSBitmapImageRep *imageRep;
	NSData *imageData;
	BOOL hasAlpha = NO;
	
	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	
	// Determine whether or not an alpha channel would be redundant
	for (i = 0; i < width * height && hasAlpha == NO; i++) {
		if (srcData[(i + 1) * spp - 1] != 255)
			hasAlpha = YES;
	}
	
	// Strip the alpha channel if necessary
	if (!hasAlpha) {
		spp--;
		destData = malloc(width * height * spp);
		for (i = 0; i < width * height; i++) {
			for (j = 0; j < spp; j++)
				destData[i * spp + j] = srcData[i * (spp + 1) + j];
		}
	}
	else
		destData = srcData;
	
	// Make an image representation from the data
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
	imageData = [imageRep representationUsingType:NSPNGFileType properties:NULL];
		
	// Save our file and let's go
	[imageData writeToFile:path atomically:YES];
	[imageRep autorelease];
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end
