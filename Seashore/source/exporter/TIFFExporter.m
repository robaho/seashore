#import "TIFFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"
#import <TIFF/tiff.h>
#import <TIFF/tiffio.h>

@implementation TIFFExporter

- (id)init
{
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (BOOL)hasOptions
{
	return YES;
}

- (IBAction)showOptions:(id)sender
{
	// Work things out
	if ([[idocument contents] cmykSave])
		[targetRadios selectCellAtRow:1 column:0];
	else
		[targetRadios selectCellAtRow:0 column:0];
	
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
}

- (IBAction)targetChanged:(id)sender
{
	switch ([targetRadios selectedRow]) {
		case 0:
			[[idocument contents] setCMYKSave:NO];
		break;
		case 1:
			[[idocument contents] setCMYKSave:YES];
		break;
	}
}

- (IBAction)endPanel:(id)sender
{
	[NSApp stopModal];
}

- (NSString *)title
{
	return @"TIFF image";
}

- (NSString *)extension
{
	return @"tiff";
}

- (NSString *)optionsString
{
	if ([[idocument contents] cmykSave])
		return @"CMYK";
	else
		return @"RGB/RGBA";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int i, j, width, height, spp, xres, yres;
	unsigned char *srcData,*destData;
	//NSBitmapImageRep *imageRep;
	BOOL hasAlpha = NO;

	// Get the data to write
	srcData = [(SeaWhiteboard *)[document whiteboard] data];
	width = [(SeaContent *)[document contents] width];
	height = [(SeaContent *)[document contents] height];
	spp = [(SeaContent *)[document contents] spp];
	xres = [[document contents] xres];
	yres = [[document contents] yres];
    
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
    
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
	// Behave differently if we are targeting a CMYK file
	if ([[document contents] cmykSave] && spp == 4) {
        
        NSColorSpace* cs = [NSColorSpace deviceCMYKColorSpace];
        imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
    }
    
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSTIFFCompressionLZW] forKey:NSImageCompressionMethod];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
    NSData *imageData = [imageRep representationUsingType:NSBitmapImageFileTypeTIFF properties:imageProps];

    [imageData writeToFile:path atomically:NO];
    
    return YES;

}

@end
