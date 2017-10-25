#import "GIFExporter.h"
#import "SeaContent.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"

@implementation GIFExporter

- (BOOL) hasOptions
{
	return NO;
}

- (IBAction) showOptions: (id) sender
{
	
}

- (NSString *) title
{
	return @"Graphics Interchange Format (GIF)";
}

- (NSString *) extension
{
	return @"gif";
}

- (BOOL) writeDocument: (id) document toFile: (NSString *) path
{
	// Get the image data
	unsigned char* srcData = [(SeaWhiteboard *)[document whiteboard] data];
	int width = [(SeaContent *)[document contents] width];
	int height = [(SeaContent *)[document contents] height];
	int spp = [(SeaContent *)[document contents] spp];
	
	// Strip the alpha channel (there is no alpha in then GIF format)
	unsigned char* destData = malloc(width * height * (spp - 1));
	stripAlphaToWhite(spp, destData, srcData, width * height);
	spp--;
	
	// Make an image representation from the data
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]	initWithBitmapDataPlanes: &destData
			pixelsWide: width 
			pixelsHigh: height 
			bitsPerSample: 8
			samplesPerPixel: spp
			hasAlpha: NO 
			isPlanar: NO 
			colorSpaceName: (spp > 2) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace 
			bytesPerRow:width * spp 
			bitsPerPixel: 8 * spp];
	
	// With these GIF properties, we will let the OS do the dithering
	NSDictionary *gifProperties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSImageDitherTransparency, NULL];
	
	// Save to a file
	NSData* imageData = [imageRep representationUsingType: NSGIFFileType properties: gifProperties];
	[imageData writeToFile: path atomically: YES];
	
	// Cleanup
	[imageRep autorelease];
	free(destData);
	
	return YES;
}

@end
