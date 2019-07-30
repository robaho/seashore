#import "PNGExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"

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
	int width, height, spp, xres, yres;
	unsigned char *srcData, *destData;
	NSBitmapImageRep *imageRep;
	NSData *imageData;
	BOOL hasAlpha = true;
	
	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
    xres = [[document contents] xres];
    yres = [[document contents] yres];
	
    destData = stripAlpha(srcData,width,height,spp);
    if (destData!=srcData) {
        spp--;
        hasAlpha=false;
    }
    
	// Make an image representation from the data
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp > 2) ? MyRGBSpace : MyGraySpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
	imageData = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		
    NSError *error;
	// Save our file and let's go
    if([imageData writeToFile:path options:0 error:&error]==NO) {
        NSLog(@"unable to write file %@",error);
    }
	
	// If the destination data is not equivalent to the source data free the former
	if (destData != srcData)
		free(destData);
	
	return YES;
}

@end
