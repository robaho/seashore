#import "TIFFExporter.h"
#import "SeaContent.h"
#import "SeaLayer.h"
#import "SeaDocument.h"
#import "SeaWhiteboard.h"
#import "Bitmap.h"

@implementation TIFFExporter

- (id)init
{
	return self;
}

- (BOOL)hasOptions
{
    // Work things out
    if ([[idocument contents] saveProofProfile])
        [targetRadios selectCellAtRow:2 column:0];
    else
        [targetRadios selectCellAtRow:0 column:0];
    
	return YES;
}

- (IBAction)showOptions:(id)sender
{
	// Display the options dialog
	[panel center];
	[NSApp runModalForWindow:panel];
	[panel orderOut:self];
}

- (IBAction)targetChanged:(id)sender
{
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
    SeaColorProfile *cp = [[idocument whiteboard] proofProfile];
                           
    switch ([targetRadios selectedRow]) {
        case 0:
            return @"RGB/RGBA";
        case 1:
            return @"CMYK";
        case 2:
            if(cp!=NULL && cp.cs!=NULL){
                return cp.desc;
            }
            return @"RGB/RGBA";
    }
    return @"Unknown";
}

- (BOOL)writeDocument:(id)document toFile:(NSString *)path
{
	int width, height, spp, xres, yres;
	unsigned char *srcData,*destData;
	BOOL hasAlpha = true;
    NSDictionary *exifData;

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
    
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&destData pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:(spp == 4) ? MyRGBSpace : MyGraySpace bytesPerRow:width * spp bitsPerPixel:8 * spp];
    
    switch([targetRadios selectedRow]) {
        case 1: {
                NSColorSpace* cs = [NSColorSpace deviceCMYKColorSpace];
                imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cs renderingIntent:NSColorRenderingIntentDefault];
            }
            break;
        case 2:{
                SeaColorProfile *cp = [[document whiteboard] proofProfile];
                if(cp!=NULL && cp.cs!=NULL){
                    imageRep = [imageRep bitmapImageRepByConvertingToColorSpace:cp.cs renderingIntent:NSColorRenderingIntentDefault];
                }
            }
            break;
    }
    
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSTIFFCompressionLZW] forKey:NSImageCompressionMethod];
    
    NSSize newSize;
    newSize.width = [imageRep pixelsWide] * 72.0 / xres;  // x-resolution
    newSize.height = [imageRep pixelsHigh] * 72.0 / yres;  // y-resolution
    
    [imageRep setSize:newSize];
    
    exifData = [[document contents] exifData];
    if (exifData) [imageRep setProperty:@"NSImageEXIFData" withValue:exifData];
    
    NSData *imageData = [imageRep representationUsingType:NSBitmapImageFileTypeTIFF properties:imageProps];

    [imageData writeToFile:path atomically:NO];

    // If the destination data is not equivalent to the source data free the former
    if (destData != srcData)
        free(destData);
    
    return YES;
}

@end
